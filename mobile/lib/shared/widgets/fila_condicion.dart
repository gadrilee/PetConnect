import 'package:flutter/material.dart';

import '../../core/theme.dart';

/// Una condicion del anuncio: un icono y el dato que explica.
///
/// REGLA DE LA PIEZA
/// -----------------
/// El icono ocupa siempre 32 y el texto arranca a 24 del borde. Se apilan con
/// 8 entre filas, de modo que el ritmo entre condiciones sea siempre el mismo.
/// El icono orienta, no decora: si no aporta a distinguir el dato, sobra.
///
/// Estaba escrita dos veces —en el detalle del anuncio y en la pantalla de
/// solicitar visita— con un tamano de texto distinto en cada una, asi que la
/// misma condicion se leia diferente segun donde apareciera.
class FilaCondicion extends StatelessWidget {
  const FilaCondicion({super.key, required this.icono, required this.texto});

  final IconData icono;
  final String texto;

  @override
  Widget build(BuildContext context) {
    final esquema = Theme.of(context).colorScheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: esquema.primaryContainer.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Icon(icono, size: 16, color: esquema.primary),
        ),
        const SizedBox(width: Espacio.sm),
        Expanded(
          child: Padding(
            // 8 = (32 - 16) / 2. Centra la PRIMERA linea con el icono y deja
            // que el texto largo crezca hacia abajo, en vez de centrar todo
            // el bloque y que el icono quede flotando en el medio.
            padding: const EdgeInsets.only(top: Espacio.sm),
            child: Text(texto, style: Theme.of(context).textTheme.bodyMedium),
          ),
        ),
      ],
    );
  }
}
