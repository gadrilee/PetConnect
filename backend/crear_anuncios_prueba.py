import os
import django
import math

os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'config.settings')
django.setup()

from django.contrib.auth import get_user_model
from anuncios.models import Anuncio
from usuarios.models import Perfil
from config import settings

User = get_user_model()
# Asegurarse de que el usuario exista
try:
    user = User.objects.get(username='gadrilee')
except User.DoesNotExist:
    user = User.objects.create_user(username='gadrilee', password='Admin123')
    print("Usuario gadrilee creado.")

perfil, created = Perfil.objects.get_or_create(
    usuario=user,
    defaults={'rol': Perfil.Rol.PROPIETARIO, 'whatsapp': '79409208'}
)
if perfil.rol != Perfil.Rol.PROPIETARIO:
    perfil.rol = Perfil.Rol.PROPIETARIO
    perfil.save()

# Minutos objetivo: 10, 20, 30, 40, 50
minutos_objetivo = [10, 20, 30, 40, 50]

print("Creando anuncios de prueba...")

for mins in minutos_objetivo:
    # 1 km = 1/111 grados de latitud
    # Segun la formula: km = (horas * vel) / factor_rodeo
    km = (mins / 60.0) * settings.VELOCIDAD_CAMINANDO_KMH / 1.3
    
    # Movemos solo en latitud para simplificar (hacia el norte = sumar a la latitud negativa)
    delta_lat = km / 111.0
    
    lat = settings.UAGRM_LAT + delta_lat
    lng = settings.UAGRM_LNG
    
    anuncio = Anuncio.objects.create(
        propietario=user,
        titulo=f'Habitación a aprox {mins} min de la UAGRM',
        tipo_espacio=Anuncio.TipoEspacio.HABITACION,
        precio_alquiler=1000 + (50 * mins),
        incluye_agua=True,
        incluye_luz=True,
        incluye_internet=False,
        costo_servicios_estimado=150.00,
        acepta_mascotas=(mins % 20 == 0), # 20 y 40 aceptan mascotas
        restricciones='Solo para estudiantes' if mins % 2 != 0 else '',
        lat=lat,
        lng=lng,
        direccion_referencia=f'Ubicación a aprox {mins} minutos',
    )
    print(f"Creado: ID {anuncio.id} - '{anuncio.titulo}' (Minutos calculados por el backend: {anuncio.minutos_caminando})")
