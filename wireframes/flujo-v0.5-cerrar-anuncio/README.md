# Pantallas — Flujo v0.5 · Marta cierra el anuncio

**Integrantes:** Gabriel Mamani Sandoval, Daniel Joaquin Mamani Peña
**Flujo:** [`flujo/flujo-v0.5.md`](../../flujo/flujo-v0.5.md) · **Figma:** página *Flujos*, sección *Flujo v0.5 — Cerrar el anuncio*

Cuatro pantallas de 440 × 956, exportadas de la fila **Principal** del archivo de
Figma. Los caminos completos (*Happy Path*) y los errores (*Validaciones*) están
en las otras dos filas de la misma sección.

![Las cuatro pantallas del flujo](flujo-completo.png)

| # | Archivo | Momento de la tarea |
|---|---|---|
| 01 | [`01 Mis anuncios.png`](01%20Mis%20anuncios.png) | Ve sus anuncios, cada uno con su estado |
| 02 | [`02 Ya lo alquilaste.png`](02%20Ya%20lo%20alquilaste.png) | **Antes de cerrar, ve qué va a pasar** |
| 03 | [`03 Ya lo alquilaste - sin pendientes.png`](03%20Ya%20lo%20alquilaste%20-%20sin%20pendientes.png) | Lo mismo sin solicitudes esperando: no se cierra ninguna |
| 04 | [`04 Sin anuncios.png`](04%20Sin%20anuncios.png) | Todavía no publicó nada: el botón la lleva a publicar |

## Cómo leer la 02 y la 03

Son la misma pantalla y aparece siempre, con solicitudes pendientes o sin
ellas: apagar el anuncio es lo que menos se deshace, y el botón tiene que hacer
siempre lo mismo. Lo que cambia es lo que cuenta. Con pendientes (02): se
cierran las que esperaban y a cada persona se le avisa. Sin pendientes (03): lo
dice —*"No tenés solicitudes pendientes: no se cierra ninguna"*—, así ella sabe
que nadie queda colgado.

No pregunta *"¿estás segura?"*: dice qué va a pasar. La pregunta sola no da nada
para decidir; la lista, sí.
