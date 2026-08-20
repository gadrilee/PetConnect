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

## Estructura

```
mobile/lib/
├── main.dart                    # providers + qué pantalla se ve según la sesión
├── core/
│   ├── config.dart              # baseUrl de la API
│   ├── api_client.dart          # HTTP con JWT, renueva el token al vencer
│   └── theme.dart               # colores y medidas, en un solo lugar
├── features/
│   ├── auth/                    # login, registro, estado de sesión
│   ├── anuncios/                # publicar y gestionar anuncios
│   └── home/                    # bifurcación por rol
└── shared/widgets/              # widgets transversales
```

Organización *feature-first*: cada carpeta de `features/` es autocontenida y
corresponde a un módulo del `appmap/appmap-v0.1.md`, igual que las apps del
backend. Falta `solicitudes/`.

## Autenticación

Ya funciona contra la API real:

- `POST /api/auth/token/` devuelve access y refresh, que se guardan con
  **flutter_secure_storage** (Keystore en Android), no en texto plano.
- Cada pedido lleva el `Authorization: Bearer`. Si el access venció, el
  `ApiClient` lo renueva y **reintenta el pedido una sola vez**.
- Al abrir la app, `restaurarSesion()` usa el token guardado: verificado que
  entra al home sin volver a pedir credenciales.
- Los errores de DRF se traducen a mensajes legibles, y los que vienen por
  campo (`{"whatsapp": [...]}`) se pintan debajo del input correspondiente.

### Dos decisiones de build que conviene conocer

**`flutter_secure_storage` está fijado en 10.3.1, no en la última.** La 11.0.0
exige compilar contra Android SDK 37. Flutter instala esa plataforma solo, pero
la deja como `android-37.0` mientras Gradle busca `android-37`, y la build
falla. La 10.3.1 compila contra SDK 36 y evita el problema en cualquier máquina.

**HTTP en claro habilitado sólo en debug.** Android lo bloquea desde API 28 y el
backend de desarrollo no tiene TLS. La excepción vive en
`android/app/src/debug/res/xml/network_security_config.xml` y se limita a
`10.0.2.2`, `localhost` y `127.0.0.1`. Al estar en `src/debug/` **no forma parte
de la build de release**.

## Publicar un anuncio

El flujo v0.1 completo, verificado de punta a punta contra el backend real.

| Paso del flujo | En la app |
|---|---|
| 1. Tipo de espacio | Botón segmentado: habitación / departamento / casa |
| 2. Precio final | Alquiler + qué servicios incluye. Si alguno queda afuera aparece el campo de costo aparte, y el **precio final se recalcula en vivo** mientras escribe |
| 3. Reglas | Mascotas como interruptor filtrable, no texto libre |
| 4. Ubicación | GPS con `geolocator`, pidiendo el permiso en el momento |
| 5. Fotos | Cámara con `image_picker`; la fecha de captura es **el momento de la toma** |
| 6-7. Publicar | Crea el anuncio y después sube cada foto por `multipart` |

**Mis anuncios** lista los propios en cualquier estado y permite marcar
*Ya alquilado* en un toque. Verificado: al marcarlo, el anuncio desaparece de
la búsqueda pero sigue visible para su dueño.

### Permisos de Android

`ACCESS_FINE_LOCATION` y `ACCESS_COARSE_LOCATION` están declarados en el
manifest principal. **No se declara `CAMERA`**: `image_picker` abre la cámara
del sistema por intent, y declararlo obligaría a pedirlo en tiempo de ejecución
sin ganar nada.

Para probar el GPS en el emulador hay que fijarle una posición:

```bash
adb emu geo fix -63.1980 -17.7757
```

## Emulador

**La ventana del emulador abre fuera del area visible de la pantalla.** Aparece
como `device` en `adb devices` y en `flutter devices`, pero no se ve nada: queda
en Y = -1000, mil pixeles por encima del borde superior.

### La causa

`window.scale = -1` (automatico) en `emulator-user.ini`. El emulador calcula la
posicion de la ventana con el tamano **sin escalar** del dispositivo (1440x3200)
y despues escala solo el tamano, no la posicion. Centrar 3200 px en una pantalla
de 800 da aproximadamente -1000.

Fijar una escala explicita lo arregla... hasta que cerras el emulador: **borra y
recrea `emulator-user.ini`, reseteando la escala a -1**. Marcar el archivo como
solo-lectura tampoco sirve, porque al recrearlo limpia el atributo. Comprobado.

### La solucion: instalarla una vez

```powershell
cd mobile
.\scripts\emulador-watcher.ps1 -Install
```

Queda como tarea programada al iniciar sesion y funciona **sin importar como
arranques el emulador** — boton de Android Studio, linea de comandos o el script
de abajo. Trabaja en dos capas:

1. **Al cerrarse el emulador**, reescribe `emulator-user.ini` con una escala
   explicita calculada desde el alto real de tu monitor. Asi el proximo arranque
   ya abre bien por si solo.
2. **Si aun asi abre fuera**, detecta la ventana y la reubica, recortandola
   contra los limites del monitor.

Actua **una sola vez por sesion** de emulador: si despues moves la ventana a
mano, no te la vuelve a correr.

```powershell
.\scripts\emulador-watcher.ps1 -Uninstall   # quitarla
```

### Arranque manual (opcional)

```powershell
.\scripts\emulador.ps1                      # arranca y reubica
.\scripts\emulador.ps1 -Avd Pixel_10_Pro_Fold
.\scripts\emulador.ps1 -ColdBoot            # tras cambiar RAM o nucleos
```

### Config del AVD (fuera del repo)

Estos cambios estan en `%USERPROFILE%\.android\avd\<avd>.avd\config.ini`, que no
se versiona. Si armas el entorno en otra maquina, replicalos:

| Clave | Valor | Por que |
|---|---|---|
| `emulator.dev.xr.glasses_display` | **eliminada** | Estaba en `monocular_right`: renderizaba como pantalla de gafas XR, por eso la ventana salia apaisada (975x469) pese a `hw.initialOrientation=portrait` |
| `hw.ramSize` | 5120 -> 2048 | Mas RAM de la que queda libre en la maquina |
| `vm.heapSize` | 4096 -> 512 | Desproporcionado para una app de este tamano |
| `hw.cpu.ncore` | 8 -> 4 | La mitad de los nucleos dedicados al emulador |

Con eso la CPU en reposo bajo de **73% a 6%**, que era la causa del ruido del
ventilador. Hay un respaldo en `config.ini.bak` junto al original.

> **Los cambios de RAM, heap y nucleos no se aplican con el arranque normal**,
> porque restaura un snapshot con la configuracion vieja. Hay que arrancar una
> vez con `-ColdBoot`.

> **Para esta app conviene un telefono real por USB.** El GPS y la camara con
> fecha de captura son el corazon del producto y no se prueban bien en un
> emulador — ademas no consume RAM de tu maquina.

## Conectarse al backend

Con el backend corriendo en `localhost:8000`, la base de la API desde el **emulador de Android** es `http://10.0.2.2:8000` (el emulador no ve `localhost` como la máquina anfitriona). En dispositivo físico, la IP de la máquina en la red local.
