"""Pruebas de la API recorriendo los dos flujos documentados."""

from rest_framework import status
from rest_framework.test import APITestCase


class BaseAPITest(APITestCase):

    ANUNCIO = {
        'titulo': 'Habitacion con bano privado',
        'tipo_espacio': 'HABITACION',
        'precio_alquiler': '700.00',
        'incluye_agua': True,
        'incluye_luz': True,
        'incluye_internet': True,
        'costo_servicios_estimado': '0.00',
        'acepta_mascotas': True,
        'lat': -17.7757,
        'lng': -63.1980,
        'direccion_referencia': 'A media cuadra del campus',
    }

    def registrar(self, username, rol, whatsapp=''):
        datos = {'username': username, 'password': 'clave-larga-123', 'rol': rol}
        if whatsapp:
            datos['whatsapp'] = whatsapp
        r = self.client.post('/api/usuarios/registro/', datos, format='json')
        assert r.status_code == status.HTTP_201_CREATED, r.data
        return datos

    def autenticar(self, username):
        r = self.client.post(
            '/api/auth/token/',
            {'username': username, 'password': 'clave-larga-123'},
            format='json',
        )
        assert r.status_code == status.HTTP_200_OK, r.data
        self.client.credentials(HTTP_AUTHORIZATION='Bearer ' + r.data['access'])

    def salir(self):
        self.client.credentials()


class FlujoPublicarTest(BaseAPITest):
    """Flujo v0.1 — Marta publica un inmueble."""

    def setUp(self):
        self.registrar('marta', 'PROPIETARIO', whatsapp='70011122')
        self.autenticar('marta')

    def test_publica_y_la_app_calcula_los_minutos(self):
        r = self.client.post('/api/anuncios/', self.ANUNCIO, format='json')
        self.assertEqual(r.status_code, status.HTTP_201_CREATED, r.data)

        detalle = self.client.get('/api/anuncios/{}/'.format(r.data['id'])).data
        self.assertEqual(detalle['minutos_caminando'], 0)
        self.assertEqual(detalle['estado'], 'DISPONIBLE')

    def test_no_puede_publicar_escondiendo_los_servicios(self):
        datos = dict(self.ANUNCIO, incluye_agua=False, costo_servicios_estimado='0.00')
        r = self.client.post('/api/anuncios/', datos, format='json')
        self.assertEqual(r.status_code, status.HTTP_400_BAD_REQUEST)
        self.assertIn('costo_servicios_estimado', str(r.data))

    def test_el_precio_final_suma_los_servicios_aparte(self):
        datos = dict(self.ANUNCIO, incluye_agua=False, incluye_luz=False,
                     costo_servicios_estimado='300.00')
        r = self.client.post('/api/anuncios/', datos, format='json')
        detalle = self.client.get('/api/anuncios/{}/'.format(r.data['id'])).data
        self.assertEqual(detalle['precio_final'], '1000.00')

    def test_marcar_alquilado_lo_saca_de_la_busqueda(self):
        anuncio_id = self.client.post(
            '/api/anuncios/', self.ANUNCIO, format='json').data['id']

        r = self.client.post('/api/anuncios/{}/marcar_alquilado/'.format(anuncio_id))
        self.assertEqual(r.status_code, status.HTTP_200_OK)
        self.assertEqual(r.data['estado'], 'ALQUILADO')

        # Evidencia 8: el anuncio tiene que morir cuando el propietario lo apaga.
        self.assertEqual(self.client.get('/api/anuncios/').data['count'], 0)
        # Pero el propietario lo sigue viendo entre los suyos.
        self.assertEqual(self.client.get('/api/anuncios/mios/').data['count'], 1)

    def test_un_inquilino_no_puede_publicar(self):
        self.salir()
        self.registrar('andrea', 'INQUILINO')
        self.autenticar('andrea')
        r = self.client.post('/api/anuncios/', self.ANUNCIO, format='json')
        self.assertEqual(r.status_code, status.HTTP_403_FORBIDDEN)

    def test_no_se_edita_el_anuncio_de_otro(self):
        anuncio_id = self.client.post(
            '/api/anuncios/', self.ANUNCIO, format='json').data['id']
        self.salir()
        self.registrar('otro', 'PROPIETARIO', whatsapp='70099988')
        self.autenticar('otro')
        r = self.client.patch('/api/anuncios/{}/'.format(anuncio_id),
                              {'titulo': 'Secuestrado'}, format='json')
        self.assertEqual(r.status_code, status.HTTP_403_FORBIDDEN)

    def test_propietario_sin_whatsapp_no_se_registra(self):
        self.salir()
        r = self.client.post(
            '/api/usuarios/registro/',
            {'username': 'sinwpp', 'password': 'clave-larga-123', 'rol': 'PROPIETARIO'},
            format='json',
        )
        self.assertEqual(r.status_code, status.HTTP_400_BAD_REQUEST)
        self.assertIn('whatsapp', r.data)


class FlujoBuscarTest(BaseAPITest):
    """Flujo v0.2 — Andrea filtra por las condiciones de descarte."""

    def setUp(self):
        self.registrar('marta', 'PROPIETARIO', whatsapp='70011122')
        self.autenticar('marta')
        # Barato, acepta mascotas, en el campus.
        self.client.post('/api/anuncios/', self.ANUNCIO, format='json')
        # Mismo alquiler pero con servicios aparte, sin mascotas y lejos.
        self.client.post('/api/anuncios/', dict(
            self.ANUNCIO,
            titulo='Departamento amplio',
            tipo_espacio='DEPARTAMENTO',
            acepta_mascotas=False,
            incluye_agua=False,
            incluye_luz=False,
            costo_servicios_estimado='400.00',
            lat=-17.8200,
            lng=-63.2400,
        ), format='json')
        self.salir()
        self.registrar('andrea', 'INQUILINO')
        self.autenticar('andrea')

    def test_filtra_por_mascotas(self):
        r = self.client.get('/api/anuncios/', {'acepta_mascotas': 'true'})
        self.assertEqual(r.data['count'], 1)
        self.assertTrue(r.data['results'][0]['acepta_mascotas'])

    def test_el_filtro_de_precio_corre_sobre_el_precio_final(self):
        # Los dos tienen alquiler 700, pero el departamento suma 400 de
        # servicios aparte. Filtrar hasta 800 tiene que dejarlo afuera:
        # filtrar por el alquiler pelado repetiria la evidencia 1.
        r = self.client.get('/api/anuncios/', {'precio_max': '800'})
        self.assertEqual(r.data['count'], 1)
        self.assertEqual(r.data['results'][0]['precio_final'], '700.00')

    def test_filtra_por_minutos_caminando(self):
        r = self.client.get('/api/anuncios/', {'minutos_max': '10'})
        self.assertEqual(r.data['count'], 1)
        self.assertLessEqual(r.data['results'][0]['minutos_caminando'], 10)

    def test_filtra_por_tipo_de_espacio(self):
        r = self.client.get('/api/anuncios/', {'tipo_espacio': 'DEPARTAMENTO'})
        self.assertEqual(r.data['count'], 1)

    def test_los_resultados_vienen_ordenados_por_cercania(self):
        r = self.client.get('/api/anuncios/')
        minutos = [a['minutos_caminando'] for a in r.data['results']]
        self.assertEqual(minutos, sorted(minutos))
