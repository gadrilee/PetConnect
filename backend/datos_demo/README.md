# Datos y fotos para mostrar la app

Lo que usa `python manage.py poblar_demo --limpiar` para dejar la base con
gente, anuncios y solicitudes que se parecen a los de verdad.

```bash
python backend/manage.py poblar_demo --limpiar
```

> `--limpiar` **borra todo lo que no sea superusuario**: cuentas, anuncios,
> solicitudes y los archivos de `media/`. Copiá `backend/db.sqlite3` antes si
> te importa lo que hay adentro.

## Qué es real y qué no

| | De dónde sale |
|---|---|
| **Las fotos** | Fotografías reales de Pexels, con licencia libre. Están en `fotos/` y `creditos.json` dice el id y la página de cada una. |
| **Las ubicaciones** | Coordenadas reales de Santa Cruz de la Sierra, sacadas con geocodificación inversa de OpenStreetMap (Nominatim). Cada anuncio cae en una calle y un barrio que existen —Av. Busch, Calle Cupesi, barrio Palermo, Urbarí…— y a la distancia del campus que dice la tarjeta. Los minutos los calcula el modelo; el comando avisa si alguno no da. |
| **Los precios** | El rango que se paga alrededor de la UAGRM: habitación 420–750 Bs, departamento 1.200–2.200, casa 2.600. El precio final suma los servicios que no están incluidos, que es la evidencia 1. |
| **Las historias** | `research/evidencias.md`. Marta alquila cuatro habitaciones (Ev. 7), Rosa no pone su número (Ev. 9), Andrea tiene un gato (persona v0.2). |
| **Las personas** | **Inventadas.** Nombres, correos y WhatsApp no son de nadie. |

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
| `marta.quiroga` | Propietaria. Cuatro habitaciones en casa compartida. |
| `rosa.mendoza` | Propietaria. Tres departamentos. |
| `julio.arispe` | Propietario. Una casa y dos habitaciones. |
| `elena.vaca` | Propietaria. Un departamento y dos habitaciones. |
| `andrea.rojas` | Inquilina. Tercer semestre, de provincia, tiene un gato. |
| `camila.terceros` | Inquilina. Primer semestre. |
| `luis.banegas` | Inquilino. Quinto semestre. |
| `daniela.chavez` | Inquilina. Buscando ahora. |
| `pablo.suarez` | Inquilino. Alquila hace dos años. |

Cada inquilina/o tiene solicitudes en varios estados, así se pueden ver las
cuatro pantallas de *Estado de solicitudes* sin tocar la base. Cada propietaria/o
tiene pendientes esperando en la bandeja.

## Y el otro comando

`sembrar_anuncios` sigue ahí y hace doce anuncios sin fotos ni personas, con
coordenadas repartidas en círculo alrededor del campus. Sirve para probar los
filtros rápido; para mostrar la app, este.
