# Prompts para Google Stitch

Para generar las pantallas de AlquilaMatch y exportarlas a Figma.

**Cómo usarlo:** pegá primero el *prompt base* para que Stitch entienda el
producto. Después pegá **un prompt de pantalla por vez**. Al terminar, usá
*Export to Figma* en cada pantalla.

**Modo:** si tenés disponible el modo experimental, usalo — respeta mejor las
restricciones (sobre todo la de "no mostrar el teléfono").

---

## Prompt base — pegalo primero

```
Estoy diseñando una app móvil Android llamada AlquilaMatch, para alquiler de
vivienda en Santa Cruz de la Sierra, Bolivia. Todos los textos de la interfaz
deben estar en español.

El problema: hoy los anuncios de alquiler no dicen el precio final ni si
aceptan mascotas, así que los estudiantes pierden tardes enteras visitando
lugares que no aplicaban. Y los propietarios reciben veinte mensajes de
WhatsApp repitiendo siempre lo mismo.

La app tiene dos tipos de usuario:
- El propietario, que publica un inmueble declarando las condiciones por
  adelantado.
- La inquilina, una estudiante universitaria que busca cuarto desde el celular.

Las cuatro condiciones de descarte que SIEMPRE deben ser visibles en un
anuncio son: precio final con servicios incluidos, política de mascotas,
tipo de espacio (habitación / departamento / casa) y minutos caminando
hasta la universidad UAGRM.

REGLA CRÍTICA DE DISEÑO: el número de teléfono o WhatsApp del propietario
NUNCA aparece en un anuncio ni en los resultados de búsqueda. Sólo se revela
después de que el propietario aprueba una solicitud de visita.

Reglas de diseño para todas las pantallas:
1. La información importante debe ser visible sin desplazarse.
2. Debe haber UNA SOLA acción principal por pantalla, claramente destacada.
3. Después de cada acción, una pantalla que muestre qué ocurrió.

Estilo: limpio y sobrio, mucho espacio en blanco, tipografía sans serif,
esquinas redondeadas. Diseño móvil vertical, 360x800.
```

---

## Flujo 2 — La inquilina que busca

### 01 Buscar

```
Pantalla "Buscar" de AlquilaMatch. Es donde la estudiante pone sus filtros
antes de ver resultados.

Contiene: un campo de precio máximo mensual en bolivianos (Bs); un selector
de tipo de espacio con tres opciones (Habitación, Departamento, Casa); un
interruptor "Acepta mascotas"; y un control para el máximo de minutos
caminando hasta la UAGRM, con valores de 5 a 30.

La acción principal, un botón ancho en la parte inferior: "VER RESULTADOS".

No incluyas ningún dato de contacto en esta pantalla.
```

### 02 Resultados

```
Pantalla de resultados de búsqueda de AlquilaMatch, una lista vertical de
tarjetas de inmuebles ordenadas por cercanía a la universidad.

Cada tarjeta muestra: una foto, el título, el PRECIO FINAL en bolivianos por
mes (ej. "1.000 Bs / mes"), los minutos caminando a la UAGRM (ej. "9 min"),
si acepta mascotas, y el tipo de espacio. Mostrá 4 tarjetas.

Arriba, una fila con los filtros activos que se pueden tocar para cambiarlos.

IMPORTANTE: ninguna tarjeta muestra teléfono, WhatsApp ni botón de llamar.
Sólo se puede tocar la tarjeta para abrir el anuncio.
```

### 03 Anuncio  ← la pantalla más importante

