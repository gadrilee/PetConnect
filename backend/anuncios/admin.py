from django.contrib import admin

from .models import Anuncio, FotoAnuncio


class FotoAnuncioInline(admin.TabularInline):
    model = FotoAnuncio
    extra = 1
    fields = ('imagen', 'fecha_captura', 'orden')


@admin.register(Anuncio)
class AnuncioAdmin(admin.ModelAdmin):
    list_display = (
        'titulo', 'tipo_espacio', 'precio_final_display',
        'acepta_mascotas', 'minutos_caminando', 'estado', 'propietario',
    )
    list_filter = ('estado', 'tipo_espacio', 'acepta_mascotas')
    search_fields = ('titulo', 'direccion_referencia', 'propietario__username')
    readonly_fields = ('minutos_caminando', 'publicado_en', 'actualizado_en', 'alquilado_en')
    inlines = [FotoAnuncioInline]
    actions = ['marcar_como_alquilado', 'marcar_como_disponible']

    fieldsets = (
        (None, {'fields': ('propietario', 'titulo', 'tipo_espacio', 'estado')}),
        ('Precio final (condicion de descarte 1)', {
            'fields': ('precio_alquiler', 'incluye_agua', 'incluye_luz',
                       'incluye_internet', 'costo_servicios_estimado'),
        }),
        ('Reglas (condicion de descarte 2)', {'fields': ('acepta_mascotas', 'restricciones')}),
        ('Ubicacion (condicion de descarte 4)', {
            'fields': ('lat', 'lng', 'direccion_referencia', 'minutos_caminando'),
        }),
        ('Fechas', {'fields': ('publicado_en', 'actualizado_en', 'alquilado_en')}),
    )

    @admin.display(description='precio final', ordering='precio_alquiler')
    def precio_final_display(self, obj):
        return f'{obj.precio_final:.0f} Bs'

    @admin.action(description='Marcar como Ya alquilado')
    def marcar_como_alquilado(self, request, queryset):
        for anuncio in queryset:
            anuncio.marcar_alquilado()

    @admin.action(description='Marcar como Disponible')
    def marcar_como_disponible(self, request, queryset):
        for anuncio in queryset:
            anuncio.marcar_disponible()
