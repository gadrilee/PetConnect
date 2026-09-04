"""Anuncios de prueba para poder usar la busqueda de verdad.

Con dos o tres anuncios no se puede evaluar la pantalla de resultados: no hay
nada que descartar, que es justamente la tarea. Este comando siembra una
docena con precios, distancias y condiciones distintas, para que filtrar
cambie el resultado y se pueda probar el flujo v0.2 completo.

    python manage.py sembrar_anuncios
    python manage.py sembrar_anuncios --limpiar

Los datos NO se inventan libres: pasan por `full_clean()`, asi que respetan la
regla del modelo de que un anuncio con servicios no incluidos tiene que
declarar cuanto se paga aparte. Si un dia esa regla cambia, este comando falla
y avisa, en vez de meter datos que la app no podria haber creado.
"""

import math

from django.conf import settings
from django.contrib.auth import get_user_model
from django.core.management.base import BaseCommand
from django.db import transaction

from anuncios.models import Anuncio
from anuncios.utils import FACTOR_RODEO, RADIO_TIERRA_KM, minutos_caminando_a_uagrm
from usuarios.models import Perfil

User = get_user_model()

# Los usuarios sembrados llevan este sufijo para poder borrarlos despues sin
# tocar cuentas reales.
SUFIJO = '_demo'

PROPIETARIOS = [
    ('marta' + SUFIJO, 'Marta', '70011122'),
    ('carlos' + SUFIJO, 'Carlos', '70033344'),
    ('rosa' + SUFIJO, 'Rosa', '70055566'),
]

# titulo, tipo, alquiler, (agua, luz, internet), costo servicios, mascotas,
# minutos objetivo, restricciones
ANUNCIOS = [
    ('Habitación con baño privado', 'HABITACION', 800, (1, 1, 1), 0, True, 5, ''),
    ('Habitación amoblada a pasos del campus', 'HABITACION', 650, (1, 1, 0), 120, False, 8, 'Solo señoritas'),
    ('Departamento céntrico de 1 dormitorio', 'DEPARTAMENTO', 1200, (1, 0, 1), 180, False, 10, ''),
    ('Departamento con patio', 'DEPARTAMENTO', 1400, (1, 0, 0), 250, True, 12, ''),
    ('Habitación en casa familiar', 'HABITACION', 500, (1, 1, 1), 0, False, 15, 'Sin visitas después de las 22:00'),
    ('Departamento amoblado', 'DEPARTAMENTO', 1800, (1, 1, 1), 0, True, 18, ''),
    ('Habitación con entrada independiente', 'HABITACION', 700, (1, 0, 1), 150, True, 20, ''),
    ('Casa para compartir entre estudiantes', 'CASA', 2200, (0, 0, 0), 400, True, 25, 'Grupo de hasta 4 personas'),
    ('Habitación económica', 'HABITACION', 450, (1, 1, 0), 100, False, 28, 'Solo señoritas'),
    ('Departamento con garaje', 'DEPARTAMENTO', 1600, (1, 1, 0), 200, False, 32, ''),
    ('Casa de 2 dormitorios', 'CASA', 2500, (1, 1, 1), 0, True, 40, ''),
    ('Habitación compartida entre dos', 'HABITACION', 350, (1, 1, 1), 0, False, 45, 'Se comparte con otra estudiante'),
]


def coordenada_para(minutos, indice, total):
    """Devuelve la lat/lng que el modelo va a leer como `minutos` caminando.

    Hay que invertir el calculo de `utils.minutos_caminando_a_uagrm`, porque
    los minutos son un campo derivado: el modelo los recalcula en cada save y
    no acepta que se los escriba a mano.

    Como ese calculo redondea HACIA ARRIBA, se apunta a medio minuto menos que
    el objetivo. Apuntar justo al entero daria un minuto de mas casi siempre.
    """
    km = (minutos - 0.5) * settings.VELOCIDAD_CAMINANDO_KMH / (FACTOR_RODEO * 60)

    # Se reparten alrededor del campus en vez de alinearlos: un mapa con todo
    # sobre el mismo meridiano no se parece a una ciudad.
    angulo = 2 * math.pi * indice / total
    grados = math.degrees(km / RADIO_TIERRA_KM)

    lat = settings.UAGRM_LAT + grados * math.cos(angulo)
    lng = settings.UAGRM_LNG + (
        grados * math.sin(angulo) / math.cos(math.radians(settings.UAGRM_LAT))
    )
    return lat, lng


