# Datos y fotos para mostrar la app

Lo que usa `python manage.py poblar_demo --limpiar` para dejar la base con
gente, anuncios y solicitudes que se parecen a los de verdad: **90 cuentas,
130 anuncios con 314 fotos y 150 solicitudes**.

```bash
python backend/manage.py poblar_demo --limpiar

# o más chico, para probar rápido
python backend/manage.py poblar_demo --limpiar --anuncios 20 --solicitudes 25
```

Se puede ajustar con `--propietarios`, `--inquilinos`, `--anuncios` y
`--solicitudes`. La semilla del azar es fija: dos corridas con los mismos
números dan la misma base.

> `--limpiar` **borra todo lo que no sea superusuario**: cuentas, anuncios,
> solicitudes y los archivos de `media/`. Copiá `backend/db.sqlite3` antes si
> te importa lo que hay adentro.

## Qué es real y qué no

| | De dónde sale |
|---|---|
| **Las fotos** | 163 fotografías reales de Pexels, con licencia libre: 125 de ambientes y 38 retratos. Están en `fotos/` y `creditos.json` dice el id y la página de cada una. |
| **Las ubicaciones** | 66 coordenadas reales de Santa Cruz de la Sierra en `ubicaciones.json`, sacadas con geocodificación inversa de OpenStreetMap (Nominatim), de 3 a 160 minutos del campus. Cada anuncio cae en una calle y un barrio que existen —Av. Busch, Calle Cupesi, barrio Palermo, Urbarí…— con unos metros de diferencia entre uno y otro, porque dos anuncios de la misma calle no están en la misma puerta. Los minutos los calcula el modelo a partir de ahí. |
| **Los precios** | El rango que se paga alrededor de la UAGRM: habitación 380–900 Bs de alquiler, departamento 1.000–2.600, casa 2.200–4.800. El precio final suma los servicios que no están incluidos, que es la evidencia 1. |
| **Las historias** | `research/evidencias.md`. Marta alquila cuatro habitaciones (Ev. 7), Rosa no pone su número (Ev. 9), Andrea tiene un gato (persona v0.2). |
| **Las personas** | **Inventadas.** Las nueve del principio salen de la investigación; las otras 81 se arman combinando nombres y apellidos de uso corriente en Santa Cruz. Ni los nombres ni los correos ni los WhatsApp son de nadie. |

## Por qué las personas son inventadas

Poner la foto, el nombre y el teléfono de alguien real en una cuenta que no es
suya no hace la demo más real: mete a un tercero en un trabajo que no pidió
estar. Los retratos de `fotos/cara-*.jpg` son fotos de banco con licencia
libre, que es otra cosa: quien posó sabía que la foto se iba a usar así.

Dos cosas que conviene saber antes de mostrar la app:

- **Los WhatsApp tienen formato boliviano pero no son de nadie en particular.**
  Si alguien toca *ABRIR WHATSAPP* en la demo, el chat se abre contra un número
  que puede existir. Antes de mostrarlo en vivo, cambiá el de la cuenta que
  vayas a usar por el tuyo:

  ```bash
  python backend/manage.py shell -c "from usuarios.models import Perfil; Perfil.objects.filter(usuario__username='marta.quiroga').update(whatsapp='7XXXXXXX')"
  ```

- **Los correos son inventados sobre dominios que sí existen** (`uagrm.edu.bo`,
  `gmail.com`). No sale ni un mail: `settings.py` usa el backend de consola, que
  los imprime en la terminal. Si algún día se configura un SMTP de verdad, hay
  que cambiar estos correos antes.

## Las cuentas

Todas con la contraseña `demo1234`.

| Usuario | Quién es |
|---|---|
| `marta.quiroga` | Propietaria. Cinco anuncios: es la que tiene la bandeja más llena. |
| `rosa.mendoza` | Propietaria. Cinco anuncios. |
| `julio.arispe` | Propietario. Cinco anuncios. |
| `elena.vaca` | Propietaria. Cinco anuncios. |
| `andrea.rojas` | Inquilina. Tercer semestre, de provincia, tiene un gato. |
| `camila.terceros` | Inquilina. Primer semestre. |
| `luis.banegas` | Inquilino. Quinto semestre. |
| `daniela.chavez` | Inquilina. Buscando ahora. |
| `pablo.suarez` | Inquilino. Alquila hace dos años. |

Además de esas nueve hay 81 cuentas más —31 propietarias/os y 50 inquilinas/os—
con la misma contraseña, para que la búsqueda y las bandejas se vean con gente
adentro. 38 de las 90 tienen foto de perfil: en la app de verdad tampoco la
sube todo el mundo.

Los estados no se escriben a mano. Las solicitudes nacen pendientes y después
un 10 % de los anuncios se marca como alquilado con el mismo método que usa la
app, así las que estaban esperando quedan **cerradas** por el camino de
siempre. Quedan las cuatro pantallas de *Estado de solicitudes* para mirar.

> **Ojo con la búsqueda sin filtros.** La API pagina de a 20 y la app se queda
> con la primera página, así que de los 117 disponibles se ven los 20 más
> cercanos. Filtrando —que es lo que hace Andrea— el resultado entra entero.

## Y el otro comando

`sembrar_anuncios` sigue ahí y hace doce anuncios sin fotos ni personas, con
coordenadas repartidas en círculo alrededor del campus. Sirve para probar los
filtros rápido; para mostrar la app, este.
