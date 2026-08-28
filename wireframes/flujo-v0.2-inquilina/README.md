# Wireframes — Flujo v0.2 · Andrea, la inquilina

**Integrantes:** Gabriel Mamani Sandoval, Daniel Joaquin Mamani Peña
**Flujo:** [`flujo/flujo-v0.2.md`](../../flujo/flujo-v0.2.md) · **Reglas de dibujo:** [`_lenguaje-visual.md`](../_lenguaje-visual.md)

Seis pantallas, 360 × 800, escala de grises. Cada `.svg` es un frame de Figma:
se arrastra al archivo y entra con capas, textos editables y formas reales, no
como imagen.

## Las pantallas

| Frame en Figma | Archivo | Rol en la clase | Paso del flujo |
|---|---|---|---|
| `01 Buscar` | `01-buscar.svg` | Contenido | 1 — pone sus filtros |
| `02 Resultados` | `02-resultados.svg` | Contenido | 2 — ve la lista por cercanía |
| `03 Anuncio` | `03-anuncio.svg` | Contenido | 3 — **el momento de descarte** |
| `04 Solicitar visita` | `04-solicitar-visita.svg` | Acción | 4 — acepta las condiciones |
| `05 Solicitud enviada` | `05-solicitud-enviada.svg` | Feedback | 5 — queda pendiente |
| `06 Contacto liberado` | `06-contacto-liberado.svg` | Feedback | 6 y 7 — se libera el WhatsApp |

Entre la 05 y la 06 va el paso amarillo del flujo: **el propietario aprueba**.
No es una pantalla de Andrea, y por eso no se dibuja.

## Cómo se cumplen las tres reglas

**1 · Contenido.** Las barras grises son relleno, pero los cuatro datos de
descarte van con texto real en las seis pantallas: precio final, minutos
caminando, mascotas y tipo. Son el producto; abstraerlos escondería justo lo
que hay que evaluar.

**2 · Acción.** Una sola forma rellena de `#4A4A4A` por pantalla. *Cancelar*,
*Ajustar filtros* y *Volver a los resultados* van sin relleno, con trazo.

> `02 Resultados` es la excepción deliberada: en una lista la acción principal
> es abrir una tarjeta, no un botón. Se marca con el chevron `›` y con la nota
> al pie. Si hubiera un botón oscuro abajo competiría con las cuatro tarjetas.

**3 · Feedback.** El flujo termina en dos pantallas que dicen qué ocurrió: la
05 muestra *Pendiente* y qué falta; la 06 muestra *Aprobada* y da la salida.

## La regla del contacto

El teléfono aparece **una sola vez en las seis pantallas**, en la `06`, después
de que el propietario aprobó. Las cinco anteriores lo dicen explícitamente en
lugar de simplemente omitirlo: la ausencia se explica, no se disimula. Ese
recuadro es el corazón del producto — si el contacto se filtra a la `02` o a la
`03`, la app vuelve a ser un grupo de Facebook.

## Importar a Figma

1. **Nuevo archivo de diseño**, nombrarlo `AlquilaMatch — Wireframes v0.2`.
2. Crear dos páginas: `Flujo 1 — Propietario` y `Flujo 2 — Inquilina`.
3. En la página del flujo 2, arrastrar los seis `.svg` de golpe.
4. Cada uno entra como grupo. Seleccionarlo y `Ctrl/Cmd + Alt + G` para
   convertirlo en **frame**, o pegarlo dentro de un frame *Android Large*
   (360 × 800) ya creado.
5. Renombrar los frames con el orden del flujo: `01 Buscar`, `02 Resultados`,
   `03 Anuncio`, `04 Solicitar visita`, `05 Solicitud enviada`,
   `06 Contacto liberado`.
6. Acomodarlos en fila, de izquierda a derecha, en el orden del flujo.

**Todavía no conectar nada.** Primero se ordena; la interacción prototipada es
la etapa siguiente (diapositiva 7, punto 04).

### Si querés mantener los colores editables

Al importar, Figma trae cada relleno como valor suelto. Para poder cambiar el
gris de todas las pantallas de un toque, crear estos estilos y aplicarlos:

| Estilo | Valor | Dónde se usa |
|---|---|---|
| `wf/accion` | `#4A4A4A` | El botón principal |
| `wf/texto` | `#3A3A3A` | Texto real |
| `wf/texto-suave` | `#8A8A8A` | Rótulos y notas |
| `wf/relleno-fuerte` | `#9A9A9A` | Barras de título |
| `wf/relleno-suave` | `#C9C9C9` | Barras de párrafo |
| `wf/trazo` | `#BDBDBD` | Cajas y campos |
| `wf/imagen` | `#E8E8E8` | Placeholders de foto |

## Pendiente de decidir

- **El precio de `03 Anuncio` dice 1.000 Bs**, pero el filtro de Andrea es
  800 Bs y el resto del flujo (04, 05, 06) usa 800. Hay que igualar los dos:
  o el anuncio baja a 800, o el filtro sube.
- **El botón de la `06` va en gris**, no en el verde de WhatsApp. En wireframe
  no se toman decisiones de color; el verde entra recién en el mockup.
- **Caminos alternos de la v0.3:** sin resultados, solicitud rechazada, sin
  respuesta, y anuncio marcado *Ya alquilado* mientras ella espera.
