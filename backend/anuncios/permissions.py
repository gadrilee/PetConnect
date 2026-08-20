from rest_framework import permissions

from usuarios.models import Perfil


class EsPropietario(permissions.BasePermission):
    """Solo quien entro como propietario puede publicar."""

    message = 'Solo un propietario puede publicar anuncios.'

    def has_permission(self, request, view):
        if request.method in permissions.SAFE_METHODS:
            return True
        perfil = getattr(request.user, 'perfil', None)
        return perfil is not None and perfil.rol == Perfil.Rol.PROPIETARIO


class EsDuenoDelAnuncio(permissions.BasePermission):
    """Editar o apagar un anuncio es cosa de su dueño, de nadie mas."""

    message = 'Este anuncio no es tuyo.'

    def has_object_permission(self, request, view, obj):
        if request.method in permissions.SAFE_METHODS:
            return True
        return obj.propietario_id == request.user.id
