import re
from io import BytesIO

from django.contrib.auth.models import User
from django.contrib.auth.tokens import default_token_generator
from django.core.files.base import ContentFile
from django.db import transaction
from django.utils.encoding import force_str
from django.utils.http import urlsafe_base64_decode
from PIL import Image, ImageOps
from rest_framework import serializers

from .models import Perfil

# Un WhatsApp de Bolivia: exactamente 8 digitos. Es la misma regla que aplica
# la app al escribirlo; aca se repite porque el backend no puede confiar en
# que siempre le llegue desde la app.
_OCHO_DIGITOS = re.compile(r'^\d{8}$')

# La foto de perfil. La app ya la achica antes de mandarla, asi que estos
# topes solo frenan a quien le pegue a la API directo.
FOTO_MAX_BYTES = 5 * 1024 * 1024
FOTO_MAX_PIXELES = 40_000_000
# Se guarda de 512 x 512: el avatar mas grande de la app mide 96, y 512
# alcanza para pantallas de alta densidad sin guardar fotos de 4 MB.
FOTO_LADO = 512


def validar_whatsapp(valor):
    valor = (valor or '').strip()
    if valor and not _OCHO_DIGITOS.match(valor):
        raise serializers.ValidationError('Escribí los 8 dígitos, como 70099988.')
    return valor


class PerfilSerializer(serializers.ModelSerializer):
    """El perfil que ve la persona en Mi perfil.

    Aca se cambia solo el WhatsApp; la foto tiene su propio camino
    (FotoPerfilSerializer) porque viaja como archivo. El rol decide que app ve
    cada una y no se cambia desde adentro (flujo de acceso), y el correo es con
    lo que se recupera la cuenta: cambiarlo pide confirmar la direccion nueva,
    y ese camino todavia no existe.
    """

    username = serializers.CharField(source='usuario.username', read_only=True)
    email = serializers.EmailField(source='usuario.email', read_only=True)
    # La direccion completa, lista para mostrar; null si no tiene foto.
    foto = serializers.SerializerMethodField()

    class Meta:
        model = Perfil
        fields = ('username', 'email', 'rol', 'whatsapp', 'foto', 'creado_en')
        read_only_fields = ('rol', 'creado_en')

    def get_foto(self, perfil):
        if not perfil.foto:
            return None
        request = self.context.get('request')
        url = perfil.foto.url
        return request.build_absolute_uri(url) if request else url

    def validate_whatsapp(self, value):
        return validar_whatsapp(value)

    def validate(self, data):
        perfil = self.instance
        if perfil and perfil.es_propietario and 'whatsapp' in data and not data['whatsapp']:
            raise serializers.ValidationError({
                'whatsapp': 'Un propietario necesita un WhatsApp: es lo que se '
                            'libera cuando aprueba una solicitud.',
            })
        return data


def preparar_foto(archivo):
    """La foto como se guarda: cuadrada, de 512 px, en JPEG y sin metadatos.

    - La endereza segun lo que anoto la camara (EXIF) antes de borrar ese
      dato: si no, las fotos del telefono quedan acostadas.
    - La recorta al centro, porque el avatar es un circulo.
    - La vuelve a escribir sin EXIF: una foto del telefono puede traer las
      coordenadas GPS de donde se saco, y en esta app eso suele ser la casa de
      la persona.
    """
    archivo.seek(0)
    with Image.open(archivo) as original:
        ancho, alto = original.size
        if ancho * alto > FOTO_MAX_PIXELES:
            raise serializers.ValidationError(
                'La foto es demasiado grande. Elegí otra más chica.')
        # Un JPEG se decodifica ya achicado: no hace falta abrir los 12
        # megapixeles de la camara para quedarse con 512.
        original.draft('RGB', (FOTO_LADO * 2, FOTO_LADO * 2))
        imagen = ImageOps.exif_transpose(original)

        if imagen.mode in ('RGBA', 'LA', 'P'):
            # Lo transparente de un PNG queda blanco, no negro.
            con_alfa = imagen.convert('RGBA')
            fondo = Image.new('RGB', con_alfa.size, (255, 255, 255))
            fondo.paste(con_alfa, mask=con_alfa.getchannel('A'))
            imagen = fondo
        else:
            imagen = imagen.convert('RGB')

        imagen = ImageOps.fit(imagen, (FOTO_LADO, FOTO_LADO),
                              method=Image.Resampling.LANCZOS)
        salida = BytesIO()
        imagen.save(salida, format='JPEG', quality=85, optimize=True)

    return ContentFile(salida.getvalue(), name='foto.jpg')


