import re

from django.contrib.auth.models import User
from django.contrib.auth.tokens import default_token_generator
from django.db import transaction
from django.utils.encoding import force_str
from django.utils.http import urlsafe_base64_decode
from rest_framework import serializers

from .models import Perfil

# Un WhatsApp de Bolivia: exactamente 8 digitos. Es la misma regla que aplica
# la app al escribirlo; aca se repite porque el backend no puede confiar en
# que siempre le llegue desde la app.
_OCHO_DIGITOS = re.compile(r'^\d{8}$')


def validar_whatsapp(valor):
    valor = (valor or '').strip()
    if valor and not _OCHO_DIGITOS.match(valor):
        raise serializers.ValidationError('Escribí los 8 dígitos, como 70099988.')
    return valor


class PerfilSerializer(serializers.ModelSerializer):
    """El perfil que ve la persona en Mi perfil.

    Lo unico que se puede cambiar es el WhatsApp. El rol decide que app ve
    cada una y no se cambia desde adentro (flujo de acceso), y el correo es con
    lo que se recupera la cuenta: cambiarlo pide confirmar la direccion nueva,
    y ese camino todavia no existe.
    """

    username = serializers.CharField(source='usuario.username', read_only=True)
    email = serializers.EmailField(source='usuario.email', read_only=True)

    class Meta:
        model = Perfil
        fields = ('username', 'email', 'rol', 'whatsapp', 'creado_en')
        read_only_fields = ('rol', 'creado_en')

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
