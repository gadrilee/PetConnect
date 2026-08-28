# Decisión de diseño — Clase 5

**Jerarquía, layout y espaciado**
Integrantes: Gabriel Mamani Sandoval · Daniel Joaquin Mamani Peña
Fecha: 27/08/2026

---

## Pantalla elegida

**`03 Anuncio`** del flujo v0.2 (la inquilina que busca).

**El momento:** *La persona está **decidiendo** si este cuarto le sirve o lo
descarta.* Es el paso 3 del `flujo/flujo-v0.2.md` y el que el propio documento
marca como el momento clave: si no le sirve, vuelve a los resultados sin haber
gastado un viaje.

- Wireframe: [`03 Anuncio`](https://www.figma.com/design/kAU2JWOHr8JluthuoakVzw)
- Código: `mobile/lib/features/buscar/presentation/anuncio_screen.dart`

---

## La auditoría, antes de mover nada

Siguiendo los cuatro pasos de la actividad:

### 1. Nombrar el momento
La persona está **decidiendo si descarta**. No está navegando ni comparando:
tiene un anuncio abierto y necesita responder una sola pregunta.

### 2. Ordenar prioridades

| | Qué | Estaba bien? |
|---|---|---|
| **1. Orientar** | Qué inmueble estoy viendo | ✅ el título estaba arriba |
| **2. Informar** | Las cuatro condiciones de descarte | ❌ ver abajo |
| **3. Actuar** | Solicitar la visita | ✅ una sola acción, fija abajo |

### 3. Detectar grupos
Las cuatro condiciones **se leen como una sola decisión**, pero estaban
sueltas: cuatro filas idénticas separadas por 10 px, mientras que la
separación con el título era de 16 px. Casi la misma distancia dentro del grupo
que fuera de él, así que **no se veía que formaran un grupo**.

### 4. Medir el espaciado
Conté los valores de espaciado del archivo:

```
4, 8, 10, 10, 10, 12, 14, 14, 16, 16, 20, 20, 20, 20, 24, 32
```

**13 de 18 estaban fuera de una escala de 8** (los 10, 12, 14 y 20).

---

## ANTES

Tres problemas concretos, en orden de gravedad:

1. **Jerarquía.** El precio final es el **criterio de descarte n.º 1** según
   `brief/brief-v0.2.0.md` y la evidencia 1 ("eran 300 bolivianos más"). Pero
   en pantalla tenía **exactamente el mismo tamaño, color y peso** que los
   otros tres datos. El dato que decide no se distinguía del que acompaña.

2. **Layout.** Las cuatro condiciones no formaban grupo. Separación interna de
   10 px contra 16 px externa: el ojo no podía agruparlas.

3. **Espaciado.** Sin escala. 10, 12, 14 y 20 mezclados sin criterio.

---

## CAMBIO

### En el código

**Se creó la escala** en `mobile/lib/core/theme.dart`, con la regla de cuándo
usar cada valor escrita en el propio código:

```dart
class Espacio {
  static const double xs = 4;   // medio paso, dentro de un elemento
  static const double sm = 8;   // cosas que se leen juntas
  static const double md = 16;  // contenido relacionado
  static const double lg = 24;  // entre grupos
  static const double xl = 32;  // entre momentos de la tarea
}
```

**Se agruparon las cuatro condiciones** dentro de un contenedor con fondo
propio, y se les dio jerarquía interna:

```dart
// ═══ 2. INFORMAR — las cuatro condiciones de descarte ═══
//
// Van juntas dentro de un mismo contenedor porque se leen como
// una sola decision: "¿me sirve o lo descarto?".
Container(
  padding: const EdgeInsets.all(Espacio.md),
  decoration: BoxDecoration(
    color: esquema.surfaceContainerHighest.withValues(alpha: 0.4),
    borderRadius: BorderRadius.circular(12),
  ),
  child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      // El precio final es el criterio de descarte n.º 1 del
      // brief, asi que se lee primero y con mas peso.
      Text('Precio final', style: texto.labelSmall?.copyWith(...)),
      const SizedBox(height: Espacio.xs),
      Text('${anuncio.precioFinal} Bs / mes',
          style: texto.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
      // ...
```

**El subtítulo del precio dejó de mentir.** Antes decía `todo incluido` fijo,
sin importar los servicios reales. Ahora se deriva:

```dart
Text(
  servicios.length == 3
      ? 'todo incluido'
      : servicios.isEmpty
          ? 'sin servicios incluidos'
          : 'incluye ${servicios.join(', ').toLowerCase()}',
  ...
)
```

Ese detalle importa: mostrar "todo incluido" cuando no lo está es exactamente
el problema de la evidencia 1 que el producto vino a resolver.

### En Figma

El frame `03 Anuncio` se rehízo con la misma estructura: etiqueta `PRECIO
FINAL`, el monto en 24 px negrita, los otros tres datos separados 24 px dentro
del mismo contenedor gris, y una sola acción oscura abajo.

### Resultado medible

| | Antes | Después |
|---|---|---|
| Valores fuera de la escala de 8 | **13 de 18** | **0** |
| Tamaño del precio final | igual que los demás (13 px) | **24 px, negrita** |
| Las 4 condiciones | 4 filas sueltas | **1 grupo con contenedor** |
| Separación dentro del grupo | 10 px | 24 px (`lg`) |
| Separación entre grupos | 16 px | 24 px (`lg`) |

---

## DESPUÉS

**Prueba realizada:** 27/08/2026, con una persona que no conocía el proyecto
(hermana de un integrante). Se le mostró la pantalla `03 Anuncio` sin explicarle
nada y se le pidió que dijera si el cuarto le servía o no.

### Lo que hizo

| Observación | Qué revela |
|---|---|
| **Miró primero la foto**, no el precio | La jerarquía que diseñamos empieza en el título, pero la foto ocupa 176 px arriba de todo y gana la atención primero |
| **Preguntó: _"¿cuánto es con luz?"_** | Vio el precio destacado y **aun así tuvo que preguntar qué cubre** |

### Lo que esto significa

**La segunda observación contradice nuestra hipótesis.** Habíamos supuesto que
destacar el precio final resolvía el criterio de descarte n.º 1. No lo resolvió:
ella leyó "1.000 Bs / mes" en 24 px negrita y **igual preguntó por la luz**.

El problema es que **el número solo no significa nada**. "1.000 Bs" es ambiguo
hasta saber qué cubre. Le dimos toda la jerarquía a la cifra y dejamos el dato
que la vuelve interpretable —`incluye agua, luz`— como texto chico y gris
debajo. Subordinamos justamente la mitad que responde su pregunta.

Es exactamente la evidencia 1 del brief reapareciendo en otra forma: no basta
con mostrar un precio, hay que hacer inseparable el precio de lo que incluye.

**La primera observación** es más leve pero real: el orden de lectura que
diseñamos (título → datos → acción) no coincide con el orden en que la pantalla
se mira. La foto domina y no forma parte del modelo de prioridades.

---

## SEGUNDA ITERACIÓN — la corrección que salió de la prueba

Implementada el 27/08, después de la observación. **Todavía no fue probada con
usuarios:** es la respuesta a lo que preguntó, no una mejora verificada.

### Qué cambió

**Los servicios se mudaron al lado del precio.** Antes vivían en una sección
aparte, más abajo en la pantalla, bajo el título "Servicios incluidos". Esa
distancia era el problema: el dato que respondía su pregunta existía, pero
estaba lejos de la cifra que la generaba.

**Lo que NO está incluido ahora aparece.** Antes se omitía. Si el internet no
entraba en el precio, simplemente no se mencionaba — y omitirlo es lo que
obliga a preguntar, porque no se distingue "no está incluido" de "no lo
dijeron".

```dart
// ─── Corregido tras la prueba con usuaria (27/08) ───
//
// Ella leyo el precio destacado y IGUAL pregunto "¿cuanto es con luz?".
// El numero solo es ambiguo: no significa nada hasta saber que cubre.
Wrap(
  spacing: Espacio.sm,
  runSpacing: Espacio.xs,
  children: [
    _Servicio(nombre: 'Agua',     incluido: anuncio.serviciosIncluidos['agua'] == true),
    _Servicio(nombre: 'Luz',      incluido: anuncio.serviciosIncluidos['luz'] == true),
    _Servicio(nombre: 'Internet', incluido: anuncio.serviciosIncluidos['internet'] == true),
  ],
),
```

El widget `_Servicio` marca cada uno con un ícono lleno o vacío, y el texto
cambia de `Internet` a `Internet no`. Los tres se ven siempre.

### Cómo se lee ahora

```
PRECIO FINAL
1.000 Bs / mes
● Agua   ● Luz   ○ Internet no
```

La pregunta *"¿cuánto es con luz?"* queda respondida sin que haya que hacerla.

El frame `03 Anuncio` en Figma se actualizó igual, así que wireframe y código
siguen representando la misma pantalla.

### Lo que falta

**Volver a probar.** No sabemos si esto funciona: sabemos que responde la
pregunta que apareció. Puede que la próxima persona pregunte otra cosa, o que
tres indicadores juntos agreguen ruido al bloque del precio. Es una hipótesis
nueva, no una conclusión.

---

## SIGUIENTE

**Qué conservamos.** La agrupación de las cuatro condiciones y la escala de
espaciado: ninguna fue cuestionada por la prueba. La escala ya está en el tema,
así que aplicarla al resto de las pantallas es reemplazar números por
constantes.

**Qué corregimos.** El resto del flujo todavía usa valores sueltos:
`buscar_screen.dart`, `resultados_screen.dart` y `solicitar_visita_screen.dart`
son las siguientes. Y la tarjeta de resultados repite el mismo error que
acabamos de corregir — muestra el precio sin decir qué incluye.

**Qué investigamos.**

1. *Si la corrección funciona.* Segunda prueba con otra persona, mirando si
   pregunta por el precio o pasa directo a decidir.
2. *Si la foto debe seguir arriba.* Ella la miró primero, pero no sabemos si
   eso la ayudó o la distrajo. Un dato de una sola persona no alcanza para
   reordenar la pantalla.

**Lo que aprendimos del método.** Las métricas daban bien —13 valores fuera de
escala pasaron a 0—, el wireframe y el código coincidían, y aun así el problema
seguía ahí. Hizo falta una persona real haciendo una pregunta concreta para
descubrirlo. Ninguna revisión entre nosotros lo habría encontrado.