class Command(BaseCommand):
    help = 'Crea anuncios de prueba variados para poder buscar en la app.'

    def add_arguments(self, parser):
        parser.add_argument(
            '--limpiar',
            action='store_true',
            help='Borra los anuncios y usuarios sembrados antes de crear los nuevos.',
        )

    @transaction.atomic
    def handle(self, *args, **opciones):
        if opciones['limpiar']:
            borrados, _ = User.objects.filter(username__endswith=SUFIJO).delete()
            self.stdout.write(self.style.WARNING(
                f'Limpieza: {borrados} registros borrados (usuarios de prueba y sus anuncios).'
            ))

        propietarios = [self._propietario(*datos) for datos in PROPIETARIOS]

        creados = []
        for i, fila in enumerate(ANUNCIOS):
            titulo, tipo, alquiler, servicios, costo, mascotas, minutos, restricciones = fila
            agua, luz, internet = servicios
            lat, lng = coordenada_para(minutos, i, len(ANUNCIOS))

            anuncio = Anuncio(
                propietario=propietarios[i % len(propietarios)],
                titulo=titulo,
                tipo_espacio=tipo,
                precio_alquiler=alquiler,
                incluye_agua=bool(agua),
                incluye_luz=bool(luz),
                incluye_internet=bool(internet),
                costo_servicios_estimado=costo,
                acepta_mascotas=mascotas,
                restricciones=restricciones,
                lat=lat,
                lng=lng,
                direccion_referencia='Zona norte, a pocas cuadras del campus',
            )
            # El campo es derivado, pero full_clean() lo necesita poblado para
            # no protestar por un obligatorio vacio.
            anuncio.minutos_caminando = minutos_caminando_a_uagrm(lat, lng)

            # Valida la regla del modelo: si algo no esta incluido, hay que
            # decir cuanto se paga aparte.
            anuncio.full_clean()
            anuncio.save()
            creados.append((anuncio, minutos))

        self._informe(creados)

    def _propietario(self, username, nombre, whatsapp):
        usuario, nuevo = User.objects.get_or_create(
            username=username,
            defaults={'first_name': nombre, 'email': f'{username}@ejemplo.test'},
        )
        if nuevo:
            usuario.set_password('demo1234')
            usuario.save()

        Perfil.objects.update_or_create(
            usuario=usuario,
            defaults={'rol': Perfil.Rol.PROPIETARIO, 'whatsapp': whatsapp},
        )
        return usuario

    def _informe(self, creados):
        self.stdout.write('')
        self.stdout.write(f'{"min":>4}  {"precio final":>12}  {"tipo":<12}  {"mascotas":<8}  título')
        self.stdout.write('-' * 78)

        desvios = []
        for anuncio, objetivo in creados:
            if anuncio.minutos_caminando != objetivo:
                desvios.append((anuncio.titulo, objetivo, anuncio.minutos_caminando))
            self.stdout.write(
                f'{anuncio.minutos_caminando:>4}  '
                f'{anuncio.precio_final:>9} Bs  '
                f'{anuncio.get_tipo_espacio_display():<12}  '
                f'{"sí" if anuncio.acepta_mascotas else "no":<8}  '
                f'{anuncio.titulo}'
            )

        self.stdout.write('')
        self.stdout.write(self.style.SUCCESS(f'{len(creados)} anuncios disponibles para buscar.'))

        # Si la inversion del calculo fallara, los minutos no coincidirian con
        # lo pedido y los filtros de distancia probarian otra cosa.
        if desvios:
            self.stdout.write(self.style.ERROR('Minutos que no dieron el objetivo:'))
            for titulo, esperado, real in desvios:
                self.stdout.write(self.style.ERROR(f'  {titulo}: se pidio {esperado}, quedo {real}'))
        else:
            self.stdout.write('Todos los minutos coinciden con el objetivo.')

        self.stdout.write(
            'Usuarios: marta_demo / carlos_demo / rosa_demo — contraseña demo1234'
        )
