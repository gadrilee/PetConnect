"""Puebla la base con gente, anuncios y solicitudes para mostrar la app.

Lo que hay acá no son datos de relleno: cada anuncio cae en una calle real de
Santa Cruz —geocodificadas con OpenStreetMap, en `datos_demo/ubicaciones.json`—
a una distancia real del campus, los precios están en el rango que se paga hoy
alrededor de la UAGRM, y las nueve personas del principio salen de
`research/evidencias.md`. Las fotos son fotografías reales con licencia libre
de Pexels (ver `backend/datos_demo/`).

    python manage.py poblar_demo --limpiar
    python manage.py poblar_demo --limpiar --anuncios 40 --inquilinos 20

`--limpiar` borra TODO lo que no sea superusuario: cuentas, anuncios,
solicitudes y los archivos de `media/`. Hacé una copia de `db.sqlite3` antes
si te importa lo que hay.

Lo único inventado son las personas: nombres, correos y WhatsApp. Tiene que
ser así — poner la cara y el teléfono de alguien real en una cuenta que no es
suya no es "más real", es meter a un tercero en una demo. Los números siguen
el formato boliviano pero no son de nadie: antes de mostrar el flujo de
"Abrir WhatsApp" en vivo, cambiá el de la cuenta que vayas a usar por el tuyo.
"""

import json
import os
import random
import unicodedata
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

DATOS = settings.BASE_DIR / 'datos_demo'
FOTOS = DATOS / 'fotos'
CLAVE = 'demo1234'

# ─── Las nueve personas de la investigación ──────────────────────
# usuario, nombre, apellido, correo, rol, whatsapp, de dónde sale
PROTAGONISTAS = [
    ('marta.quiroga', 'Marta', 'Quiroga', 'PROPIETARIO', '71234567',
     'Alquila cuatro habitaciones en una casa compartida (evidencia 7).'),
    ('rosa.mendoza', 'Rosa', 'Mendoza', 'PROPIETARIO', '76543210',
     'No pone su número en los anuncios y así casi nadie la contacta (evidencia 9).'),
    ('julio.arispe', 'Julio', 'Arispe', 'PROPIETARIO', '70812345',
     'Publicaba lo mismo en tres grupos de Facebook (evidencia 11).'),
    ('elena.vaca', 'Elena', 'Vaca', 'PROPIETARIO', '67891234',
     'Se cansó de esperar visitas que no llegan (evidencia 10).'),
    ('andrea.rojas', 'Andrea', 'Rojas', 'INQUILINO', '',
     'Tercer semestre, de provincia, tiene un gato (persona v0.2).'),
    ('camila.terceros', 'Camila', 'Terceros', 'INQUILINO', '',
     'Primer semestre. Viajó media hora a un "cerca de la U" (evidencia 2).'),
    ('luis.banegas', 'Luis', 'Banegas', 'INQUILINO', '',
     'Quinto semestre. Quiere saber con quiénes va a compartir (evidencia 6).'),
    ('daniela.chavez', 'Daniela', 'Chávez', 'INQUILINO', '',
     'Escribió a cinco anuncios, le contestaron dos (evidencia 5).'),
    ('pablo.suarez', 'Pablo', 'Suárez', 'INQUILINO', '',
     'Le cobraron 300 Bs más al llegar (evidencia 1).'),
]

