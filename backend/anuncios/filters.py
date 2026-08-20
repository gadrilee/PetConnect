"""Filtros de busqueda: exactamente las cuatro condiciones de descarte.

El filtro de precio corre sobre el precio FINAL (alquiler + servicios que se
pagan aparte), no sobre el alquiler pelado. Filtrar por el alquiler seria
repetir el problema de la evidencia 1.
"""

import django_filters as filters

from .models import Anuncio


class AnuncioFilter(filters.FilterSet):
    precio_max = filters.NumberFilter(field_name='precio_final_calc', lookup_expr='lte')
    precio_min = filters.NumberFilter(field_name='precio_final_calc', lookup_expr='gte')
    minutos_max = filters.NumberFilter(field_name='minutos_caminando', lookup_expr='lte')
    acepta_mascotas = filters.BooleanFilter()
    tipo_espacio = filters.ChoiceFilter(choices=Anuncio.TipoEspacio.choices)

    class Meta:
        model = Anuncio
        fields = ('precio_min', 'precio_max', 'minutos_max',
                  'acepta_mascotas', 'tipo_espacio')
