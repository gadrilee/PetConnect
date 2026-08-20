from django.contrib import admin

from .models import SolicitudVisita


@admin.register(SolicitudVisita)
class SolicitudVisitaAdmin(admin.ModelAdmin):
    list_display = ('anuncio', 'inquilino', 'estado', 'condiciones_aceptadas',
                    'contacto_display', 'creada_en')
    list_filter = ('estado', 'condiciones_aceptadas')
    search_fields = ('anuncio__titulo', 'inquilino__username')
    readonly_fields = ('creada_en', 'respondida_en')
    actions = ['aprobar_solicitudes', 'rechazar_solicitudes']

    @admin.display(description='contacto liberado')
    def contacto_display(self, obj):
        return obj.contacto_liberado or '— oculto —'

    @admin.action(description='Aprobar y liberar el contacto')
    def aprobar_solicitudes(self, request, queryset):
        for s in queryset:
            s.aprobar()

    @admin.action(description='Rechazar')
    def rechazar_solicitudes(self, request, queryset):
        for s in queryset:
            s.rechazar()
