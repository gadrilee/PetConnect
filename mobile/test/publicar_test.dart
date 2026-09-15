import 'dart:async';

import 'package:alquilamatch/core/api_client.dart';
import 'package:alquilamatch/core/theme.dart';
import 'package:alquilamatch/features/propietario/data/anuncio.dart';
import 'package:alquilamatch/features/propietario/data/anuncios_repository.dart';
import 'package:alquilamatch/features/propietario/presentation/publicar_screen.dart';
import 'package:alquilamatch/features/propietario/providers/publicar_provider.dart';
import 'package:alquilamatch/shared/widgets/aviso.dart';
import 'package:alquilamatch/shared/widgets/boton_principal.dart';
import 'package:alquilamatch/shared/widgets/campo_texto.dart';
import 'package:alquilamatch/shared/widgets/casilla.dart';
import 'package:alquilamatch/shared/widgets/controles.dart';
import 'package:alquilamatch/shared/widgets/pie_acciones.dart';
import 'package:alquilamatch/shared/widgets/precio_final.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

/// Pruebas de Publicar contra los frames de Figma del flujo v0.1: "02
/// Publicar", "02 Publicar · vacío", "03 Datos con error", "04 Falta la
/// ubicación" y "05 No se pudo publicar".
///
/// Corren sin backend, con un repositorio en memoria y el tema real, en un
/// telefono de 360 x 800.

const _telefono = Size(360, 800);

const _campoTitulo = 'Título del anuncio';
const _campoAlquiler = 'Alquiler mensual';
const _campoServicios = 'Cuánto paga aparte por los servicios';

const _faltaUbicacion = 'Falta marcar la ubicación del inmueble. Tocá Usar GPS.';
const _noSePudoPublicar =
    'No se pudo publicar. Revisá tu conexión e intentá de nuevo.';

const _anuncio = Anuncio(
  id: 1,
  titulo: 'Habitación luminosa cerca de la UAGRM',
  tipoEspacio: TipoEspacio.habitacion,
  precioFinal: '1100.00',
  aceptaMascotas: false,
  minutosCaminando: 12,
  estado: EstadoAnuncio.disponible,
);

/// Publica en memoria. Con [falla] responde como un backend caido; con
/// [demorar] deja el envio en el aire hasta que la prueba lo suelte.
class _RepoFalso extends Fake implements AnunciosRepository {
  _RepoFalso({this.falla, this.demorar});

  final Exception? falla;
  final Completer<void>? demorar;
  int publicaciones = 0;

  @override
  Future<Anuncio> publicar({
    required String titulo,
    required TipoEspacio tipoEspacio,
    required String precioAlquiler,
    required bool incluyeAgua,
    required bool incluyeLuz,
    required bool incluyeInternet,
    required String costoServiciosEstimado,
    required bool aceptaMascotas,
    required double lat,
    required double lng,
    String restricciones = '',
    String direccionReferencia = '',
    List<FotoParaSubir> fotos = const [],
  }) async {
    publicaciones++;
    if (demorar != null) await demorar!.future;
    if (falla != null) throw falla!;
    return _anuncio;
  }
}

/// Abre Publicar encima de una pantalla vacia, como en la app, para poder
/// comprobar que al publicar vuelve con el anuncio.
Future<(PublicarProvider, Future<Anuncio?>)> _montar(
  WidgetTester tester, {
  _RepoFalso? repo,
}) async {
  tester.view.physicalSize = _telefono;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  final provider = PublicarProvider(repo ?? _RepoFalso());
  await tester.pumpWidget(
    MaterialApp(theme: AppTheme.claro, home: const SizedBox.shrink()),
  );
  final resultado = tester
      .state<NavigatorState>(find.byType(Navigator))
      .push<Anuncio>(
        MaterialPageRoute(
          builder: (_) => ChangeNotifierProvider.value(
            value: provider,
            child: const PublicarScreen(),
          ),
        ),
      );
  await tester.pumpAndSettle();
  return (provider, resultado);
}

