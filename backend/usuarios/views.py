from django.contrib.auth.models import User
from django.contrib.auth.tokens import default_token_generator
from django.core.mail import send_mail
from django.utils.encoding import force_bytes
from django.utils.http import urlsafe_base64_encode
from rest_framework import generics, permissions, status
from rest_framework.parsers import FormParser, MultiPartParser
from rest_framework.response import Response
from rest_framework.views import APIView
from rest_framework_simplejwt.tokens import RefreshToken

from .models import Perfil
from .serializers import (
    ConfirmarRecuperacionSerializer,
    FotoPerfilSerializer,
    PerfilSerializer,
    RecuperarSerializer,
    RegistroSerializer,
)

# La app abre este enlace directo en la pantalla "Nueva contrasena". Va con el
# host "app" porque Flutter arma la ruta con el path del enlace: en
# alquilamatch://recuperar la palabra quedaria como host y se perderia.
ENLACE_RECUPERAR = 'alquilamatch://app/recuperar?uid={uid}&token={token}'

# Siempre la misma respuesta, exista o no la cuenta: si dijera "ese correo no
# esta registrado", cualquiera podria averiguar quien usa la app probando
# correos.
RESPUESTA_RECUPERAR = 'Si ese correo tiene una cuenta, te llegó un enlace. Revisá tu bandeja.'


class RegistroView(generics.CreateAPIView):
    """POST /api/usuarios/registro/ — crear cuenta eligiendo rol."""

    serializer_class = RegistroSerializer
    permission_classes = [permissions.AllowAny]


class MiPerfilView(generics.RetrieveUpdateAPIView):
    """GET y PATCH /api/usuarios/yo/ — el perfil de quien entro.

    Solo PATCH: se cambia un dato a la vez (hoy, el WhatsApp), nunca el perfil
    entero.
    """

    serializer_class = PerfilSerializer
    http_method_names = ['get', 'patch', 'head', 'options']

    def get_object(self):
        return Perfil.objects.select_related('usuario').get(usuario=self.request.user)


class MiFotoView(APIView):
    """POST y DELETE /api/usuarios/yo/foto/ — poner, cambiar o quitar la foto.

    Va aparte del PATCH de /yo/ porque la foto viaja como archivo (multipart)
    y el resto del perfil como JSON. Las dos respuestas devuelven el perfil
    entero, como el PATCH: la app reemplaza el que tenia y listo.
    """

    parser_classes = [MultiPartParser, FormParser]

    def _perfil(self):
        return Perfil.objects.select_related('usuario').get(usuario=self.request.user)

    def _responder(self, perfil):
        return Response(PerfilSerializer(perfil, context={'request': self.request}).data)

    def post(self, request):
        perfil = self._perfil()
        serializer = FotoPerfilSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)

        anterior = perfil.foto.name if perfil.foto else None
        perfil.foto.save('foto.jpg', serializer.validated_data['foto'], save=False)
        perfil.save(update_fields=['foto'])
        # La vieja se borra recien con la nueva guardada: si algo falla antes,
        # la persona conserva la que tenia.
        if anterior:
            perfil.foto.storage.delete(anterior)
        return self._responder(perfil)

    def delete(self, request):
        perfil = self._perfil()
        if perfil.foto:
            perfil.foto.delete(save=False)
            perfil.save(update_fields=['foto'])
        return self._responder(perfil)


class RecuperarView(APIView):
    """POST /api/usuarios/recuperar/ — mandar el enlace para una contrasena nueva."""

    permission_classes = [permissions.AllowAny]

    def post(self, request):
        serializer = RecuperarSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        email = serializer.validated_data['email']

        for usuario in User.objects.filter(email__iexact=email, is_active=True):
            enlace = ENLACE_RECUPERAR.format(
                uid=urlsafe_base64_encode(force_bytes(usuario.pk)),
                token=default_token_generator.make_token(usuario),
            )
            send_mail(
                subject='AlquilaMatch — Poné una contraseña nueva',
                message=(
                    f'Hola {usuario.username}:\n\n'
                    'Pediste poner una contraseña nueva. Abrí este enlace desde '
                    'el teléfono donde tenés la app:\n\n'
                    f'{enlace}\n\n'
                    'Si no fuiste vos, ignorá este correo: tu contraseña sigue '
                    'siendo la misma.'
                ),
                from_email=None,
                recipient_list=[usuario.email],
            )

        return Response({'detalle': RESPUESTA_RECUPERAR})


class ConfirmarRecuperacionView(APIView):
    """POST /api/usuarios/recuperar/confirmar/ — poner la contrasena nueva.

    Devuelve los tokens de sesion: al guardar la contrasena nueva la persona ya
    queda adentro, sin volver a escribirla en Ingresar.
    """

    permission_classes = [permissions.AllowAny]

    def post(self, request):
        serializer = ConfirmarRecuperacionSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        usuario = serializer.validated_data['usuario']
        usuario.set_password(serializer.validated_data['password'])
        usuario.save(update_fields=['password'])

        refresh = RefreshToken.for_user(usuario)
        return Response(
            {'access': str(refresh.access_token), 'refresh': str(refresh)},
            status=status.HTTP_200_OK,
        )
