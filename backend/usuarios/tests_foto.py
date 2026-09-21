"""La foto de perfil: se sube, se cambia y se quita desde Mi perfil.

Se guarda cuadrada, chica y sin metadatos: una foto del telefono puede traer
las coordenadas de donde se saco.
"""

import io
import os
import shutil
import tempfile
from unittest import mock

from django.contrib.auth.models import User
from django.core.files.storage import default_storage
from django.test import override_settings
from PIL import Image
from rest_framework import status

from anuncios.tests_api import BaseAPITest

MEDIA_TEMPORAL = tempfile.mkdtemp()

# Etiquetas EXIF: 0x0112 es la orientacion y 0x8825 el bloque del GPS.
ORIENTACION = 0x0112
GPS = 0x8825


def imagen(ancho=80, alto=80, formato='JPEG', nombre='cara.jpg', exif=None,
           color=(200, 140, 100)):
    """Una imagen real y minima, como la que manda la app."""
    buffer = io.BytesIO()
    modo = 'RGBA' if formato == 'PNG' else 'RGB'
    img = Image.new(modo, (ancho, alto), color=color)
    if exif is not None:
        img.save(buffer, format=formato, exif=exif)
    else:
        img.save(buffer, format=formato)
    buffer.seek(0)
    buffer.name = nombre
    return buffer


