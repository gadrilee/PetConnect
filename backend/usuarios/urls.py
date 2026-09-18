from django.urls import path

from .views import (
    ConfirmarRecuperacionView,
    MiFotoView,
    MiPerfilView,
    RecuperarView,
    RegistroView,
)

urlpatterns = [
    path('registro/', RegistroView.as_view(), name='registro'),
    path('yo/', MiPerfilView.as_view(), name='mi-perfil'),
    path('yo/foto/', MiFotoView.as_view(), name='mi-foto'),
    path('recuperar/', RecuperarView.as_view(), name='recuperar'),
    path('recuperar/confirmar/', ConfirmarRecuperacionView.as_view(), name='recuperar-confirmar'),
]
