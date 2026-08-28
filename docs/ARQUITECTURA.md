# Arquitectura de AlquilaMatch

Guía para explicar el proyecto. Todas las rutas y números de línea de este
documento fueron verificados contra el código real.

---

## 1. La idea que ordena todo

Ni el backend ni la app se organizan por capas técnicas en el nivel de arriba.
**Se parten por dominio**, y cada carpeta corresponde a un módulo del
`appmap/appmap-v0.1.md`.

| Backend (app de Django) | Mobile (feature de Flutter) | Módulo del app map |
|---|---|---|
| `usuarios/` | `features/auth/` | 0. Entrar |
| `anuncios/` | `features/anuncios/` | 1. Publicar anuncio |
| `anuncios/` (filtros) | `features/buscar/` | 4. Buscar · 5. Ver anuncio |
| `solicitudes/` | `features/buscar/` + `features/solicitudes_recibidas/` | 2. Gestionar solicitudes · 6. Solicitar visita |

> **Si te preguntan por qué está así:** porque la estructura del código refleja
> el mapa de la app que documentamos **antes** de programar. No al revés.

---

## 2. Qué patrón usa cada lado

### Backend — Django por apps + DRF con ViewSet y Router

```
backend/
├── config/          # settings y enrutado raíz
│   ├── settings.py
│   └── urls.py      # delega con include() a cada app
├── usuarios/
├── anuncios/
└── solicitudes/
```

Cada app repite el mismo juego de archivos:

| Archivo | Rol |
|---|---|
| `models.py` | Los datos **y las reglas de negocio** |
| `serializers.py` | Traduce entre objetos Python y JSON, y valida lo que entra |
| `views.py` | Recibe el pedido HTTP e invoca al modelo |
| `urls.py` | Qué URL corresponde a qué vista |
| `permissions.py` | Quién puede hacer qué |
| `filters.py` | Los filtros de búsqueda (sólo en `anuncios`) |

**Dos decisiones que conviene poder nombrar:**

**No hay capa de servicios.** La lógica de negocio vive en métodos del modelo, y
las vistas sólo la invocan. Ejemplos reales: `Anuncio.marcar_alquilado()`
(`anuncios/models.py:112`), `SolicitudVisita.aprobar()`
(`solicitudes/models.py:78`) y la property `contacto_liberado`
(`solicitudes/models.py:55`). Para un proyecto de este tamaño, agregar una capa
de servicios sería sobre-ingeniería.

**Las operaciones que no son CRUD entran como `@action`.** El router de DRF da
list/create/retrieve/update/delete gratis; lo demás se declara explícitamente:

```python
# anuncios/views.py
@action(detail=True, methods=['post'])
def marcar_alquilado(self, request, pk=None):
    """Apagar el anuncio en un toque (Ev. 8)."""
    anuncio = self.get_object()
    self.check_object_permissions(request, anuncio)
    anuncio.marcar_alquilado()
    return Response(AnuncioDetailSerializer(anuncio, context={'request': request}).data)
```

`usuarios` es la excepción: son dos generic views sueltas con `path()`, porque
registro y perfil no son un CRUD.

### Mobile — feature-first, tres capas, MVVM sobre ChangeNotifier

```
mobile/lib/
├── core/            # transversal: api_client, config, theme
├── shared/widgets/  # widgets reutilizables
└── features/
    ├── auth/
    ├── anuncios/
    ├── buscar/
    ├── solicitudes_recibidas/
    └── home/        # sólo presentation: no habla con la red
```

Cada feature repite exactamente tres carpetas:

| Capa | Contiene | Sabe de… |
|---|---|---|
| `data/` | Modelos y **repositorio** | El `ApiClient` |
| `providers/` | **Estado** (`ChangeNotifier`) | El repositorio |
| `presentation/` | Pantallas (widgets) | El provider |

**La dependencia va en un solo sentido.** Una pantalla nunca llama a la API
directo, y el repositorio nunca sabe que existe un widget.

La inyección es manual con `package:provider` desde `main.dart:16-32`: se
instancia **un solo** `ApiClient`, se lo pasa a los tres repositorios y se
publican con `MultiProvider`.

No hay capa de dominio ni casos de uso, y la navegación es imperativa con
`Navigator.push`, sin router declarativo. Son decisiones deliberadas de escala.

---

## 3. Cómo se comunican los dos lados

**Protocolo:** HTTP con JSON, autenticado con **JWT** en la cabecera
`Authorization: Bearer <token>`.

### Un solo punto de contacto

Esto es lo más importante que podés señalar del diseño:

> **`mobile/lib/core/api_client.dart` es el único archivo de toda la app que
> hace HTTP.** Ninguna pantalla, ningún provider abre una conexión.

Por eso el token, su renovación y la traducción de errores están escritos **una
sola vez**.

### El recorrido completo de un pedido

Tomemos el botón **"Marcar Ya alquilado"**. Son cuatro saltos:

**1. La pantalla** sólo avisa que la tocaron — `mis_anuncios_screen.dart:170`

