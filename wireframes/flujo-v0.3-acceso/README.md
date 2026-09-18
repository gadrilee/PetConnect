# Pantallas — Flujo v0.3 · Entrar con el rol correcto

**Integrantes:** Gabriel Mamani Sandoval, Daniel Joaquin Mamani Peña
**Flujo:** [`flujo/flujo-v0.3.md`](../../flujo/flujo-v0.3.md) · **Figma:** página *Flujos*, sección *Flujo v0.1 — Acceso*

Once pantallas de 440 × 956, exportadas de la fila **Principal** del archivo de
Figma: cada pantalla del flujo en su estado normal, con los formularios vacíos.
Los caminos completos con los datos puestos (*Happy Path*) y los errores
(*Validaciones*) están en las otras dos filas de la misma sección.

![Las once pantallas del flujo](flujo-completo.png)

## Las pantallas, en el orden en que pasan

| # | Archivo | Momento de la tarea |
|---|---|---|
| 01 | [`01 Ingresar.png`](01%20Ingresar.png) | Abre la app |
| 02 | [`02 Olvidaste tu contraseña.png`](02%20Olvidaste%20tu%20contrase%C3%B1a.png) | No se acuerda la contraseña: pide el enlace |
| 03 | [`03 Revisá tu correo.png`](03%20Revis%C3%A1%20tu%20correo.png) | Confirmación, sin decir si el correo tiene cuenta |
| 04 | [`04 Nueva contraseña.png`](04%20Nueva%20contrase%C3%B1a.png) | Abre el enlace y pone una nueva; entra directo |
| 05 | [`05 Elegir rol.png`](05%20Elegir%20rol.png) | No tiene cuenta: **elige si busca o publica** |
| 06 | [`06 Crear cuenta - propietaria.png`](06%20Crear%20cuenta%20-%20propietaria.png) | Usuario, correo, contraseña y WhatsApp |
| 07 | [`07 Crear cuenta - inquilina.png`](07%20Crear%20cuenta%20-%20inquilina.png) | Lo mismo, sin WhatsApp |
| 08 | [`08 Adentro - propietaria.png`](08%20Adentro%20-%20propietaria.png) | Cae con **tres** módulos |
| 09 | [`09 Adentro - inquilina.png`](09%20Adentro%20-%20inquilina.png) | Cae con **dos** |
| 10 | [`10 Mi perfil - propietaria.png`](10%20Mi%20perfil%20-%20propietaria.png) | Sus datos, su WhatsApp editable y la salida |
| 11 | [`11 Mi perfil - inquilina.png`](11%20Mi%20perfil%20-%20inquilina.png) | Sus datos y la salida: no tiene nada que proteger |

**Recuperar la contraseña va pegado a Ingresar** porque sale de ahí: es lo que
pasa cuando no se puede entrar. Mi perfil va al final porque pasa después de
estar adentro.

## Cómo leer la 05

Es la pantalla que decide el producto. Los dos roles se muestran **con lo que
gana cada uno** (*"Busco dónde alquilar"*, no *"Inquilino"*), y el botón nace
apagado: sin elegir, no se sigue. La elección decide todo lo que viene después
— un formulario con WhatsApp o sin él, una app con tres módulos o con dos.

## Cómo leer la 10 y la 11

Son la misma pantalla, y la diferencia es el argumento del flujo entero. Marta
tiene algo que proteger —su WhatsApp, lo único editable, con la promesa de que
no aparece en sus anuncios—. Andrea no publica: le quedan sus datos y la salida.
*Cerrar sesión* vive acá y no en el inicio, para que una salida que no se
deshace no quede a un toque de la primera pantalla.

> **Numeración.** En el repositorio este es el flujo v0.3. En Figma está
> primero, porque es por donde se entra a todo lo demás.