class FotoPerfilSerializer(serializers.Serializer):
    """Poner o cambiar la foto de perfil."""

    foto = serializers.ImageField(error_messages={
        'required': 'Elegí una foto.',
        'empty': 'La foto llegó vacía. Probá de nuevo.',
        'invalid': 'Ese archivo no es una foto. Elegí una imagen JPG o PNG.',
        'invalid_image': 'Ese archivo no es una foto. Elegí una imagen JPG o PNG.',
    })

    def validate_foto(self, archivo):
        if archivo.size > FOTO_MAX_BYTES:
            raise serializers.ValidationError(
                'La foto pesa más de 5 MB. Elegí una más liviana.')
        return preparar_foto(archivo)


class RegistroSerializer(serializers.Serializer):
    """Crea la cuenta y el perfil en un solo paso: no se entra a la app sin rol."""

    username = serializers.CharField(max_length=150)
    # Obligatorio: es lo unico con lo que se puede recuperar la cuenta. Sin
    # correo, olvidar la contrasena es perder la cuenta, y para la propietaria
    # eso es perder sus anuncios publicados.
    email = serializers.EmailField()
    password = serializers.CharField(write_only=True, min_length=8)
    rol = serializers.ChoiceField(choices=Perfil.Rol.choices)
    whatsapp = serializers.CharField(max_length=20, required=False, allow_blank=True)

    def validate_username(self, value):
        if User.objects.filter(username=value).exists():
            raise serializers.ValidationError('Ese nombre de usuario ya esta tomado.')
        return value

    def validate_email(self, value):
        value = value.strip().lower()
        # Un correo, una cuenta: si dos cuentas lo comparten, el enlace de
        # recuperacion no sabe a cual de las dos le cambia la contrasena.
        if User.objects.filter(email__iexact=value).exists():
            raise serializers.ValidationError('Ya hay una cuenta con ese correo.')
        return value

    def validate_whatsapp(self, value):
        return validar_whatsapp(value)

    def validate(self, data):
        # El propietario sin WhatsApp no puede recibir solicitudes: no hay
        # nada que liberar cuando aprueba.
        if data['rol'] == Perfil.Rol.PROPIETARIO and not data.get('whatsapp'):
            raise serializers.ValidationError({
                'whatsapp': 'Un propietario necesita un WhatsApp: es lo que se '
                            'libera cuando aprueba una solicitud.',
            })
        return data

    @transaction.atomic
    def create(self, validated_data):
        usuario = User.objects.create_user(
            username=validated_data['username'],
            email=validated_data['email'],
            password=validated_data['password'],
        )
        Perfil.objects.create(
            usuario=usuario,
            rol=validated_data['rol'],
            whatsapp=validated_data.get('whatsapp', ''),
        )
        return usuario

    def to_representation(self, instance):
        return PerfilSerializer(instance.perfil).data


class RecuperarSerializer(serializers.Serializer):
    """Pedir el enlace para poner una contrasena nueva."""

    email = serializers.EmailField()

    def validate_email(self, value):
        return value.strip().lower()


class ConfirmarRecuperacionSerializer(serializers.Serializer):
    """Poner la contrasena nueva con el uid y el token que llegaron por correo."""

    uid = serializers.CharField()
    token = serializers.CharField()
    password = serializers.CharField(write_only=True, min_length=8)

    ENLACE_VENCIDO = 'Ese enlace ya venció. Pedí uno nuevo y volvé a intentar.'

    def validate(self, data):
        try:
            usuario = User.objects.get(pk=force_str(urlsafe_base64_decode(data['uid'])))
        except (TypeError, ValueError, OverflowError, User.DoesNotExist):
            usuario = None
        # El token deja de valer apenas se usa (cambia la contrasena y con ella
        # el hash que lo firma) y tambien pasado PASSWORD_RESET_TIMEOUT.
        if usuario is None or not default_token_generator.check_token(usuario, data['token']):
            raise serializers.ValidationError({'detalle': self.ENLACE_VENCIDO})
        data['usuario'] = usuario
        return data