```dart
OutlinedButton.icon(
  onPressed: () =>
      context.read<MisAnunciosProvider>().alternarEstado(anuncio),
  icon: const Icon(Icons.check_circle_outline, size: 18),
  label: const Text('Marcar Ya alquilado'),
)
```

**2. El provider** decide qué hacer y avisa a la UI cuando cambió algo —
`mis_anuncios_provider.dart:41`

```dart
Future<void> alternarEstado(Anuncio anuncio) async {
  try {
    final actualizado = anuncio.estaDisponible
        ? await _repo.marcarAlquilado(anuncio.id)
        : await _repo.marcarDisponible(anuncio.id);

    final i = _anuncios.indexWhere((a) => a.id == anuncio.id);
    if (i != -1) _anuncios[i] = actualizado;
    notifyListeners();          // ← esto redibuja la pantalla
  } on ApiException catch (e) {
    error = e.mensaje;
    notifyListeners();
  }
}
```

**3. El repositorio** traduce la intención a un endpoint —
`anuncios_repository.dart:81`

```dart
Future<Anuncio> marcarAlquilado(int id) async {
  final datos =
      await _api.post('/api/anuncios/$id/marcar_alquilado/') as Map<String, dynamic>;
  return Anuncio.desdeJson(datos);
}
```

**4. El `ApiClient`** pone el token y hace el viaje — `api_client.dart:104`

```dart
if (conToken) {
  final token = await accessToken;
  if (token != null) cabeceras['Authorization'] = 'Bearer $token';
}
```

Del otro lado, Django recibe, valida el permiso, llama al método del modelo y
devuelve el anuncio actualizado en JSON.

### La renovación automática del token

El access token dura 8 horas (`settings.py:181`). Cuando vence, el backend
responde **401** y el `ApiClient` lo resuelve solo, sin que la persona se entere
— `api_client.dart:122`

```dart
// El access vencio: renovarlo y reintentar una unica vez.
if (respuesta.statusCode == 401 && conToken && !esReintento) {
  if (await _renovarToken()) {
    return _enviar(metodo, ruta,
        cuerpo: cuerpo, query: query, conToken: conToken, esReintento: true);
  }
}
```

El `esReintento` evita un bucle infinito: si la renovación tampoco funciona, el
error sube y la app vuelve al login.

---

## 4. Qué botón habla con el backend

Verificado control por control. **"sin llamada"** significa que ese control sólo
cambia estado local o navega.

### Autenticación

| Pantalla | Control | Qué dispara |
|---|---|---|
| Login | **ENTRAR** | `POST /api/auth/token/` **y después** `GET /api/usuarios/yo/` |
| Registro | **CREAR CUENTA** | `POST /api/usuarios/registro/` → `POST /api/auth/token/` → `GET /api/usuarios/yo/` |
| Home | Ícono de salir | **Ninguna llamada** — ver nota abajo |
| (arranque) | `restaurarSesion()` | `GET /api/usuarios/yo/`, **sólo si hay token guardado** |

> **Ojo con dos de estos, porque son trampa de examen.**
>
> **"Entrar" hace dos llamadas, no una.** `AuthRepository.login`
> (`auth_repository.dart:11-24`) pide los tokens y, en el `return` de la línea
> 23, encadena `miPerfil()`. Sin ese segundo pedido la app no sabría tu rol.
>
> **"Crear cuenta" hace tres.** Registro, después login, después perfil
> (`auth_repository.dart:49` hace `return login(...)`).

### Anuncios — lado propietario

| Pantalla | Control | Qué dispara |
|---|---|---|
| Mis anuncios | (al abrir) | `GET /api/anuncios/mios/` |
| Publicar | Tipo de espacio, título, precio, servicios | sin llamada — viajan dentro del POST |
| Publicar | **Usar mi ubicación** | sin llamada — lee el GPS del teléfono |
| Publicar | **Tomar una foto** | sin llamada — la foto se sube al publicar |
| Publicar | **PUBLICAR** | `POST /api/anuncios/` → un `POST /api/anuncios/{id}/fotos/` **por cada foto** → `GET /api/anuncios/{id}/` → `GET /api/anuncios/mios/` |
| Mis anuncios | **Marcar Ya alquilado** | `POST /api/anuncios/{id}/marcar_alquilado/` |
| Mis anuncios | **Volver a publicar** | `POST /api/anuncios/{id}/marcar_disponible/` |

> **"Publicar" es el más complejo de la app.** Son dos pasos porque el anuncio
> se crea con JSON y las fotos necesitan `multipart`, y además cada foto se
> cuelga de un anuncio que ya tiene id.

### Buscar — lado inquilina

