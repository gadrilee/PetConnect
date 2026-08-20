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
