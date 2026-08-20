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

## Emulador

Arrancalo siempre con el script, no con el boton de Android Studio:

```powershell
cd mobile
.\scripts\emulador.ps1
```

### Por que un script y no el boton

El emulador **abre su ventana fuera del area visible de la pantalla**. Aparece
como `device` en `adb devices` y en `flutter devices`, pero no se ve nada: la
ventana queda en Y = -1000, mil pixeles por encima del borde superior. Guarda
una posicion en `emulator-user.ini` pero la ignora — comprobado dos veces
seguidas, arranca en la misma posicion invalida aunque el `.ini` diga otra cosa.

El script espera a que termine de bootear y despues reubica la ventana,
recortandola contra los limites del monitor real. Si el AVD no entra en la
pantalla, la achica en vez de dejarla a medias afuera.

```powershell
.\scripts\emulador.ps1 -Avd Pixel_10_Pro_Fold   # elegir otro AVD
.\scripts\emulador.ps1 -ColdBoot                # arranque en frio
```

### Config del AVD (fuera del repo)

Estos cambios estan en `%USERPROFILE%\.androidvd\<avd>.avd\config.ini`,
que no se versiona. Si armas el entorno en otra maquina, replicalos:

| Clave | Valor | Por que |
|---|---|---|
| `emulator.dev.xr.glasses_display` | **eliminada** | Estaba en `monocular_right`: renderizaba como pantalla de gafas XR, por eso la ventana salia apaisada (975x469) pese a `hw.initialOrientation=portrait`. Sin esta linea vuelve a ser vertical (447x800) |
| `hw.ramSize` | 5120 → 2048 | Mas RAM de la que queda libre en la maquina |
| `vm.heapSize` | 4096 → 512 | Desproporcionado para una app de este tamano |
| `hw.cpu.ncore` | 8 → 4 | La mitad de los nucleos dedicados al emulador |

Con eso la CPU en reposo bajo de **73% a 6%**, que era la causa del ruido del
ventilador. Hay un respaldo en `config.ini.bak` junto al original.

> **Los cambios de RAM, heap y nucleos no se aplican con el arranque normal**,
> porque restaura un snapshot que trae la configuracion vieja. Hay que arrancar
> una vez con `-ColdBoot`.

> **Para esta app conviene un telefono real por USB.** El GPS y la camara con
> fecha de captura son el corazon del producto y no se prueban bien en un
> emulador — ademas no consume RAM de tu maquina.

## Conectarse al backend

Con el backend corriendo en `localhost:8000`, la base de la API desde el **emulador de Android** es `http://10.0.2.2:8000` (el emulador no ve `localhost` como la máquina anfitriona). En dispositivo físico, la IP de la máquina en la red local.
