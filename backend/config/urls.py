"""URLs del proyecto AlquilaMatch."""

from django.conf import settings
from django.conf.urls.static import static
from django.contrib import admin
from django.urls import include, path
from rest_framework_simplejwt.views import TokenObtainPairView, TokenRefreshView

urlpatterns = [
    path('admin/', admin.site.urls),

    # Auth para el cliente movil
    path('api/auth/token/', TokenObtainPairView.as_view(), name='token_obtain_pair'),
    path('api/auth/token/refresh/', TokenRefreshView.as_view(), name='token_refresh'),

    # Modulos del appmap v0.1 — se habilitan al crear cada urls.py
    # path('api/usuarios/', include('usuarios.urls')),
    # path('api/anuncios/', include('anuncios.urls')),
    # path('api/solicitudes/', include('solicitudes.urls')),
]

if settings.DEBUG:
    urlpatterns += static(settings.MEDIA_URL, document_root=settings.MEDIA_ROOT)
