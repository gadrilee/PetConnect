# Persona v0.1 — El propietario

**Proyecto:** AlquilaMatch — app móvil de alquiler con contacto filtrado
**Integrantes:** Gabriel Mamani Sandoval, Daniel Joaquin Mamani Peña
**Base:** Brief v0.2.0 + `research/evidencias.md` (sección B, Ev. 7-11)
**Fecha:** 20/08/2026

> **Usuario seleccionado: el propietario que publica.** Es el lado de la oferta: sin anuncios cargados no hay nada que buscar, por eso arrancamos por acá.
> La inquilina que busca es el otro actor y se documentará en la v0.2. Ambas personas conviven — la app no funciona si falta cualquiera de las dos.

---

**Nombre y situación:** Marta, dueña de una casa cerca de la UAGRM con cuatro habitaciones que alquila a estudiantes. No es inmobiliaria: administra el alquiler en sus ratos libres, desde el WhatsApp del celular. Publica en tres grupos de Facebook porque es gratis y es donde está la gente.

**Objetivo:** Llenar las habitaciones vacías antes de que arranque el semestre, sin pasarse el día contestando mensajes.

**Dificultad:** Le escriben veinte personas y a quince les repite lo mismo — el precio, que no acepta mascotas, que es sólo para señoritas. Cuando ya alquiló, los mensajes siguen llegando por semanas porque el anuncio no muere y actualizar en tres grupos es un trabajo aparte. No pone su número en la publicación para no recibir cualquier cosa, pero sin número nadie la contacta. Y cuando por fin coordina una visita, a veces la persona no llega y ella espera una hora en la casa.

**Necesidad:** Publicar **una sola vez** con las condiciones por delante, que el anuncio filtre solo, decidir a quién le da su contacto, y apagarlo en un toque cuando ya alquiló.

---

## El riesgo de diseño que trae esta persona

Marta es quien **paga el costo** del producto. Los campos obligatorios que le pedimos —precio final, mascotas, ubicación por GPS, fotos con fecha— le agregan trabajo justo en el momento en que ya está apurada. El beneficio que recibe a cambio (dejar de repetirse) llega **después**, cuando el anuncio ya está publicado.

Esa asimetría entre costo inmediato y beneficio diferido es la principal amenaza de abandono del producto, y el diseño tiene que atacarla explícitamente: si el formulario no le comunica *"declarar esto te evita quince mensajes"* mientras lo está llenando, lo va a leer como fricción y va a abandonar la publicación a medias.

## Preguntas abiertas

Datos que no aparecen en la evidencia y que por eso quedan como pregunta, no como afirmación:

- ¿Cuántos campos obligatorios tolera antes de abandonar la publicación a medias?
- ¿Acepta que su WhatsApp quede oculto, o eso le hace sentir que pierde clientes?
- ¿Está dispuesta a publicar **desde el inmueble** con el celular, o prefiere hacerlo después con calma aunque las fotos queden viejas?
- ¿Qué la motiva a marcar "Ya alquilado" si ella ya consiguió lo que quería?
- ¿Con qué frecuencia se le desocupa una habitación? ¿Publica una por una o todas juntas?
- ¿Dejaría Facebook, o la app tendría que convivir con sus grupos?
- ¿Qué hace hoy cuando alguien no llega a la visita?

## Trazabilidad

| Dato de la persona | Evidencia |
|---|---|
| Alquila cuatro habitaciones a estudiantes | Ev. 7 |
| Repite lo mismo a quince de veinte personas | Ev. 7 |
| Filtra por precio, mascotas y "sólo señoritas" | Ev. 7 |
| Los mensajes siguen llegando después de alquilar | Ev. 8 |
| No pone su número, pero sin número nadie contacta | Ev. 9 |
| Coordinó una visita y la persona no llegó | Ev. 10 |
| Publica en tres grupos y actualiza en los tres | Ev. 11 |
| Administra desde WhatsApp, en sus ratos libres | Brief v0.2.0 §2 |
