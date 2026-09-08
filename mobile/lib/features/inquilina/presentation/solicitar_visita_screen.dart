import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme.dart';
import '../../../shared/widgets/aviso.dart';
import '../../../shared/widgets/boton_principal.dart';
import '../../../shared/widgets/boton_secundario.dart';
import '../../../shared/widgets/casilla.dart';
import '../../../shared/widgets/encabezado.dart';
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(provider.error ?? 'No se pudo enviar la solicitud.'),
          behavior: SnackBarBehavior.floating,
        ),
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

    // Servicios incluidos
    final servicios = <String>[];
    if (anuncio.serviciosIncluidos['agua'] == true) servicios.add('Agua');
    if (anuncio.serviciosIncluidos['luz'] == true) servicios.add('Luz');
    if (anuncio.serviciosIncluidos['internet'] == true) {
      servicios.add('Internet');
    }
    final serviciosTexto = servicios.isNotEmpty
        ? ', todo incluido (${servicios.join(", ")})'
        : '';

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: const Encabezado(titulo: 'Solicitar visita'),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          Espacio.lg,
          Espacio.md,
          Espacio.lg,
          Espacio.lg,
        ),
        children: [
          // Introducción
          Text(
            'Aceptás estas condiciones antes de solicitar la visita. '
            'El propietario no necesita repetírtelas.',
            style: AppText.caption(context).copyWith(color: AppColors.text.withValues(alpha: 0.7)),
          ),

          const SizedBox(height: Espacio.lg),

          // ---- Condiciones del anuncio ----
          Container(
            decoration: BoxDecoration(
              color: AppColors.text.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(Medida.radio),
              border: Border.all(color: AppColors.text.withValues(alpha: 0.1)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    Espacio.md,
                    Espacio.md,
                    Espacio.md,
                    Espacio.sm,
                  ),
                  child: Text(
                    'Estás aceptando:',
                    style: AppText.caption(context).copyWith(
                      color: AppColors.text.withValues(alpha: 0.7),
                    ),
                  ),
                ),
                FilaCondicion(
                  icono: Icons.attach_money,
                  texto: '${anuncio.precioFinal} Bs por mes$serviciosTexto',
                ),
                FilaCondicion(
                  icono: Icons.directions_walk,
                  texto: '${anuncio.minutosCaminando} min caminando a la UAGRM',
                ),
                FilaCondicion(
                  icono: anuncio.aceptaMascotas
                      ? Icons.pets
                      : Icons.pets_outlined,
                  texto: anuncio.aceptaMascotas
                      ? 'Acepta mascotas'
                      : 'No acepta mascotas',
                ),
                if (anuncio.restricciones.isNotEmpty)
                  FilaCondicion(
                    icono: Icons.info_outline,
                    texto: anuncio.restricciones,
                  ),
                const SizedBox(height: Espacio.sm),
              ],
            ),
          ),

          const SizedBox(height: Espacio.lg),

          // ---- Checkbox de aceptación ----
          Casilla(
            etiqueta: 'Acepto estas condiciones',
            marcado: _condicionesAceptadas,
            alCambiar: (v) => setState(() => _condicionesAceptadas = v ?? false),
          ),

          const SizedBox(height: Espacio.lg),

          // ---- Aviso del contacto ----
          Aviso(
            icono: Icons.lock_clock_outlined,
            mensaje: 'Cuando el propietario apruebe tu solicitud, recibirás su contacto de WhatsApp.',
            tipo: TipoAviso.info,
          ),

          const SizedBox(height: Espacio.lg),

          // ---- Resumen de precio ----
          Container(
            padding: const EdgeInsets.all(Espacio.md),
            decoration: BoxDecoration(
              color: AppColors.text.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(Medida.radio),
              border: Border.all(color: AppColors.text.withValues(alpha: 0.1)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Precio final',
                  style: AppText.caption(context).copyWith(
                    color: AppColors.text.withValues(alpha: 0.7),
                  ),
                ),
                const SizedBox(height: Espacio.sm),
                Text(
                  '${anuncio.precioFinal} Bs / mes',
                  style: AppText.heading(context).copyWith(
                    color: AppColors.primary,
                    fontSize: 24,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: Espacio.lg),
        ],
      ),
      bottomNavigationBar: Padding(
        padding: EdgeInsets.fromLTRB(
          Espacio.lg,
          Espacio.sm,
          Espacio.lg,
          MediaQuery.of(context).padding.bottom + Espacio.md,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // La salida secundaria va arriba, como en el wireframe: la accion
            // principal queda al alcance del pulgar.
            BotonSecundario(
              etiqueta: 'CANCELAR',
              alTocar: provider.cargando ? null : () => Navigator.of(context).pop(),
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
      ),
    );
  }
}
