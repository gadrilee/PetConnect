import 'package:alquilamatch/core/theme.dart';
import 'package:alquilamatch/features/inquilina/data/solicitud.dart';
import 'package:alquilamatch/features/inquilina/providers/buscar_provider.dart';
import 'package:alquilamatch/features/propietario/data/anuncio.dart';
import 'package:alquilamatch/shared/layout/pagina.dart';
import 'package:alquilamatch/shared/widgets/aviso.dart';
import 'package:alquilamatch/shared/widgets/bloque.dart';
import 'package:alquilamatch/shared/widgets/boton_principal.dart';
import 'package:alquilamatch/shared/widgets/boton_secundario.dart';
import 'package:alquilamatch/shared/widgets/boton_texto.dart';
import 'package:alquilamatch/shared/widgets/campo_texto.dart';
import 'package:alquilamatch/shared/widgets/controles.dart';
import 'package:alquilamatch/shared/widgets/estado_vacio.dart';
import 'package:alquilamatch/shared/widgets/etiqueta_estado.dart';
import 'package:alquilamatch/shared/widgets/icono_circulo.dart';
import 'package:alquilamatch/shared/widgets/pie_acciones.dart';
import 'package:alquilamatch/shared/widgets/precio_final.dart';
import 'package:alquilamatch/shared/widgets/resumen_busqueda.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Pruebas de las piezas con las que se arman todas las pantallas.
///
/// Fijan la promesa del sistema: una pieza se escribe una vez, y cambiarla
/// cambia todas las pantallas que la usan.

const _telefono = Size(360, 800);
const _escritorio = Size(1440, 900);
const _contenido = Key('contenido');

