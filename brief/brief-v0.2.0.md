# Brief v0.2.0 — AlquilaMatch: alquiler de habitaciones y departamentos

**Proyecto:** Aplicación móvil de alquiler con contacto filtrado (habitaciones, departamentos y casas)
**Tipo de Proyecto:** Aplicación móvil
**Materia:** Interacción Hombre Computador ELC106-SA
**Integrantes:** Gabriel Mamani Sandoval, Daniel Joaquin Mamani Peña
**Versión:** 0.2.0
**Fecha:** 16/08/2026
**Estado:** Hipótesis revisada — evidencia preliminar simulada, pendiente validación con usuarios reales

> **Nota de honestidad metodológica:** la evidencia de esta versión proviene de entrevistas simuladas con IA, en línea con la modalidad declarada del proyecto (desarrollo asistido con IA). Sirve para ajustar el brief, **no sustituye la validación con usuarios reales**. Las entrevistas reales están planificadas antes de la v0.3 (ver `research/guia-entrevistas.md`).

---

## 1. Problema revisado

En la v0.1 planteamos el problema como "falta de transparencia y de filtros" en el alquiler. Al ordenar la evidencia, el problema se ve más preciso:

**El costo real no está en encontrar anuncios, sino en descubrir demasiado tarde que el anuncio no aplica.**

Los datos que sirven para descartar un inmueble —precio final con servicios, si acepta mascotas, cuánto se camina hasta la universidad, si es habitación compartida— casi nunca están en la publicación. Ambas partes sólo se enteran **después** de haber gastado el recurso caro: el inquilino un traslado de 40 minutos, el propietario una conversación de WhatsApp repetida por décima vez.

Se agrega una dificultad que no habíamos identificado: **los anuncios no mueren**. Una publicación de Facebook sigue recibiendo mensajes semanas después de que el inmueble ya fue alquilado, porque nadie tiene el incentivo ni la forma sencilla de darla de baja.

## 2. Usuario y contexto

**Inquilino — estudiante de la UAGRM (foco principal de la v0.2).**
Estudiante, muchas veces de provincia, con presupuesto ajustado y sin vehículo propio. Busca al inicio de semestre o al vencer su contrato. Se mueve caminando o en micro, por lo que la distancia al campus es una condición de descarte, no un detalle. Busca desde el celular, con datos móviles limitados.

**Propietario / Arrendador.**
Dueño de una casa con habitaciones sueltas o de uno o dos departamentos. No es una inmobiliaria: administra el alquiler en sus ratos libres, desde WhatsApp. Publica en grupos de Facebook porque es gratis y es donde está la gente, y asume el ruido como parte del costo.

Acotamos el contexto a **zonas aledañas a la UAGRM en Santa Cruz de la Sierra**, en temporada de inicio de semestre.

## 3. Evidencia

Evidencia preliminar (simulada, ver nota metodológica). El detalle completo está en `research/evidencias.md`.

- *"Llegué hasta el lugar y recién ahí me dijeron que el precio no incluía agua ni luz. Eran 300 bolivianos más."* — Estudiante, 3er semestre.
- *"Tengo un gato. En el anuncio nunca dice nada de mascotas, así que tengo que preguntar siempre, y la mitad de las veces me dicen que no."* — Estudiante, vive sola.
- *"Decía 'cerca de la U'. Cerca era 25 minutos caminando."* — Estudiante de provincia.
- *"Me escriben veinte personas y a quince les tengo que repetir lo mismo: el precio, que no acepto mascotas, que es sólo para señoritas."* — Propietaria, 4 habitaciones.
- *"El cuarto lo alquilé hace un mes y me siguen escribiendo. Ya ni contesto."* — Propietario, casa compartida.
- *"No pongo mi número en el anuncio porque después te escriben para cualquier cosa, pero si no lo pongo nadie te contacta."* — Propietaria.

### Qué cambió respecto a la v0.1

| v0.1 asumía | La evidencia sugiere |
|---|---|
| El problema es la información incompleta en general | El problema son 4 datos concretos de descarte que faltan siempre |
| El propietario quiere "filtrar inquilinos serios" | El propietario quiere **dejar de repetirse**; el filtro es el medio, no el fin |
| El inquilino busca el mejor lugar | El inquilino busca **descartar rápido** para no perder traslados |
| — (no identificado) | Los anuncios vencidos siguen generando contactos inútiles |

## 4. Insight

