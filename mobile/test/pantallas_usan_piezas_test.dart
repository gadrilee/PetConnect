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
  RegExp(r'\b(SnackBar|ScaffoldMessenger)\b'):
      'Usá Aviso: en PieAcciones.aviso si la pantalla tiene pie, '
          'o Aviso.mostrarToast si no.',
  RegExp(r'\bColor\(0x'): 'Usá un color de AppColors.',
  RegExp(r'\bColors\.'): 'Usá un color de AppColors.',
  RegExp(r'withValues\(alpha'): 'Usá un tinte de AppColors.',
  RegExp(r'\bfontSize:'): 'Usá un estilo de AppText.',
};

/// `pie: Column(`, `pie: BotonPrincipal(`: una pantalla que arma su propio
/// pie. Se acepta `pie: PieAcciones(` y tambien `pie: _armarPie()` (un metodo
/// o una variable en minuscula), siempre que el archivo use PieAcciones.
final _pieAMano = RegExp(r'\bpie:\s*(?:const\s+)?([A-Z]\w*)\(');

Iterable<File> _archivosDeFeatures() => Directory('lib/features')
    .listSync(recursive: true)
    .whereType<File>()
    .where((f) => f.path.endsWith('.dart'));

String _ruta(File archivo) => archivo.path.replaceAll(r'\', '/');

/// El codigo sin las lineas de comentario: un "sin pie: el boton va en el
/// contenido" explicando una decision no es un pie.
String _sinComentarios(File archivo) => archivo
    .readAsLinesSync()
    .where((linea) => !linea.trim().startsWith('//'))
    .join('\n');

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

  test('el resumen del anuncio sale de la pieza, no escrito a mano', () {
    // Marcar como alquilado y el Detalle de la solicitud mostraban el mismo
    // bloque —título y "Tipo: X · N Bs/mes"— cada uno por su cuenta, y sólo
    // uno de los dos tenía la foto. Ahora es ResumenAnuncio. Si alguna
    // pantalla vuelve a escribir esa línea sin usar la pieza, la foto se le
    // pierde de nuevo y nadie se entera.
    const pantallas = [
      'lib/features/propietario/presentation/solicitud_detalle_screen.dart',
      'lib/features/propietario/presentation/confirmar_alquilado_screen.dart',
    ];
    final infracciones = <String>[];

    for (final ruta in pantallas) {
      final fuente = _sinComentarios(File(ruta));
      if (!fuente.contains('ResumenAnuncio(')) {
        infracciones.add('$ruta  Usá ResumenAnuncio.');
      }
      if (fuente.contains(r'Tipo: ${anuncio.tipoEspacio.etiqueta}')) {
        infracciones.add('$ruta  vuelve a escribir el resumen a mano.');
      }
    }

    expect(infracciones, isEmpty, reason: infracciones.join('\n'));
  });

  test('todo pie se arma con PieAcciones', () {
    // El pie ordena el aviso, los botones y las notas igual en todas las
    // pantallas. Si una pantalla le pasa a Pagina su propia Column o un boton
    // suelto, un cambio en el pie ya no llega a esa pantalla. La garantia de
    // verdad es el tipo de `Pagina.pie` (PieAcciones?), que no compila con
    // otra cosa; esta prueba deja la regla escrita donde se lee.
    final infracciones = <String>[];

    for (final archivo in _archivosDeFeatures()) {
      if (!archivo.path.endsWith('_screen.dart')) continue;
      final fuente = _sinComentarios(archivo);
      if (!fuente.contains(RegExp(r'\bpie:'))) continue;

      for (final m in _pieAMano.allMatches(fuente)) {
        if (m.group(1) != 'PieAcciones') {
          infracciones.add(
            '${_ruta(archivo)}  pie: ${m.group(1)}(  Usá PieAcciones.',
          );
        }
      }
      if (!fuente.contains('PieAcciones(')) {
        infracciones.add(
          '${_ruta(archivo)}  tiene pie pero no usa PieAcciones.',
        );
      }
    }

    expect(infracciones, isEmpty, reason: infracciones.join('\n'));
  });
}
