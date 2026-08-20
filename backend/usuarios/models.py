"""Perfiles de usuario: quien publica y quien busca."""

from django.conf import settings
from django.db import models


class Perfil(models.Model):
    """Extiende al User de Django con el rol y el contacto que la app protege."""

    class Rol(models.TextChoices):
        INQUILINO = 'INQUILINO', 'Inquilino'
        PROPIETARIO = 'PROPIETARIO', 'Propietario'

    usuario = models.OneToOneField(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name='perfil',
    )
    rol = models.CharField(max_length=20, choices=Rol.choices)

    # El dato que el producto existe para proteger. No se expone en ningun
    # anuncio: solo se libera cuando el propietario aprueba una solicitud.
    # Evidencia 9: "No pongo mi numero en el anuncio porque despues te
    # escriben para cualquier cosa, pero si no lo pongo nadie te contacta."
    whatsapp = models.CharField('WhatsApp', max_length=20, blank=True)

    creado_en = models.DateTimeField(auto_now_add=True)

    class Meta:
        verbose_name = 'perfil'
        verbose_name_plural = 'perfiles'

    def __str__(self):
        return f'{self.usuario.username} ({self.get_rol_display()})'

    @property
    def es_propietario(self):
        return self.rol == self.Rol.PROPIETARIO
