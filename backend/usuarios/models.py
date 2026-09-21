"""Perfiles de usuario: quien publica y quien busca."""

import uuid

from django.conf import settings
from django.db import models
from django.db.models.signals import post_delete
from django.dispatch import receiver


def ruta_foto_perfil(perfil, nombre_original):
    """Un nombre nuevo para cada foto.

    Si la foto nueva se guardara con el mismo nombre, la direccion no cambiaria
    y la app seguiria mostrando la vieja que tiene guardada. El nombre original
    no se usa: puede decir de mas ("marta-dni.jpg").
    """
    return f'perfiles/{uuid.uuid4().hex}.jpg'


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

    # Opcional: sin foto, la app muestra el icono del rol. Se guarda ya
    # recortada, chica y sin metadatos (ver FotoPerfilSerializer).
    foto = models.ImageField(upload_to=ruta_foto_perfil, blank=True)

    creado_en = models.DateTimeField(auto_now_add=True)

    class Meta:
        verbose_name = 'perfil'
        verbose_name_plural = 'perfiles'

    def __str__(self):
        return f'{self.usuario.username} ({self.get_rol_display()})'

    @property
    def es_propietario(self):
        return self.rol == self.Rol.PROPIETARIO


@receiver(post_delete, sender=Perfil)
def borrar_foto_del_perfil(sender, instance, **kwargs):
    """Borrar la cuenta borra la foto: no queda una cara suelta en el disco."""
    if instance.foto:
        instance.foto.delete(save=False)
