import 'package:alquilamatch/features/propietario/data/anuncio.dart';
import 'package:flutter_test/flutter_test.dart';

/// Como llega un anuncio desde la API.
///
/// El backend manda las fotos de dos formas segun el endpoint: el detalle
/// manda la lista entera en `fotos` y las listas mandan solo la primera en
/// `foto_principal`. La app leia una sola, asi que las tarjetas de resultados
/// y del historial salian con el icono gris aunque el anuncio tuviera fotos.
void main() {
  Map<String, dynamic> base() => {
        'id': 7,
        'titulo': 'Habitación con baño privado',
        'tipo_espacio': 'HABITACION',
        'precio_final': '830.00',
        'acepta_mascotas': false,
        'minutos_caminando': 3,
        'estado': 'DISPONIBLE',
        'servicios_incluidos': {'agua': true, 'luz': true, 'internet': false},
      };

  test('el detalle trae la lista completa en fotos', () {
    final anuncio = Anuncio.desdeJson({
      ...base(),
      'fotos': [
        {'imagen': 'http://x/uno.jpg', 'fecha_captura': '2026-09-11T00:45:28-04:00'},
        {'imagen': 'http://x/dos.jpg', 'fecha_captura': '2026-09-10T18:45:28-04:00'},
      ],
    });

    expect(anuncio.fotos.length, 2);
    expect(anuncio.fotos.first.imagen, 'http://x/uno.jpg');
    expect(anuncio.fotos.first.fechaCaptura.day, 11);
  });

  test('una lista trae solo la primera, en foto_principal', () {
    final anuncio = Anuncio.desdeJson({
      ...base(),
      'foto_principal': {
        'imagen': 'http://x/uno.jpg',
        'fecha_captura': '2026-09-11T00:45:28-04:00',
      },
    });

    // Con una sola foto alcanza: es la que muestra la tarjeta.
    expect(anuncio.fotos.length, 1);
    expect(anuncio.fotos.first.imagen, 'http://x/uno.jpg');
  });

  test('un anuncio sin fotos no rompe ni inventa una vacia', () {
    expect(Anuncio.desdeJson(base()).fotos, isEmpty);
    expect(Anuncio.desdeJson({...base(), 'foto_principal': null}).fotos, isEmpty);
    expect(Anuncio.desdeJson({...base(), 'fotos': []}).fotos, isEmpty);
  });

  group('dónde queda', () {
    test('el detalle trae lat y lng, y de ahí sale el mapa', () {
      final anuncio = Anuncio.desdeJson({
        ...base(),
        'lat': -17.77712,
        'lng': -63.19035,
      });

      expect(anuncio.lat, -17.77712);
      expect(anuncio.lng, -63.19035);
      expect(
        anuncio.mapa.toString(),
        'https://www.google.com/maps/search/?api=1&query=-17.77712,-63.19035',
      );
    });

    test('un número redondo llega como int y no rompe', () {
      // JSON no distingue 17 de 17.0: el backend manda floats y a veces
      // salen sin decimales.
      final anuncio = Anuncio.desdeJson({...base(), 'lat': -17, 'lng': -63});

      expect(anuncio.lat, -17.0);
      expect(anuncio.mapa, isNotNull);
    });

    test('una lista no los manda, y entonces no hay mapa que abrir', () {
      // Los resultados de la busqueda no traen lat/lng: la tarjeta no los
      // necesita. Sin ellos el aviso de ubicacion no lleva a ningun lado en
      // vez de abrir un mapa en el medio del mar.
      expect(Anuncio.desdeJson(base()).mapa, isNull);
    });
  });

  test('si vienen las dos formas gana la lista completa', () {
    final anuncio = Anuncio.desdeJson({
      ...base(),
      'fotos': [
        {'imagen': 'http://x/uno.jpg', 'fecha_captura': '2026-09-11T00:45:28-04:00'},
        {'imagen': 'http://x/dos.jpg', 'fecha_captura': '2026-09-10T18:45:28-04:00'},
      ],
      'foto_principal': {
        'imagen': 'http://x/uno.jpg',
        'fecha_captura': '2026-09-11T00:45:28-04:00',
      },
    });

    expect(anuncio.fotos.length, 2);
  });
}
