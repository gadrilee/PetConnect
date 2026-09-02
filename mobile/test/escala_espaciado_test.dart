import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// La escala de espaciado de la Clase 5, convertida en una prueba.
///
/// No alcanza con aplicar 8, 16, 24 y 32 una vez: el proximo que agregue un
/// `SizedBox(height: 14)` desarma el ritmo sin que nadie se entere. Esta prueba
/// lee el codigo fuente y falla si aparece un numero de separacion escrito a
/// mano en vez de una constante de `Espacio`.
///
/// Solo mira separaciones (`SizedBox` y `EdgeInsets`). Los tamanos de un
/// elemento —el alto de una foto, el lado de un icono— no son espaciado y no
/// se revisan aca.

/// Archivos donde la escala es obligatoria: el flujo v0.2 y las piezas.
const _vigilados = [
  'lib/features/buscar/presentation/buscar_screen.dart',
  'lib/features/buscar/presentation/resultados_screen.dart',
  'lib/features/buscar/presentation/anuncio_screen.dart',
  'lib/features/buscar/presentation/solicitar_visita_screen.dart',
  'lib/features/buscar/presentation/solicitud_estado_screen.dart',
  'lib/shared/widgets/boton_principal.dart',
  'lib/shared/widgets/campo_texto.dart',
  'lib/shared/widgets/tarjeta_anuncio.dart',
  'lib/shared/widgets/fila_condicion.dart',
];

/// `SizedBox(height: 12)` y `SizedBox(width: 12)` en una sola linea.
final _sizedBox = RegExp(r'SizedBox\((?:height|width):\s*(\d+(?:\.\d+)?)\s*\)');

/// Cualquier `EdgeInsets.loQueSea( ... )` en una sola linea.
final _edgeInsets = RegExp(r'EdgeInsets\.\w+\(([^)]*)\)');

/// Un numero suelto dentro de los argumentos de un EdgeInsets.
final _numeroSuelto = RegExp(r'(?<![\w.])(\d+(?:\.\d+)?)(?![\w.])');

void main() {
  test('ninguna separacion escrita a mano fuera de la escala', () {
    final infracciones = <String>[];

    for (final ruta in _vigilados) {
      final archivo = File(ruta);
      expect(archivo.existsSync(), isTrue, reason: 'no existe $ruta');

      final lineas = archivo.readAsLinesSync();
      for (var i = 0; i < lineas.length; i++) {
        final linea = lineas[i];
        final donde = '$ruta:${i + 1}';

        for (final m in _sizedBox.allMatches(linea)) {
          // El 0 se permite: "sin separacion" es una decision, no un numero
          // elegido a ojo.
          if (double.parse(m.group(1)!) != 0) {
            infracciones.add('$donde  ${m.group(0)}');
          }
        }

        for (final m in _edgeInsets.allMatches(linea)) {
          for (final n in _numeroSuelto.allMatches(m.group(1)!)) {
            if (double.parse(n.group(1)!) != 0) {
              infracciones.add('$donde  ${m.group(0)}');
            }
          }
        }
      }
    }

    expect(
      infracciones,
      isEmpty,
      reason: 'Usá una constante de Espacio (sm/md/lg/xl) en vez del número:\n'
          '${infracciones.join('\n')}',
    );
  });

  test('la escala es la de la clase: 8, 16, 24 y 32', () {
    final fuente = File('lib/core/theme.dart').readAsStringSync();

    // Si alguien cambia un valor, la app entera cambia de ritmo. Que sea
    // deliberado y no un descuido.
    for (final (nombre, valor) in [
      ('sm', 8),
      ('md', 16),
      ('lg', 24),
      ('xl', 32),
    ]) {
      expect(
        fuente,
        contains('double $nombre = $valor;'),
        reason: 'Espacio.$nombre debería valer $valor',
      );
    }
  });
}
