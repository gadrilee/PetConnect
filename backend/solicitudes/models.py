"""La solicitud de visita: donde vive la regla central del producto.

El contacto del propietario es el recurso caro para los dos lados. Hoy se
gasta primero y se descarta despues. Este modelo invierte ese orden: el
WhatsApp no existe para el inquilino hasta que el propietario aprueba.
"""

from django.conf import settings
from django.core.exceptions import ValidationError
from django.db import models
from django.utils import timezone

from anuncios.models import Anuncio


class SolicitudVisita(models.Model):
    class Estado(models.TextChoices):
        PENDIENTE = 'PENDIENTE', 'Pendiente'
        APROBADA = 'APROBADA', 'Aprobada'
        RECHAZADA = 'RECHAZADA', 'Rechazada'

    anuncio = models.ForeignKey(Anuncio, on_delete=models.CASCADE, related_name='solicitudes')
    inquilino = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name='solicitudes',
    )

    # El inquilino ya leyo y acepto precio final, mascotas, tipo y ubicacion
    # ANTES de pedir el contacto. Es lo que le ahorra al propietario repetir
    # las mismas condiciones a quince personas (Ev. 7).
    condiciones_aceptadas = models.BooleanField(default=False)

    estado = models.CharField(max_length=20, choices=Estado.choices, default=Estado.PENDIENTE)
    creada_en = models.DateTimeField(auto_now_add=True)
    respondida_en = models.DateTimeField(null=True, blank=True, editable=False)

    class Meta:
        ordering = ['-creada_en']
        verbose_name = 'solicitud de visita'
        verbose_name_plural = 'solicitudes de visita'
        constraints = [
            models.UniqueConstraint(
                fields=['anuncio', 'inquilino'],
                name='una_solicitud_por_anuncio_e_inquilino',
            ),
        ]

    def __str__(self):
        return f'{self.inquilino} → {self.anuncio} ({self.get_estado_display()})'

    # ---------- La regla central ----------

    @property
    def contacto_liberado(self):
        """El WhatsApp del propietario, o None si todavia no fue aprobada.

        Cualquier serializer o vista que muestre el contacto debe pasar por
        aca. Si se lee el telefono directo del perfil, se rompe el producto.
        """
        if self.estado != self.Estado.APROBADA:
            return None
        perfil = getattr(self.anuncio.propietario, 'perfil', None)
        return perfil.whatsapp if perfil else None

    def clean(self):
        if not self.condiciones_aceptadas:
            raise ValidationError({
                'condiciones_aceptadas':
                    'No se puede solicitar una visita sin aceptar antes las '
                    'condiciones del anuncio.',
            })
        if self.estado == self.Estado.PENDIENTE and not self.anuncio.esta_disponible:
            raise ValidationError({
                'anuncio': 'El anuncio ya esta marcado como alquilado.',
            })

    def aprobar(self):
        self.estado = self.Estado.APROBADA
        self.respondida_en = timezone.now()
        self.save(update_fields=['estado', 'respondida_en'])

    def rechazar(self):
        self.estado = self.Estado.RECHAZADA
        self.respondida_en = timezone.now()
        self.save(update_fields=['estado', 'respondida_en'])
