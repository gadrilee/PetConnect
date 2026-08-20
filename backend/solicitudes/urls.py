from rest_framework.routers import DefaultRouter

from .views import SolicitudVisitaViewSet

router = DefaultRouter()
router.register('', SolicitudVisitaViewSet, basename='solicitud')

urlpatterns = router.urls
