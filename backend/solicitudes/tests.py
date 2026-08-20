"""La regla central: el contacto no existe hasta que el propietario aprueba."""

from decimal import Decimal

from django.contrib.auth.models import User
from django.core.exceptions import ValidationError
from django.db import IntegrityError, transaction
from django.test import TestCase

from anuncios.models import Anuncio
from usuarios.models import Perfil

from .models import SolicitudVisita


class ContactoOcultoTest(TestCase):

    def setUp(self):
        self.marta = User.objects.create_user('marta')
        Perfil.objects.create(
            usuario=self.marta, rol=Perfil.Rol.PROPIETARIO, whatsapp='70011122',
        )
        self.andrea = User.objects.create_user('andrea')
        Perfil.objects.create(usuario=self.andrea, rol=Perfil.Rol.INQUILINO)

        self.anuncio = Anuncio.objects.create(
            propietario=self.marta,
            titulo='Habitacion cerca del campus',
            tipo_espacio=Anuncio.TipoEspacio.HABITACION,
            precio_alquiler=Decimal('700'),
            incluye_agua=True, incluye_luz=True, incluye_internet=True,
            acepta_mascotas=False,
            lat=-17.7757, lng=-63.1980,
        )
        self.solicitud = SolicitudVisita.objects.create(
            anuncio=self.anuncio, inquilino=self.andrea, condiciones_aceptadas=True,
        )

    def test_pendiente_no_libera_el_contacto(self):
        self.assertIsNone(self.solicitud.contacto_liberado)

    def test_rechazada_no_libera_el_contacto(self):
        self.solicitud.rechazar()
        self.assertIsNone(self.solicitud.contacto_liberado)

    def test_aprobada_libera_el_whatsapp_del_propietario(self):
        self.solicitud.aprobar()
        self.assertEqual(self.solicitud.contacto_liberado, '70011122')
        self.assertIsNotNone(self.solicitud.respondida_en)

    def test_no_se_solicita_sin_aceptar_las_condiciones(self):
        s = SolicitudVisita(anuncio=self.anuncio, inquilino=User.objects.create_user('otro'))
        with self.assertRaises(ValidationError) as ctx:
            s.full_clean()
        self.assertIn('condiciones_aceptadas', ctx.exception.message_dict)

    def test_no_se_solicita_sobre_un_anuncio_ya_alquilado(self):
        self.anuncio.marcar_alquilado()
        s = SolicitudVisita(
            anuncio=self.anuncio,
            inquilino=User.objects.create_user('tarde'),
            condiciones_aceptadas=True,
        )
        with self.assertRaises(ValidationError) as ctx:
            s.full_clean()
        self.assertIn('anuncio', ctx.exception.message_dict)

    def test_no_se_puede_solicitar_dos_veces_el_mismo_anuncio(self):
        with self.assertRaises(IntegrityError):
            with transaction.atomic():
                SolicitudVisita.objects.create(
                    anuncio=self.anuncio, inquilino=self.andrea, condiciones_aceptadas=True,
                )
