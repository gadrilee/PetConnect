"""Carga los datos con los que se recorre la guía de pruebas.

Crea cinco cuentas, dos anuncios y las solicitudes que hacen falta para llegar
a cada estado de `docs/guia-de-pruebas.html`. Todo lleva el sufijo `_qa`, así
se borra de un saque al terminar:

    python backend/manage.py shell -c "from django.contrib.auth import get_user_model; get_user_model().objects.filter(username__endswith='_qa').delete()"

Se corre contra el backend de desarrollo, que tiene que estar levantado:

    python backend/manage.py runserver
    python docs/preparar-datos-de-prueba.py
"""
import json
import urllib.error
import urllib.request

API = 'http://127.0.0.1:8000'
CLAVE = 'demo1234'


def pedir(ruta, datos=None, token=None, metodo=None):
    """Una llamada a la API. `metodo` sirve para POST sin cuerpo, como aprobar."""
    cuerpo = json.dumps(datos).encode() if datos is not None else None
    req = urllib.request.Request(
        API + ruta, data=cuerpo, method=metodo or ('POST' if datos else 'GET'))
    req.add_header('Content-Type', 'application/json')
    if token:
        req.add_header('Authorization', 'Bearer ' + token)
    try:
        with urllib.request.urlopen(req) as r:
            return r.status, json.loads(r.read().decode() or '{}')
    except urllib.error.HTTPError as e:
        return e.code, json.loads(e.read().decode() or '{}')
    except urllib.error.URLError:
        raise SystemExit(
            f'No hay nadie en {API}. Levantá el backend primero:\n'
            '    python backend/manage.py runserver')


def cuenta(username, rol, whatsapp=''):
    """Registra la cuenta si no existe y devuelve su token."""
    datos = {'username': username, 'email': f'{username}@ejemplo.test',
             'password': CLAVE, 'rol': rol}
    if whatsapp:
        datos['whatsapp'] = whatsapp
    estado, _ = pedir('/api/usuarios/registro/', datos)
    _, r = pedir('/api/auth/token/', {'username': username, 'password': CLAVE})
    print(f'  {username:10} registro {estado}')
    return r['access']


print('Cuentas')
prop = cuenta('marta_qa', 'PROPIETARIO', '70011199')
andrea = cuenta('andrea_qa', 'INQUILINO')
ines = cuenta('ines_qa', 'INQUILINO')
sofia = cuenta('sofia_qa', 'INQUILINO')
cuenta('nueva_qa', 'INQUILINO')  # sin solicitudes: para el estado vacio

print('Anuncios')
ids = []
for titulo, precio, mascotas in [
    ('Habitación QA con baño privado', '700.00', True),
    ('Habitación QA sin pendientes', '650.00', False),
]:
    estado, a = pedir('/api/anuncios/', {
        'titulo': titulo, 'tipo_espacio': 'HABITACION', 'precio_alquiler': precio,
        'incluye_agua': True, 'incluye_luz': True, 'incluye_internet': False,
        'costo_servicios_estimado': '100.00', 'acepta_mascotas': mascotas,
        'lat': -17.7757, 'lng': -63.1980,
        'direccion_referencia': 'A media cuadra del campus',
    }, token=prop)
    print(f'  {titulo:32} {estado} id={a.get("id")}')
    ids.append(a.get('id'))

# Una solicitud por inquilina sobre el primer anuncio. Quedan pendientes: de
# ahi salen la bandeja con decisiones por tomar y la confirmacion "con
# pendientes" del flujo v0.5.
print('Solicitudes')
for token, nombre in ((andrea, 'andrea_qa'), (ines, 'ines_qa'), (sofia, 'sofia_qa')):
    estado, s = pedir('/api/solicitudes/',
                      {'anuncio': ids[0], 'condiciones_aceptadas': True}, token=token)
    print(f'  {nombre:10} {estado} id={s.get("id")}')

print(f'\nListo. Anuncios: {ids}. Todas las claves son "{CLAVE}".')
