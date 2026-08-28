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

> ⚠️ **Esta sección hay que completarla probando con una persona real.**
> No se puede inventar: la clase pide observar, no suponer.

**Cómo hacerlo** (10 minutos): mostrale la pantalla a alguien que no conozca el
proyecto y pedile que complete la tarea **sin explicarle nada**:

> *"Estás buscando cuarto. Mirá esta pantalla y decime si este te sirve o no,
> y por qué."*

Observá y anotá, sin intervenir:

- [ ] ¿Qué dato miró primero?
- [ ] ¿Reconoció el precio final, o preguntó cuánto costaba?
- [ ] ¿Entendió que el contacto aparece después de solicitar?
- [ ] ¿Distinguió la acción principal?
- [ ] ¿Buscó algo en un lugar donde no estaba?

**Observación registrada:**

```
(Ejemplo del formato que pide la clase:
 "Buscó la fecha debajo de la lista de cuidados.")

→ Escribir acá lo que hizo la persona, no lo que opinó.
```

---

## SIGUIENTE

**Qué conservamos:** la agrupación de las cuatro condiciones y la escala de
espaciado. La escala ya está en el tema, así que aplicarla al resto de las
pantallas es reemplazar números por constantes.

**Qué corregimos:** el resto de las pantallas del flujo todavía usa valores
sueltos. `buscar_screen.dart`, `resultados_screen.dart` y
`solicitar_visita_screen.dart` son las siguientes.

**Qué investigamos:** si el precio destacado cambia el comportamiento. La
hipótesis es que la persona decide más rápido, pero **es una hipótesis hasta
que la prueba con usuarios la confirme o la desmienta**.