void _pantalla(WidgetTester tester, Size tamano) {
  tester.view.physicalSize = tamano;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

Widget _app(Widget hijo) => MaterialApp(theme: AppTheme.claro, home: hijo);

Widget _enCaja(Widget hijo) => _app(
  Scaffold(body: Center(child: SizedBox(width: 320, child: hijo))),
);

Size _cajaDe(WidgetTester tester, String etiqueta) => tester.getSize(
  find.ancestor(
    of: find.text(etiqueta),
    matching: find.byType(AnimatedContainer),
  ),
);

void main() {
  group('Pagina', () {
    testWidgets('telefono: el contenido deja 24 de margen a cada lado', (
      tester,
    ) async {
      _pantalla(tester, _telefono);
      await tester.pumpWidget(
        _app(
          const Pagina(
            titulo: 'Prueba',
            hijos: [SizedBox(key: _contenido, height: 40)],
          ),
        ),
      );

      expect(find.text('Prueba'), findsOneWidget);
      expect(tester.getSize(find.byKey(_contenido)).width, 312);
      expect(tester.getTopLeft(find.byKey(_contenido)).dx, 24);
    });

    testWidgets('CONSTRAINTS: en escritorio se detiene en su ancho, centrada', (
      tester,
    ) async {
      _pantalla(tester, _escritorio);
      for (final ancho in AnchoPagina.values) {
        await tester.pumpWidget(
          _app(
            Pagina(
              ancho: ancho,
              hijos: const [SizedBox(key: _contenido, height: 40)],
            ),
          ),
        );

        final caja = tester.getRect(find.byKey(_contenido));
        expect(caja.width, ancho.maximo, reason: '$ancho');
        expect(caja.center.dx, _escritorio.width / 2, reason: '$ancho');
      }
    });

    testWidgets('el pie queda abajo y no pasa el ancho de un formulario', (
      tester,
    ) async {
      _pantalla(tester, _escritorio);
      await tester.pumpWidget(
        _app(
          Pagina(
            hijos: const [SizedBox(height: 40)],
            pie: PieAcciones(
              botonPrincipal: BotonPrincipal(etiqueta: 'SEGUIR', alTocar: () {}),
            ),
          ),
        ),
      );

      final boton = tester.getRect(find.byType(BotonPrincipal));
      expect(boton.width, AnchoPagina.formulario.maximo);
      expect(boton.center.dx, _escritorio.width / 2);
      expect(boton.bottom, _escritorio.height - Espacio.md);
    });

    testWidgets('el pie lleva borde arriba, fondo blanco y 16 de relleno', (
      tester,
    ) async {
      // El marco del pie es de Pagina, no de la pantalla: en Figma es el
      // marco "Pie" de cada pantalla, con su borde de 1 arriba.
      _pantalla(tester, _telefono);
      await tester.pumpWidget(
        _app(
          Pagina(
            titulo: 'Prueba',
            hijos: const [SizedBox(height: 40)],
            pie: PieAcciones(
              botonPrincipal: BotonPrincipal(etiqueta: 'SEGUIR', alTocar: () {}),
            ),
          ),
        ),
      );

      final marco = find
          .ancestor(
            of: find.byType(PieAcciones),
            matching: find.byType(DecoratedBox),
          )
          .first;
      final decoracion =
          tester.widget<DecoratedBox>(marco).decoration as BoxDecoration;
      expect(decoracion.color, AppColors.surface);
      expect((decoracion.border! as Border).top.color, AppColors.text12);

      final pie = tester.getRect(marco);
      final boton = tester.getRect(find.byType(BotonPrincipal));
      // El borde va de punta a punta; el contenido, con el margen de la pagina.
      expect(pie.width, _telefono.width);
      expect(boton.left, Espacio.lg);
      expect(boton.width, _telefono.width - Espacio.lg * 2);
      expect(boton.top - pie.top, Espacio.md);
      expect(pie.bottom - boton.bottom, Espacio.md);
    });

    testWidgets('sin nada que listar, el cuerpo queda en el centro', (
      tester,
    ) async {
      _pantalla(tester, _telefono);
      await tester.pumpWidget(
        _app(
          const Pagina(
            titulo: 'Prueba',
            cuerpo: EstadoVacio(
              icono: Icons.inbox_outlined,
              titulo: 'Nada por aquí',
            ),
          ),
        ),
      );

      // El alto libre va del encabezado de 56 al borde de abajo.
      final centro = tester.getCenter(find.byType(EstadoVacio));
      expect(centro.dx, _telefono.width / 2);
      expect((centro.dy - (56 + _telefono.height) / 2).abs(), lessThan(1));
    });
  });

  group('Bloque', () {
    testWidgets('los cuatro tonos salen de una sola tabla', (tester) async {
      for (final tono in TonoBloque.values) {
        await tester.pumpWidget(
          _enCaja(Bloque(tono: tono, child: const Text('dato'))),
        );

        final material = tester.widget<Material>(
          find
              .descendant(
                of: find.byType(Bloque),
                matching: find.byType(Material),
              )
              .first,
        );
        expect(material.color, Bloque.coloresDe(tono).$1, reason: '$tono');
      }
    });

    testWidgets('AUTO LAYOUT: crece con el contenido, no con un numero', (
      tester,
    ) async {
      Size medir() => tester.getSize(find.byType(Bloque));

      await tester.pumpWidget(_enCaja(const Bloque(child: Text('Una línea'))));
      final corto = medir();

      await tester.pumpWidget(
        _enCaja(const Bloque(child: Text('Una línea\nDos líneas\nTres'))),
      );
      expect(medir().height, greaterThan(corto.height));
      expect(medir().width, corto.width);
    });

    testWidgets('responde al toque cuando se le pide', (tester) async {
      var toques = 0;
      await tester.pumpWidget(
        _enCaja(Bloque(alTocar: () => toques++, child: const Text('tocame'))),
      );

      await tester.tap(find.text('tocame'));
      expect(toques, 1);
    });
  });

  group('EtiquetaEstado', () {
    testWidgets('cada estado dice su palabra y el ancho lo pone la palabra', (
      tester,
    ) async {
      final anchos = <TipoEstado, double>{};
      for (final (estado, palabra) in [
        (TipoEstado.pendiente, 'Pendiente'),
        (TipoEstado.aprobada, 'Aprobada'),
        (TipoEstado.rechazada, 'Rechazada'),
        (TipoEstado.disponible, 'Disponible'),
        (TipoEstado.alquilado, 'Ya alquilado'),
      ]) {
        await tester.pumpWidget(
          _enCaja(Center(child: EtiquetaEstado(estado: estado))),
        );
        expect(find.text(palabra), findsOneWidget);
        anchos[estado] = tester.getSize(find.byType(EtiquetaEstado)).width;
      }

      expect(
        anchos[TipoEstado.alquilado],
        greaterThan(anchos[TipoEstado.aprobada]!),
      );
    });

    test('los atajos traducen el estado que manda el backend', () {
      expect(
        EtiquetaEstado.solicitud(EstadoSolicitud.rechazada).estado,
        TipoEstado.rechazada,
      );
      expect(
        const EtiquetaEstado.anuncio(EstadoAnuncio.alquilado).estado,
        TipoEstado.alquilado,
      );
    });
  });

  testWidgets('IconoCirculo: el icono mide la mitad del circulo', (
    tester,
  ) async {
    for (final diametro in [20.0, 48.0, 72.0]) {
      await tester.pumpWidget(
        _enCaja(Center(child: IconoCirculo(Icons.check, diametro: diametro))),
      );

      expect(
        tester.getSize(find.byType(IconoCirculo)),
        Size(diametro, diametro),
      );
      expect(tester.widget<Icon>(find.byIcon(Icons.check)).size, diametro / 2);
    }
  });

  testWidgets('EstadoVacio: la accion aparece solo si tiene texto', (
    tester,
  ) async {
    await tester.pumpWidget(
      _enCaja(
        const EstadoVacio(icono: Icons.inbox_outlined, titulo: 'Nada todavía'),
      ),
    );
    expect(find.byType(BotonSecundario), findsNothing);

    var reintentos = 0;
    await tester.pumpWidget(
      _enCaja(
        EstadoVacio(
          icono: Icons.error_outline,
          titulo: 'No cargó',
          esError: true,
          accion: 'Reintentar',
          alAccion: () => reintentos++,
        ),
      ),
    );
    await tester.tap(find.text('Reintentar'));
    expect(reintentos, 1);
    expect(
      tester.widget<Icon>(find.byIcon(Icons.error_outline)).color,
      AppColors.error,
    );
  });

  group('Botones', () {
    testWidgets('compacto: el mismo boton, con 48 de alto', (tester) async {
      await tester.pumpWidget(
        _enCaja(
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              BotonPrincipal(etiqueta: 'NORMAL', alTocar: () {}),
              BotonPrincipal(etiqueta: 'CHICO', alTocar: () {}, compacto: true),
              BotonSecundario(etiqueta: 'OTRO', alTocar: () {}, compacto: true),
            ],
          ),
        ),
      );

      expect(_cajaDe(tester, 'NORMAL').height, Medida.boton);
      expect(_cajaDe(tester, 'CHICO').height, Medida.campo);
      expect(_cajaDe(tester, 'OTRO').height, Medida.campo);
    });

    testWidgets('BotonTexto sin accion queda deshabilitado', (tester) async {
      await tester.pumpWidget(
        _enCaja(const BotonTexto(etiqueta: 'No tengo cuenta', alTocar: null)),
      );

      expect(tester.widget<TextButton>(find.byType(TextButton)).onPressed,
          isNull);
    });
  });

  testWidgets('Opcion: el ancho lo pone la palabra, el alto es el mismo', (
    tester,
  ) async {
    await tester.pumpWidget(
      _enCaja(
        Wrap(
          children: [
            Opcion(etiqueta: 'Casa', seleccionada: false, alTocar: () {}),
            Opcion(etiqueta: 'Departamento', seleccionada: true, alTocar: () {}),
          ],
        ),
      ),
    );

    final casa = tester.getSize(find.widgetWithText(Opcion, 'Casa'));
    final depto = tester.getSize(find.widgetWithText(Opcion, 'Departamento'));
    expect(depto.width, greaterThan(casa.width));
    expect(depto.height, casa.height);
  });

  group('CampoTexto', () {
    testWidgets('esClave: oculta el texto y el ojito lo muestra', (
      tester,
    ) async {
      await tester.pumpWidget(
        _enCaja(
          CampoTexto(
            etiqueta: 'Contraseña',
            controlador: TextEditingController(text: 'secreto'),
            esClave: true,
          ),
        ),
      );

      bool oculto() =>
          tester.widget<TextField>(find.byType(TextField)).obscureText;
      expect(oculto(), isTrue);

      await tester.tap(find.byIcon(Icons.visibility_outlined));
      await tester.pump();
      expect(oculto(), isFalse);
    });

    testWidgets('unidad: se lee a la derecha, dentro de la caja', (
      tester,
    ) async {
      await tester.pumpWidget(
        _enCaja(
          CampoTexto(
            etiqueta: 'Alquiler mensual',
            controlador: TextEditingController(),
            unidad: 'Bs',
          ),
        ),
      );

      final caja = tester.getRect(find.byType(AnimatedContainer));
      final unidad = tester.getRect(find.text('Bs'));
      expect(caja.contains(unidad.center), isTrue);
      expect(unidad.left, greaterThan(caja.center.dx));
    });
  });

  testWidgets('ResumenBusqueda: nombra los cuatro filtros, usados o no', (
    tester,
  ) async {
    await tester.pumpWidget(
      _enCaja(
        const ResumenBusqueda(filtros: FiltrosBusqueda(minutosMax: 15)),
      ),
    );
    expect(find.text('Tu búsqueda'), findsOneWidget);
    expect(find.text('Sin límite de precio'), findsOneWidget);
    expect(find.text('Cualquier tipo de espacio'), findsOneWidget);
    expect(find.text('Con o sin mascotas'), findsOneWidget);
    expect(find.text('Hasta 15 min caminando'), findsOneWidget);

    await tester.pumpWidget(
      _enCaja(
        const ResumenBusqueda(
          filtros: FiltrosBusqueda(
            precioMax: 800,
            tipoEspacio: TipoEspacio.habitacion,
            aceptaMascotas: true,
            minutosMax: 15,
          ),
          cantidad: 3,
        ),
      ),
    );
    expect(find.text('Hasta 800 Bs por mes'), findsOneWidget);
    expect(find.text('Habitación'), findsOneWidget);
    expect(find.text('Acepta mascotas'), findsOneWidget);
    expect(find.text('3 anuncios encontrados'), findsOneWidget);
  });

  group('PieAcciones', () {
    const aviso = 'No se pudo publicar. Revisá tu conexión.';
    const nota = 'Coordiná la visita por WhatsApp antes de ir.';
    const motivo = 'Corregí los 3 campos marcados en rojo para poder publicar.';

    testWidgets('las ranuras salen en el orden de la pieza, con 8 entre ellas', (
      tester,
    ) async {
      await tester.pumpWidget(
        _enCaja(
          PieAcciones(
            aviso: const Aviso(mensaje: aviso, tipo: TipoAviso.error),
            notaArriba: nota,
            botonSecundarioArriba:
                BotonSecundario(etiqueta: 'CANCELAR', alTocar: () {}),
            botonPrincipal: BotonPrincipal(etiqueta: 'PUBLICAR', alTocar: () {}),
            botonSecundarioAbajo: BotonSecundario(
              etiqueta: 'Rechazar',
              destructiva: true,
              alTocar: () {},
            ),
            motivo: motivo,
            notaWhatsApp: true,
          ),
        ),
      );

      // De arriba hacia abajo, siempre en este orden.
      final textos = [
        aviso,
        nota,
        'CANCELAR',
        'PUBLICAR',
        'Rechazar',
        motivo,
        PieAcciones.textoNotaWhatsApp,
      ];
      final altos = [for (final t in textos) tester.getTopLeft(find.text(t)).dy];
      for (var i = 1; i < altos.length; i++) {
        expect(
          altos[i],
          greaterThan(altos[i - 1]),
          reason: '"${textos[i]}" va debajo de "${textos[i - 1]}"',
        );
      }

      // 8 entre ranuras, tambien entre los botones.
      final cancelar = tester.getRect(find.widgetWithText(BotonSecundario, 'CANCELAR'));
      final principal = tester.getRect(find.byType(BotonPrincipal));
      final rechazar = tester.getRect(find.widgetWithText(BotonSecundario, 'Rechazar'));
      expect(principal.top - cancelar.bottom, Espacio.sm);
      expect(rechazar.top - principal.bottom, Espacio.sm);
      expect(principal.width, cancelar.width);

      // Las notas van centradas y con el color que les toca.
      final textoMotivo = tester.widget<Text>(find.text(motivo));
      expect(textoMotivo.textAlign, TextAlign.center);
      expect(textoMotivo.style?.color, AppColors.error);
      expect(tester.widget<Text>(find.text(nota)).style?.color, AppColors.text70);
      expect(find.byIcon(Icons.lock_outline), findsOneWidget);
    });

    testWidgets('las ranuras vacias no ocupan lugar', (tester) async {
      // Solo el boton: el pie mide lo que el boton.
      await tester.pumpWidget(
        _enCaja(
          PieAcciones(
            botonPrincipal: BotonPrincipal(etiqueta: 'CONTINUAR', alTocar: () {}),
          ),
        ),
      );
      expect(tester.getSize(find.byType(PieAcciones)).height, Medida.boton);
      expect(find.byType(Aviso), findsNothing);
      expect(find.byType(BotonSecundario), findsNothing);
      expect(find.byIcon(Icons.lock_outline), findsNothing);

      // Solo el aviso, como el inicio despues de publicar: sin boton
      // principal, el pie es el aviso y nada mas.
      await tester.pumpWidget(
        _enCaja(
          const PieAcciones(
            aviso: Aviso(mensaje: 'Publicado.', tipo: TipoAviso.exito),
          ),
        ),
      );
      expect(tester.getSize(find.byType(PieAcciones)).height, 64);
      expect(find.byType(BotonPrincipal), findsNothing);
      expect(find.text('Publicado.'), findsOneWidget);
    });
  });

  group('PrecioFinal', () {
    const monto = '1250.00';
    final cifra = PrecioFinal.cifraDe(monto);

    Widget conAncho(double ancho, Widget hijo) =>
        _app(Scaffold(body: Center(child: SizedBox(width: ancho, child: hijo))));

    testWidgets('barra: etiqueta a la izquierda y cifra a la derecha, en una '
        'linea, a todo el ancho', (tester) async {
      await tester.pumpWidget(
        conAncho(720, const PrecioFinal(monto: monto)),
      );

      final barra = tester.getRect(find.byType(PrecioFinal));
      final etiqueta = tester.getRect(find.text(PrecioFinal.etiqueta));
      final numero = tester.getRect(find.text(cifra));

      // La barra no se achica a su contenido aunque nadie la estire.
      expect(barra.width, 720);
      expect(numero.left, greaterThan(etiqueta.right));
      expect(numero.center.dy, closeTo(etiqueta.center.dy, 1));
      expect(etiqueta.left, barra.left + Espacio.md);
      expect(numero.right, barra.right - Espacio.md);
      expect(
        tester.widget<Text>(find.text(cifra)).style?.color,
        AppColors.surface,
      );
    });

    testWidgets('barra angosta: la cifra baja entera a la linea siguiente, '
        'sin cortarse ni desbordar', (tester) async {
      // Entra la cifra sola, pero no al lado de la etiqueta: como en un
      // telefono con la barra dentro del resumen del anuncio.
      await tester.pumpWidget(
        conAncho(480, const PrecioFinal(monto: monto)),
      );

      expect(tester.takeException(), isNull);
      final etiqueta = tester.getRect(find.text(PrecioFinal.etiqueta));
      final numero = tester.getRect(find.text(cifra));
      expect(numero.top, greaterThanOrEqualTo(etiqueta.bottom));
      expect(numero.left, etiqueta.left);
      expect(numero.height, lessThan(numero.width), reason: 'una sola linea');
    });

    testWidgets('resumen: la etiqueta arriba y la cifra en verde', (
      tester,
    ) async {
      await tester.pumpWidget(
        _enCaja(const PrecioFinal(monto: monto, estilo: EstiloPrecio.resumen)),
      );

      final etiqueta = tester.getRect(find.text(PrecioFinal.etiqueta));
      final numero = tester.getRect(find.text(cifra));
      expect(numero.top - etiqueta.bottom, Espacio.sm);
      expect(numero.left, etiqueta.left);
      expect(
        tester.widget<Text>(find.text(cifra)).style?.color,
        AppColors.primary,
      );
    });
  });
}
