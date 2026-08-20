from django.urls import path

from .views import MiPerfilView, RegistroView

urlpatterns = [
    path('registro/', RegistroView.as_view(), name='registro'),
    path('yo/', MiPerfilView.as_view(), name='mi-perfil'),
]
