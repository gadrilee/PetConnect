"""La cuenta: correo obligatorio, Mi perfil y recuperar la contrasena."""

import re

from django.core import mail
from rest_framework import status

from anuncios.tests_api import BaseAPITest


class CorreoEnElRegistroTest(BaseAPITest):

    def datos(self, **cambios):
        base = {'username': 'andrea', 'email': 'andrea@uagrm.edu.bo',
                'password': 'clave-larga-123', 'rol': 'INQUILINO'}
        return {**base, **cambios}

    def test_sin_correo_no_se_puede_crear_la_cuenta(self):
        datos = self.datos()
        del datos['email']
        r = self.client.post('/api/usuarios/registro/', datos, format='json')
        self.assertEqual(r.status_code, status.HTTP_400_BAD_REQUEST)
        self.assertIn('email', r.data)

    def test_un_correo_es_una_sola_cuenta(self):
        self.client.post('/api/usuarios/registro/', self.datos(), format='json')
        otra = self.datos(username='andrea2', email='ANDREA@uagrm.edu.bo')
        r = self.client.post('/api/usuarios/registro/', otra, format='json')
        self.assertEqual(r.status_code, status.HTTP_400_BAD_REQUEST)
        self.assertIn('Ya hay una cuenta con ese correo', str(r.data))

    def test_el_whatsapp_tiene_ocho_digitos(self):
        datos = self.datos(username='marta', email='marta@uagrm.edu.bo',
                           rol='PROPIETARIO', whatsapp='7001')
        r = self.client.post('/api/usuarios/registro/', datos, format='json')
        self.assertEqual(r.status_code, status.HTTP_400_BAD_REQUEST)
        self.assertIn('8 dígitos', str(r.data))


class MiPerfilTest(BaseAPITest):

    def setUp(self):
        self.registrar('marta', 'PROPIETARIO', whatsapp='70011122')
        self.autenticar('marta')

    def test_muestra_el_correo(self):
        r = self.client.get('/api/usuarios/yo/')
        self.assertEqual(r.data['email'], 'marta@uagrm.edu.bo')

    def test_cambia_el_whatsapp(self):
        r = self.client.patch('/api/usuarios/yo/', {'whatsapp': '70099988'}, format='json')
        self.assertEqual(r.status_code, status.HTTP_200_OK, r.data)
        self.assertEqual(self.client.get('/api/usuarios/yo/').data['whatsapp'], '70099988')

    def test_rechaza_un_whatsapp_incompleto(self):
        r = self.client.patch('/api/usuarios/yo/', {'whatsapp': '7009'}, format='json')
        self.assertEqual(r.status_code, status.HTTP_400_BAD_REQUEST)
        self.assertEqual(self.client.get('/api/usuarios/yo/').data['whatsapp'], '70011122')

    def test_la_propietaria_no_puede_quedarse_sin_whatsapp(self):
        r = self.client.patch('/api/usuarios/yo/', {'whatsapp': ''}, format='json')
        self.assertEqual(r.status_code, status.HTTP_400_BAD_REQUEST)

    def test_el_rol_no_se_cambia_desde_el_perfil(self):
        self.client.patch('/api/usuarios/yo/', {'rol': 'INQUILINO'}, format='json')
        self.assertEqual(self.client.get('/api/usuarios/yo/').data['rol'], 'PROPIETARIO')

    def test_no_acepta_reemplazar_el_perfil_entero(self):
        r = self.client.put('/api/usuarios/yo/', {'whatsapp': '70099988'}, format='json')
        self.assertEqual(r.status_code, status.HTTP_405_METHOD_NOT_ALLOWED)


class RecuperarContrasenaTest(BaseAPITest):

    NUEVA = 'otra-clave-segura-456'

    def setUp(self):
        self.registrar('marta', 'PROPIETARIO', whatsapp='70011122')

    def pedir(self, email='marta@uagrm.edu.bo'):
        return self.client.post('/api/usuarios/recuperar/', {'email': email}, format='json')

    def enlace(self):
        """uid y token del enlace que llego por correo."""
        m = re.search(r'uid=([\w-]+)&token=([\w-]+)', mail.outbox[-1].body)
        return m.group(1), m.group(2)

    def test_manda_el_enlace_al_correo_de_la_cuenta(self):
        r = self.pedir()
        self.assertEqual(r.status_code, status.HTTP_200_OK)
        self.assertEqual(len(mail.outbox), 1)
        self.assertEqual(mail.outbox[0].to, ['marta@uagrm.edu.bo'])
        self.assertIn('alquilamatch://app/recuperar?uid=', mail.outbox[0].body)

    def test_no_revela_si_el_correo_tiene_cuenta(self):
        con_cuenta = self.pedir().data
        sin_cuenta = self.pedir('nadie@uagrm.edu.bo').data
        self.assertEqual(con_cuenta, sin_cuenta)
        self.assertEqual(len(mail.outbox), 1)   # sólo el de la cuenta real

    def test_la_contrasena_nueva_deja_adentro_y_sirve_para_entrar(self):
        self.pedir()
        uid, token = self.enlace()
        r = self.client.post('/api/usuarios/recuperar/confirmar/',
                             {'uid': uid, 'token': token, 'password': self.NUEVA}, format='json')
        self.assertEqual(r.status_code, status.HTTP_200_OK, r.data)
        self.assertIn('access', r.data)

        entrar = self.client.post('/api/auth/token/',
                                  {'username': 'marta', 'password': self.NUEVA}, format='json')
        self.assertEqual(entrar.status_code, status.HTTP_200_OK)

    def test_el_enlace_sirve_una_sola_vez(self):
        self.pedir()
        uid, token = self.enlace()
        datos = {'uid': uid, 'token': token, 'password': self.NUEVA}
        self.client.post('/api/usuarios/recuperar/confirmar/', datos, format='json')
        r = self.client.post('/api/usuarios/recuperar/confirmar/', datos, format='json')
        self.assertEqual(r.status_code, status.HTTP_400_BAD_REQUEST)
        self.assertIn('venció', str(r.data))

    def test_un_enlace_inventado_no_sirve(self):
        r = self.client.post('/api/usuarios/recuperar/confirmar/',
                             {'uid': 'MQ', 'token': 'abc-123', 'password': self.NUEVA}, format='json')
        self.assertEqual(r.status_code, status.HTTP_400_BAD_REQUEST)