```
Pantalla de detalle de un anuncio de alquiler en AlquilaMatch. Es el momento
en que la estudiante decide si le sirve o lo descarta, así que los datos
tienen que estar todos a la vista.

Arriba: una foto grande del cuarto, con una etiqueta encima que muestra la
fecha en que se tomó la foto ("Foto del 12/08/2026"). Esa etiqueta es
importante: garantiza que la foto es actual.

Debajo, los cuatro datos con íconos, cada uno en su fila:
- "1.000 Bs / mes · todo incluido"
- "9 min caminando a la UAGRM"
- "Acepta mascotas"
- "Habitación con baño privado"

Después: los servicios incluidos como etiquetas (Agua, Luz), una breve
descripción, y un recuadro informativo que dice "El contacto del propietario
se libera cuando aprueba tu solicitud".

La acción principal abajo: "SOLICITAR VISITA".

CRÍTICO: no muestres teléfono, WhatsApp, botón de llamar ni de chatear. La
ausencia del contacto es intencional y es el corazón del producto.
```

### 04 Solicitar visita

```
Pantalla "Solicitar visita" de AlquilaMatch. La estudiante confirma que acepta
las condiciones del anuncio antes de pedir el contacto.

Contiene un recuadro titulado "Estás aceptando:" que lista las condiciones
como una lista con tildes:
- 1.000 Bs por mes, todo incluido
- 9 min caminando a la UAGRM
- Acepta mascotas
- Sólo señoritas

Debajo, una casilla de verificación con el texto "Acepto estas condiciones",
y un texto pequeño que explica: "Cuando el propietario apruebe, vas a recibir
su WhatsApp".

Más abajo, un bloque destacado con el precio final: "1.000 Bs / mes".

La acción principal abajo: "ENVIAR SOLICITUD". Encima, un botón secundario
con borde y sin relleno: "Cancelar".
```

### 05 Solicitud enviada  (feedback)

```
Pantalla de confirmación de AlquilaMatch, mostrada justo después de enviar una
solicitud de visita.

Centrada: un ícono grande de reloj o de espera, el título "Solicitud enviada"
y un texto explicativo: "El propietario tiene que aprobarla. Te avisamos
apenas responda."

Debajo, una tarjeta pequeña que recuerda a qué anuncio corresponde, con la
foto en miniatura, el título y el precio final.

Una etiqueta de estado que diga "Pendiente".

La acción principal abajo: "VOLVER A LOS RESULTADOS".

Todavía NO se muestra ningún contacto: la solicitud está pendiente.
```

### 06 Contacto liberado  (feedback)

```
Pantalla de AlquilaMatch que se muestra cuando el propietario APROBÓ la
solicitud de visita. Es el único momento de toda la app donde aparece el
contacto.

Centrada arriba: un ícono de verificación, el título "Solicitud aprobada" y
el texto "Ya podés coordinar la visita".

Debajo, una tarjeta destacada con el contacto recién liberado: el nombre del
propietario y su número de WhatsApp (70011122), con un ícono de WhatsApp.

Debajo, la tarjeta del anuncio con foto en miniatura, título y precio final.

La acción principal abajo, en verde de WhatsApp: "ABRIR WHATSAPP".

Un texto pequeño al pie: "Coordiná la visita por WhatsApp".
```

---

## Flujo 1 — El propietario que publica

### 01 Ingresar

```
Pantalla de inicio de sesión de AlquilaMatch. Sobria y centrada verticalmente.

El nombre "AlquilaMatch" como título, y debajo el lema "Alquiler con las
condiciones por delante". Un campo "Usuario" con ícono de persona y un campo
"Contraseña" con ícono de candado y un ojito para revelarla.

La acción principal: "ENTRAR". Debajo, un enlace de texto: "No tengo cuenta".
```

### 02 Crear cuenta

```
Pantalla de registro de AlquilaMatch. Lo primero que se elige es el rol.

Arriba, el título "Qué vas a hacer en la app" y dos tarjetas grandes
seleccionables, una debajo de la otra:
- "Busco dónde alquilar" — con ícono de lupa y el texto "Filtrás por precio
  final, mascotas y minutos caminando a la UAGRM."
- "Quiero publicar" — con ícono de casa y el texto "Publicás una vez con las
  condiciones por delante y dejás de repetirte por WhatsApp."

La segunda está seleccionada, con borde destacado y una tilde.

Debajo: campos de "Usuario", "Contraseña" y "WhatsApp". El de WhatsApp lleva
un texto de ayuda: "No aparece en tus anuncios. Se libera sólo cuando aprobás
una visita."

La acción principal: "CREAR CUENTA".
```

