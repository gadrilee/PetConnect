# Pantallas — Flujo v0.1 · Marta publica

**Integrantes:** Gabriel Mamani Sandoval, Daniel Joaquin Mamani Peña
**Flujo:** [`flujo/flujo-v0.1.md`](../../flujo/flujo-v0.1.md) · **Figma:** página *Flujos*, sección *Flujo v0.2 — Propietario*

Tres pantallas de 440 × 956, exportadas de la fila **Principal** del archivo de
Figma: cada pantalla del flujo, en su estado normal. Los caminos completos
(*Happy Path*) y los errores (*Validaciones*) están en las otras dos filas de la
misma sección.

![Las tres pantallas del flujo](flujo-completo.png)

| # | Archivo | Momento de la tarea |
|---|---|---|
| 01 | [`01 Inicio - propietaria.png`](01%20Inicio%20-%20propietaria.png) | Entra y ve sus tres módulos |
| 02 | [`02 Publicar.png`](02%20Publicar.png) | **Declara las condiciones de descarte** |
| 03 | [`03 Mis anuncios.png`](03%20Mis%20anuncios.png) | Ve sus anuncios y su estado |

## Cómo leer la 02

Es la pantalla donde el producto se juega la partida, dividida en secciones
numeradas:

- **El precio final** es el bloque más fuerte de la pantalla: suma el alquiler y
  lo que se paga aparte (800 + 300 = 1.100 Bs). Es el criterio de descarte n.º 1
  de la inquilina, y la obliga a Marta a sincerar el precio.
- **"Cuánto paga aparte por los servicios"** aparece porque hay un servicio sin
  incluir. El backend no deja publicar con servicios afuera y costo en cero:
  publicar sólo el alquiler es lo que hoy hace perder viajes.
- **Ubicación y fotos** se resuelven con el GPS y la cámara del teléfono estando
  en el inmueble: es el argumento de por qué el producto es móvil.
- Debajo de *Publicar*, la promesa: **su WhatsApp no aparece en el anuncio**.

## La relación con los otros flujos

Es el lado de la oferta: hasta que Marta no publica, no hay nada que buscar
([flujo v0.2](../flujo-v0.2-inquilina/README.md)). *Mis anuncios* es donde
arranca el [flujo v0.5](../flujo-v0.5-cerrar-anuncio/README.md): marcar el cuarto
como alquilado cuando consigue inquilino.

> **Numeración.** En el repositorio este es el flujo v0.1, el primero que se
> diseñó. En Figma está segundo, porque ahí se ordenan como se viven.