Finder _campo(String etiqueta) => find.descendant(
  of: find.widgetWithText(CampoTexto, etiqueta),
  matching: find.byType(TextField),
);

Future<void> _escribir(
  WidgetTester tester,
  String etiqueta,
  String texto,
) async {
  await tester.enterText(_campo(etiqueta), texto);
  await tester.pumpAndSettle();
}

/// Los tres campos con valores que sirven: 800 + 300 = 1.100 Bs, como en Figma.
Future<void> _completarCampos(WidgetTester tester) async {
  await _escribir(tester, _campoTitulo, _anuncio.titulo);
  await _escribir(tester, _campoAlquiler, '800');
  await _escribir(tester, _campoServicios, '300');
}

Future<void> _marcarUbicacion(
  WidgetTester tester,
  PublicarProvider provider,
) async {
  provider.fijarUbicacionManual(-17.7833, -63.1821);
  await tester.pumpAndSettle();
}

/// El estado no se pasa por parametro: se deriva. Se lee desde el State.
EstadoBoton _estadoDelBoton(WidgetTester tester) {
  final state = tester.state(find.byType(BotonPrincipal));
  return (state as dynamic).estado as EstadoBoton;
}

/// El aviso del pie, si lo hay.
Aviso? _avisoDelPie(WidgetTester tester) {
  final aviso = find.descendant(
    of: find.byType(PieAcciones),
    matching: find.byType(Aviso),
  );
  return aviso.evaluate().isEmpty ? null : tester.widget<Aviso>(aviso);
}

Finder get _motivo => find.textContaining('para poder publicar.');

