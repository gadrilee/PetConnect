"""Flujo v0.5 — al marcar el cuarto como alquilado, las pendientes se cierran."""

from rest_framework import status

from anuncios.tests_api import BaseAPITest


def _primero(datos):
    """El primer anuncio de una respuesta, este paginada o no."""
    return (datos['results'] if isinstance(datos, dict) else datos)[0]


class CerrarAlAlquilarTest(BaseAPITest):

    def setUp(self):
        self.registrar('marta', 'PROPIETARIO', whatsapp='70011122')
        self.autenticar('marta')
        self.anuncio_id = self.client.post('/api/anuncios/', self.ANUNCIO, format='json').data['id']
        self.salir()

        # Tres personas piden visita al mismo cuarto.
        self.ids = {}
        for nombre in ('andrea', 'lucia', 'sofia'):
            self.registrar(nombre, 'INQUILINO')
            self.autenticar(nombre)
            r = self.client.post('/api/solicitudes/',
                                 {'anuncio': self.anuncio_id, 'condiciones_aceptadas': True},
                                 format='json')
            assert r.status_code == status.HTTP_201_CREATED, r.data
            self.ids[nombre] = r.data['id']
            self.salir()

        # Marta ya le respondio a andrea: esa no queda pendiente.
        self.autenticar('marta')
        self.client.post('/api/solicitudes/{}/aprobar/'.format(self.ids['andrea']))

    def estado_de(self, nombre):
        self.salir()
        self.autenticar(nombre)
        estado = self.client.get('/api/solicitudes/{}/'.format(self.ids[nombre])).data['estado']
        self.salir()
        self.autenticar('marta')
        return estado

    def marcar_alquilado(self):
        return self.client.post('/api/anuncios/{}/marcar_alquilado/'.format(self.anuncio_id))

    def test_mis_anuncios_cuenta_las_pendientes(self):
        anuncio = _primero(self.client.get('/api/anuncios/mios/').data)
        self.assertEqual(anuncio['solicitudes_pendientes'], 2)

    def test_la_busqueda_no_muestra_las_pendientes(self):
        self.salir()
        self.autenticar('lucia')
        anuncio = _primero(self.client.get('/api/anuncios/').data)
        self.assertNotIn('solicitudes_pendientes', anuncio)

    def test_marcar_alquilado_cierra_las_pendientes_y_dice_cuantas(self):
        r = self.marcar_alquilado()
        self.assertEqual(r.status_code, status.HTTP_200_OK, r.data)
        self.assertEqual(r.data['estado'], 'ALQUILADO')
        self.assertEqual(r.data['solicitudes_cerradas'], 2)
        self.assertEqual(self.estado_de('lucia'), 'CERRADA')
        self.assertEqual(self.estado_de('sofia'), 'CERRADA')

    def test_no_toca_la_que_ya_tenia_respuesta(self):
        self.marcar_alquilado()
        self.assertEqual(self.estado_de('andrea'), 'APROBADA')

    def test_ya_no_quedan_pendientes_despues_de_alquilar(self):
        self.marcar_alquilado()
        anuncio = _primero(self.client.get('/api/anuncios/mios/').data)
        self.assertEqual(anuncio['solicitudes_pendientes'], 0)

    def test_volver_a_publicar_no_reabre_las_cerradas(self):
        self.marcar_alquilado()
        self.client.post('/api/anuncios/{}/marcar_disponible/'.format(self.anuncio_id))
        self.assertEqual(self.estado_de('lucia'), 'CERRADA')
