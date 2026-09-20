"""Puebla la base con gente, anuncios y solicitudes para mostrar la app.

Lo que hay acá no son datos de relleno: cada anuncio cae en una calle real de
Santa Cruz —geocodificada con OpenStreetMap— a una distancia real del campus,
los precios están en el rango que se paga hoy alrededor de la UAGRM, y las
historias de cada persona salen de `research/evidencias.md`. Las fotos son
fotografías reales con licencia libre de Pexels (ver `backend/datos_demo/`).

    python manage.py poblar_demo --limpiar

`--limpiar` borra TODO lo que no sea superusuario: cuentas, anuncios,
solicitudes y los archivos de `media/`. Hacé una copia de `db.sqlite3` antes
si te importa lo que hay.

Lo único inventado son las personas: nombres, correos y WhatsApp. Tiene que
ser así — poner la cara y el teléfono de alguien real en una cuenta que no es
suya no es "más real", es meter a un tercero en una demo. Los números siguen
el formato boliviano pero no son de nadie: antes de mostrar el flujo de
"Abrir WhatsApp" en vivo, cambiá el de la cuenta que vayas a usar por el tuyo.
"""

import os
import random
from datetime import timedelta

from django.conf import settings
from django.contrib.auth import get_user_model
from django.core.files.base import ContentFile
from django.core.management.base import BaseCommand
from django.db import transaction
from django.utils import timezone

from anuncios.models import Anuncio, FotoAnuncio
from solicitudes.models import SolicitudVisita
from usuarios.models import Perfil
from usuarios.serializers import preparar_foto

User = get_user_model()

FOTOS = settings.BASE_DIR / 'datos_demo' / 'fotos'
CLAVE = 'demo1234'

# ─── Las personas ────────────────────────────────────────────────
# usuario, nombre, apellido, correo, rol, whatsapp, foto, de dónde sale
PERSONAS = [
    ('marta.quiroga', 'Marta', 'Quiroga', 'marta.quiroga@gmail.com', 'PROPIETARIO',
     '71234567', 'cara-02',
     'Alquila cuatro habitaciones en una casa compartida (evidencia 7).'),
    ('rosa.mendoza', 'Rosa', 'Mendoza', 'rosa.mendoza@gmail.com', 'PROPIETARIO',
     '76543210', 'cara-01',
     'No pone su número en los anuncios y así casi nadie la contacta (evidencia 9).'),
    ('julio.arispe', 'Julio', 'Arispe', 'julio.arispe@gmail.com', 'PROPIETARIO',
     '70812345', 'cara-06',
     'Publicaba lo mismo en tres grupos de Facebook (evidencia 11).'),
    ('elena.vaca', 'Elena', 'Vaca', 'elena.vaca@gmail.com', 'PROPIETARIO',
     '67891234', 'cara-03',
     'Alquila un departamento; se cansó de esperar visitas que no llegan (evidencia 10).'),

    ('andrea.rojas', 'Andrea', 'Rojas', 'andrea.rojas@uagrm.edu.bo', 'INQUILINO',
     '', 'cara-07',
     'Tercer semestre, de provincia, tiene un gato (persona v0.2).'),
    ('camila.terceros', 'Camila', 'Terceros', 'camila.terceros@uagrm.edu.bo', 'INQUILINO',
     '', 'cara-09',
     'Primer semestre. Viajó media hora a un "cerca de la U" (evidencia 2).'),
    ('luis.banegas', 'Luis', 'Banegas', 'luis.banegas@uagrm.edu.bo', 'INQUILINO',
     '', 'cara-12',
     'Quinto semestre. Quiere saber con quiénes va a compartir (evidencia 6).'),
    ('daniela.chavez', 'Daniela', 'Chávez', 'daniela.chavez@uagrm.edu.bo', 'INQUILINO',
     '', 'cara-10',
     'Escribió a cinco anuncios, le contestaron dos (evidencia 5).'),
    ('pablo.suarez', 'Pablo', 'Suárez', 'pablo.suarez@uagrm.edu.bo', 'INQUILINO',
     '', 'cara-05',
     'Vive en alquiler hace dos años. Le cobraron 300 Bs más al llegar (evidencia 1).'),
]