void main() {
  group('02 Publicar: que estas alquilando', () {
    testWidgets('las tres opciones reparten la fila por partes iguales, con 8 '
        'entre ellas y la etiqueta centrada', (tester) async {
      await _montar(tester);
      expect(tester.takeException(), isNull);

      // Es la pieza la que reparte, no la pantalla a mano.
      expect(find.byType(FilaOpciones), findsOneWidget);
      final opciones = find.byType(Opcion);
      expect(opciones, findsNWidgets(3));
      final rects = [for (var i = 0; i < 3; i++) tester.getRect(opciones.at(i))];
      final fila = tester.getRect(find.widgetWithText(CampoTexto, _campoTitulo));

      // Del mismo ancho y en una sola fila: "Casa" mide lo mismo que
      // "Departamento" en vez de encogerse a su palabra.
      expect(rects[1].width, closeTo(rects[0].width, 0.01));
      expect(rects[2].width, closeTo(rects[0].width, 0.01));
      expect(rects[1].top, rects[0].top);
      expect(rects[2].top, rects[0].top);

      // De punta a punta del formulario, con 8 entre una y otra.
      expect(rects[0].left, fila.left);
      expect(rects[2].right, closeTo(fila.right, 0.01));
      expect(rects[1].left - rects[0].right, closeTo(Espacio.sm, 0.01));
      expect(rects[2].left - rects[1].right, closeTo(Espacio.sm, 0.01));

      // La etiqueta queda centrada en su pastilla, no pegada a la izquierda.
      expect(
        tester.getCenter(find.text('Casa')).dx,
        closeTo(rects[2].center.dx, 0.5),
      );

      // Sigue siendo la misma Opcion: tocarla la elige.
      await tester.tap(find.text('Casa'));
      await tester.pump();
      expect(tester.widget<Opcion>(opciones.at(2)).seleccionada, isTrue);
      expect(tester.widget<Opcion>(opciones.at(0)).seleccionada, isFalse);
    });
  });

  group('02 Publicar: precio final', () {
    testWidgets('la barra suma alquiler y servicios, y con todo incluido deja '
        'de sumar los servicios, como lo que se publica', (tester) async {
      await _montar(tester);
      await _completarCampos(tester);
      expect(find.text(PrecioFinal.cifraDe('1100')), findsOneWidget);

      // Agua y luz ya vienen marcadas: con internet queda todo incluido, el
      // campo de servicios se esconde y la barra baja a lo que se manda (0
      // de servicios). Antes seguia diciendo 1.100 y se publicaba 800.
      await tester.tap(find.widgetWithText(Casilla, 'Internet'));
      await tester.pumpAndSettle();
      expect(find.widgetWithText(CampoTexto, _campoServicios), findsNothing);
      expect(find.text(PrecioFinal.cifraDe('800')), findsOneWidget);
      expect(find.text(PrecioFinal.cifraDe('1100')), findsNothing);

      // Al desmarcar, el campo vuelve con su 300 y la barra lo suma de nuevo.
      await tester.tap(find.widgetWithText(Casilla, 'Internet'));
      await tester.pumpAndSettle();
      expect(find.text(PrecioFinal.cifraDe('1100')), findsOneWidget);
    });
  });

  group('02 Publicar · vacío', () {
    testWidgets('el boton esta apagado, sin motivo, sin aviso y sin rojos', (
      tester,
    ) async {
      await _montar(tester);

      expect(_estadoDelBoton(tester), EstadoBoton.deshabilitado);
      expect(_motivo, findsNothing);
      expect(_avisoDelPie(tester), isNull);
      // Un campo vacio que nadie toco todavia no es un error.
      expect(find.text('Poné un título'), findsNothing);
      expect(find.text('Poné un monto válido'), findsNothing);
      expect(find.text('Estimá cuánto paga aparte'), findsNothing);
      expect(find.text(PieAcciones.textoNotaWhatsApp), findsOneWidget);
    });
  });

  group('03 Datos con error', () {
    testWidgets('cada campo dice que corregir, el boton sigue apagado y el pie '
        'cuenta cuantos hay en rojo', (tester) async {
      await _montar(tester);

      // Un titulo que se borra, un alquiler que no es un numero y el costo de
      // los servicios vacio: los servicios validan igual que el alquiler.
      await _escribir(tester, _campoTitulo, 'Casa');
      await _escribir(tester, _campoTitulo, '');
      await _escribir(tester, _campoAlquiler, 'abc');
      await _escribir(tester, _campoServicios, '');

      expect(find.text('Poné un título'), findsOneWidget);
      expect(find.text('Poné un monto válido'), findsOneWidget);
      expect(find.text('Estimá cuánto paga aparte'), findsOneWidget);
      expect(_estadoDelBoton(tester), EstadoBoton.deshabilitado);

      const tres = 'Corregí los 3 campos marcados en rojo para poder publicar.';
      expect(find.text(tres), findsOneWidget);
      // Es la ranura motivo del pie: en rojo y debajo del boton.
      expect(tester.widget<Text>(find.text(tres)).style?.color, AppColors.error);
      expect(
        tester.getTopLeft(find.text(tres)).dy,
        greaterThan(tester.getBottomLeft(find.byType(BotonPrincipal)).dy),
      );
      // Sin ubicacion todavia, pero eso no se avisa mientras haya rojos.
      expect(_avisoDelPie(tester), isNull);

      // Corregir un campo baja la cuenta; corregirlos todos la borra.
      await _escribir(tester, _campoAlquiler, '800');
      expect(find.text('Poné un monto válido'), findsNothing);
      expect(
        find.text('Corregí los 2 campos marcados en rojo para poder publicar.'),
        findsOneWidget,
      );

      await _escribir(tester, _campoServicios, '300');
      expect(
        find.text('Corregí el campo marcado en rojo para poder publicar.'),
        findsOneWidget,
      );

      await _escribir(tester, _campoTitulo, _anuncio.titulo);
      expect(_motivo, findsNothing);
    });

    testWidgets('un monto negativo o cero tampoco sirve', (tester) async {
      await _montar(tester);

      await _escribir(tester, _campoAlquiler, '0');
      expect(find.text('Poné un monto válido'), findsOneWidget);

      await _escribir(tester, _campoServicios, '-5');
      expect(find.text('Estimá cuánto paga aparte'), findsOneWidget);

      // Pero 0 de servicios si: puede no pagar nada aparte.
      await _escribir(tester, _campoServicios, '0');
      expect(find.text('Estimá cuánto paga aparte'), findsNothing);
    });
  });

  group('04 Falta la ubicación', () {
    testWidgets('con los campos bien pero sin ubicacion, avisa en naranja '
        'arriba del boton apagado', (tester) async {
      final (provider, _) = await _montar(tester);
      await _completarCampos(tester);

      final aviso = _avisoDelPie(tester);
      expect(aviso, isNotNull);
      expect(aviso!.tipo, TipoAviso.advertencia);
      expect(aviso.mensaje, _faltaUbicacion);
      expect(_estadoDelBoton(tester), EstadoBoton.deshabilitado);
      // No es un error de los campos: no hay motivo.
      expect(_motivo, findsNothing);

      // El aviso va en el pie, arriba del boton y de su mismo ancho: nunca
      // encima, como el toast de antes.
      final rectAviso = tester.getRect(find.byType(Aviso));
      final rectBoton = tester.getRect(find.byType(BotonPrincipal));
      expect(rectAviso.bottom, lessThanOrEqualTo(rectBoton.top));
      expect(rectAviso.width, rectBoton.width);

      // Marcada la ubicacion, el aviso se va y el boton se prende.
      await _marcarUbicacion(tester, provider);
      expect(_avisoDelPie(tester), isNull);
      expect(_estadoDelBoton(tester), EstadoBoton.reposo);
    });

    testWidgets('con el formulario a medias no avisa: primero los campos', (
      tester,
    ) async {
      await _montar(tester);
      await _escribir(tester, _campoTitulo, _anuncio.titulo);

      expect(_avisoDelPie(tester), isNull);
      expect(_estadoDelBoton(tester), EstadoBoton.deshabilitado);
    });
  });

  group('Publicar', () {
    testWidgets('con todo listo el boton se prende, publica y vuelve con el '
        'anuncio', (tester) async {
      final repo = _RepoFalso(demorar: Completer<void>());
      final (provider, resultado) = await _montar(tester, repo: repo);
      await _completarCampos(tester);
      await _marcarUbicacion(tester, provider);
      expect(_estadoDelBoton(tester), EstadoBoton.reposo);

      await tester.tap(find.text('PUBLICAR'));
      await tester.pump();

      // Mientras publica, el boton lo dice y no acepta otro toque.
      expect(_estadoDelBoton(tester), EstadoBoton.cargando);
      expect(find.text('PUBLICANDO...'), findsOneWidget);

      repo.demorar!.complete();
      await tester.pumpAndSettle();

      expect(repo.publicaciones, 1);
      expect(find.byType(PublicarScreen), findsNothing);
      expect(await resultado, same(_anuncio));
    });
  });

  group('05 No se pudo publicar', () {
    testWidgets('avisa en rojo y deja el boton prendido para reintentar', (
      tester,
    ) async {
      final repo = _RepoFalso(
        falla: ApiException('No se pudo conectar con el servidor.'),
      );
      final (provider, _) = await _montar(tester, repo: repo);
      await _completarCampos(tester);
      await _marcarUbicacion(tester, provider);

      await tester.tap(find.text('PUBLICAR'));
      await tester.pumpAndSettle();

      final aviso = _avisoDelPie(tester);
      expect(aviso, isNotNull);
      expect(aviso!.tipo, TipoAviso.error);
      expect(aviso.mensaje, _noSePudoPublicar);
      expect(_motivo, findsNothing);
      // La pantalla sigue abierta y el boton, prendido: se puede reintentar.
      expect(find.byType(PublicarScreen), findsOneWidget);
      expect(_estadoDelBoton(tester), EstadoBoton.reposo);

      await tester.tap(find.text('PUBLICAR'));
      await tester.pumpAndSettle();
      expect(repo.publicaciones, 2);
    });

    testWidgets('el servidor caido es el mismo caso que sin red', (
      tester,
    ) async {
      final repo = _RepoFalso(
        falla: ApiException(
          'El servidor tuvo un problema. Intentá de nuevo en un momento.',
          codigo: 500,
        ),
      );
      final (provider, _) = await _montar(tester, repo: repo);
      await _completarCampos(tester);
      await _marcarUbicacion(tester, provider);

      await tester.tap(find.text('PUBLICAR'));
      await tester.pumpAndSettle();

      final aviso = _avisoDelPie(tester);
      expect(aviso?.tipo, TipoAviso.error);
      expect(aviso?.mensaje, _noSePudoPublicar);
      expect(_estadoDelBoton(tester), EstadoBoton.reposo);
    });

    testWidgets('si el backend rechaza el pedido entero (403), el aviso repite '
        'lo que dijo en vez de culpar a la conexion', (tester) async {
      const sinPermiso = 'No tenés permiso para hacer esto.';
      final repo = _RepoFalso(
        falla: ApiException(sinPermiso, codigo: 403),
      );
      final (provider, _) = await _montar(tester, repo: repo);
      await _completarCampos(tester);
      await _marcarUbicacion(tester, provider);

      await tester.tap(find.text('PUBLICAR'));
      await tester.pumpAndSettle();

      final aviso = _avisoDelPie(tester);
      expect(aviso, isNotNull);
      expect(aviso!.tipo, TipoAviso.error);
      expect(aviso.mensaje, sinPermiso);
      expect(find.text(_noSePudoPublicar), findsNothing);
      // Ningun campo tiene la culpa: sin rojos ni motivo, y se puede
      // reintentar.
      expect(_motivo, findsNothing);
      expect(_estadoDelBoton(tester), EstadoBoton.reposo);
    });

    testWidgets('lo que el backend objeta de algo que no es un campo de la '
        'pantalla, como una foto, va al aviso del pie', (tester) async {
      const fotoMala = 'La imagen tiene que ser JPG o PNG.';
      final repo = _RepoFalso(
        falla: ApiException(
          fotoMala,
          codigo: 400,
          porCampo: {'imagen': fotoMala},
        ),
      );
      final (provider, _) = await _montar(tester, repo: repo);
      await _completarCampos(tester);
      await _marcarUbicacion(tester, provider);

      await tester.tap(find.text('PUBLICAR'));
      await tester.pumpAndSettle();

      // No hay campo donde pintarlo en rojo, asi que no se calla: lo dice el
      // aviso, con las palabras del backend, y el boton queda para reintentar.
      final aviso = _avisoDelPie(tester);
      expect(aviso, isNotNull);
      expect(aviso!.tipo, TipoAviso.error);
      expect(aviso.mensaje, fotoMala);
      expect(_motivo, findsNothing);
      expect(_estadoDelBoton(tester), EstadoBoton.reposo);
    });

    testWidgets('lo que el backend objeta va debajo del campo y se destraba al '
        'corregirlo', (tester) async {
      final repo = _RepoFalso(
        falla: ApiException(
          'Datos inválidos.',
          codigo: 400,
          porCampo: {'titulo': 'Máximo 120 caracteres.'},
        ),
      );
      final (provider, _) = await _montar(tester, repo: repo);
      await _completarCampos(tester);
      await _marcarUbicacion(tester, provider);

      await tester.tap(find.text('PUBLICAR'));
      await tester.pumpAndSettle();

      expect(find.text('Máximo 120 caracteres.'), findsOneWidget);
      expect(
        find.text('Corregí el campo marcado en rojo para poder publicar.'),
        findsOneWidget,
      );
      expect(_estadoDelBoton(tester), EstadoBoton.deshabilitado);
      // Un campo objetado no es un problema de conexion: el aviso rojo de
      // "05" no aparece. El error se cuenta una sola vez, debajo del campo.
      expect(_avisoDelPie(tester), isNull);
      expect(find.text(_noSePudoPublicar), findsNothing);

      // Editar el campo descarta la objecion: si no, el boton quedaria
      // apagado para siempre.
      await _escribir(tester, _campoTitulo, 'Habitación con patio');
      expect(find.text('Máximo 120 caracteres.'), findsNothing);
      expect(_motivo, findsNothing);
      expect(_estadoDelBoton(tester), EstadoBoton.reposo);
      // Y no queda ningun aviso viejo colgado del pie.
      expect(_avisoDelPie(tester), isNull);
    });
  });
}
