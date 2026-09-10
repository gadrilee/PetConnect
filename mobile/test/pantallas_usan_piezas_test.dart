import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Las pantallas se arman con las piezas compartidas, no a mano.
///
/// Si una pantalla vuelve a escribir su propio Scaffold, su propia caja con
/// BoxDecoration o su propio boton de Material, un cambio en la pieza ya no
/// llega a esa pantalla. Esta prueba lee el codigo de lib/features y falla si
/// aparece uno de esos atajos.
final _prohibidos = <RegExp, String>{
  RegExp(r'\bScaffold\('): 'Usá Pagina: el margen, el ancho y el pie ya están.',
  RegExp(r'\bBoxDecoration\('): 'Usá Bloque, Pastilla o IconoCirculo.',
  RegExp(r'\b(ElevatedButton|FilledButton)\b'): 'Usá BotonPrincipal.',
  RegExp(r'\bOutlinedButton\b'): 'Usá BotonSecundario.',
  RegExp(r'\bTextButton\b'): 'Usá BotonTexto.',
  RegExp(r'\bFloatingActionButton\b'): 'Usá BotonFlotante.',
  RegExp(r'\b(SnackBar|ScaffoldMessenger)\b'): 'Usá Aviso.mostrarToast.',
  RegExp(r'\bColor\(0x'): 'Usá un color de AppColors.',
  RegExp(r'\bColors\.'): 'Usá un color de AppColors.',
  RegExp(r'\bfontSize:'): 'Usá un estilo de AppText.',
};

Iterable<File> _archivosDeFeatures() => Directory('lib/features')
    .listSync(recursive: true)
    .whereType<File>()
    .where((f) => f.path.endsWith('.dart'));

String _ruta(File archivo) => archivo.path.replaceAll(r'\', '/');

void main() {
  test('ninguna pantalla arma a mano lo que ya resuelve una pieza', () {
    final infracciones = <String>[];

    for (final archivo in _archivosDeFeatures()) {
      final lineas = archivo.readAsLinesSync();
      for (var i = 0; i < lineas.length; i++) {
        final linea = lineas[i].trim();
        if (linea.startsWith('//')) continue;
        for (final MapEntry(key: patron, value: motivo)
            in _prohibidos.entries) {
          if (patron.hasMatch(linea)) {
            infracciones.add('${_ruta(archivo)}:${i + 1}  $motivo');
          }
        }
      }
    }

    expect(infracciones, isEmpty, reason: infracciones.join('\n'));
  });

  test('toda pantalla se arma sobre Pagina', () {
    final sinPagina = [
      for (final archivo in _archivosDeFeatures())
        if (archivo.path.endsWith('_screen.dart') &&
            !archivo.readAsStringSync().contains('Pagina('))
          _ruta(archivo),
    ];

    expect(sinPagina, isEmpty, reason: sinPagina.join('\n'));
  });
}
