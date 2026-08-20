from rest_framework import mixins, permissions, status, viewsets
from rest_framework.decorators import action
from rest_framework.response import Response

from usuarios.models import Perfil

from .models import SolicitudVisita
from .permissions import EsDuenoDelAnuncioDeLaSolicitud
from .serializers import SolicitudVisitaCreateSerializer, SolicitudVisitaSerializer


class SolicitudVisitaViewSet(mixins.CreateModelMixin,
                             mixins.ListModelMixin,
                             mixins.RetrieveModelMixin,
                             viewsets.GenericViewSet):
    """Solicitar una visita, y del otro lado aprobarla o rechazarla.

    El listado cambia segun quien mira: el inquilino ve las que envio, el
    propietario ve las que recibio.
    """

    def get_queryset(self):
        qs = SolicitudVisita.objects.select_related(
            'anuncio', 'inquilino', 'anuncio__propietario__perfil',
        ).prefetch_related('anuncio__fotos')

        perfil = getattr(self.request.user, 'perfil', None)
        if perfil is not None and perfil.rol == Perfil.Rol.PROPIETARIO:
            return qs.filter(anuncio__propietario=self.request.user)
        return qs.filter(inquilino=self.request.user)

    def get_serializer_class(self):
        if self.action == 'create':
            return SolicitudVisitaCreateSerializer
        return SolicitudVisitaSerializer

    def create(self, request, *args, **kwargs):
        serializer = self.get_serializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        solicitud = serializer.save()
        salida = SolicitudVisitaSerializer(solicitud, context=self.get_serializer_context())
        return Response(salida.data, status=status.HTTP_201_CREATED)

    @action(detail=True, methods=['post'],
            permission_classes=[permissions.IsAuthenticated, EsDuenoDelAnuncioDeLaSolicitud])
    def aprobar(self, request, pk=None):
        """Aprobar libera el contacto, y solo a esta persona."""
        solicitud = self.get_object()
        self.check_object_permissions(request, solicitud)
        solicitud.aprobar()
        return Response(SolicitudVisitaSerializer(
            solicitud, context=self.get_serializer_context()).data)

    @action(detail=True, methods=['post'],
            permission_classes=[permissions.IsAuthenticated, EsDuenoDelAnuncioDeLaSolicitud])
    def rechazar(self, request, pk=None):
        solicitud = self.get_object()
        self.check_object_permissions(request, solicitud)
        solicitud.rechazar()
        return Response(SolicitudVisitaSerializer(
            solicitud, context=self.get_serializer_context()).data)
