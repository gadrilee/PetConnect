"""Serializers de la solicitud de visita.

`contacto` sale siempre de `SolicitudVisita.contacto_liberado`, que devuelve
None mientras no haya aprobacion. Ninguna vista lee el WhatsApp del perfil.
"""

from rest_framework import serializers

from anuncios.models import Anuncio
from anuncios.serializers import AnuncioListSerializer

from .models import SolicitudVisita


class SolicitudVisitaSerializer(serializers.ModelSerializer):
    anuncio = AnuncioListSerializer(read_only=True)
    inquilino = serializers.CharField(source='inquilino.username', read_only=True)
    estado_display = serializers.CharField(source='get_estado_display', read_only=True)
    contacto = serializers.SerializerMethodField()

    class Meta:
        model = SolicitudVisita
        fields = ('id', 'anuncio', 'inquilino', 'condiciones_aceptadas',
                  'estado', 'estado_display', 'contacto', 'creada_en', 'respondida_en')

    def get_contacto(self, obj):
        """None mientras la solicitud no este aprobada. Es la regla central."""
        return obj.contacto_liberado


class SolicitudVisitaCreateSerializer(serializers.ModelSerializer):
    anuncio = serializers.PrimaryKeyRelatedField(queryset=Anuncio.objects.all())

    class Meta:
        model = SolicitudVisita
        fields = ('id', 'anuncio', 'condiciones_aceptadas')

    def validate_condiciones_aceptadas(self, value):
        if not value:
            raise serializers.ValidationError(
                'Hay que aceptar las condiciones del anuncio antes de pedir la visita.'
            )
        return value

    def validate_anuncio(self, anuncio):
        if not anuncio.esta_disponible:
            raise serializers.ValidationError('Este anuncio ya esta marcado como alquilado.')
        if anuncio.propietario_id == self.context['request'].user.id:
            raise serializers.ValidationError('No podes solicitar una visita a tu propio anuncio.')
        return anuncio

    def validate(self, data):
        ya_existe = SolicitudVisita.objects.filter(
            anuncio=data['anuncio'], inquilino=self.context['request'].user,
        ).exists()
        if ya_existe:
            raise serializers.ValidationError(
                'Ya enviaste una solicitud para este anuncio.'
            )
        return data

    def create(self, validated_data):
        validated_data['inquilino'] = self.context['request'].user
        return super().create(validated_data)
