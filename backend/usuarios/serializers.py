from django.contrib.auth.models import User
from django.db import transaction
from rest_framework import serializers

from .models import Perfil


class PerfilSerializer(serializers.ModelSerializer):
    username = serializers.CharField(source='usuario.username', read_only=True)

    class Meta:
        model = Perfil
        fields = ('username', 'rol', 'whatsapp', 'creado_en')
        read_only_fields = ('creado_en',)


class RegistroSerializer(serializers.Serializer):
    """Crea la cuenta y el perfil en un solo paso: no se entra a la app sin rol."""

    username = serializers.CharField(max_length=150)
    email = serializers.EmailField(required=False, allow_blank=True)
    password = serializers.CharField(write_only=True, min_length=8)
    rol = serializers.ChoiceField(choices=Perfil.Rol.choices)
    whatsapp = serializers.CharField(max_length=20, required=False, allow_blank=True)

    def validate_username(self, value):
        if User.objects.filter(username=value).exists():
            raise serializers.ValidationError('Ese nombre de usuario ya esta tomado.')
        return value

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
            email=validated_data.get('email', ''),
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