| Pantalla | Control | Qué dispara |
|---|---|---|
| Buscar | Precio, tipo, mascotas, minutos | sin llamada — sólo estado local |
| Buscar | **BUSCAR** | `GET /api/anuncios/` con los filtros como query params |
| Resultados | Tarjeta de anuncio | sin llamada — navega al detalle |
| Anuncio | (al abrir) | `GET /api/anuncios/{id}/` |
| Anuncio | **SOLICITAR VISITA** | sin llamada — navega al formulario |
| Solicitar visita | **ENVIAR SOLICITUD** | `POST /api/solicitudes/` |
| Estado | **Actualizar estado** | `GET /api/solicitudes/{id}/` |
| Estado | **ABRIR WHATSAPP** | sin llamada al backend — abre `wa.me` con `url_launcher` |
| Mis solicitudes | (al abrir / pull-to-refresh) | `GET /api/solicitudes/` |

### Solicitudes recibidas — lado propietario

| Pantalla | Control | Qué dispara |
|---|---|---|
| Gestionar solicitudes | (al abrir / pull-to-refresh) | `GET /api/solicitudes/` |
| Gestionar solicitudes | **Aprobar** | `POST /api/solicitudes/{id}/aprobar/` |
| Gestionar solicitudes | **Rechazar** | `POST /api/solicitudes/{id}/rechazar/` |

> **Detalle fino:** la tarjeta "Gestionar solicitudes" del Home **no** hace la
> llamada. Sólo navega. El `GET` lo dispara el `initState` de la pantalla
> destino (`solicitudes_recibidas_screen.dart:18-23`).

---

## 5. Inventario de endpoints

| Endpoint | Quién puede |
|---|---|
| `POST /api/auth/token/` | Público |
| `POST /api/auth/token/refresh/` | Público (con un refresh válido) |
| `POST /api/usuarios/registro/` | Público (`AllowAny` explícito) |
| `GET /api/usuarios/yo/` | Autenticado |
| `GET /api/anuncios/` | Autenticado — **sólo devuelve los DISPONIBLES** |
| `POST /api/anuncios/` | Sólo rol **PROPIETARIO** |
| `GET /api/anuncios/{id}/` | Autenticado |
| `PATCH` / `DELETE /api/anuncios/{id}/` | Sólo el **dueño** del anuncio |
| `GET /api/anuncios/mios/` | Autenticado — sólo los propios, en cualquier estado |
| `POST /api/anuncios/{id}/marcar_alquilado/` | Sólo el dueño |
| `POST /api/anuncios/{id}/marcar_disponible/` | Sólo el dueño |
| `POST /api/anuncios/{id}/fotos/` | Sólo el dueño |
| `GET /api/solicitudes/` | Autenticado — **enviadas o recibidas según el rol** |
| `POST /api/solicitudes/` | Autenticado |
| `POST /api/solicitudes/{id}/aprobar/` | Sólo el dueño del anuncio |
| `POST /api/solicitudes/{id}/rechazar/` | Sólo el dueño del anuncio |

**No existe endpoint de logout.** El cierre de sesión es puramente local: borra
los dos tokens del almacenamiento seguro (`api_client.dart:47-50`). El refresh
token sigue siendo técnicamente válido hasta 30 días. Es una decisión conocida,
no un olvido: implementar una blacklist requeriría
`rest_framework_simplejwt.token_blacklist`, que no está instalada.

---

## 6. Los tres puntos que definen el producto

Si tenés que defender el diseño, apuntá a estos:

### El contacto tiene un único camino

```python
# solicitudes/models.py:55
@property
def contacto_liberado(self):
    """El WhatsApp del propietario, o None si todavia no fue aprobada."""
    if self.estado != self.Estado.APROBADA:
        return None
    perfil = getattr(self.anuncio.propietario, 'perfil', None)
    return perfil.whatsapp if perfil else None
```

Ningún serializer de anuncio expone el teléfono. Hay **4 pruebas** que intentan
romperlo: listado, detalle, solicitud pendiente y solicitud rechazada.

### El precio final se deriva, no se escribe

```python
# anuncios/models.py
@property
def precio_final(self):
    """Lo que el inquilino termina pagando por mes."""
    return self.precio_alquiler + self.costo_servicios_estimado
```

Y `clean()` **impide publicar** dejando servicios afuera con costo en cero. El
filtro de búsqueda corre sobre el precio final anotando el queryset, no sobre el
alquiler pelado.

### Los minutos los calcula la app

```python
# anuncios/models.py
def save(self, *args, **kwargs):
    # Los minutos caminando siempre se derivan de la ubicacion: nunca
    # los escribe el propietario, que es de donde sale hoy el "cerca de la U".
    self.minutos_caminando = minutos_caminando_a_uagrm(self.lat, self.lng)
    super().save(*args, **kwargs)
```

---

## 7. Limitación conocida

**La renovación automática del token no cubre la subida de fotos.**

`postArchivo` (`api_client.dart:70-91`) arma un `MultipartRequest`, adjunta el
token a mano y llama a `_interpretar` directo, **sin pasar por `_enviar`**. Por
eso un 401 durante `POST /api/anuncios/{id}/fotos/` no dispara el refresh: falla
con una excepción.

En la práctica se nota sólo si alguien deja la app abierta más de 8 horas y
después publica con fotos. Está identificado y es de pocas líneas.
