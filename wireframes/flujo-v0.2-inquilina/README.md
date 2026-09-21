# Pantallas — Flujo v0.2 · Andrea busca y pide la visita

**Integrantes:** Gabriel Mamani Sandoval, Daniel Joaquin Mamani Peña
**Flujo:** [`flujo/flujo-v0.2.md`](../../flujo/flujo-v0.2.md) · **Figma:** página *Flujos*, sección *Flujo v0.3 — Inquilina*

Doce pantallas de 440 × 956, exportadas de la fila **Principal** del archivo de
Figma. Los caminos completos (*Happy Path*) y los errores (*Validaciones*) están
en las otras dos filas de la misma sección.

![Las doce pantallas del flujo](flujo-completo.png)

| # | Archivo | Momento de la tarea |
|---|---|---|
| 01 | [`01 Inicio.png`](01%20Inicio.png) | Entra y elige qué va a hacer |
| 02 | [`02 Buscar.png`](02%20Buscar.png) | Pone sus filtros: precio, tipo, mascotas, minutos |
| 03 | [`03 Resultados.png`](03%20Resultados.png) | Ve los resultados ordenados por cercanía |
| 04 | [`04 Sin resultados.png`](04%20Sin%20resultados.png) | Ningún cuarto cumple: lo dice y sugiere ampliar |
| 05 | [`05 Anuncio.png`](05%20Anuncio.png) | **Decide si le sirve o lo descarta** |
| 06 | [`06 Solicitar visita.png`](06%20Solicitar%20visita.png) | Acepta las condiciones y pide la visita |
| 07 | [`07 Solicitud enviada.png`](07%20Solicitud%20enviada.png) | Queda a la espera de la respuesta |
| 08 | [`08 Estado de solicitudes.png`](08%20Estado%20de%20solicitudes.png) | Vuelve desde el Inicio a ver en qué quedó cada una |
| 09 | [`09 Contacto liberado.png`](09%20Contacto%20liberado.png) | El propietario aprobó: aparece el contacto |
| 10 | [`10 Solicitud rechazada.png`](10%20Solicitud%20rechazada.png) | El propietario dijo que no |
| 11 | [`11 Solicitud cerrada.png`](11%20Solicitud%20cerrada.png) | El cuarto se alquiló mientras esperaba |
| 12 | [`12 Sin solicitudes.png`](12%20Sin%20solicitudes.png) | Todavía no pidió ninguna visita |

Cada pantalla que no tiene nada para mostrar va al lado de la que la origina:
*Sin resultados* después de *Resultados*, y *Sin solicitudes* al final de lo que
sale de *Estado de solicitudes*.

## Cómo leer la 05

Es la pantalla que decide el producto, y ya incluye la corrección que salió de
la prueba con una usuaria (ver [`docs/decision-clase-05.md`](../../docs/decision-clase-05.md)):
el **precio final** domina, los servicios incluidos van pegados a él —también el
que *no* está incluido, que fue lo que obligó a la usuaria a preguntar *"¿cuánto
es con luz?"*— y **no hay ningún contacto**: el teléfono recién aparece en la 09,
después de la aprobación.

## Cómo leer la 08

Es la puerta de *Estado de solicitudes*, el segundo módulo del Inicio. Cada
tarjeta dice qué anuncio, cuándo la mandó y **en qué quedó**, con la misma
etiqueta de color que ve Marta del otro lado. Las más nuevas van primero, y
tocar una abre su estado: la 07 si sigue pendiente, la 09, la 10 o la 11 si ya
se resolvió. Sin solicitudes, la 12 lo dice en vez de mostrar una lista vacía.

## La 11, nueva con el flujo v0.5

Antes, si Marta marcaba el cuarto como alquilado, la solicitud de Andrea quedaba
*pendiente* para siempre: la evidencia 5 (*"uno ya estaba alquilado"*) pasando
adentro de la app. Ahora se cierra sola y la pantalla lo dice. La etiqueta es
**neutra, no roja**: nadie la rechazó, el cuarto se alquiló.

> **Numeración.** En el repositorio este es el flujo v0.2. En Figma está tercero,
> porque ahí se ordenan como se viven.
