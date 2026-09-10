import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme.dart';
import '../../../shared/layout/grilla.dart';
import '../../../shared/layout/pagina.dart';
import '../../../shared/widgets/aviso.dart';
import '../../../shared/widgets/bloque.dart';
import '../../../shared/widgets/boton_principal.dart';
import '../../../shared/widgets/boton_secundario.dart';
import '../../../shared/widgets/casilla.dart';
import '../../../shared/widgets/fila_condicion.dart';
import '../../propietario/data/anuncio.dart';
import '../providers/solicitud_provider.dart';
import 'solicitud_estado_screen.dart';

/// Vista 05 — Solicitar visita.
///
/// El inquilino revisa las condiciones del anuncio, las acepta explicitamente
/// con un checkbox y envía la solicitud. El contacto del propietario solo se
/// libera después de la aprobación (pantalla 06).
class SolicitarVisitaScreen extends StatefulWidget {
  const SolicitarVisitaScreen({super.key, required this.anuncio});

  final Anuncio anuncio;

  @override
  State<SolicitarVisitaScreen> createState() => _SolicitarVisitaScreenState();
}

class _SolicitarVisitaScreenState extends State<SolicitarVisitaScreen> {
  bool _condicionesAceptadas = false;

  Future<void> _enviar() async {
    final provider = context.read<SolicitudProvider>();
    final ok = await provider.enviar(widget.anuncio.id);

    if (!mounted) return;

    if (!ok) {
      Aviso.mostrarToast(
        context,
        mensaje: provider.error ?? 'No se pudo enviar la solicitud.',
        tipo: TipoAviso.error,
      );
      return;
    }

    // Navega a la pantalla de estado reemplazando esta para que el botón
    // "volver" no regrese aquí sino a los resultados.
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => ChangeNotifierProvider.value(
          value: provider,
          child: const SolicitudEstadoScreen(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<SolicitudProvider>();
    final anuncio = widget.anuncio;
    final tenue = AppText.caption(context)
        .copyWith(color: AppColors.text.withValues(alpha: 0.7));

    final servicios = [
      if (anuncio.serviciosIncluidos['agua'] == true) 'Agua',
      if (anuncio.serviciosIncluidos['luz'] == true) 'Luz',
      if (anuncio.serviciosIncluidos['internet'] == true) 'Internet',
    ];
    final serviciosTexto = servicios.isNotEmpty
        ? ', todo incluido (${servicios.join(", ")})'
        : '';

    final condiciones = <(IconData, String)>[
      (Icons.attach_money, '${anuncio.precioFinal} Bs por mes$serviciosTexto'),
      (
        Icons.directions_walk,
        '${anuncio.minutosCaminando} min caminando a la UAGRM',
      ),
      (
        anuncio.aceptaMascotas ? Icons.pets : Icons.pets_outlined,
        anuncio.aceptaMascotas ? 'Acepta mascotas' : 'No acepta mascotas',
      ),
      if (anuncio.restricciones.isNotEmpty)
        (Icons.info_outline, anuncio.restricciones),
    ];

    return Pagina(
      titulo: 'Solicitar visita',
      pie: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // La salida secundaria va arriba, como en el wireframe: la accion
          // principal queda al alcance del pulgar.
          BotonSecundario(
            etiqueta: 'CANCELAR',
            alTocar:
                provider.cargando ? null : () => Navigator.of(context).pop(),
          ),
          const SizedBox(height: Espacio.sm),
          BotonPrincipal(
            etiqueta: 'ENVIAR SOLICITUD',
            etiquetaCargando: 'ENVIANDO...',
            // null deshabilita: es como la pieza expresa "falta algo".
            alTocar: _condicionesAceptadas ? _enviar : null,
            cargando: provider.cargando,
            motivoDeshabilitado: 'Marcá que aceptás las condiciones.',
          ),
        ],
      ),
      hijos: [
        // GRID: lo que se acepta ocupa 8 columnas; el aviso y el precio, 4.
        // En movil van 12 y 12, en el orden del wireframe.
        Grilla12(
          separacionFilas: Espacio.lg,
          celdas: [
            CeldaGrilla(
              columnas: const Columnas(tablet: 6, escritorio: 8),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Aceptás estas condiciones antes de solicitar la visita. '
                    'El propietario no necesita repetírtelas.',
                    style: tenue,
                  ),
                  const SizedBox(height: Espacio.lg),

                  // ---- Condiciones del anuncio ----
                  Bloque(
                    tono: TonoBloque.suave,
                    hijos: [
                      Text('Estás aceptando:', style: tenue),
                      for (final (icono, texto) in condiciones) ...[
                        const SizedBox(height: Espacio.sm),
                        FilaCondicion(icono: icono, texto: texto),
                      ],
                    ],
                  ),
                  const SizedBox(height: Espacio.lg),

                  // ---- Checkbox de aceptación ----
                  Casilla(
                    etiqueta: 'Acepto estas condiciones',
                    marcado: _condicionesAceptadas,
                    alCambiar: (v) =>
                        setState(() => _condicionesAceptadas = v ?? false),
                  ),
                ],
              ),
            ),
            CeldaGrilla(
              columnas: const Columnas(tablet: 6, escritorio: 4),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // ---- Aviso del contacto ----
                  const Aviso(
                    icono: Icons.lock_clock_outlined,
                    mensaje:
                        'Cuando el propietario apruebe tu solicitud, recibirás su contacto de WhatsApp.',
                  ),
                  const SizedBox(height: Espacio.lg),

                  // ---- Resumen de precio ----
                  Bloque(
                    tono: TonoBloque.suave,
                    hijos: [
                      Text('Precio final', style: tenue),
                      const SizedBox(height: Espacio.sm),
                      Text(
                        '${anuncio.precioFinal} Bs / mes',
                        style: AppText.cifra(context)
                            .copyWith(color: AppColors.primary),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}
