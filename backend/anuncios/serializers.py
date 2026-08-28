"""Serializers del anuncio.

Ninguno expone el telefono del propietario. El unico camino al contacto es
`SolicitudVisita.contacto_liberado`, y solo despues de una aprobacion.
"""

from rest_framework import serializers

from .models import Anuncio, FotoAnuncio


class ServiciosIncluidosMixin:
    """Agrupa los tres booleanos de servicios en un solo objeto.

    En la base son tres columnas sueltas porque asi se puede filtrar por cada
    una, pero la app las consume juntas. Vive en un mixin para que el listado
    y el detalle devuelvan exactamente la misma forma.
    """

    def get_servicios_incluidos(self, obj):
        return {
            'agua': obj.incluye_agua,
            'luz': obj.incluye_luz,
            'internet': obj.incluye_internet,
        }


class FotoAnuncioSerializer(serializers.ModelSerializer):
    class Meta:
        model = FotoAnuncio
        fields = ('id', 'imagen', 'fecha_captura', 'orden')


class AnuncioListSerializer(ServiciosIncluidosMixin, serializers.ModelSerializer):
    """La tarjeta del listado: lo justo para descartar sin abrir el anuncio."""

    precio_final = serializers.DecimalField(max_digits=8, decimal_places=2, read_only=True)
    tipo_espacio_display = serializers.CharField(source='get_tipo_espacio_display', read_only=True)
    foto_principal = serializers.SerializerMethodField()
    # Sin esto el precio final es ambiguo: 1.000 Bs no significa nada
    # hasta saber que cubre. Y el listado es donde primero se descarta.
    servicios_incluidos = serializers.SerializerMethodField()

    class Meta:
        model = Anuncio
        fields = ('id', 'titulo', 'tipo_espacio', 'tipo_espacio_display',
                  'precio_final', 'servicios_incluidos', 'acepta_mascotas',
                  'minutos_caminando', 'estado', 'foto_principal')

    def get_foto_principal(self, obj):
        foto = obj.fotos.first()
        if not foto:
            return None
        request = self.context.get('request')
        url = foto.imagen.url
        return {
            'imagen': request.build_absolute_uri(url) if request else url,
            'fecha_captura': foto.fecha_captura,
        }


class AnuncioDetailSerializer(ServiciosIncluidosMixin, serializers.ModelSerializer):
    """El anuncio completo. Es el momento en que el inquilino decide si descarta."""

    precio_final = serializers.DecimalField(max_digits=8, decimal_places=2, read_only=True)
    tipo_espacio_display = serializers.CharField(source='get_tipo_espacio_display', read_only=True)
    fotos = FotoAnuncioSerializer(many=True, read_only=True)
    servicios_incluidos = serializers.SerializerMethodField()

    class Meta:
        model = Anuncio
        fields = (
            'id', 'titulo', 'tipo_espacio', 'tipo_espacio_display',
            'precio_alquiler', 'costo_servicios_estimado', 'precio_final',
            'servicios_incluidos', 'acepta_mascotas', 'restricciones',
            'lat', 'lng', 'direccion_referencia', 'minutos_caminando',
            'estado', 'publicado_en', 'fotos',
        )


class AnuncioWriteSerializer(serializers.ModelSerializer):
    """Publicar o editar. El propietario sale del usuario autenticado."""

    class Meta:
        model = Anuncio
        fields = (
            'id', 'titulo', 'tipo_espacio',
            'precio_alquiler', 'incluye_agua', 'incluye_luz', 'incluye_internet',
            'costo_servicios_estimado', 'acepta_mascotas', 'restricciones',
            'lat', 'lng', 'direccion_referencia',
        )

    def validate(self, data):
        # Reusa la validacion del modelo para que la API y el admin apliquen
        # exactamente la misma regla, en vez de dos copias que se despegan.
        instancia = Anuncio(**{**self._datos_actuales(), **data})
        instancia.clean()
        return data

    def _datos_actuales(self):
        if self.instance is None:
            return {}
        campos = [f.name for f in Anuncio._meta.fields if f.name != 'id']
        return {c: getattr(self.instance, c) for c in campos}

    def create(self, validated_data):
        validated_data['propietario'] = self.context['request'].user
        return super().create(validated_data)
