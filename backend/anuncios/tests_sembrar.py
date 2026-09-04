"""Pruebas del comando que siembra anuncios de prueba.

Lo que se fija aca no es que "cree filas": es que los datos sembrados sirvan
para probar la busqueda. Si los minutos caminando no dan lo que se pidio, los
filtros de distancia se estarian probando contra numeros inventados y la
pantalla de resultados diria cualquier cosa.
"""

from io import StringIO

from django.contrib.auth.models import User
from django.core.management import call_command
from django.test import TestCase

from .management.commands.sembrar_anuncios import ANUNCIOS, SUFIJO
from .models import Anuncio


class SembrarAnunciosTest(TestCase):
    def sembrar(self, *args):
        salida = StringIO()
        call_command('sembrar_anuncios', *args, stdout=salida, stderr=salida)
        return salida.getvalue()

    def test_crea_todos_los_anuncios_disponibles(self):
        self.sembrar()

        anuncios = Anuncio.objects.all()
        self.assertEqual(anuncios.count(), len(ANUNCIOS))
        # La busqueda solo devuelve DISPONIBLE: sembrar algo ya alquilado no
        # apareceria y el comando no serviria para lo que se lo escribio.
        self.assertTrue(all(a.esta_disponible for a in anuncios))

    def test_los_minutos_caminando_dan_lo_que_se_pidio(self):
        """La parte fragil: invertir el calculo de la distancia.

        `minutos_caminando` es derivado y se redondea hacia arriba, asi que la
        coordenada se calcula al reves desde el objetivo. Si esa inversion se
        corre aunque sea un minuto, filtrar "hasta 15 min" deja afuera cosas
        que deberian entrar.
        """
        self.sembrar()

        esperados = sorted(fila[6] for fila in ANUNCIOS)
        reales = sorted(Anuncio.objects.values_list('minutos_caminando', flat=True))
        self.assertEqual(reales, esperados)

    def test_ninguno_queda_a_cero_minutos(self):
        """Nada esta a 0 minutos del campus.

        Un anuncio en 0 delata una coordenada sin cargar —el default cae justo
        sobre la UAGRM— y ensucia el orden por cercania, que es lo primero que
        se lee en los resultados.
        """
        self.sembrar()

        self.assertNotIn(0, Anuncio.objects.values_list('minutos_caminando', flat=True))

    def test_hay_variedad_para_que_filtrar_sirva(self):
        """Con datos todos iguales, mover un filtro no cambiaria nada."""
        self.sembrar()

        anuncios = list(Anuncio.objects.all())
        precios = {a.precio_final for a in anuncios}
        tipos = {a.tipo_espacio for a in anuncios}
        mascotas = {a.acepta_mascotas for a in anuncios}

        self.assertGreaterEqual(len(precios), 8, 'pocos precios distintos')
        self.assertEqual(len(tipos), 3, 'faltan tipos de espacio')
        self.assertEqual(mascotas, {True, False}, 'el filtro de mascotas no discrimina')

    def test_todos_respetan_la_regla_del_precio_final(self):
        """Si algo no esta incluido, hay que declarar cuanto se paga aparte.

        Es la regla que sostiene el producto. Datos de prueba que la violen
        serian datos que la app nunca habria podido crear.
        """
        self.sembrar()

        for anuncio in Anuncio.objects.all():
            if not anuncio.todos_los_servicios_incluidos:
                self.assertGreater(
                    anuncio.costo_servicios_estimado,
                    0,
                    f'{anuncio.titulo} esconde lo que falta pagar',
                )

    def test_limpiar_no_toca_los_anuncios_reales(self):
        """--limpiar borra lo sembrado, no la base."""
        real = User.objects.create_user('propietaria_real')
        Anuncio.objects.create(
            propietario=real,
            titulo='Anuncio de verdad',
            tipo_espacio=Anuncio.TipoEspacio.CASA,
            precio_alquiler=900,
            incluye_agua=True,
            incluye_luz=True,
            incluye_internet=True,
            acepta_mascotas=True,
            lat=-17.78,
            lng=-63.19,
        )

        self.sembrar()
        self.sembrar('--limpiar')

        # Sembrar dos veces no acumula, y el anuncio ajeno sigue en pie.
        self.assertEqual(Anuncio.objects.count(), len(ANUNCIOS) + 1)
        self.assertTrue(Anuncio.objects.filter(titulo='Anuncio de verdad').exists())
        self.assertFalse(
            User.objects.filter(username__endswith=SUFIJO).exclude(
                anuncios__isnull=False
            ).exists()
            and Anuncio.objects.filter(
                propietario__username__endswith=SUFIJO
            ).count() != len(ANUNCIOS)
        )
