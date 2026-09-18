import 'package:alquilamatch/core/theme.dart';
import 'package:alquilamatch/shared/widgets/boton_principal.dart';
import 'package:alquilamatch/shared/widgets/campo_texto.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Capturas de referencia de las piezas compartidas.
///
/// Los demas tests preguntan por el comportamiento ("¿se puede tocar?",
/// "¿muestra el error?"). Este pregunta por el aspecto: guarda una imagen de
/// cada pieza y falla si alguien la cambia sin querer. Es el equivalente de
/// mirar la pagina "Sistema visual" de Figma, pero automatico.
///
/// Cuando un cambio de aspecto es a proposito, se vuelven a generar con:
///
///     flutter test --update-goldens test/goldens_piezas_test.dart
///
/// y la imagen nueva queda en el commit, asi que en el diff se ve que cambio.
///
/// OJO: en las pruebas el texto se dibuja como bloques, porque no se carga la
/// tipografia real. Alcanza para detectar cambios de tamano, color, borde,
/// espaciado y posicion, que es lo que se desarma solo.

/// Cada pieza se captura sobre el tema de la app y a un ancho fijo: si el
/// ancho cambiara entre corridas, la imagen no serviria de referencia.
Widget _catalogo({required String titulo, required List<Widget> piezas}) {
  return MaterialApp(
    theme: AppTheme.claro,
    debugShowCheckedModeBanner: false,
    home: Scaffold(
      body: Center(
        child: SizedBox(
          width: 360,
          child: Padding(
            padding: const EdgeInsets.all(Espacio.lg),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (final pieza in piezas) ...[
                  pieza,
                  const SizedBox(height: Espacio.md),
                ],
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

void main() {
  testWidgets('Botón principal: sus estados', (tester) async {
    await tester.pumpWidget(
      _catalogo(
        titulo: 'boton',
        piezas: [
          // Reposo: se puede tocar.
          BotonPrincipal(etiqueta: 'ENTRAR', alTocar: () {}),
          // Cargando: hay una operacion en curso.
          BotonPrincipal(
            etiqueta: 'ENTRAR',
            etiquetaCargando: 'ENTRANDO...',
            cargando: true,
            alTocar: () {},
          ),
          // Deshabilitado: falta algo, y se dice que falta.
          const BotonPrincipal(
            etiqueta: 'ENTRAR',
            alTocar: null,
            pistaDeshabilitado: 'Completá los datos para continuar.',
          ),
        ],
      ),
    );
    await tester.pump();

    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/boton_principal.png'),
    );
  });

  testWidgets('Campo de texto: sus estados', (tester) async {
    final vacio = TextEditingController();
    final lleno = TextEditingController(text: 'marta@uagrm.edu.bo');
    final conError = TextEditingController(text: '7009');
    addTearDown(vacio.dispose);
    addTearDown(lleno.dispose);
    addTearDown(conError.dispose);

    await tester.pumpWidget(
      _catalogo(
        titulo: 'campo',
        piezas: [
          CampoTexto(
            etiqueta: 'Correo',
            controlador: vacio,
            pista: 'tucorreo@ejemplo.com',
            icono: Icons.mail_outline,
          ),
          CampoTexto(
            etiqueta: 'Correo',
            controlador: lleno,
            icono: Icons.mail_outline,
          ),
          CampoTexto(
            etiqueta: 'WhatsApp',
            controlador: conError,
            icono: Icons.chat_outlined,
            mensajeError: 'Escribí los 8 dígitos, como 70099988.',
          ),
        ],
      ),
    );
    await tester.pump();

    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/campo_texto.png'),
    );
  });
}
