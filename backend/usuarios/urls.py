from django.urls import path

from .views import ConfirmarRecuperacionView, MiPerfilView, RecuperarView, RegistroView

urlpatterns = [
    path('registro/', RegistroView.as_view(), name='registro'),
    path('yo/', MiPerfilView.as_view(), name='mi-perfil'),
    path('recuperar/', RecuperarView.as_view(), name='recuperar'),
    path('recuperar/confirmar/', ConfirmarRecuperacionView.as_view(), name='recuperar-confirmar'),
]