# ─── Los anuncios ────────────────────────────────────────────────
# Las coordenadas salieron de geocodificación inversa con Nominatim
# (OpenStreetMap): son puntos que caen en esa calle y ese barrio de verdad.
# Los minutos los calcula el modelo solo; el comando avisa si no dan.
#
# propietario, título, tipo, alquiler, (agua, luz, internet), servicios,
# mascotas, restricciones, lat, lng, dirección, minutos esperados, fotos,
# días desde que se publicó, estado
ANUNCIOS = [
    ('marta.quiroga', 'Habitación con baño privado a una cuadra del campus', 'HABITACION',
     750, (1, 1, 0), 80, False, 'Solo señoritas',
     -17.774346, -63.197482, 'Av. Felipe Leonor Ribera Arteaga, barrio Faremafu',
     3, ['hab-01', 'bano-02'], 9, 'DISPONIBLE'),

    ('marta.quiroga', 'Habitación amoblada con entrada independiente', 'HABITACION',
     700, (1, 1, 1), 0, True, '',
     -17.777596, -63.198725, 'Calle 8 de Febrero, barrio Cervecería',
     4, ['hab-03', 'hab-11'], 26, 'ALQUILADO'),

    ('marta.quiroga', 'Habitación en casa compartida entre estudiantes', 'HABITACION',
     500, (1, 1, 0), 120, True, 'Se comparte cocina y baño con otras tres estudiantes',
     -17.777179, -63.202267, 'Calle 1, barrio Cervecería',
     8, ['hab-06', 'cocina-04', 'bano-04'], 14, 'DISPONIBLE'),

    ('marta.quiroga', 'Habitación con placard y escritorio', 'HABITACION',
     620, (1, 1, 1), 0, False, 'Sin visitas después de las 22:00',
     -17.776587, -63.195440, 'Av. Doctor Enrique Aponte, barrio Palermo',
     5, ['hab-04', 'hab-13'], 5, 'DISPONIBLE'),

    ('rosa.mendoza', 'Departamento de un dormitorio', 'DEPARTAMENTO',
     1500, (1, 1, 0), 150, False, '',
     -17.774115, -63.200884, 'Zona Piraí, a seis minutos del campus',
     6, ['depto-01', 'cocina-01', 'bano-01'], 18, 'DISPONIBLE'),

    ('rosa.mendoza', 'Departamento amoblado con patio', 'DEPARTAMENTO',
     1800, (1, 1, 1), 0, True, '',
     -17.769959, -63.201481, 'Av. Noel Kempff Mercado, barrio El Carmen',
     12, ['hab-10', 'cocina-03', 'patio-01'], 31, 'DISPONIBLE'),

    ('rosa.mendoza', 'Monoambiente cerca del segundo anillo', 'DEPARTAMENTO',
     1200, (1, 0, 0), 180, False, '',
     -17.780846, -63.196033, 'Calle Cupesi, barrio Palermo',
     10, ['hab-07', 'cocina-02'], 3, 'DISPONIBLE'),

    ('julio.arispe', 'Habitación sobre la avenida Busch', 'HABITACION',
     650, (1, 1, 0), 90, False, '',
     -17.773050, -63.195218, 'Av. Busch, barrio Faremafu',
     7, ['hab-12', 'hab-05'], 21, 'DISPONIBLE'),

    ('julio.arispe', 'Casa para compartir entre cuatro estudiantes', 'CASA',
     2600, (1, 0, 0), 400, True, 'Grupo de hasta cuatro personas',
     -17.774349, -63.189951, 'Calle Nicaragua, barrio Panamericano',
     14, ['fachada-01', 'hab-14', 'cocina-02'], 40, 'DISPONIBLE'),

    ('julio.arispe', 'Habitación económica', 'HABITACION',
     420, (1, 1, 0), 110, False, 'Solo señoritas',
     -17.783020, -63.203382, 'Calle Tacuaral, barrio Villa San Luis',
     16, ['hab-08', 'bano-03'], 12, 'DISPONIBLE'),

    ('elena.vaca', 'Habitación en casa familiar', 'HABITACION',
     550, (1, 1, 1), 0, False, '',
     -17.782926, -63.188957, 'Barrio Bancario, a veinte minutos caminando',
     20, ['hab-09', 'bano-04'], 7, 'DISPONIBLE'),

    ('elena.vaca', 'Departamento en Urbarí', 'DEPARTAMENTO',
     2200, (1, 1, 1), 0, True, '',
     -17.795589, -63.198000, 'Calle Guacaya, barrio Urbarí',
     35, ['hab-02', 'fachada-03'], 48, 'DISPONIBLE'),

    ('elena.vaca', 'Habitación con ventana a la calle', 'HABITACION',
     480, (1, 1, 0), 100, True, '',
     -17.780155, -63.171469, 'Calle Chiquitos, barrio Obrero',
     45, ['hab-13', 'fachada-02'], 35, 'DISPONIBLE'),
]

