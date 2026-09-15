import 'dart:io';

import 'package:alquilamatch/core/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Los tintes son variables, no cuentas.
///
/// En Figma cada transparencia es una variable de la coleccion Tokens
/// (Color/Text 5 %, Color/Primary 10 %, ...). En la app cada una es una
/// constante de AppColors. Esta prueba lee el codigo de las piezas compartidas
/// y falla si una vuelve a calcular su propio tinte con `withValues(alpha)`:
/// si eso pasara, cambiar el tinte en AppColors ya no llegaria a esa pieza.
///
/// Las pantallas (lib/features) tienen la misma regla en
/// pantallas_usan_piezas_test. Los archivos del tema (lib/core) son el unico
/// lugar donde se calcula un tinte.

Iterable<File> _archivosDe(String carpeta) => Directory(carpeta)
    .listSync(recursive: true)
    .whereType<File>()
    .where((f) => f.path.endsWith('.dart'));

String _ruta(File archivo) => archivo.path.replaceAll(r'\', '/');

void main() {
  test('ninguna pieza compartida calcula su propio tinte', () {
    final infracciones = <String>[];

    for (final archivo in _archivosDe('lib/shared')) {
      final lineas = archivo.readAsLinesSync();
      for (var i = 0; i < lineas.length; i++) {
        final linea = lineas[i].trim();
        if (linea.startsWith('//')) continue;
        if (linea.contains('withValues(alpha')) {
          infracciones.add(
            '${_ruta(archivo)}:${i + 1}  Usá un tinte de AppColors.',
          );
        }
      }
    }

    expect(infracciones, isEmpty, reason: infracciones.join('\n'));
  });

  test('cada tinte vale lo que dice su nombre', () {
    // Si alguien cambia un valor, cambia en toda la app. Que sea deliberado
    // y que el nombre siga diciendo la verdad.
    final tintes = <String, (Color tinte, Color base, double alfa)>{
      'text05': (AppColors.text05, AppColors.text, 0.05),
      'text06': (AppColors.text06, AppColors.text, 0.06),
      'text10': (AppColors.text10, AppColors.text, 0.1),
      'text12': (AppColors.text12, AppColors.text, 0.12),
      'text38': (AppColors.text38, AppColors.text, 0.38),
      'text40': (AppColors.text40, AppColors.text, 0.4),
      'text50': (AppColors.text50, AppColors.text, 0.5),
      'text60': (AppColors.text60, AppColors.text, 0.6),
      'text70': (AppColors.text70, AppColors.text, 0.7),
      'primary05': (AppColors.primary05, AppColors.primary, 0.05),
      'primary10': (AppColors.primary10, AppColors.primary, 0.1),
      'primary12': (AppColors.primary12, AppColors.primary, 0.12),
      'success10': (AppColors.success10, AppColors.success, 0.1),
      'success12': (AppColors.success12, AppColors.success, 0.12),
      'error08': (AppColors.error08, AppColors.error, 0.08),
      'error10': (AppColors.error10, AppColors.error, 0.1),
      'error12': (AppColors.error12, AppColors.error, 0.12),
      'warning12': (AppColors.warning12, AppColors.warning, 0.12),
    };

    for (final MapEntry(key: nombre, value: (tinte, base, alfa))
        in tintes.entries) {
      expect(tinte, base.withValues(alpha: alfa), reason: 'AppColors.$nombre');
    }
  });
}