# ─── Vocabulario para el resto de la gente ───────────────────────
# Nombres y apellidos de uso corriente en Santa Cruz. Las personas que salen
# de combinarlos no existen: son cuentas de demostración.
NOMBRES_F = [
    'María', 'Ana', 'Lucía', 'Valeria', 'Gabriela', 'Fernanda', 'Carla', 'Paola',
    'Noelia', 'Mariana', 'Jhoselin', 'Rocío', 'Alejandra', 'Patricia', 'Verónica',
    'Silvia', 'Roxana', 'Karina', 'Lorena', 'Mónica', 'Claudia', 'Tatiana',
    'Estefanía', 'Yessica', 'Nataly', 'Brenda', 'Sofía', 'Micaela', 'Jimena',
    'Adriana', 'Melany', 'Ximena', 'Rebeca', 'Ruth', 'Mercedes', 'Teresa',
]
NOMBRES_M = [
    'Carlos', 'José', 'Juan', 'Marco', 'Diego', 'Álvaro', 'Rodrigo', 'Sergio',
    'Fernando', 'Mauricio', 'Javier', 'Gonzalo', 'Ramiro', 'Óscar', 'Iván',
    'Richard', 'Wilson', 'Jhonny', 'Edwin', 'Rubén', 'Hernán', 'Cristian',
    'Miguel', 'Ariel', 'Freddy', 'Limber', 'Danilo', 'Erick', 'Josué', 'Néstor',
]
APELLIDOS = [
    'Justiniano', 'Áñez', 'Roca', 'Montero', 'Cuéllar', 'Melgar', 'Saucedo',
    'Peredo', 'Salvatierra', 'Ribera', 'Chávez', 'Durán', 'Ortiz', 'Pinto',
    'Guzmán', 'Aguilera', 'Barbery', 'Céspedes', 'Egüez', 'Ferrufino', 'Gutiérrez',
    'Hurtado', 'Ibáñez', 'Landívar', 'Menacho', 'Nogales', 'Ovando', 'Parada',
    'Quezada', 'Rivero', 'Sandoval', 'Tapia', 'Urquidi', 'Velasco', 'Zambrana',
    'Arteaga', 'Bejarano', 'Camacho', 'Dorado', 'Escobar', 'Flores', 'Gil',
    'Herrera', 'Ledezma', 'Moreno', 'Núñez', 'Oliva', 'Pacheco', 'Rocha', 'Serrate',
]

# ─── Vocabulario para los anuncios ───────────────────────────────
# tipo -> (rango de alquiler, características del título)
CATALOGO = {
    'HABITACION': ((380, 900), [
        'Habitación con baño privado', 'Habitación amoblada',
        'Habitación con entrada independiente', 'Habitación en casa familiar',
        'Habitación con placard y escritorio', 'Habitación con ventana a la calle',
        'Habitación en casa compartida', 'Habitación económica',
        'Habitación con aire acondicionado', 'Habitación amplia',
        'Habitación con baño compartido', 'Habitación para estudiante',
        'Habitación con cocina compartida', 'Habitación luminosa',
        'Habitación recién pintada', 'Habitación con ropero empotrado',
    ]),
    'DEPARTAMENTO': ((1000, 2600), [
        'Departamento de un dormitorio', 'Departamento amoblado',
        'Monoambiente', 'Departamento de dos dormitorios',
        'Departamento con patio', 'Departamento en planta alta',
        'Monoambiente amoblado', 'Departamento con garaje',
        'Departamento recién estrenado', 'Departamento con balcón',
    ]),
    'CASA': ((2200, 4800), [
        'Casa para compartir entre estudiantes', 'Casa de dos dormitorios',
        'Casa con patio grande', 'Casa de tres dormitorios',
        'Casa independiente', 'Casa con garaje',
    ]),
}
# Cuántos anuncios de cada tipo, en proporción: la mayoría son habitaciones,
# que es lo que busca un estudiante.
MEZCLA = ['HABITACION'] * 62 + ['DEPARTAMENTO'] * 28 + ['CASA'] * 10

COLETILLAS = [
    '', '', '', '', ' a una cuadra del campus', ' cerca de la UAGRM',
    ' sobre avenida', ' en zona tranquila', ' para una persona',
    ' con todo incluido', ' sin expensas',
]

