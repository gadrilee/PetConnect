from django.db.models import DecimalField, F
from django.db.models.functions import Cast
from django_filters.rest_framework import DjangoFilterBackend
from rest_framework import permissions, status, viewsets
from rest_framework.decorators import action
from rest_framework.parsers import FormParser, MultiPartParser
from rest_framework.response import Response

from .filters import AnuncioFilter
from .models import Anuncio
from .permissions import EsDuenoDelAnuncio, EsPropietario
from .serializers import (
    AnuncioDetailSerializer,
    AnuncioListSerializer,
    AnuncioWriteSerializer,
    FotoAnuncioSerializer,
)


class AnuncioViewSet(viewsets.ModelViewSet):
    """Publicar, buscar y gestionar anuncios.

    La busqueda solo devuelve anuncios DISPONIBLES: un anuncio ya alquilado
    que sigue apareciendo es exactamente el problema de la evidencia 8.
    """

    permission_classes = [permissions.IsAuthenticated, EsPropietario, EsDuenoDelAnuncio]
    filter_backends = [DjangoFilterBackend]
    filterset_class = AnuncioFilter

    def get_queryset(self):
        qs = Anuncio.objects.annotate(
            precio_final_calc=Cast(
                F('precio_alquiler') + F('costo_servicios_estimado'),
                output_field=DecimalField(max_digits=8, decimal_places=2),
            ),
        ).prefetch_related('fotos')

        if self.action == 'mios':
            return qs.filter(propietario=self.request.user)
        if self.action in ('list',):
            return qs.filter(estado=Anuncio.Estado.DISPONIBLE)
        return qs

    def get_serializer_class(self):
        if self.action in ('create', 'update', 'partial_update'):
            return AnuncioWriteSerializer
        if self.action in ('list', 'mios'):
            return AnuncioListSerializer
        return AnuncioDetailSerializer

    @action(detail=False, methods=['get'])
    def mios(self, request):
        """GET /api/anuncios/mios/ — los anuncios del propietario, en cualquier estado."""
        page = self.paginate_queryset(self.get_queryset())
        serializer = self.get_serializer(page, many=True)
        return self.get_paginated_response(serializer.data)

    @action(detail=True, methods=['post'])
    def marcar_alquilado(self, request, pk=None):
        """Apagar el anuncio en un toque (Ev. 8)."""
        anuncio = self.get_object()
        self.check_object_permissions(request, anuncio)
        anuncio.marcar_alquilado()
        return Response(AnuncioDetailSerializer(anuncio, context={'request': request}).data)

    @action(detail=True, methods=['post'])
    def marcar_disponible(self, request, pk=None):
        anuncio = self.get_object()
        self.check_object_permissions(request, anuncio)
        anuncio.marcar_disponible()
        return Response(AnuncioDetailSerializer(anuncio, context={'request': request}).data)

    @action(detail=True, methods=['post'], url_path='fotos',
            parser_classes=[MultiPartParser, FormParser])
    def agregar_foto(self, request, pk=None):
        """Foto tomada con la camara, con su fecha de captura (Ev. 4)."""
        anuncio = self.get_object()
        self.check_object_permissions(request, anuncio)
        serializer = FotoAnuncioSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        serializer.save(anuncio=anuncio)
        return Response(serializer.data, status=status.HTTP_201_CREATED)
