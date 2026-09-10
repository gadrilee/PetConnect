import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../core/theme.dart';
import '../../../shared/layout/grilla.dart';
import '../../../shared/layout/pagina.dart';
import '../../../shared/widgets/bloque.dart';
import '../../../shared/widgets/boton_flotante.dart';
import '../../../shared/widgets/boton_secundario.dart';
import '../../../shared/widgets/boton_texto.dart';
import '../../../shared/widgets/estado_vacio.dart';
import '../../../shared/widgets/etiqueta_estado.dart';
import '../../../shared/widgets/fila_condicion.dart';
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
    final anuncios = estado.anuncios;

    Widget? cuerpo;
    if (estado.cargando && anuncios.isEmpty) {
      cuerpo = const CircularProgressIndicator();
    } else if (estado.error != null && anuncios.isEmpty) {
      cuerpo = EstadoVacio(
        icono: Icons.error_outline,
        titulo: estado.error!,
        esError: true,
        accion: 'Reintentar',
        alAccion: estado.cargar,
      );
    } else if (anuncios.isEmpty) {
      cuerpo = const EstadoVacio(
        icono: Icons.home_work_outlined,
        titulo: 'Todavía no publicaste nada',
        detalle:
            'Publicá una vez con las condiciones por delante y el anuncio filtra solo.',
      );
    }

    return Pagina(
      titulo: 'Mis anuncios',
      alRefrescar: estado.cargar,
      botonFlotante: BotonFlotante(
        etiqueta: 'Publicar',
        icono: Icons.add,
        alTocar: _publicar,
      ),
      cuerpo: cuerpo,
      hijos: [
        // GRID: un anuncio por fila en movil, dos en tablet y tres en
        // escritorio.
        Grilla12(
          celdas: [
            for (final anuncio in anuncios)
              CeldaGrilla(
                columnas: const Columnas(tablet: 6, escritorio: 4),
                child: _TarjetaGestion(anuncio: anuncio),
              ),
          ],
        ),
      ],
    );
  }
}

/// La tarjeta del PROPIETARIO: muestra el estado del anuncio y la accion de
/// marcarlo como alquilado. No es la misma pieza que TarjetaAnuncio, que es
/// la que ve la inquilina para decidir; comparten las piezas, no el trabajo.
class _TarjetaGestion extends StatelessWidget {
  const _TarjetaGestion({required this.anuncio});

  final Anuncio anuncio;

  @override
  Widget build(BuildContext context) {
    final precio = NumberFormat.decimalPattern('es')
        .format(double.tryParse(anuncio.precioFinal) ?? 0);
    void alternar() =>
        context.read<MisAnunciosProvider>().alternarEstado(anuncio);

    final datos = <(IconData, String)>[
      (Icons.payments_outlined, '$precio Bs'),
      (Icons.directions_walk, '${anuncio.minutosCaminando} min'),
      (
        anuncio.aceptaMascotas ? Icons.pets : Icons.block,
        anuncio.aceptaMascotas ? 'Mascotas' : 'Sin mascotas',
      ),
      (Icons.home_outlined, anuncio.tipoEspacio.etiqueta),
    ];

    return Bloque(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // FLEXBOX: el titulo toma el espacio libre y el estado queda
          // anclado a la derecha.
          Row(
            children: [
              Expanded(
                child: Text(
                  anuncio.titulo,
                  style:
                      AppText.button(context).copyWith(color: AppColors.text),
                ),
              ),
              const SizedBox(width: Espacio.sm),
              EtiquetaEstado.anuncio(anuncio.estado),
            ],
          ),
          const SizedBox(height: Espacio.sm),
          // FLEXBOX: los datos van en fila y bajan si no entran (flex-wrap).
          Wrap(
            spacing: Espacio.md,
            runSpacing: Espacio.xs,
            children: [
              for (final (icono, texto) in datos)
                FilaCondicion(
                  enLinea: true,
                  icono: icono,
                  texto: texto,
                  colorIcono: AppColors.text.withValues(alpha: 0.5),
                  estilo: AppText.caption(context)
                      .copyWith(color: AppColors.text.withValues(alpha: 0.7)),
                ),
            ],
          ),
          const SizedBox(height: Espacio.md),
          if (anuncio.estaDisponible)
            BotonSecundario(
              etiqueta: 'Marcar Ya alquilado',
              icono: Icons.check_circle_outline,
              compacto: true,
              alTocar: alternar,
            )
          else
            BotonTexto(
              etiqueta: 'Volver a publicar',
              icono: Icons.refresh,
              alTocar: alternar,
            ),
        ],
      ),
    );
  }
}
