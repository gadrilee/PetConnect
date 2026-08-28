# Lenguaje visual de los wireframes

Reglas que **todas** las pantallas cumplen. Vienen de la Clase 4:

> "La pregunta no es «¿qué color tendrá el botón?». La primera pregunta es
> «¿María entiende qué puede hacer y qué ocurrirá después?»"

Por eso todo es escala de grises: no hay ninguna decisión de color todavía.

## Lienzo

| | Valor |
|---|---|
| Tamaño del frame | **360 × 800** (preset "Android Large" de Figma) |
| Fondo | `#FFFFFF` |
| Borde del frame | `#D0D0D0`, 1px |
| Margen lateral | 20px → ancho de contenido **320** |
| Barra de estado | `y 0–28`, relleno `#F0F0F0` |
| Barra de título | `y 28–76` |
| El contenido arranca en | `y ≈ 92` |

## Elementos

| Elemento | Cómo se dibuja |
|---|---|
| Texto de relleno, importante | Barra `#9A9A9A`, alto 10, radio 5 |
| Texto de relleno, secundario | Barra `#C9C9C9`, alto 8, radio 4 |
| Caja / campo | Relleno ninguno, trazo `#BDBDBD` 1px, radio 8 |
| Imagen | Relleno `#E8E8E8`, trazo `#BDBDBD`, con una diagonal cruzada |
| **Acción principal** | Relleno `#4A4A4A`, radio 8, alto 44, texto **blanco MAYÚSCULAS** 12px, `letter-spacing 1` |
| Acción secundaria | Sin relleno, trazo `#8A8A8A`, texto `#4A4A4A` |
| Ícono | Cuadrado `#9A9A9A` de 16×16, radio 3 |

## Las tres reglas de la clase

1. **CONTENIDO — la información importante debe ser visible.**
   Las barras grises son relleno, pero **los cuatro datos de descarte van con
   texto real**: precio final, minutos caminando, mascotas y tipo. Son el
   producto; abstraerlos escondería justo lo que hay que evaluar.

2. **ACCIÓN — la acción principal debe distinguirse.**
   **Una sola** por pantalla, y es la única forma rellena de oscuro. Si hay
   dos botones oscuros, el wireframe está mal.

3. **FEEDBACK — el sistema debe mostrar qué ocurrió.**
   Todo flujo termina en una pantalla que dice qué pasó y ofrece la salida.

## Tipografía

Sans del sistema (`Inter, Arial, sans-serif`). Tamaños: 11 · 13 · 15 · 18.
Color de texto `#3A3A3A`; sobre la acción principal, `#FFFFFF`.

## Nombres de los frames

Se usa el orden del flujo, como pide la diapositiva 7:
`01 Buscar`, `02 Resultados`, `03 Anuncio`… El número va en el nombre del
frame en Figma, **no dibujado dentro** del lienzo.
