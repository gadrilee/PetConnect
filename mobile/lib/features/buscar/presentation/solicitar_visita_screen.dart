import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme.dart';
import '../../anuncios/data/anuncio.dart';
import '../providers/solicitud_provider.dart';
import 'solicitud_estado_screen.dart';

/// Vista 04 — Solicitar visita.
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
    Navigator.of(context).pushReplacement(MaterialPageRoute(
      builder: (_) => ChangeNotifierProvider.value(
        value: provider,
        child: const SolicitudEstadoScreen(),
      ),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final esquema = Theme.of(context).colorScheme;
    final texto = Theme.of(context).textTheme;
    final provider = context.watch<SolicitudProvider>();
    final anuncio = widget.anuncio;

    // Servicios incluidos
    final servicios = <String>[];
    if (anuncio.serviciosIncluidos['agua'] == true) servicios.add('Agua');
    if (anuncio.serviciosIncluidos['luz'] == true) servicios.add('Luz');
    if (anuncio.serviciosIncluidos['internet'] == true) servicios.add('Internet');
    final serviciosTexto = servicios.isNotEmpty
        ? ', todo incluido (${servicios.join(", ")})'
        : '';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Solicitar visita'),
        leading: const BackButton(),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        children: [
          // Introducción
          Text(
            'Aceptás estas condiciones antes de solicitar la visita. '
            'El propietario no necesita repetírtelas.',
            style: texto.bodySmall?.copyWith(color: esquema.onSurfaceVariant),
          ),

          const SizedBox(height: Espacio.lg),

          // ---- Condiciones del anuncio ----
          Container(
            decoration: BoxDecoration(
              color: esquema.surfaceContainerHighest.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: esquema.outline.withValues(alpha: 0.4)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
                  child: Text(
                    'Estás aceptando:',
                    style: texto.labelMedium?.copyWith(color: esquema.onSurfaceVariant),
                  ),
                ),
                _FilaCondicion(
                  icono: Icons.attach_money,
                  texto: '${anuncio.precioFinal} Bs por mes$serviciosTexto',
                ),
                _FilaCondicion(
                  icono: Icons.directions_walk,
                  texto: '${anuncio.minutosCaminando} min caminando a la UAGRM',
                ),
                _FilaCondicion(
                  icono: anuncio.aceptaMascotas ? Icons.pets : Icons.pets_outlined,
                  texto: anuncio.aceptaMascotas ? 'Acepta mascotas' : 'No acepta mascotas',
                ),
                if (anuncio.restricciones.isNotEmpty)
                  _FilaCondicion(
                    icono: Icons.info_outline,
                    texto: anuncio.restricciones,
                  ),
                const SizedBox(height: 8),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // ---- Checkbox de aceptación ----
          InkWell(
            onTap: () => setState(() => _condicionesAceptadas = !_condicionesAceptadas),
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  Checkbox(
                    value: _condicionesAceptadas,
                    onChanged: (v) => setState(() => _condicionesAceptadas = v ?? false),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      'Acepto estas condiciones',
                      style: texto.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // ---- Aviso del contacto ----
          Container(
            padding: const EdgeInsets.all(Espacio.md),
            decoration: BoxDecoration(
              color: esquema.surfaceContainerHighest.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: esquema.outline.withValues(alpha: 0.4)),
            ),
            child: Row(
              children: [
                Icon(Icons.lock_clock_outlined, size: 18, color: esquema.onSurfaceVariant),
                const SizedBox(width: Espacio.sm),
                Expanded(
                  child: Text(
                    'Cuando el propietario apruebe tu solicitud, '
                    'recibirás su contacto de WhatsApp.',
                    style: texto.bodySmall?.copyWith(color: esquema.onSurfaceVariant),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // ---- Resumen de precio ----
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: esquema.surfaceContainerHighest.withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: esquema.outline.withValues(alpha: 0.4)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Precio final',
                    style: texto.labelMedium?.copyWith(color: esquema.onSurfaceVariant)),
                const SizedBox(height: 4),
                Text(
                  '${anuncio.precioFinal} Bs / mes',
                  style: texto.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),
        ],
      ),
      bottomNavigationBar: Padding(
        padding: EdgeInsets.fromLTRB(
            20, 8, 20, MediaQuery.of(context).padding.bottom + 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            FilledButton(
              onPressed: (_condicionesAceptadas && !provider.cargando) ? _enviar : null,
              child: provider.cargando
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Text('ENVIAR SOLICITUD'),
            ),
            const SizedBox(height: Espacio.md),
            OutlinedButton(
              onPressed: provider.cargando ? null : () => Navigator.of(context).pop(),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(52),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Cancelar'),
            ),
          ],
        ),
      ),
    );
  }
}

class _FilaCondicion extends StatelessWidget {
  const _FilaCondicion({required this.icono, required this.texto});

  final IconData icono;
  final String texto;

  @override
  Widget build(BuildContext context) {
    final esquema = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: esquema.primaryContainer.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(icono, size: 16, color: esquema.primary),
          ),
          const SizedBox(width: Espacio.sm),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(texto, style: Theme.of(context).textTheme.bodySmall),
            ),
          ),
        ],
      ),
    );
  }
}