# ─── Las solicitudes ─────────────────────────────────────────────
# inquilino, índice del anuncio (según la lista de arriba), estado,
# días desde que la mandó
SOLICITUDES = [
    ('andrea.rojas', 2, 'PENDIENTE', 2),
    ('andrea.rojas', 5, 'APROBADA', 11),
    ('andrea.rojas', 1, 'CERRADA', 24),
    ('camila.terceros', 3, 'PENDIENTE', 1),
    ('camila.terceros', 9, 'RECHAZADA', 8),
    ('camila.terceros', 0, 'PENDIENTE', 4),
    ('luis.banegas', 8, 'PENDIENTE', 3),
    ('luis.banegas', 4, 'RECHAZADA', 13),
    ('luis.banegas', 1, 'CERRADA', 22),
    ('daniela.chavez', 0, 'PENDIENTE', 6),
    ('daniela.chavez', 2, 'APROBADA', 9),
    ('daniela.chavez', 7, 'PENDIENTE', 1),
    ('pablo.suarez', 6, 'APROBADA', 5),
    ('pablo.suarez', 11, 'PENDIENTE', 2),
    ('pablo.suarez', 4, 'PENDIENTE', 7),
]


class Command(BaseCommand):
    help = 'Puebla la base con personas, anuncios y solicitudes para mostrar la app.'

    def add_arguments(self, parser):
        parser.add_argument(
            '--limpiar', action='store_true',
            help='Borra antes todo lo que no sea superusuario, incluidos los archivos de media/.',
        )

    @transaction.atomic
    def handle(self, *args, **opciones):
        if not FOTOS.is_dir():
            self.stderr.write(self.style.ERROR(f'No encuentro las fotos en {FOTOS}'))
            return

        # Mismo resultado en cada corrida: las fechas y las fotos no bailan.
        random.seed(2026)
        self.ahora = timezone.now()

        if opciones['limpiar']:
            self._limpiar()

        personas = self._crear_personas()
        anuncios = self._crear_anuncios(personas)
        self._crear_solicitudes(personas, anuncios)
        self._informe(personas, anuncios)

    # ─── Limpieza ────────────────────────────────────────────────

    def _limpiar(self):
        borrados, _ = User.objects.filter(is_superuser=False).delete()
        sobran = Anuncio.objects.all().delete()[0] + SolicitudVisita.objects.all().delete()[0]

        archivos = 0
        for carpeta in ('anuncios', 'perfiles'):
            raiz = settings.MEDIA_ROOT / carpeta
            for base, _, nombres in os.walk(raiz):
                for nombre in nombres:
                    os.remove(os.path.join(base, nombre))
                    archivos += 1

        self.stdout.write(self.style.WARNING(
            f'Limpieza: {borrados + sobran} registros y {archivos} archivos borrados. '
            'Los superusuarios quedaron.'
        ))

    # ─── Personas ────────────────────────────────────────────────

    def _crear_personas(self):
        personas = {}
        for usuario, nombre, apellido, correo, rol, whatsapp, foto, _ in PERSONAS:
            u = User.objects.create_user(
                username=usuario, email=correo, password=CLAVE,
                first_name=nombre, last_name=apellido,
            )
            perfil = Perfil.objects.create(usuario=u, rol=rol, whatsapp=whatsapp)
            with open(FOTOS / f'{foto}.jpg', 'rb') as f:
                # Por el mismo camino que una foto subida desde el teléfono:
                # cuadrada, 512 px, sin EXIF.
                perfil.foto.save('foto.jpg', preparar_foto(f), save=True)
            personas[usuario] = u
        return personas

    # ─── Anuncios ────────────────────────────────────────────────

    def _crear_anuncios(self, personas):
        creados = []
        for fila in ANUNCIOS:
            (duenio, titulo, tipo, alquiler, servicios, costo, mascotas,
             restricciones, lat, lng, direccion, minutos, fotos, dias, estado) = fila
            agua, luz, internet = servicios

            anuncio = Anuncio(
                propietario=personas[duenio], titulo=titulo, tipo_espacio=tipo,
                precio_alquiler=alquiler,
                incluye_agua=bool(agua), incluye_luz=bool(luz), incluye_internet=bool(internet),
                costo_servicios_estimado=costo, acepta_mascotas=mascotas,
                restricciones=restricciones, lat=lat, lng=lng,
                direccion_referencia=direccion,
            )
            # Lo valida la misma regla del modelo que valida un anuncio real:
            # si algo no está incluido, hay que decir cuánto se paga aparte.
            anuncio.full_clean()
            anuncio.save()

            publicado = self.ahora - timedelta(days=dias, hours=random.randint(0, 23))
            Anuncio.objects.filter(pk=anuncio.pk).update(publicado_en=publicado)
            anuncio.refresh_from_db()

            for orden, nombre in enumerate(fotos):
                with open(FOTOS / f'{nombre}.jpg', 'rb') as f:
                    contenido = ContentFile(f.read(), name=f'{nombre}.jpg')
                # La foto se sacó cuando se publicó, no hoy: es el dato que la
                # app muestra para que nadie viaje a ver una foto de hace años.
                FotoAnuncio.objects.create(
                    anuncio=anuncio, imagen=contenido, orden=orden,
                    fecha_captura=publicado - timedelta(hours=random.randint(1, 30)),
                )

            if estado == 'ALQUILADO':
                anuncio.marcar_alquilado()

            creados.append((anuncio, minutos))
        return creados

    # ─── Solicitudes ─────────────────────────────────────────────

    def _crear_solicitudes(self, personas, anuncios):
        for inquilino, indice, estado, dias in SOLICITUDES:
            anuncio = anuncios[indice][0]
            creada = self.ahora - timedelta(days=dias, hours=random.randint(0, 23))

            solicitud = SolicitudVisita.objects.create(
                anuncio=anuncio, inquilino=personas[inquilino],
                condiciones_aceptadas=True, estado='PENDIENTE',
            )
            campos = {'creada_en': creada}
            if estado != 'PENDIENTE':
                # Contestar tarda entre un rato y dos días: el propietario no
                # está mirando la bandeja cuando llega.
                campos['estado'] = estado
                campos['respondida_en'] = creada + timedelta(hours=random.randint(2, 40))
            SolicitudVisita.objects.filter(pk=solicitud.pk).update(**campos)

    # ─── Informe ─────────────────────────────────────────────────

    def _informe(self, personas, anuncios):
        self.stdout.write('')
        self.stdout.write(f'{"min":>4}  {"precio final":>13}  {"tipo":<12}  {"mascotas":<8}  '
                          f'{"estado":<12}  título')
        self.stdout.write('-' * 100)
        desvios = []
        for anuncio, esperado in anuncios:
            if anuncio.minutos_caminando != esperado:
                desvios.append((anuncio.titulo, esperado, anuncio.minutos_caminando))
            self.stdout.write(
                f'{anuncio.minutos_caminando:>4}  {anuncio.precio_final:>10} Bs  '
                f'{anuncio.get_tipo_espacio_display():<12}  '
                f'{"sí" if anuncio.acepta_mascotas else "no":<8}  '
                f'{anuncio.get_estado_display():<12}  {anuncio.titulo}'
            )

        self.stdout.write('')
        for usuario, nombre, apellido, correo, rol, whatsapp, _, historia in PERSONAS:
            marca = 'propietaria/o' if rol == 'PROPIETARIO' else 'inquilina/o'
            cuenta = f'{nombre} {apellido}'
            extra = f' · WhatsApp {whatsapp}' if whatsapp else ''
            self.stdout.write(f'  {usuario:16} {cuenta:18} {marca:14}{extra}')
            self.stdout.write(f'  {"":16} {historia}')

        pendientes = SolicitudVisita.objects.filter(estado='PENDIENTE').count()
        self.stdout.write('')
        self.stdout.write(self.style.SUCCESS(
            f'{len(personas)} cuentas, {len(anuncios)} anuncios, '
            f'{FotoAnuncio.objects.count()} fotos de inmuebles y '
            f'{SolicitudVisita.objects.count()} solicitudes ({pendientes} pendientes).'
        ))
        self.stdout.write(f'Todas las contraseñas son "{CLAVE}".')

        if desvios:
            self.stdout.write(self.style.ERROR('Minutos que no dieron lo esperado:'))
            for titulo, esperado, real in desvios:
                self.stdout.write(self.style.ERROR(
                    f'  {titulo}: se esperaba {esperado}, quedó {real}'))
        else:
            self.stdout.write('Cada anuncio quedó a los minutos que dice su coordenada real.')
