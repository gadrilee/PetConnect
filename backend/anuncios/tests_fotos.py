"""Pruebas de la carga de fotos.

La foto lleva `fecha_captura`: cuando se **tomo**, no cuando se subio. Es lo
que ataca la evidencia 4, "las fotos eran de hace años".
"""

import io
import shutil
import tempfile

from django.test import override_settings
from django.utils import timezone
from PIL import Image
from rest_framework import status

from .tests_api import BaseAPITest

MEDIA_TEMPORAL = tempfile.mkdtemp()


def imagen_de_prueba(nombre='cuarto.jpg'):
    """Un JPEG real y minimo: ImageField valida que sea una imagen de verdad."""
    buffer = io.BytesIO()
    Image.new('RGB', (40, 40), color=(120, 160, 140)).save(buffer, format='JPEG')
    buffer.seek(0)
    buffer.name = nombre
    return buffer


@override_settings(MEDIA_ROOT=MEDIA_TEMPORAL)
class FotosAPITest(BaseAPITest):
    """Las fotos se escriben en un MEDIA_ROOT temporal, no en el del proyecto."""

    @classmethod
    def tearDownClass(cls):
        shutil.rmtree(MEDIA_TEMPORAL, ignore_errors=True)
        super().tearDownClass()

    def setUp(self):
        self.registrar('marta', 'PROPIETARIO', whatsapp='70011122')
        self.autenticar('marta')
        self.anuncio_id = self.client.post(
            '/api/anuncios/', self.ANUNCIO, format='json').data['id']

    def subir(self, fecha=None):
        return self.client.post(
            '/api/anuncios/{}/fotos/'.format(self.anuncio_id),
            {
                'imagen': imagen_de_prueba(),
                'fecha_captura': (fecha or timezone.now()).isoformat(),
            },
            format='multipart',
        )

    def test_el_propietario_sube_una_foto_con_su_fecha_de_captura(self):
        cuando = timezone.now()
        r = self.subir(cuando)
        self.assertEqual(r.status_code, status.HTTP_201_CREATED, r.data)
        self.assertIn('imagen', r.data)
        self.assertIsNotNone(r.data['fecha_captura'])

    def test_la_foto_aparece_en_el_detalle_del_anuncio(self):
        self.subir()
        detalle = self.client.get('/api/anuncios/{}/'.format(self.anuncio_id)).data
        self.assertEqual(len(detalle['fotos']), 1)
        self.assertIn('fecha_captura', detalle['fotos'][0])

    def test_sin_fecha_de_captura_no_se_acepta(self):
        # Una foto sin fecha es una foto que puede ser de hace años: es
        # exactamente el problema que el campo viene a resolver.
        r = self.client.post(
            '/api/anuncios/{}/fotos/'.format(self.anuncio_id),
            {'imagen': imagen_de_prueba()},
            format='multipart',
        )
        self.assertEqual(r.status_code, status.HTTP_400_BAD_REQUEST)
        self.assertIn('fecha_captura', r.data)

    def test_un_archivo_que_no_es_imagen_se_rechaza(self):
        falso = io.BytesIO(b'esto no es una imagen')
        falso.name = 'trampa.jpg'
        r = self.client.post(
            '/api/anuncios/{}/fotos/'.format(self.anuncio_id),
            {'imagen': falso, 'fecha_captura': timezone.now().isoformat()},
            format='multipart',
        )
        self.assertEqual(r.status_code, status.HTTP_400_BAD_REQUEST)

    def test_nadie_sube_fotos_al_anuncio_de_otro(self):
        self.salir()
        self.registrar('intruso', 'PROPIETARIO', whatsapp='70055566')
        self.autenticar('intruso')
        r = self.subir()
        self.assertEqual(r.status_code, status.HTTP_403_FORBIDDEN)

    def test_una_inquilina_no_sube_fotos(self):
        self.salir()
        self.registrar('andrea', 'INQUILINO')
        self.autenticar('andrea')
        r = self.subir()
        self.assertEqual(r.status_code, status.HTTP_403_FORBIDDEN)

    def test_varias_fotos_conservan_su_orden(self):
        self.subir()
        self.subir()
        detalle = self.client.get('/api/anuncios/{}/'.format(self.anuncio_id)).data
        self.assertEqual(len(detalle['fotos']), 2)
