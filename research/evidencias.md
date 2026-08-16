# Evidencias de Investigación — AlquilaMatch

> **Estado:** evidencia preliminar **simulada con IA**, coherente con la modalidad declarada del proyecto (desarrollo asistido con IA).
> No sustituye la validación con usuarios reales. Las entrevistas reales se realizarán antes de la v0.3 y reemplazarán esta sección.
> Guía de entrevista en `research/guia-entrevistas.md`.

---

## A. Lado Inquilino (estudiantes UAGRM)

1. "Llegué hasta el lugar y recién ahí me dijeron que el precio no incluía agua ni luz. Eran 300 bolivianos más." — Estudiante, 3er semestre, vive en alquiler hace 2 años.
2. "Decía 'cerca de la U'. Cerca era 25 minutos caminando. Perdí toda la tarde." — Estudiante de provincia, primer semestre.
3. "Tengo un gato. En el anuncio nunca dice nada de mascotas, así que tengo que preguntar siempre, y la mitad de las veces me dicen que no después de que ya escribí." — Estudiante, vive sola.
4. "Las fotos eran de hace años. El baño no era ese." — Estudiante, buscó cuarto en enero.
5. "Escribo a cinco anuncios y me responden dos, y uno ya estaba alquilado." — Estudiante, busca actualmente.
6. "Si voy a compartir casa, quiero saber con quiénes. Eso no lo dice ningún anuncio." — Estudiante, 5to semestre.

## B. Lado Propietario / Arrendador

7. "Me escriben veinte personas y a quince les tengo que repetir lo mismo: el precio, que no acepto mascotas, que es sólo para señoritas." — Propietaria, alquila 4 habitaciones.
8. "El cuarto lo alquilé hace un mes y me siguen escribiendo. Ya ni contesto." — Propietario, casa compartida.
9. "No pongo mi número en el anuncio porque después te escriben para cualquier cosa, pero si no lo pongo nadie te contacta." — Propietaria.
10. "Coordiné una visita y la persona no llegó. Me quedé esperando una hora en la casa." — Propietario, un departamento.
11. "Publico en tres grupos de Facebook distintos y tengo que actualizar en los tres." — Propietaria.

---

## Patrones observados

| Patrón | Evidencias | Implicación de diseño |
|---|---|---|
| El precio publicado no es el precio final | 1 | Separar "alquiler" de "servicios incluidos" como campos distintos y obligatorios |
| "Cerca" es un término inútil sin referencia | 2 | Calcular y mostrar minutos caminando a la UAGRM |
| Las reglas ocultas se descubren tras el contacto | 3, 7 | Política de mascotas y restricciones como campo obligatorio y filtrable |
| Las fotos publicadas no corresponden al estado actual | 4 | Fotos tomadas con la cámara de la app y fecha de captura visible en el anuncio |
| Los anuncios no mueren | 5, 8, 11 | Estado *Disponible / Ya alquilado* en un toque |
| El contacto directo es caro para ambos lados | 7, 9, 10 | Solicitud de visita con contacto oculto hasta la aprobación |
| Compartir espacio tiene un dato faltante | 6 | Evaluar campo "con quién se comparte" para habitaciones |

## Contra-evidencia y riesgos detectados

- La evidencia 9 muestra que el propietario **quiere** ocultar su número, pero también teme perder contactos. Ocultar el contacto podría leerse como fricción si no se explica el beneficio.
- Ningún entrevistado pidió explícitamente una app nueva. El problema se tolera hoy con Facebook + WhatsApp; la app debe ser claramente más rápida o no se adoptará.
- Exigir que las fotos y la ubicación se capturen desde el teléfono estando en el inmueble mejora la calidad del anuncio, pero agrega fricción justo en el paso donde el propietario ya está apurado. Es un supuesto a validar, no un hecho.
