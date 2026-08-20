from rest_framework import generics, permissions

from .models import Perfil
from .serializers import PerfilSerializer, RegistroSerializer


class RegistroView(generics.CreateAPIView):
    """POST /api/usuarios/registro/ — crear cuenta eligiendo rol."""

    serializer_class = RegistroSerializer
    permission_classes = [permissions.AllowAny]


class MiPerfilView(generics.RetrieveAPIView):
    """GET /api/usuarios/yo/ — el perfil del usuario autenticado."""

    serializer_class = PerfilSerializer

    def get_object(self):
        return Perfil.objects.get(usuario=self.request.user)