> Antes de necesitar un portal con miles de anuncios, verificación de identidad o pagos en línea, ambos lados necesitan una sola cosa: **que las condiciones de descarte sean obligatorias y visibles antes del primer contacto.**

El contacto es el recurso caro para los dos. Hoy se gasta primero y se descarta después. La app debe invertir ese orden.

## 5. Hipótesis revisada

> Si obligamos al propietario a declarar en el formulario las **cuatro condiciones de descarte** (precio final con servicios incluidos, política de mascotas, tipo de espacio y ubicación exacta con minutos caminando al campus), y sólo habilitamos el contacto cuando el inquilino ya vio y aceptó esas condiciones, entonces el inquilino dejará de hacer visitas fallidas y el propietario dejará de responder mensajes que terminan en "no".

### Lo que creemos ahora

- El precio **con servicios incluidos** es el criterio de descarte n.º 1, no el precio a secas.
- "Cerca de la U" debe expresarse en **minutos caminando**, no en distancia ni en nombre de barrio.
- Ocultar el contacto es un beneficio para el propietario, no una fricción — es lo que hoy hace a mano al no publicar su número.
- Marcar "ya alquilado" tiene que costar un solo toque, o no va a pasar.

### Lo que todavía debemos comprobar

- Si el propietario acepta llenar un formulario más largo a cambio de recibir menos mensajes.
- Si el inquilino confía en un anuncio sin poder escribir de inmediato.
- Cuál es realmente la condición de descarte n.º 1 (¿precio, mascotas o distancia?).
- Si una habitación en casa compartida necesita un dato que un departamento entero no: **con quién se comparte**.

## 6. Alcance inicial

**Entra en la primera versión:**

- Cuentas diferenciadas: Inquilino y Propietario.
- **Publicación estructurada** con campos obligatorios de descarte: precio final, qué servicios incluye, acepta mascotas (sí/no), tipo de espacio (habitación / depto / casa) y ubicación.
- **Ubicación tomada del GPS del teléfono** estando en el inmueble, con ajuste manual en el mapa.
- **Fotos tomadas desde la cámara de la app** al momento de publicar, con la fecha de captura visible en el anuncio.
- Cálculo automático de **minutos caminando hasta la UAGRM** a partir de esa ubicación.
- Búsqueda con filtros sobre esas mismas condiciones.
- **Solicitud de Visita**: el contacto del propietario permanece oculto hasta que este aprueba la solicitud.
- **Notificación al inquilino** cuando el propietario aprueba o rechaza (cierra el ciclo sin que tenga que volver a entrar a revisar).
- Estado del anuncio en un toque: *Disponible* / *Ya alquilado*.

**Por qué móvil y no web:** las tres acciones críticas dependen del teléfono — el propietario marca la ubicación **parado en el inmueble** y fotografía **el estado actual** en ese momento (ataca directamente las fotos viejas y el "cerca de la U"), y el inquilino busca en la calle, entre clases, decidiendo si camina hasta ahí. Un formulario web se llena después, desde la memoria, y ahí es donde hoy se cuela la información desactualizada.

## 7. Fuera de alcance

- Pago de alquiler, garantías o depósitos dentro de la app.
- Versión web o de escritorio (la primera versión es sólo móvil).
- Contratos digitales o firma electrónica.
- Chat interno en tiempo real (tras la aprobación se libera el contacto y se continúa por WhatsApp).
- Verificación de identidad con documentos o scoring crediticio del inquilino.
- Reseñas y calificaciones entre usuarios.
- Tours virtuales 360° o planos del inmueble.
- Puntos de interés distintos a la UAGRM (otras universidades, oficinas, colegios).

## 8. Preguntas abiertas

- ¿El propietario acepta que su WhatsApp quede oculto, o eso le hace sentir que pierde clientes?
- ¿Cuántos campos obligatorios tolera antes de abandonar la publicación a medias?
- ¿"Minutos caminando" se entiende mejor que cuadras, o los estudiantes piensan en cuadras?
- ¿Quién marca el anuncio como alquilado, y qué lo motiva a hacerlo si ya consiguió inquilino?
- Para habitaciones en casa compartida, ¿saber con quién se comparte pesa más que el precio?
- ¿Cómo evitamos que el propietario declare "acepta mascotas" sólo para recibir más solicitudes?
- ¿El propietario está dispuesto a publicar desde el celular estando en el inmueble, o prefiere hacerlo después con calma aunque las fotos queden viejas?
- ¿Obligar a que las fotos se tomen dentro de la app resuelve el problema o hace que el propietario abandone la publicación?
