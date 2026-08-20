# Mobile — AlquilaMatch

App móvil en **Flutter**. Consume la API de `../backend`.

## Por qué móvil y no web

Del `brief/brief-v0.2.0.md` §6: las tres acciones críticas dependen del teléfono.

- El propietario marca la ubicación **parado en el inmueble** (GPS).
- Fotografía **el estado actual** en ese momento (ataca las fotos viejas).
- La inquilina busca en la calle, entre clases, decidiendo si camina hasta ahí.

Un formulario web se llena después, desde la memoria, y ahí es donde se cuela la información desactualizada.

## Levantar la app

El proyecto ya está creado (`bo.edu.uagrm.alquilamatch`, sólo Android e iOS — sin web ni escritorio, porque el brief define el producto como exclusivamente móvil).

```powershell
cd mobile
flutter run
```

Si clonás el repo de cero, antes: `flutter pub get`.

## Capacidades del dispositivo que se usan

| Capacidad | Para qué | Módulo del app map |
|---|---|---|
| GPS | Ubicación del inmueble al publicar | 2. Publicar anuncio |
| Cámara | Fotos selladas con fecha de captura | 2. Publicar anuncio |
| Notificaciones push | Avisar la respuesta a la solicitud | 3. Gestionar solicitudes |

## Estructura prevista

Hoy `lib/` sólo tiene el `main.dart` que genera Flutter. La organización a medida que se implemente:

```
mobile/lib/
├── main.dart
├── core/                # cliente HTTP, tema, constantes
├── features/
│   ├── auth/            # registro, login, elegir rol
│   ├── anuncios/        # publicar, mis anuncios, estado
│   └── solicitudes/     # bandeja, aprobar / rechazar
└── shared/              # widgets transversales
```

Organización *feature-first*: cada carpeta de `features/` es autocontenida y corresponde a un módulo del `appmap/appmap-v0.1.md`, igual que las apps del backend.

## Conectarse al backend

Con el backend corriendo en `localhost:8000`, la base de la API desde el **emulador de Android** es `http://10.0.2.2:8000` (el emulador no ve `localhost` como la máquina anfitriona). En dispositivo físico, la IP de la máquina en la red local.
