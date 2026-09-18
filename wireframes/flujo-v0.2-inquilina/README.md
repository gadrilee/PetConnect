# Pantallas — Flujo v0.2 · Andrea busca y pide la visita

**Integrantes:** Gabriel Mamani Sandoval, Daniel Joaquin Mamani Peña
**Flujo:** [`flujo/flujo-v0.2.md`](../../flujo/flujo-v0.2.md) · **Figma:** página *Flujos*, sección *Flujo v0.3 — Inquilina*

Ocho pantallas de 440 × 956, exportadas de la fila **Principal** del archivo de
Figma. Los caminos completos (*Happy Path*) y los errores (*Validaciones*) están
en las otras dos filas de la misma sección.

![Las ocho pantallas del flujo](flujo-completo.png)

| # | Archivo | Momento de la tarea |
|---|---|---|
| 01 | [`01 Inicio.png`](01%20Inicio.png) | Entra y elige qué va a hacer |
| 02 | [`02 Buscar.png`](02%20Buscar.png) | Pone sus filtros: precio, tipo, mascotas, minutos |
| 03 | [`03 Resultados.png`](03%20Resultados.png) | Ve los resultados ordenados por cercanía |
| 04 | [`04 Anuncio.png`](04%20Anuncio.png) | **Decide si le sirve o lo descarta** |
| 05 | [`05 Solicitar visita.png`](05%20Solicitar%20visita.png) | Acepta las condiciones y pide la visita |
| 06 | [`06 Solicitud enviada.png`](06%20Solicitud%20enviada.png) | Queda a la espera de la respuesta |
| 07 | [`07 Contacto liberado.png`](07%20Contacto%20liberado.png) | El propietario aprobó: aparece el contacto |
| 08 | [`08 Solicitud cerrada.png`](08%20Solicitud%20cerrada.png) | El cuarto se alquiló mientras esperaba |

## Cómo leer la 04

Es la pantalla que decide el producto, y ya incluye la corrección que salió de
la prueba con una usuaria (ver [`docs/decision-clase-05.md`](../../docs/decision-clase-05.md)):
el **precio final** domina, los servicios incluidos van pegados a él —también el
que *no* está incluido, que fue lo que obligó a la usuaria a preguntar *"¿cuánto
es con luz?"*— y **no hay ningún contacto**: el teléfono recién aparece en la 07,
después de la aprobación.

## La 08, nueva con el flujo v0.5

Antes, si Marta marcaba el cuarto como alquilado, la solicitud de Andrea quedaba
*pendiente* para siempre: la evidencia 5 (*"uno ya estaba alquilado"*) pasando
adentro de la app. Ahora se cierra sola y la pantalla lo dice. La etiqueta es
**neutra, no roja**: nadie la rechazó, el cuarto se alquiló.

> **Numeración.** En el repositorio este es el flujo v0.2. En Figma está tercero,
> porque ahí se ordenan como se viven.
