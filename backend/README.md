# Backend — AlquilaMatch

API REST en **Django 6 + Django REST Framework**. Sirve a la app móvil de `../mobile`.

## Stack

| Pieza | Elección | Por qué |
|---|---|---|
| Framework | Django 6.x | El admin permite gestionar anuncios y solicitudes sin construir pantallas |
| API | Django REST Framework | Serializers y permission classes para la regla del contacto oculto |
| Auth | `djangorestframework-simplejwt` | JWT es lo que consume un cliente móvil |
| Base de datos | PostgreSQL (en Docker) | — |
| CORS | `django-cors-headers` | Para que Flutter pueda consumir la API |

> **Django 6.x requiere Python ≥ 3.12.** La versión 5.2 LTS no sirve acá: corta en Python 3.13 y el entorno del proyecto usa 3.14.

## Decisiones tomadas

**Sin GeoDjango ni PostGIS.** El cálculo de "minutos caminando" es contra un único punto fijo (la UAGRM), así que no hace falta una base de datos geoespacial. Dos columnas `lat` / `lng` en el modelo del anuncio y una fórmula de haversine en Python alcanzan: distancia en línea recta ÷ 5 km/h ≈ minutos caminando. Instalar GDAL/GEOS en Windows cuesta más de lo que aporta.

Si en el futuro se necesita la ruta real por vereda, se resuelve con una llamada a una API de routing, no cambiando la base de datos.

**Fotos.** En desarrollo van a `MEDIA_ROOT` local. Antes de desplegar hay que mover el almacenamiento a un servicio externo (Cloudinary tiene free tier), porque el disco local no sobrevive a un hosting gratuito. Decidirlo temprano evita migrar URLs después.

## Levantar el entorno

El proyecto ya está creado. Para trabajar:

```powershell
cd backend
.venv\Scripts\Activate.ps1
python manage.py runserver
```

Admin en `http://localhost:8000/admin/` (crear usuario con `python manage.py createsuperuser`).

### Base de datos

El `.env` viene con `USE_SQLITE=True` para que arranque sin depender de nada. Para pasar a PostgreSQL:

```powershell
docker run --name alquilamatch-db -e POSTGRES_PASSWORD=devpass -e POSTGRES_DB=alquilamatch -p 5432:5432 -d postgres:17
```

y poner `USE_SQLITE=False` en el `.env`.

### Si clonás el repo de cero

```powershell
cd backend
python -m venv .venv
.venv\Scripts\Activate.ps1
pip install -r requirements.txt
copy .env.example .env
python manage.py migrate
```

## Estructura

```
backend/
├── config/              # settings, urls, wsgi, asgi
├── usuarios/            # perfiles: inquilino / propietario
├── anuncios/            # publicación, condiciones de descarte, estado
├── solicitudes/         # solicitud de visita, aprobación, liberación de contacto
├── manage.py
├── requirements.txt
├── .env.example         # plantilla versionada
└── .env                 # NO se versiona
```

Las tres apps corresponden a los módulos del `appmap/appmap-v0.1.md`. Los `models.py` están vacíos: el modelo de datos es el próximo paso de diseño.

## Ya configurado

- **DRF + JWT** — `POST /api/auth/token/` y `/api/auth/token/refresh/` ya responden.
- **CORS** — habilitado para `localhost:8000` y `10.0.2.2:8000` (así ve el emulador de Android al localhost de la máquina).
- **Locale** — `es-bo`, zona horaria `America/La_Paz`.
- **Media** — `MEDIA_ROOT` en `backend/media/`, servido sólo con `DEBUG=True`.
- **Punto de referencia UAGRM** — `UAGRM_LAT` / `UAGRM_LNG` en settings, para el cálculo de minutos caminando. **Las coordenadas por defecto son aproximadas y hay que verificarlas en el mapa** antes de confiar en el resultado.

## Modelo de datos

Las cuatro condiciones de descarte del Brief v0.2.0 son **campos obligatorios** de `Anuncio`. Esa obligatoriedad es el producto: si se pudieran dejar vacías, la app sería otro tablón de anuncios.

| Modelo | App | Rol |
|---|---|---|
| `Perfil` | usuarios | Rol (inquilino / propietario) y el **WhatsApp que la app protege** |
| `Anuncio` | anuncios | Las 4 condiciones de descarte + estado *Disponible / Ya alquilado* |
| `FotoAnuncio` | anuncios | Imagen con **`fecha_captura`** — cuándo se tomó, no cuándo se subió |
| `SolicitudVisita` | solicitudes | La regla central: el contacto se libera sólo al aprobar |

