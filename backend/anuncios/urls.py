from rest_framework.routers import DefaultRouter

from .views import AnuncioViewSet

router = DefaultRouter()
router.register('', AnuncioViewSet, basename='anuncio')

urlpatterns = router.urls
