# Auditoría de accesibilidad — Clase 10

**Análisis sobre la página que realmente hicimos**
Integrantes: Gabriel Mamani Sandoval · Daniel Joaquin Mamani Peña
Fecha: 15/09/2026

> Regla de la clase: el resultado del scan es evidencia de una revisión, no una
> nota ni un certificado. Por eso este documento guarda qué se corrió, sobre
> qué versión, qué se leyó, qué se cambió (en Figma y en código) y qué pasó al
> repetir.

---

## 1. Ejecutar

| | |
|---|---|
| Fecha y hora | 15/09/2026 21:26 (UTC-4) — `fetchTime` del reporte `2026-09-16T01:26:16Z` |
| Commit auditado | `7c4ffec` en la rama `feat/figma-espejo-flutter` (PR #3) |
| URL | `http://localhost:8080` — la app Flutter corriendo en web (`flutter run -d web-server`) contra el backend local en `:8000` |
| Pantalla auditada | `01 Ingresar` (login) para Lighthouse y la prueba de teclado; el sistema de color completo para el contraste |
| Archivo de Figma | [`kAU2JWOHr8JluthuoakVzw`](https://www.figma.com/design/kAU2JWOHr8JluthuoakVzw), página *Sistema visual* (variables de la colección *Tokens*) |

Herramientas:

1. **Lighthouse** (Chrome DevTools → Lighthouse → Accessibility, modo
   navegación, dispositivo *mobile*). Reporte guardado en
   [`accesibilidad/lighthouse/antes/report.html`](accesibilidad/lighthouse/antes/report.html).
2. **WAVE** (extensión de Chrome, sobre la misma URL local). Además, como
   tercera herramienta automática, las *accessibility guidelines* de
   `flutter_test` (`textContrastGuideline`, `androidTapTargetGuideline`,
   `labeledTapTargetGuideline`), que revisan el árbol de semántica real de cada
   pantalla — incluso las que están detrás del login.
3. **Figma**: contraste calculado (fórmula WCAG 2.x de luminancia relativa)
   sobre **cada par real** de color de los componentes, con los valores de las
   variables de *Tokens* — que son los mismos que `AppColors` en el código.
4. **Prueba manual del flujo**: recorrido con teclado (Tab), zoom 200 %
   (viewport 400 × 520) y lectura del orden de foco, sobre la app en web.

---

## 2. Leer

### 2.1 Lighthouse: 100 que no dice nada

Puntaje **Accesibilidad 100**, pero de las 76 auditorías de la categoría
**49 quedaron "no aplicable"**, 10 son manuales y sólo 17 corrieron (todas de
atributos ARIA, título, idioma y viewport del `index.html`). Flutter web dibuja
la interfaz en un `<canvas>` y **no activa el árbol de semántica hasta que
alguien toca el botón invisible "Enable accessibility"**: para el scanner no
hay textos, botones, campos ni colores que revisar.

| Elemento | Problema | Criterio | Impacto |
|---|---|---|---|
| Toda la app en web | El árbol de semántica no está activo; lectores de pantalla y scanners no ven la interfaz | WCAG 4.1.2 Nombre, función, valor · 1.3.1 Información y relaciones | Una persona con lector de pantalla no puede usar la app en web; el 100 de Lighthouse es falso |
| `index.html` | Sin `robots.txt`, avisos de API obsoleta en consola (Best practices 77, SEO 91) | — | Fuera del alcance de accesibilidad; se anota como contexto |

**WAVE** dice lo mismo desde otro ángulo: **0 errores y 0 errores de
contraste**, 2 alertas (*No heading structure*, *No page regions*), 1
característica (idioma `en-US`) y 7 ítems ARIA. Todo lo que encontró es del
`index.html` y del botón oculto `aria-label="Enable accessibility"`: ni un
campo, ni un botón, ni un texto de la app. Y el idioma declarado es inglés
para una app en español (WCAG 3.1.1).

### 2.2 Contraste: el sistema de color, par por par

Fondo blanco salvo que se indique. Umbral AA: **4.5:1 texto**, **3:1**
íconos con significado, bordes de controles y texto grande.

| Par de color (Figma = código) | Ratio | AA | Dónde se usa |
|---|---|---|---|
| `Text` #3A3A3A sobre blanco | 11.37 | ✅ | texto principal |
| `Text 70%` (#757575) sobre blanco | 4.61 | ✅ | texto secundario |
| `Text 60%` (#898989) sobre blanco | 3.50 | ❌ texto / ✅ ícono | etiquetas y detalles de tarjetas, rol en Tarjeta de perfil |
| `Text 50%` (#9C9C9C) sobre blanco | 2.75 | ❌ | nota "Tu WhatsApp no aparece", íconos de filas, ícono neutro |
| `Text 40%` (#B0B0B0) sobre blanco | 2.17 | ❌ | chevrons de tarjetas, placeholder |
| `Text 38%` borde del campo | 2.07 | ❌ borde | Campo de texto en reposo |
| `Primary` #1B6B50 sobre blanco | 6.43 | ✅ | enlaces, precio |
| Blanco sobre `Primary` | 6.43 | ✅ | Botón principal |
| `Secondary` #52796F sobre blanco | 4.86 | ✅ | — |
| `Success` #2E8B57 sobre blanco | 4.25 | ❌ texto | texto de éxito |
| `Success` sobre `Success 10%` / `12%` | 3.75 / 3.67 | ❌ | Feedback éxito, Etiqueta *Aprobada* |
| `Error` #D92929 sobre blanco | 4.88 | ✅ | texto de error bajo campos |
| `Error` sobre `Error 8%` / `12%` | 4.33 / 4.05 | ❌ | Feedback error, Etiqueta *Rechazada* |
| `Warning` #C77700 sobre blanco | 3.46 | ❌ | — |
| `Warning` sobre `Warning 12%` | 3.04 | ❌ | Feedback advertencia ("Falta marcar la ubicación") |
| `Text 70%` sobre `Text 5%` / `6%` | 4.23 / 4.15 | ❌ | Resumen de búsqueda, Pastilla neutra, etiqueta de Precio final resumen |
| `Text 38%` sobre `Text 12%` | 1.68 | exento | botón deshabilitado (control inactivo, WCAG 1.4.3 lo exceptúa) |
| Blanco sobre `Primary 75%` | 3.71 | exento | botón cargando (inactivo mientras espera) |

Lectura: **el texto principal y el botón principal están bien; falla todo lo
"secundario"** (grises al 40–60 %) y los tres colores de estado sobre sus
propios tintes. La causa es una sola: los valores de los tokens.

| Elemento | Problema | Criterio | Impacto |
|---|---|---|---|
| Texto secundario `Text 50/60%` | 2.75–3.5:1 | WCAG 1.4.3 Contraste mínimo | Con poca luz o baja visión no se lee el detalle de las tarjetas ni las notas |
| Feedback y Etiqueta de estado (éxito, error, advertencia) | 3.0–4.3:1 sobre el tinte | 1.4.3 | Justo los mensajes que dicen qué pasó son los menos legibles |
| Íconos `Text 40/50%` y borde del campo `Text 38%` | 2.1–2.75:1 | 1.4.11 Contraste no textual | No se distingue dónde termina el campo ni que la flecha es tocable |

### 2.3 Objetivo táctil y nombres

| Elemento | Problema | Criterio | Impacto |
|---|---|---|---|
| Botón de texto (32 px), Casilla (fila de 32), Opción (40), ícono del ojo y del logout (24) | Objetivo táctil menor a 48 px | WCAG 2.5.8 Tamaño del objetivo · Material 48 dp | Difícil de tocar con precisión, sobre todo en movimiento |
| Ojo de la contraseña, logout, flecha de volver | Sin nombre accesible en español (`MaterialApp` sin localización: los nombres internos salen en inglés) | 4.1.2 · 3.1.1 Idioma | El lector de pantalla anuncia "Back" o nada |

### 2.4 Prueba manual del flujo (antes)

- **Teclado** (login): Tab recorre Usuario → Contraseña → ojo → *No tengo
  cuenta*, con foco visible en los campos (borde verde), el ojo (círculo) y el
  enlace (píldora). **ENTRAR no entra en el recorrido**: `BotonPrincipal`,
  `BotonSecundario` y el `Interruptor` están hechos con `GestureDetector`, que
  no recibe foco. Criterio: WCAG 2.1.1 Teclado · 2.4.7 Foco visible. Impacto:
  sin mouse ni pantalla táctil no se puede entrar a la app.
- **Zoom 200 %** (viewport 400 × 520): la pantalla no desborda ni corta
  contenido; el cuerpo hace scroll. ✅ (WCAG 1.4.10 Reflow)
- **Lectura**: el orden visual y el de foco coinciden; las etiquetas de los
  campos están arriba del campo y los mensajes de error debajo, como en Figma.

---

## 3. Corregir

_(se completa con lo aplicado en Figma y en código)_

---

## 4. Repetir

_(se completa con el segundo scan y la prueba manual final)_
