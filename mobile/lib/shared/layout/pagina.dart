import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/theme.dart';
import '../widgets/encabezado.dart';
import 'grilla.dart';

/// Hasta donde puede estirarse el contenido de una pagina.
enum AnchoPagina {
  /// Formularios y confirmaciones: una sola columna que en un monitor no se
  /// estira mas de lo que se lee comodo.
  formulario(480),

  /// Pantallas con varios bloques, que se reparten con la grilla de 12
  /// columnas.
  completo(Grilla.anchoMaximo);

  const AnchoPagina(this.maximo);

  final double maximo;
}

/// La estructura comun de todas las pantallas de la app.
///
/// REGLA DE LA PIEZA
/// -----------------
/// Todas las pantallas tienen el mismo margen, el mismo tope de ancho y el
/// mismo lugar para la accion principal. **Ninguna pantalla arma su propio
/// Scaffold**: cambiar el margen o el ancho maximo aca lo cambia en toda la
/// app, y una prueba impide volver a escribirlo a mano en una pantalla.
///
/// - CONSTRAINTS: el contenido queda centrado y se detiene en [ancho]. El
///   [pie] queda anclado abajo, fuera del scroll, y no pasa el ancho de un
///   formulario.
/// - AUTO LAYOUT: los [hijos] se apilan en una columna que estira a lo ancho
///   y mide lo que su contenido.
class Pagina extends StatelessWidget {
  const Pagina({
    super.key,
    this.titulo,
    this.conBotonVolver = true,
    this.ancho = AnchoPagina.completo,
    this.hijos = const [],
    this.cuerpo,
    this.pie,
    this.alRefrescar,
    this.botonFlotante,
    this.centrarVertical = false,
  });

  /// Titulo del encabezado. `null` es una pantalla sin encabezado, como el
  /// login.
  final String? titulo;

  final bool conBotonVolver;
  final AnchoPagina ancho;

  /// El contenido, de arriba hacia abajo. Las separaciones las pone quien
  /// arma la pantalla, con la escala de [Espacio].
  final List<Widget> hijos;

  /// Reemplaza a [hijos] cuando no hay nada que listar: cargando, vacia o con
  /// error. Queda centrado en el espacio libre.
  final Widget? cuerpo;

  /// Las acciones fijas al pie, como la accion principal.
  final Widget? pie;

  /// Si se pasa, la pagina se actualiza tirando hacia abajo.
  final Future<void> Function()? alRefrescar;

  final Widget? botonFlotante;

  /// Centra el contenido en el alto disponible, como en el login.
  final bool centrarVertical;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: titulo == null
          ? null
          : Encabezado(titulo: titulo!, conBotonVolver: conBotonVolver),
      floatingActionButton: botonFlotante,
      body: SafeArea(
        bottom: pie == null,
        child: LayoutBuilder(builder: _contenido),
      ),
      bottomNavigationBar:
          pie == null ? null : _Pie(child: pie!),
    );
  }

  Widget _contenido(BuildContext context, BoxConstraints restricciones) {
    final conMargen = cuerpo == null;
    // Con boton flotante queda lugar abajo, para que no tape la ultima tarjeta.
    final abajo = botonFlotante == null ? Espacio.lg : Espacio.xxl * 2;
    final margen = conMargen
        ? EdgeInsets.fromLTRB(Espacio.lg, Espacio.lg, Espacio.lg, abajo)
        : EdgeInsets.zero;

    final scroll = SingleChildScrollView(
      physics:
          alRefrescar == null ? null : const AlwaysScrollableScrollPhysics(),
      padding: margen,
      child: ConstrainedBox(
        // Ocupa al menos todo el alto: con poco contenido, el cuerpo vacio y
        // la pantalla centrada quedan en el medio y no pegados arriba.
        constraints: BoxConstraints(
          minHeight: math.max(0.0, restricciones.maxHeight - margen.vertical),
        ),
        child: Align(
          alignment: centrarVertical || !conMargen
              ? Alignment.center
              : Alignment.topCenter,
          child: cuerpo ??
              ConstrainedBox(
                constraints: BoxConstraints(maxWidth: ancho.maximo),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: hijos,
                ),
              ),
        ),
      ),
    );

    if (alRefrescar == null) return scroll;
    return RefreshIndicator(onRefresh: alRefrescar!, child: scroll);
  }
}

/// Las acciones fijas al pie de la pagina.
class _Pie extends StatelessWidget {
  const _Pie({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    // CONSTRAINTS: anclado abajo y nunca mas ancho que un formulario, en
    // cualquier pagina: en un monitor el boton no se estira de punta a punta.
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          Espacio.lg,
          Espacio.sm,
          Espacio.lg,
          Espacio.md,
        ),
        child: Align(
          alignment: Alignment.topCenter,
          heightFactor: 1,
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: AnchoPagina.formulario.maximo),
            child: child,
          ),
        ),
      ),
    );
  }
}
