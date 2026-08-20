"""Calculo de los minutos caminando hasta la UAGRM.

No usamos PostGIS a proposito: la distancia se mide siempre contra un unico
punto fijo (el campus), asi que alcanza con haversine sobre dos columnas
lat/lng. Instalar GDAL/GEOS costaria mas de lo que aporta.
"""

import math

from django.conf import settings

RADIO_TIERRA_KM = 6371.0

# Las calles no son lineas rectas. Sin este factor, la estimacion quedaria
# por DEBAJO del tiempo real y la app recrearia justo el problema que viene
# a resolver: la evidencia 2 es una estudiante a la que le dijeron "cerca"
# y resulto ser 25 minutos caminando.
#
# OJO: 1.3 es un valor de referencia habitual en planificacion urbana, no
# una medicion hecha en Santa Cruz. Hay que validarlo contra recorridos
# reales antes de confiar en el numero que ve el usuario.
FACTOR_RODEO = 1.3


def distancia_km(lat1, lng1, lat2, lng2):
    """Distancia en linea recta entre dos puntos, en kilometros."""
    dlat = math.radians(lat2 - lat1)
    dlng = math.radians(lng2 - lng1)
    a = (
        math.sin(dlat / 2) ** 2
        + math.cos(math.radians(lat1))
        * math.cos(math.radians(lat2))
        * math.sin(dlng / 2) ** 2
    )
    return RADIO_TIERRA_KM * 2 * math.asin(math.sqrt(a))


def minutos_caminando_a_uagrm(lat, lng):
    """Minutos caminando desde un punto hasta el campus de la UAGRM.

    Se redondea hacia arriba: ante la duda conviene prometer de mas y no
    de menos, porque el costo de equivocarse lo paga el inquilino con un
    viaje perdido.
    """
    km = distancia_km(lat, lng, settings.UAGRM_LAT, settings.UAGRM_LNG)
    horas = (km * FACTOR_RODEO) / settings.VELOCIDAD_CAMINANDO_KMH
    return math.ceil(horas * 60)
