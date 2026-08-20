"""Pruebas de las reglas que sostienen el producto, no del ORM de Django."""

from decimal import Decimal

from django.contrib.auth.models import User
from django.core.exceptions import ValidationError
from django.test import TestCase

from .models import Anuncio
from .utils import minutos_caminando_a_uagrm


def anuncio_valido(**extra):
    campos = dict(
        titulo='Habitacion con bano privado',
        tipo_espacio=Anuncio.TipoEspacio.HABITACION,
        precio_alquiler=Decimal('700'),
        incluye_agua=True,
        incluye_luz=True,
        incluye_internet=True,
        acepta_mascotas=False,
        lat=-17.7757,
        lng=-63.1980,
    )
    campos.update(extra)
    return campos


class PrecioFinalTest(TestCase):
    """Evidencia 1: el precio publicado no es el precio final."""

    def setUp(self):
        self.marta = User.objects.create_user('marta')

    def test_todo_incluido_el_precio_final_es_el_alquiler(self):
        a = Anuncio.objects.create(propietario=self.marta, **anuncio_valido())
        self.assertEqual(a.precio_final, Decimal('700'))

    def test_servicios_aparte_se_suman_al_precio_final(self):
        a = Anuncio.objects.create(propietario=self.marta, **anuncio_valido(
            incluye_agua=False, incluye_luz=False,
            costo_servicios_estimado=Decimal('300'),
        ))
        self.assertEqual(a.precio_final, Decimal('1000'))

    def test_no_se_puede_ocultar_lo_que_falta_pagar(self):
        a = Anuncio(propietario=self.marta, **anuncio_valido(
            incluye_agua=False, costo_servicios_estimado=Decimal('0'),
        ))
        with self.assertRaises(ValidationError) as ctx:
            a.full_clean()
        self.assertIn('costo_servicios_estimado', ctx.exception.message_dict)


class MinutosCaminandoTest(TestCase):
    """Evidencia 2: "cerca de la U" resulto ser 25 minutos caminando."""

    def test_en_el_campus_son_cero_minutos(self):
        from django.conf import settings
        self.assertEqual(minutos_caminando_a_uagrm(settings.UAGRM_LAT, settings.UAGRM_LNG), 0)

    def test_un_kilometro_en_linea_recta_da_mas_de_12_minutos(self):
        from django.conf import settings
        # 1 km al norte del campus. A 5 km/h en linea recta serian 12 min;
        # con el factor de rodeo tiene que dar mas, nunca menos.
        minutos = minutos_caminando_a_uagrm(settings.UAGRM_LAT + 0.008993, settings.UAGRM_LNG)
        self.assertGreater(minutos, 12)
        self.assertLessEqual(minutos, 20)

    def test_el_propietario_no_escribe_los_minutos_los_calcula_la_app(self):
        marta = User.objects.create_user('marta2')
        a = Anuncio.objects.create(propietario=marta, **anuncio_valido())
        self.assertEqual(a.minutos_caminando, 0)


class CicloDeVidaTest(TestCase):
    """Evidencia 8: los anuncios no mueren y siguen generando mensajes."""

    def setUp(self):
        self.marta = User.objects.create_user('marta3')
        self.anuncio = Anuncio.objects.create(propietario=self.marta, **anuncio_valido())

    def test_nace_disponible(self):
        self.assertTrue(self.anuncio.esta_disponible)
        self.assertIsNone(self.anuncio.alquilado_en)

    def test_marcar_alquilado_deja_constancia_de_cuando(self):
        self.anuncio.marcar_alquilado()
        self.anuncio.refresh_from_db()
        self.assertFalse(self.anuncio.esta_disponible)
        self.assertIsNotNone(self.anuncio.alquilado_en)
