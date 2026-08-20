"""La regla central, probada sobre la API: el contacto no se filtra."""

from rest_framework import status

from anuncios.tests_api import BaseAPITest

WHATSAPP = '70011122'


class ContactoOcultoAPITest(BaseAPITest):

    def setUp(self):
        self.registrar('marta', 'PROPIETARIO', whatsapp=WHATSAPP)
        self.autenticar('marta')
        self.anuncio_id = self.client.post(
            '/api/anuncios/', self.ANUNCIO, format='json').data['id']
        self.salir()
        self.registrar('andrea', 'INQUILINO')
        self.autenticar('andrea')

    def solicitar(self):
        return self.client.post(
            '/api/solicitudes/',
            {'anuncio': self.anuncio_id, 'condiciones_aceptadas': True},
            format='json',
        )

    # --- El anuncio nunca lleva el telefono ---

    def test_el_detalle_del_anuncio_no_contiene_el_whatsapp(self):
        cuerpo = str(self.client.get('/api/anuncios/{}/'.format(self.anuncio_id)).data)
        self.assertNotIn(WHATSAPP, cuerpo)

    def test_el_listado_no_contiene_el_whatsapp(self):
        cuerpo = str(self.client.get('/api/anuncios/').data)
        self.assertNotIn(WHATSAPP, cuerpo)

    # --- La solicitud lo libera solo al aprobarse ---

    def test_solicitud_pendiente_no_trae_contacto(self):
        r = self.solicitar()
        self.assertEqual(r.status_code, status.HTTP_201_CREATED, r.data)
        self.assertEqual(r.data['estado'], 'PENDIENTE')
        self.assertIsNone(r.data['contacto'])

    def test_aprobar_libera_el_contacto_al_inquilino(self):
        solicitud_id = self.solicitar().data['id']

        self.salir()
        self.autenticar('marta')
        r = self.client.post('/api/solicitudes/{}/aprobar/'.format(solicitud_id))
        self.assertEqual(r.status_code, status.HTTP_200_OK, r.data)

        self.salir()
        self.autenticar('andrea')
        detalle = self.client.get('/api/solicitudes/{}/'.format(solicitud_id)).data
        self.assertEqual(detalle['estado'], 'APROBADA')
        self.assertEqual(detalle['contacto'], WHATSAPP)

    def test_rechazar_no_libera_el_contacto(self):
        solicitud_id = self.solicitar().data['id']
        self.salir()
        self.autenticar('marta')
        self.client.post('/api/solicitudes/{}/rechazar/'.format(solicitud_id))

        self.salir()
        self.autenticar('andrea')
        detalle = self.client.get('/api/solicitudes/{}/'.format(solicitud_id)).data
        self.assertEqual(detalle['estado'], 'RECHAZADA')
        self.assertIsNone(detalle['contacto'])

    # --- Reglas de acceso ---

    def test_no_se_solicita_sin_aceptar_las_condiciones(self):
        r = self.client.post(
            '/api/solicitudes/',
            {'anuncio': self.anuncio_id, 'condiciones_aceptadas': False},
            format='json',
        )
        self.assertEqual(r.status_code, status.HTTP_400_BAD_REQUEST)
        self.assertIn('condiciones_aceptadas', r.data)

    def test_no_se_solicita_dos_veces_el_mismo_anuncio(self):
        self.solicitar()
        r = self.solicitar()
        self.assertEqual(r.status_code, status.HTTP_400_BAD_REQUEST)

    def test_no_se_solicita_sobre_un_anuncio_ya_alquilado(self):
        self.salir()
        self.autenticar('marta')
        self.client.post('/api/anuncios/{}/marcar_alquilado/'.format(self.anuncio_id))
        self.salir()
        self.autenticar('andrea')
        r = self.solicitar()
        self.assertEqual(r.status_code, status.HTTP_400_BAD_REQUEST)

    def test_un_tercero_no_puede_aprobar_una_solicitud_ajena(self):
        solicitud_id = self.solicitar().data['id']
        self.salir()
        self.registrar('intruso', 'PROPIETARIO', whatsapp='70055566')
        self.autenticar('intruso')
        r = self.client.post('/api/solicitudes/{}/aprobar/'.format(solicitud_id))
        self.assertIn(r.status_code,
                      (status.HTTP_403_FORBIDDEN, status.HTTP_404_NOT_FOUND))

    def test_el_inquilino_no_puede_autoaprobarse(self):
        solicitud_id = self.solicitar().data['id']
        r = self.client.post('/api/solicitudes/{}/aprobar/'.format(solicitud_id))
        self.assertEqual(r.status_code, status.HTTP_403_FORBIDDEN)
        detalle = self.client.get('/api/solicitudes/{}/'.format(solicitud_id)).data
        self.assertIsNone(detalle['contacto'])

    def test_no_se_solicita_visita_al_propio_anuncio(self):
        self.salir()
        self.autenticar('marta')
        r = self.client.post(
            '/api/solicitudes/',
            {'anuncio': self.anuncio_id, 'condiciones_aceptadas': True},
            format='json',
        )
        self.assertEqual(r.status_code, status.HTTP_400_BAD_REQUEST)

    def test_cada_lado_ve_su_propia_bandeja(self):
        self.solicitar()
        self.assertEqual(self.client.get('/api/solicitudes/').data['count'], 1)

        self.salir()
        self.autenticar('marta')
        self.assertEqual(self.client.get('/api/solicitudes/').data['count'], 1)

        self.salir()
        self.registrar('ajeno', 'INQUILINO')
        self.autenticar('ajeno')
        self.assertEqual(self.client.get('/api/solicitudes/').data['count'], 0)

    def test_sin_autenticar_no_se_ve_nada(self):
        self.salir()
        self.assertEqual(self.client.get('/api/anuncios/').status_code,
                         status.HTTP_401_UNAUTHORIZED)
