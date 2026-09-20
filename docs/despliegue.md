# Despliegue — AlquilaMatch en Google Cloud

**Integrantes:** Gabriel Mamani Sandoval, Daniel Joaquin Mamani Peña
**Fecha:** 20/09/2026

La app está publicada y funcionando:

| | |
|---|---|
| **Web** | <https://34-42-165-3.nip.io/> |
| **API** | <https://34-42-165-3.nip.io/api/> |
| **Admin de Django** | <https://34-42-165-3.nip.io/admin/> |
| **APK** | `mobile/build/app/outputs/flutter-apk/app-release.apk` (52 MB) |

Las cuentas son las mismas que en desarrollo: `marta.quiroga`, `andrea.rojas` y
las otras siete, todas con la contraseña `demo1234`. En la base de producción
hay 90 cuentas, 130 anuncios con 314 fotos y 150 solicitudes.

## Qué hay levantado

Una sola máquina, con todo adentro. No hay base de datos administrada ni
almacenamiento externo: para una demo, un servicio que hay que pagar todos los
meses no se justifica.

```
Google Cloud · proyecto alquilamatch-uagrm
└── VM alquilamatch  (e2-micro, us-central1-a, Debian 13)
    ├── nginx          ← HTTPS, sirve la web y hace de proxy
    ├── gunicorn       ← Django, 2 workers, en 127.0.0.1:8000
    ├── PostgreSQL     ← la base, en la misma máquina
    └── /opt/alquilamatch/media  ← las fotos, en el disco de la VM
```

- **IP fija:** `34.42.165.3`, reservada, así el APK no se rompe si la VM se
  reinicia.
- **Dominio:** `34-42-165-3.nip.io`. nip.io resuelve cualquier `a-b-c-d.nip.io`
  a esa IP; sirve para tener un nombre real y, con él, un certificado.
- **HTTPS:** certificado de Let's Encrypt, renovación automática por systemd.
  Hace falta de verdad: Android bloquea el tráfico sin cifrar desde API 28, así
  que con `http://IP` pelado el APK no conectaría.
- **Costo:** la e2-micro y los 20 GB de disco entran en la capa gratuita de
  Google Cloud en `us-central1`. El resto (IP fija en uso, tráfico de salida)
  es de centavos. Igual conviene mirar la facturación de vez en cuando.

## Cómo volver a desplegar

### El backend

```bash
# desde la raíz del repo
tar --exclude='.venv' --exclude='db.sqlite3' --exclude='media' \
    --exclude='__pycache__' --exclude='staticfiles' --exclude='.env' \
    -czf backend.tgz backend
gcloud compute scp backend.tgz alquilamatch:/home/danie/backend.tgz \
    --project=alquilamatch-uagrm --zone=us-central1-a

gcloud compute ssh alquilamatch --project=alquilamatch-uagrm --zone=us-central1-a --command "
  cd /home/danie && tar -xzf backend.tgz &&
  sudo rsync -a --delete --exclude media --exclude .env --exclude staticfiles /tmp/backend/ /opt/alquilamatch/ &&
  cd /opt/alquilamatch &&
  sudo -u alquilamatch .venv/bin/pip install -q -r requirements.txt &&
  sudo -u alquilamatch .venv/bin/python manage.py migrate --noinput &&
  sudo -u alquilamatch .venv/bin/python manage.py collectstatic --noinput &&
  sudo systemctl restart alquilamatch"
```

### La web

```bash
cd mobile
flutter build web --release --dart-define=API_URL=https://34-42-165-3.nip.io
cd build && tar -czf ../../web.tgz web && cd ../..
gcloud compute scp web.tgz alquilamatch:/home/danie/web.tgz \
    --project=alquilamatch-uagrm --zone=us-central1-a
gcloud compute ssh alquilamatch --project=alquilamatch-uagrm --zone=us-central1-a --command "
  cd /home/danie && tar -xzf web.tgz &&
  sudo rsync -a --delete web/ /var/www/alquilamatch/ &&
  sudo chown -R www-data:www-data /var/www/alquilamatch"
```

### El APK

```bash
cd mobile
flutter build apk --release --dart-define=API_URL=https://34-42-165-3.nip.io
# queda en build/app/outputs/flutter-apk/app-release.apk
```

Sin el `--dart-define` la app apunta a `http://10.0.2.2:8000`, que es el
servidor local visto desde el emulador.

> **El APK está firmado con la clave de debug**, que es la que trae Flutter de
> fábrica. Para instalarlo de un teléfono a otro alcanza; para publicarlo en
> Play Store hay que generar una clave propia y configurarla en
> `android/app/build.gradle.kts`.

### Volver a poblar la base

```bash
gcloud compute ssh alquilamatch --project=alquilamatch-uagrm --zone=us-central1-a --command "
  cd /opt/alquilamatch &&
  sudo -u alquilamatch .venv/bin/python manage.py poblar_demo --limpiar"
```

Borra todo lo que no sea superusuario. Después hay que volver a poner el
WhatsApp, porque `poblar_demo` usa los números inventados del repo:

```bash
gcloud compute ssh alquilamatch --project=alquilamatch-uagrm --zone=us-central1-a --command "
  cd /opt/alquilamatch && sudo -u alquilamatch .venv/bin/python manage.py shell -c \"
from usuarios.models import Perfil
print(Perfil.objects.filter(rol='PROPIETARIO').update(whatsapp='TU-NUMERO'))\""
```

## Las claves

No están en el repo, a propósito. Viven en `/opt/alquilamatch/.env` en el
servidor, que es de lectura sólo para root:

```bash
gcloud compute ssh alquilamatch --project=alquilamatch-uagrm --zone=us-central1-a \
  --command "sudo cat /opt/alquilamatch/.env"
```

Ahí están el `SECRET_KEY` de Django y la contraseña de PostgreSQL. La del
superusuario `admin` del panel se pasó aparte.

## Qué mirar cuando algo falla

```bash
# ¿está corriendo Django?
gcloud compute ssh alquilamatch --project=alquilamatch-uagrm --zone=us-central1-a \
  --command "systemctl status alquilamatch --no-pager | head -20"

# los últimos errores
gcloud compute ssh alquilamatch --project=alquilamatch-uagrm --zone=us-central1-a \
  --command "sudo journalctl -u alquilamatch -n 50 --no-pager"

# nginx
gcloud compute ssh alquilamatch --project=alquilamatch-uagrm --zone=us-central1-a \
  --command "sudo tail -30 /var/log/nginx/error.log"
```

## Lo que quedó pendiente

- **Las fotos viven en el disco de la VM.** Si la máquina se borra, se pierden
  las que hayan subido los usuarios (las del repo se vuelven a generar con
  `poblar_demo`). Lo correcto sería un bucket, como dice el comentario de
  `settings.py`.
- **La búsqueda sin filtros muestra 20 de 117.** La API pagina de a 20 y la app
  se queda con la primera página.
- **Los correos no salen.** El backend sigue con el backend de consola, así que
  el enlace de recuperar contraseña se imprime en el log del servidor en vez de
  enviarse. Se ve con `journalctl -u alquilamatch`.
- **No hay copias de seguridad.** Un `pg_dump` periódico sería lo mínimo.
