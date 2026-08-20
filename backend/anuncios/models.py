"""El anuncio y sus fotos.

Las cuatro condiciones de descarte del Brief v0.2.0 son campos obligatorios
de este modelo. Esa obligatoriedad ES el producto: si se pueden dejar vacias,
la app termina siendo otro tablon de anuncios como los grupos de Facebook.
"""

from django.conf import settings
from django.core.exceptions import ValidationError
from django.db import models
from django.utils import timezone

from .utils import minutos_caminando_a_uagrm


class Anuncio(models.Model):
    class TipoEspacio(models.TextChoices):
        HABITACION = 'HABITACION', 'Habitación'
        DEPARTAMENTO = 'DEPARTAMENTO', 'Departamento'
        CASA = 'CASA', 'Casa'

    class Estado(models.TextChoices):
        DISPONIBLE = 'DISPONIBLE', 'Disponible'
        ALQUILADO = 'ALQUILADO', 'Ya alquilado'

    propietario = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name='anuncios',
    )
    titulo = models.CharField(max_length=150)

    # --- Condicion de descarte 3: tipo de espacio ---
    tipo_espacio = models.CharField(max_length=20, choices=TipoEspacio.choices)

    # --- Condicion de descarte 1: precio final con servicios ---
    # Evidencia 1: "recien ahi me dijeron que el precio no incluia agua ni
    # luz. Eran 300 bolivianos mas." Por eso el alquiler y los servicios son
    # campos separados y el precio final se deriva de ambos.
    precio_alquiler = models.DecimalField('alquiler mensual (Bs)', max_digits=8, decimal_places=2)
    incluye_agua = models.BooleanField('incluye agua', default=False)
    incluye_luz = models.BooleanField('incluye luz', default=False)
    incluye_internet = models.BooleanField('incluye internet', default=False)
    costo_servicios_estimado = models.DecimalField(
        'costo estimado de los servicios NO incluidos (Bs)',
        max_digits=8,
        decimal_places=2,
        default=0,
        help_text='Si algun servicio no esta incluido, cuanto paga aparte el inquilino.',
    )

    # --- Condicion de descarte 2: politica de mascotas ---
    # Evidencia 3: se descubre despues de haber escrito. Campo obligatorio
    # y filtrable, no texto libre.
    acepta_mascotas = models.BooleanField('acepta mascotas')
    restricciones = models.TextField(
        blank=True,
        help_text='Ej.: "solo señoritas". Se muestra antes del primer contacto.',
    )

    # --- Condicion de descarte 4: ubicacion ---
    # Se toma con el GPS del telefono estando en el inmueble.
    lat = models.FloatField('latitud')
    lng = models.FloatField('longitud')
    direccion_referencia = models.CharField(max_length=200, blank=True)
    minutos_caminando = models.PositiveIntegerField(
        'minutos caminando a la UAGRM',
        editable=False,
        help_text='Calculado a partir de lat/lng. No se carga a mano.',
    )

    # --- Ciclo de vida ---
    # Evidencia 8: "El cuarto lo alquile hace un mes y me siguen escribiendo."
    estado = models.CharField(max_length=20, choices=Estado.choices, default=Estado.DISPONIBLE)
    publicado_en = models.DateTimeField(auto_now_add=True)
    actualizado_en = models.DateTimeField(auto_now=True)
    alquilado_en = models.DateTimeField(null=True, blank=True, editable=False)

    class Meta:
        ordering = ['minutos_caminando', 'precio_alquiler']
        verbose_name = 'anuncio'
        verbose_name_plural = 'anuncios'

    def __str__(self):
        return f'{self.get_tipo_espacio_display()} — {self.titulo}'

    # ---------- Reglas de negocio ----------

    @property
    def todos_los_servicios_incluidos(self):
        return self.incluye_agua and self.incluye_luz and self.incluye_internet

    @property
    def precio_final(self):
        """Lo que el inquilino termina pagando por mes. Es el criterio de descarte n.º 1."""
        return self.precio_alquiler + self.costo_servicios_estimado

    @property
    def esta_disponible(self):
        return self.estado == self.Estado.DISPONIBLE

    def clean(self):
        """No se puede publicar un precio que esconde lo que falta pagar."""
        if not self.todos_los_servicios_incluidos and self.costo_servicios_estimado <= 0:
            raise ValidationError({
                'costo_servicios_estimado':
                    'Si algun servicio no esta incluido, hay que estimar cuanto '
                    'paga aparte el inquilino. Publicar solo el alquiler es lo '
                    'que hoy hace perder viajes.',
            })

    def marcar_alquilado(self):
        """Apagar el anuncio en un toque. Si cuesta mas que eso, no va a pasar."""
        self.estado = self.Estado.ALQUILADO
        self.alquilado_en = timezone.now()
        self.save(update_fields=['estado', 'alquilado_en', 'actualizado_en'])

    def marcar_disponible(self):
        self.estado = self.Estado.DISPONIBLE
        self.alquilado_en = None
        self.save(update_fields=['estado', 'alquilado_en', 'actualizado_en'])

    def save(self, *args, **kwargs):
        # Los minutos caminando siempre se derivan de la ubicacion: nunca
        # los escribe el propietario, que es de donde sale hoy el "cerca de la U".
        self.minutos_caminando = minutos_caminando_a_uagrm(self.lat, self.lng)
        super().save(*args, **kwargs)


class FotoAnuncio(models.Model):
    """Foto tomada con la camara de la app, sellada con la fecha de captura.

    Evidencia 4: "Las fotos eran de hace años. El baño no era ese." La fecha
    que importa es CUANDO SE TOMO, no cuando se subio.
    """

    anuncio = models.ForeignKey(Anuncio, on_delete=models.CASCADE, related_name='fotos')
    imagen = models.ImageField(upload_to='anuncios/%Y/%m/')
    fecha_captura = models.DateTimeField(
        help_text='Momento en que se tomo la foto. Se muestra en el anuncio.',
    )
    orden = models.PositiveSmallIntegerField(default=0)

    class Meta:
        ordering = ['orden', 'id']
        verbose_name = 'foto'
        verbose_name_plural = 'fotos'

    def __str__(self):
        return f'Foto de {self.anuncio_id} ({self.fecha_captura:%d/%m/%Y})'