@override_settings(MEDIA_ROOT=MEDIA_TEMPORAL)
class FotoDePerfilTest(BaseAPITest):
    """Las fotos se escriben en un MEDIA_ROOT temporal, no en el del proyecto."""

    URL = '/api/usuarios/yo/foto/'

    @classmethod
    def tearDownClass(cls):
        shutil.rmtree(MEDIA_TEMPORAL, ignore_errors=True)
        super().tearDownClass()

    def setUp(self):
        self.registrar('marta', 'PROPIETARIO', whatsapp='70011122')
        self.autenticar('marta')

    def subir(self, archivo=None):
        return self.client.post(self.URL, {'foto': archivo or imagen()}, format='multipart')

    def guardada(self):
        """La foto tal como quedo en el disco."""
        nombre = User.objects.get(username='marta').perfil.foto.name
        return Image.open(os.path.join(MEDIA_TEMPORAL, nombre))

    # --------------------------------------------------------------- subir

    def test_sube_su_foto_y_vuelve_el_perfil_con_la_direccion(self):
        r = self.subir()
        self.assertEqual(r.status_code, status.HTTP_200_OK, r.data)
        self.assertEqual(r.data['username'], 'marta')
        self.assertTrue(r.data['foto'].startswith('http://testserver/media/perfiles/'))
        self.assertTrue(r.data['foto'].endswith('.jpg'))

    def test_mi_perfil_devuelve_la_foto_y_null_si_no_hay(self):
        self.assertIsNone(self.client.get('/api/usuarios/yo/').data['foto'])
        subida = self.subir().data['foto']
        self.assertEqual(self.client.get('/api/usuarios/yo/').data['foto'], subida)

    def test_se_guarda_cuadrada_de_512_y_en_jpeg(self):
        # Un PNG apaisado con transparencia: queda un JPEG cuadrado.
        self.subir(imagen(ancho=900, alto=400, formato='PNG', nombre='cara.png'))
        foto = self.guardada()
        self.assertEqual(foto.format, 'JPEG')
        self.assertEqual(foto.size, (512, 512))

    def test_se_borran_los_metadatos_con_el_gps(self):
        exif = Image.Exif()
        exif[0x010F] = 'Telefono de Marta'  # la marca de la camara
        exif[GPS] = {1: 'S', 2: (17.0, 47.0, 0.0), 3: 'W', 4: (63.0, 10.0, 0.0)}
        self.subir(imagen(exif=exif))
        self.assertEqual(len(self.guardada().getexif()), 0)

    def test_la_endereza_segun_la_camara(self):
        # Arriba roja y abajo azul, con la marca EXIF "girala 90 grados a la
        # derecha" (orientacion 6), que es como guarda muchas fotos el
        # telefono en vertical. Enderezada, el rojo queda a la derecha.
        buffer = io.BytesIO()
        original = Image.new('RGB', (80, 80), (0, 0, 255))
        original.paste((255, 0, 0), (0, 0, 80, 40))
        exif = Image.Exif()
        exif[ORIENTACION] = 6
        original.save(buffer, format='JPEG', exif=exif)
        buffer.seek(0)
        buffer.name = 'vertical.jpg'

        self.subir(buffer)
        foto = self.guardada().convert('RGB')
        derecha = foto.getpixel((450, 256))
        izquierda = foto.getpixel((60, 256))
        self.assertGreater(derecha[0], derecha[2], 'el rojo tenia que quedar a la derecha')
        self.assertGreater(izquierda[2], izquierda[0], 'el azul tenia que quedar a la izquierda')

    def test_la_inquilina_tambien_pone_su_foto(self):
        self.salir()
        self.registrar('andrea', 'INQUILINO')
        self.autenticar('andrea')
        r = self.subir()
        self.assertEqual(r.status_code, status.HTTP_200_OK, r.data)
        self.assertIsNotNone(r.data['foto'])

    # ------------------------------------------------------ cambiar y quitar

    def test_cambiarla_borra_la_anterior_del_disco(self):
        self.subir()
        primera = User.objects.get(username='marta').perfil.foto.name
        segunda = self.subir(imagen(color=(40, 90, 160))).data['foto']

        self.assertFalse(default_storage.exists(primera))
        self.assertNotIn(primera, segunda, 'la direccion tiene que cambiar')

    def test_quitarla_vuelve_a_null_y_la_borra_del_disco(self):
        self.subir()
        nombre = User.objects.get(username='marta').perfil.foto.name

        r = self.client.delete(self.URL)
        self.assertEqual(r.status_code, status.HTTP_200_OK, r.data)
        self.assertIsNone(r.data['foto'])
        self.assertFalse(default_storage.exists(nombre))

    def test_quitarla_sin_tener_foto_no_falla(self):
        r = self.client.delete(self.URL)
        self.assertEqual(r.status_code, status.HTTP_200_OK)
        self.assertIsNone(r.data['foto'])

    def test_borrar_la_cuenta_borra_la_foto(self):
        self.subir()
        nombre = User.objects.get(username='marta').perfil.foto.name
        User.objects.get(username='marta').delete()
        self.assertFalse(default_storage.exists(nombre))

    # ------------------------------------------------------------- errores

    def test_un_archivo_que_no_es_imagen_se_rechaza(self):
        falso = io.BytesIO(b'esto no es una foto')
        falso.name = 'trampa.jpg'
        r = self.subir(falso)
        self.assertEqual(r.status_code, status.HTTP_400_BAD_REQUEST)
        self.assertIn('no es una foto', str(r.data['foto']))

    def test_sin_archivo_pide_elegir_una(self):
        r = self.client.post(self.URL, {}, format='multipart')
        self.assertEqual(r.status_code, status.HTTP_400_BAD_REQUEST)
        self.assertIn('Elegí una foto', str(r.data['foto']))

    def test_una_foto_que_pesa_demasiado_se_rechaza(self):
        with mock.patch('usuarios.serializers.FOTO_MAX_BYTES', 100):
            r = self.subir()
        self.assertEqual(r.status_code, status.HTTP_400_BAD_REQUEST)
        self.assertIn('5 MB', str(r.data['foto']))

    def test_un_rechazo_no_toca_la_foto_que_tenia(self):
        buena = self.subir().data['foto']
        falso = io.BytesIO(b'no')
        falso.name = 'x.jpg'
        self.subir(falso)
        self.assertEqual(self.client.get('/api/usuarios/yo/').data['foto'], buena)

    def test_sin_sesion_no_se_sube(self):
        self.salir()
        r = self.subir()
        self.assertEqual(r.status_code, status.HTTP_401_UNAUTHORIZED)