### Reglas codificadas (con su evidencia)

| Regla | Dónde | Evidencia |
|---|---|---|
| `precio_final` = alquiler + servicios no incluidos | `Anuncio.precio_final` | Ev. 1 — "eran 300 bolivianos más" |
| No se publica sin estimar los servicios que faltan | `Anuncio.clean()` | Ev. 1 |
| `minutos_caminando` lo calcula la app, nunca el propietario | `Anuncio.save()` | Ev. 2 — "cerca era 25 minutos" |
| La foto lleva la fecha en que se tomó | `FotoAnuncio.fecha_captura` | Ev. 4 — "las fotos eran de hace años" |
| El contacto es `None` salvo que la solicitud esté aprobada | `SolicitudVisita.contacto_liberado` | Ev. 9 |
| No se solicita sin aceptar las condiciones | `SolicitudVisita.clean()` | Ev. 7 |
| No se solicita sobre un anuncio ya alquilado | `SolicitudVisita.clean()` | Ev. 8 |
| Una sola solicitud por anuncio e inquilino | `UniqueConstraint` | — |

> **`contacto_liberado` es el único camino permitido hacia el teléfono.** Cualquier serializer o vista que lea el WhatsApp directo del `Perfil` rompe el producto.

### Minutos caminando, sin PostGIS

`anuncios/utils.py` calcula haversine contra un único punto fijo y aplica un **factor de rodeo de 1.3**, porque las calles no son líneas rectas. Sin ese factor la estimación quedaría *por debajo* del tiempo real y la app recrearía justo el problema que viene a resolver. El resultado se redondea hacia arriba: conviene prometer de más, porque el costo de equivocarse lo paga el inquilino con un viaje perdido.

**Dos valores pendientes de validar:** las coordenadas del campus y el factor 1.3 (es una referencia de planificación urbana, no una medición hecha en Santa Cruz).

### Decisión: qué NO se modeló

El campo *"con quién se comparte"* para habitaciones (Ev. 6) **no está**. El Brief v0.2.0 §8 lo tiene como pregunta abierta, no como requisito, y se decide después de las entrevistas reales.

## API

Todos los endpoints exigen JWT salvo el registro. Se obtiene con `POST /api/auth/token/`.

| Metodo | Ruta | Quien | Que hace |
|---|---|---|---|
| POST | `/api/usuarios/registro/` | publico | Crear cuenta eligiendo rol |
| GET | `/api/usuarios/yo/` | autenticado | Mi perfil |
| POST | `/api/auth/token/` | publico | Login (access + refresh) |
| POST | `/api/anuncios/` | propietario | Publicar |
| GET | `/api/anuncios/` | autenticado | Buscar — **solo DISPONIBLES** |
| GET | `/api/anuncios/{id}/` | autenticado | Ver anuncio (**sin contacto**) |
| PATCH | `/api/anuncios/{id}/` | dueño | Editar |
| GET | `/api/anuncios/mios/` | propietario | Mis anuncios, en cualquier estado |
| POST | `/api/anuncios/{id}/marcar_alquilado/` | dueño | Apagar el anuncio |
| POST | `/api/anuncios/{id}/fotos/` | dueño | Subir foto con `fecha_captura` |
| POST | `/api/solicitudes/` | inquilino | Solicitar visita |
| GET | `/api/solicitudes/` | autenticado | Enviadas o recibidas, segun el rol |
| POST | `/api/solicitudes/{id}/aprobar/` | dueño del anuncio | **Libera el contacto** |
| POST | `/api/solicitudes/{id}/rechazar/` | dueño del anuncio | Rechazar |

### Filtros de busqueda

`?precio_max=` `?precio_min=` `?minutos_max=` `?acepta_mascotas=` `?tipo_espacio=`

Son exactamente las cuatro condiciones de descarte. **El filtro de precio corre sobre el precio final**, no sobre el alquiler pelado: filtrar por el alquiler seria repetir el problema de la evidencia 1. Se resuelve anotando el queryset, porque `precio_final` es una propiedad y no una columna.

## Pruebas

```powershell
python manage.py test
```

**39 pruebas** sobre las reglas de negocio y la API — no sobre el ORM de Django. Recorren los dos flujos documentados de punta a punta: Marta publica, Andrea filtra y solicita, Marta aprueba y el contacto recien ahi aparece.

Las que mas importan son las que intentan **romper** la regla central: que el WhatsApp no aparezca en el listado ni en el detalle, que una solicitud pendiente o rechazada no lo devuelva, que el inquilino no pueda autoaprobarse y que un tercero no pueda aprobar una solicitud ajena.