RESTRICCIONES = [
    '', '', '', '', '', '', '',
    'Solo señoritas', 'Solo varones', 'Sin visitas después de las 22:00',
    'No se puede fumar adentro', 'Se comparte cocina y baño',
    'Se pide el primer mes por adelantado', 'Sin fiestas',
    'Se comparte con otras dos estudiantes', 'Entrada hasta las 23:00',
]


def sin_tildes(texto):
    return ''.join(c for c in unicodedata.normalize('NFD', texto)
                   if unicodedata.category(c) != 'Mn')


class Command(BaseCommand):
    help = 'Puebla la base con personas, anuncios y solicitudes para mostrar la app.'

    def add_arguments(self, parser):
        parser.add_argument('--limpiar', action='store_true',
                            help='Borra antes todo lo que no sea superusuario, con sus archivos.')
        parser.add_argument('--propietarios', type=int, default=35)
        parser.add_argument('--inquilinos', type=int, default=55)
        parser.add_argument('--anuncios', type=int, default=130)
        parser.add_argument('--solicitudes', type=int, default=150)

    @transaction.atomic
    def handle(self, *args, **opciones):
        if not FOTOS.is_dir():
            self.stderr.write(self.style.ERROR(f'No encuentro las fotos en {FOTOS}'))
            return

        # Mismo resultado en cada corrida: las fechas y las fotos no bailan.
        self.azar = random.Random(2026)
        self.ahora = timezone.now()
        self.fotos = self._catalogo_de_fotos()
        self.ubicaciones = json.loads((DATOS / 'ubicaciones.json').read_text(encoding='utf-8'))

        if opciones['limpiar']:
            self._limpiar()

        propietarios, inquilinos = self._crear_personas(
            opciones['propietarios'], opciones['inquilinos'])
        anuncios = self._crear_anuncios(propietarios, opciones['anuncios'])
        self._crear_solicitudes(inquilinos, anuncios, opciones['solicitudes'])
        self._alquilar_algunos(anuncios)
        self._informe(propietarios, inquilinos, anuncios)

    # ─── Fotos ───────────────────────────────────────────────────

    def _catalogo_de_fotos(self):
        """Las fotos agrupadas por lo que muestran: hab, cocina, baño…"""
        grupos = {}
        for nombre in sorted(os.listdir(FOTOS)):
            if not nombre.endswith('.jpg'):
                continue
            grupos.setdefault(nombre.rsplit('-', 1)[0], []).append(nombre)
        return grupos

    # ─── Limpieza ────────────────────────────────────────────────

    def _limpiar(self):
        borrados, _ = User.objects.filter(is_superuser=False).delete()
        sobran = Anuncio.objects.all().delete()[0] + SolicitudVisita.objects.all().delete()[0]

        archivos = 0
        for carpeta in ('anuncios', 'perfiles'):
            for base, _, nombres in os.walk(settings.MEDIA_ROOT / carpeta):
                for nombre in nombres:
                    os.remove(os.path.join(base, nombre))
                    archivos += 1

        self.stdout.write(self.style.WARNING(
            f'Limpieza: {borrados + sobran} registros y {archivos} archivos borrados. '
            'Los superusuarios quedaron.'
        ))

    # ─── Personas ────────────────────────────────────────────────

    def _crear_personas(self, cuantos_propietarios, cuantos_inquilinos):
        propietarios, inquilinos = [], []
        usados = set()
        caras = list(self.fotos.get('cara', []))
        self.azar.shuffle(caras)

        def alta(nombre, apellido, rol, whatsapp, usuario=None, historia=''):
            base = usuario or f'{sin_tildes(nombre).lower()}.{sin_tildes(apellido).lower()}'
            usuario = base
            n = 2
            while usuario in usados:
                usuario = f'{base}{n}'
                n += 1
            usados.add(usuario)
            dominio = 'gmail.com' if rol == 'PROPIETARIO' else 'uagrm.edu.bo'
            u = User.objects.create_user(
                username=usuario, email=f'{usuario}@{dominio}', password=CLAVE,
                first_name=nombre, last_name=apellido)
            perfil = Perfil.objects.create(usuario=u, rol=rol, whatsapp=whatsapp)
            # No todo el mundo sube foto: en la app de verdad tampoco.
            if caras:
                with open(FOTOS / caras.pop(), 'rb') as f:
                    # Por el mismo camino que una foto subida desde el
                    # teléfono: cuadrada, 512 px, sin EXIF.
                    perfil.foto.save('foto.jpg', preparar_foto(f), save=True)
            (propietarios if rol == 'PROPIETARIO' else inquilinos).append(
                {'usuario': u, 'historia': historia})
            return u

        # Primero las nueve de la investigación, con su historia y su foto.
        for usuario, nombre, apellido, rol, whatsapp, historia in PROTAGONISTAS:
            alta(nombre, apellido, rol, whatsapp, usuario=usuario, historia=historia)

        # Y después el resto, para que la app se vea con gente adentro.
        while len(propietarios) < cuantos_propietarios:
            hombre = self.azar.random() < 0.45
            alta(self.azar.choice(NOMBRES_M if hombre else NOMBRES_F),
                 self.azar.choice(APELLIDOS), 'PROPIETARIO',
                 f'{self.azar.choice("67")}{self.azar.randrange(1000000, 9999999)}')
        while len(inquilinos) < cuantos_inquilinos:
            hombre = self.azar.random() < 0.45
            alta(self.azar.choice(NOMBRES_M if hombre else NOMBRES_F),
                 self.azar.choice(APELLIDOS), 'INQUILINO', '')

        return propietarios, inquilinos

    # ─── Anuncios ────────────────────────────────────────────────

    def _crear_anuncios(self, propietarios, cuantos):
        # Casi todos tienen uno o dos; unos pocos alquilan media casa. Repartir
        # parejo daría 35 propietarios con lo mismo, que no es una ciudad.
        duenios = []
        for i, p in enumerate(propietarios):
            # Los cuatro de la investigación son los que más publican: son los
            # que se usan para mostrar la bandeja llena.
            cuantos_suyos = 5 if i < 4 else self.azar.choices([1, 2, 3, 4, 6], [40, 26, 16, 12, 6])[0]
            duenios += [p['usuario']] * cuantos_suyos
        self.azar.shuffle(duenios)

        creados = []
        for i in range(cuantos):
            tipo = MEZCLA[i % len(MEZCLA)]
            (minimo, maximo), titulos = CATALOGO[tipo]
            lugar = self.ubicaciones[i % len(self.ubicaciones)]

            # Precios redondeados a 10 Bs, como se publican.
            alquiler = self.azar.randrange(minimo, maximo, 10)
            todo_incluido = self.azar.random() < 0.35
            agua = todo_incluido or self.azar.random() < 0.85
            luz = todo_incluido or self.azar.random() < 0.75
            internet = todo_incluido or self.azar.random() < 0.35
            # Si algo no está incluido hay que decir cuánto se paga aparte:
            # es la regla del modelo y la evidencia 1.
            falta = 3 - sum([agua, luz, internet])
            servicios = 0 if falta == 0 else self.azar.randrange(60, 90 + 70 * falta, 10)

            titulo = titulos[self.azar.randrange(len(titulos))] + self.azar.choice(COLETILLAS)
            if titulo.endswith(' sobre avenida') and lugar['calle']:
                titulo = titulo.replace(' sobre avenida', ' sobre ' + lugar['calle'])
            elif titulo.endswith(' en zona tranquila') and lugar['barrio']:
                titulo = titulo.replace(' en zona tranquila', f' en {lugar["barrio"]}')

            direccion = ', '.join(x for x in (lugar['calle'], lugar['barrio']) if x) \
                or 'Santa Cruz de la Sierra'

            anuncio = Anuncio(
                propietario=duenios[i % len(duenios)],
                titulo=titulo[:150],
                tipo_espacio=tipo,
                precio_alquiler=alquiler,
                incluye_agua=agua, incluye_luz=luz, incluye_internet=internet,
                costo_servicios_estimado=servicios,
                acepta_mascotas=self.azar.random() < 0.4,
                restricciones=self.azar.choice(RESTRICCIONES),
                # Unos metros de diferencia sobre el punto geocodificado: dos
                # anuncios de la misma calle no están en la misma puerta.
                lat=lugar['lat'] + self.azar.uniform(-0.00035, 0.00035),
                lng=lugar['lng'] + self.azar.uniform(-0.00035, 0.00035),
                direccion_referencia=direccion[:200],
            )
            # La misma regla del modelo que valida un anuncio hecho a mano.
            anuncio.full_clean()
            anuncio.save()

            dias = self.azar.randrange(1, 95)
            publicado = self.ahora - timedelta(days=dias, hours=self.azar.randrange(24))
            Anuncio.objects.filter(pk=anuncio.pk).update(publicado_en=publicado)

            self._fotos_de(anuncio, tipo, publicado)

            anuncio.refresh_from_db()
            creados.append(anuncio)
        return creados

    def _alquilar_algunos(self, anuncios, proporcion=0.1):
        """Uno de cada diez ya se alquiló.

        Se hace **después** de las solicitudes y con el mismo método que usa
        la app, así las que estaban esperando quedan cerradas por el camino de
        siempre en vez de a mano: es la evidencia 5 pasando adentro del
        producto.
        """
        cuantos = round(len(anuncios) * proporcion)
        cerradas = 0
        for anuncio in self.azar.sample(anuncios, cuantos):
            cerradas += anuncio.marcar_alquilado()
            anuncio.refresh_from_db()
        return cuantos, cerradas

    def _fotos_de(self, anuncio, tipo, publicado):
        """Dos o tres fotos: el ambiente principal y lo que se comparte."""
        principal = 'hab' if tipo == 'HABITACION' else self.azar.choice(['sala', 'hab'])
        grupos = [principal] + self.azar.sample(['cocina', 'bano', 'sala', 'fachada'],
                                                self.azar.choice([1, 1, 2]))
        for orden, grupo in enumerate(grupos):
            disponibles = self.fotos.get(grupo) or self.fotos['hab']
            nombre = disponibles[self.azar.randrange(len(disponibles))]
            with open(FOTOS / nombre, 'rb') as f:
                contenido = ContentFile(f.read(), name=nombre)
            # La foto se sacó antes de publicar, no hoy: es el dato que la app
            # muestra para que nadie viaje a ver una foto de hace años.
            FotoAnuncio.objects.create(
                anuncio=anuncio, imagen=contenido, orden=orden,
                fecha_captura=publicado - timedelta(hours=self.azar.randrange(1, 72)),
            )

    # ─── Solicitudes ─────────────────────────────────────────────

    def _crear_solicitudes(self, inquilinos, anuncios, cuantas):
        # Se pide visita a lo que está cerca y es barato: los anuncios que
        # salen primero en la búsqueda son los que más solicitudes juntan.
        candidatos = sorted(anuncios, key=lambda a: a.minutos_caminando)
        pesos = [max(1, 60 - i) for i in range(len(candidatos))]
        hechas = set()
        creadas = 0
        intentos = 0

        while creadas < cuantas and intentos < cuantas * 20:
            intentos += 1
            anuncio = self.azar.choices(candidatos, pesos)[0]
            inquilino = self.azar.choice(inquilinos)['usuario']
            if (anuncio.id, inquilino.id) in hechas:
                continue
            hechas.add((anuncio.id, inquilino.id))

            creada = self.ahora - timedelta(days=self.azar.randrange(1, 45),
                                            hours=self.azar.randrange(24))
            if creada < anuncio.publicado_en:
                creada = anuncio.publicado_en + timedelta(hours=self.azar.randrange(1, 48))
            if creada > self.ahora:
                continue

            solicitud = SolicitudVisita.objects.create(
                anuncio=anuncio, inquilino=inquilino,
                condiciones_aceptadas=True, estado='PENDIENTE')

            # Las cerradas no se ponen a mano: salen de alquilar el cuarto
            # con solicitudes esperando, más abajo.
            estado = self.azar.choices(
                ['PENDIENTE', 'APROBADA', 'RECHAZADA'], [45, 33, 22])[0]

            campos = {'creada_en': creada}
            if estado != 'PENDIENTE':
                # Contestar tarda entre un rato y dos días: nadie vive mirando
                # la bandeja.
                campos['estado'] = estado
                campos['respondida_en'] = creada + timedelta(hours=self.azar.randrange(2, 48))
            SolicitudVisita.objects.filter(pk=solicitud.pk).update(**campos)
            creadas += 1

    # ─── Informe ─────────────────────────────────────────────────

    def _informe(self, propietarios, inquilinos, anuncios):
        from django.db.models import Count

        disponibles = Anuncio.objects.filter(estado='DISPONIBLE').count()
        minutos = sorted(a.minutos_caminando for a in anuncios)
        precios = sorted(a.precio_final for a in anuncios)
        con_anuncios = Anuncio.objects.values('propietario').distinct().count()

        self.stdout.write('')
        self.stdout.write(f'{len(propietarios) + len(inquilinos)} cuentas: '
                          f'{len(propietarios)} propietarias/os, {len(inquilinos)} inquilinas/os. '
                          f'{Perfil.objects.exclude(foto="").count()} con foto de perfil.')
        self.stdout.write(f'{len(anuncios)} anuncios: {disponibles} disponibles, '
                          f'{Anuncio.objects.filter(estado="ALQUILADO").count()} ya alquilados, de '
                          f'{con_anuncios} propietarias/os distintos.')
        for tipo, _ in Anuncio.TipoEspacio.choices:
            n = Anuncio.objects.filter(tipo_espacio=tipo).count()
            self.stdout.write(f'   {tipo.lower():13} {n:4d}')
        self.stdout.write(f'   {"con mascotas":13} '
                          f'{Anuncio.objects.filter(acepta_mascotas=True).count():4d}')
        self.stdout.write(f'   {"con reglas":13} '
                          f'{Anuncio.objects.exclude(restricciones="").count():4d}')
        self.stdout.write(f'   minutos caminando: {minutos[0]} a {minutos[-1]} '
                          f'(mitad por debajo de {minutos[len(minutos) // 2]})')
        self.stdout.write(f'   precio final: {precios[0]:.0f} a {precios[-1]:.0f} Bs '
                          f'(mitad por debajo de {precios[len(precios) // 2]:.0f})')
        self.stdout.write(f'{FotoAnuncio.objects.count()} fotos de inmueble, '
                          f'{Anuncio.objects.annotate(n=Count("fotos")).filter(n__gt=0).count()} '
                          f'anuncios con al menos una.')

        self.stdout.write(f'{SolicitudVisita.objects.count()} solicitudes:')
        for estado, etiqueta in SolicitudVisita.Estado.choices:
            self.stdout.write(f'   {etiqueta.lower():13} '
                              f'{SolicitudVisita.objects.filter(estado=estado).count():4d}')

        self.stdout.write('')
        self.stdout.write('Para entrar, cualquiera de estas nueve:')
        for usuario, nombre, apellido, rol, whatsapp, historia in PROTAGONISTAS:
            marca = 'propietaria/o' if rol == 'PROPIETARIO' else 'inquilina/o'
            self.stdout.write(f'   {usuario:16} {nombre + " " + apellido:18} {marca}')
        self.stdout.write('')
        self.stdout.write(self.style.SUCCESS(f'Todas las contraseñas son "{CLAVE}".'))
