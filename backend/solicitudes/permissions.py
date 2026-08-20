from rest_framework import permissions


class EsDuenoDelAnuncioDeLaSolicitud(permissions.BasePermission):
    """Aprobar o rechazar es cosa del propietario del anuncio."""

    message = 'Solo el propietario del anuncio puede responder esta solicitud.'

    def has_object_permission(self, request, view, obj):
        return obj.anuncio.propietario_id == request.user.id
