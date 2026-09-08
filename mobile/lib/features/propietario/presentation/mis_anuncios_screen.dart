import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../core/theme.dart';
import '../../../shared/widgets/aviso.dart';
import '../../../shared/widgets/encabezado.dart';
import '../data/anuncio.dart';
import '../providers/mis_anuncios_provider.dart';
import '../providers/publicar_provider.dart';
import 'publicar_screen.dart';

/// Los anuncios del propietario, en cualquier estado.
///
/// Lo que resuelve esta pantalla es que el anuncio muera cuando debe: si
/// marcar "Ya alquilado" cuesta mas de un toque, no va a pasar y los mensajes
/// van a seguir llegando semanas despues.
class MisAnunciosScreen extends StatefulWidget {
  const MisAnunciosScreen({super.key});

  @override
  State<MisAnunciosScreen> createState() => _MisAnunciosScreenState();
}

class _MisAnunciosScreenState extends State<MisAnunciosScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => context.read<MisAnunciosProvider>().cargar(),
    );
  }

  Future<void> _publicar() async {
    // El provider del formulario se crea nuevo en cada publicacion, para no
    // arrastrar fotos ni ubicacion del anuncio anterior.
    final repo = context.read<MisAnunciosProvider>();
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ChangeNotifierProvider(
          create: (ctx) => PublicarProvider(ctx.read()),
          child: const PublicarScreen(),
        ),
      ),
    );
    if (mounted) repo.cargar();
  }

  @override
  Widget build(BuildContext context) {
    final estado = context.watch<MisAnunciosProvider>();

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: const Encabezado(titulo: 'Mis anuncios'),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _publicar,
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.surface,
        icon: const Icon(Icons.add),
        label: const Text('Publicar'),
      ),
      body: RefreshIndicator(
        onRefresh: () => estado.cargar(),
        child: Builder(
          builder: (_) {
            if (estado.cargando && estado.anuncios.isEmpty) {
              return const Center(child: CircularProgressIndicator());
            }
            if (estado.error != null && estado.anuncios.isEmpty) {
              return ListView(
                padding: const EdgeInsets.all(24),
                children: [
                  Aviso(
                    icono: Icons.error_outline,
                    mensaje: estado.error!,
                    tipo: TipoAviso.error,
                  )
                ],
              );
            }
            if (estado.anuncios.isEmpty) return const _SinAnuncios();

            return ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
              itemCount: estado.anuncios.length,
              itemBuilder: (_, i) =>
                  _TarjetaGestion(anuncio: estado.anuncios[i]),
            );
          },
        ),
      ),
    );
  }
}

class _SinAnuncios extends StatelessWidget {
  const _SinAnuncios();

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        const SizedBox(height: 120),
        Icon(
          Icons.home_work_outlined,
          size: 56,
          color: AppColors.text.withValues(alpha: 0.5),
        ),
        const SizedBox(height: Espacio.md),
        Text(
          'Todavía no publicaste nada',
          textAlign: TextAlign.center,
          style: AppText.heading(context).copyWith(color: AppColors.text, fontSize: 18),
        ),
        const SizedBox(height: Espacio.sm),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40),
          child: Text(
            'Publicá una vez con las condiciones por delante y el anuncio '
            'filtra solo.',
            textAlign: TextAlign.center,
            style: AppText.body(context).copyWith(color: AppColors.text.withValues(alpha: 0.7)),
          ),
        ),
      ],
    );
  }
}

/// La tarjeta del PROPIETARIO: muestra el estado del anuncio y la accion de
/// marcarlo como alquilado. No es la misma pieza que TarjetaAnuncio, que es
/// la que ve la inquilina para decidir; comparten el tema, no el trabajo.
class _TarjetaGestion extends StatelessWidget {
  const _TarjetaGestion({required this.anuncio});

  final Anuncio anuncio;

  @override
  Widget build(BuildContext context) {
    final disponible = anuncio.estaDisponible;
    final precio = NumberFormat.decimalPattern(
      'es',
    ).format(double.tryParse(anuncio.precioFinal) ?? 0);

    return Container(
      margin: const EdgeInsets.only(bottom: Espacio.md),
      padding: const EdgeInsets.all(Espacio.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(Medida.radio),
        border: Border.all(color: AppColors.text.withValues(alpha: 0.1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  anuncio.titulo,
                  style: AppText.button(context).copyWith(color: AppColors.text),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: Espacio.sm, vertical: 4),
                decoration: BoxDecoration(
                  color: disponible
                      ? AppColors.primary.withValues(alpha: 0.1)
                      : AppColors.text.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(Medida.radioSm),
                ),
                child: Text(
                  anuncio.estado.etiqueta,
                  style: AppText.caption(context).copyWith(
                    color: disponible ? AppColors.primary : AppColors.text.withValues(alpha: 0.6),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: Espacio.sm),
          Wrap(
            spacing: Espacio.md,
            runSpacing: 4,
            children: [
              _Dato(Icons.payments_outlined, '$precio Bs'),
              _Dato(Icons.directions_walk, '${anuncio.minutosCaminando} min'),
              _Dato(
                anuncio.aceptaMascotas ? Icons.pets : Icons.block,
                anuncio.aceptaMascotas ? 'Mascotas' : 'Sin mascotas',
              ),
              _Dato(Icons.home_outlined, anuncio.tipoEspacio.etiqueta),
            ],
          ),
          const SizedBox(height: Espacio.md),
          SizedBox(
            width: double.infinity,
            child: disponible
                ? OutlinedButton.icon(
                    onPressed: () => context
                        .read<MisAnunciosProvider>()
                        .alternarEstado(anuncio),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.text,
                      side: BorderSide(color: AppColors.text.withValues(alpha: 0.3)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Medida.radioSm)),
                    ),
                    icon: const Icon(Icons.check_circle_outline, size: 16),
                    label: const Text('Marcar Ya alquilado'),
                  )
                : TextButton.icon(
                    onPressed: () => context
                        .read<MisAnunciosProvider>()
                        .alternarEstado(anuncio),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Medida.radioSm)),
                    ),
                    icon: const Icon(Icons.refresh, size: 16),
                    label: const Text('Volver a publicar'),
                  ),
          ),
        ],
      ),
    );
  }
}

class _Dato extends StatelessWidget {
  const _Dato(this.icono, this.texto);

  final IconData icono;
  final String texto;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icono, size: 16, color: AppColors.text.withValues(alpha: 0.5)),
        const SizedBox(width: Espacio.xs),
        Text(
          texto,
          style: AppText.caption(context).copyWith(color: AppColors.text.withValues(alpha: 0.7)),
        ),
      ],
    );
  }
}