### 03 Inicio del propietario

```
Pantalla de inicio de AlquilaMatch para un usuario propietario.

Arriba, una tarjeta de perfil con avatar circular, el nombre "marta", el rol
"Propietario", y debajo una línea con ícono de candado: "Tu WhatsApp está
oculto en los anuncios".

Debajo, tres tarjetas de módulo en lista vertical, cada una con ícono a la
izquierda, título, descripción y una flecha a la derecha:
- "Publicar anuncio" — "Las cuatro condiciones de descarte, la ubicación por
  GPS y las fotos con fecha."
- "Mis anuncios" — "Marcar Ya alquilado en un toque."
- "Gestionar solicitudes" — "Aprobar libera tu contacto, y sólo a esa persona."

En la barra superior, el título "AlquilaMatch" y un ícono de cerrar sesión.
```

### 04 Publicar

```
Formulario "Publicar" de AlquilaMatch, dividido en secciones numeradas, con
desplazamiento vertical.

"1. Qué estás alquilando": un selector segmentado de tres opciones
(Habitación, Departamento, Casa) y un campo "Título del anuncio".

"2. Precio final": un campo "Alquiler mensual" con sufijo "Bs"; tres casillas
de verificación bajo el rótulo "Qué servicios incluye" (Agua, Luz, Internet);
un campo "Cuánto paga aparte por los servicios"; y ABAJO, un bloque destacado
y resaltado que muestra el resultado en vivo: "Precio final — 1.000 Bs".
Ese bloque es lo más importante de la pantalla.

"3. Reglas": un interruptor "Acepto mascotas" y un campo de texto "Otras
condiciones (opcional)".

"4. Ubicación": un botón con borde y ícono de mira: "Usar mi ubicación".

"5. Fotos": un botón con borde e ícono de cámara: "Tomar una foto".

La acción principal abajo: "PUBLICAR". Debajo, un texto pequeño con candado:
"Tu WhatsApp no aparece en el anuncio".
```

### 05 Mis anuncios

```
Pantalla "Mis anuncios" de AlquilaMatch, la lista de publicaciones del
propietario en cualquier estado.

Mostrá dos tarjetas. Cada una tiene el título arriba a la izquierda y una
etiqueta de estado arriba a la derecha ("Disponible" en una, "Ya alquilado"
en la otra, esta última en gris apagado).

Debajo del título, una fila de datos con íconos pequeños: precio final en Bs,
minutos caminando, si acepta mascotas y el tipo de espacio.

Al pie de cada tarjeta, un botón ancho con borde y sin relleno: en la
disponible dice "Marcar Ya alquilado"; en la alquilada, "Volver a publicar".

Abajo a la derecha, un botón flotante con un signo más y la palabra
"Publicar".
```

---

## Después de generar

1. En cada pantalla, usá **Export to Figma**.
2. En Figma, renombrá cada frame con el orden del flujo: `01 Buscar`,
   `02 Resultados`, `03 Anuncio`… como pide la diapositiva 7 de la clase.
3. Separá los dos flujos en dos páginas del archivo.
4. Nombrá el archivo con proyecto y versión: `AlquilaMatch — Wireframes v0.1`.

## Si Stitch te muestra el teléfono igual

Es el error más probable, porque va contra lo que hacen todas las apps de
alquiler. Corregí con este prompt de ajuste sobre la pantalla generada:

```
Quitá cualquier número de teléfono, WhatsApp, botón de llamar o de chatear de
esta pantalla. El contacto del propietario no debe aparecer en ningún lugar
del anuncio. En su lugar poné un recuadro informativo que diga "El contacto se
libera cuando el propietario aprueba tu solicitud".
```
