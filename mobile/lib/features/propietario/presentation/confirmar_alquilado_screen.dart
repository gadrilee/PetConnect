import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme.dart';
import '../../../shared/layout/pagina.dart';
import '../../../shared/widgets/aviso.dart';
import '../../../shared/widgets/bloque.dart';
import '../../../shared/widgets/boton_principal.dart';
import '../../../shared/widgets/boton_secundario.dart';
import '../../../shared/widgets/fila_condicion.dart';
import '../../../shared/widgets/pie_acciones.dart';
import '../../../shared/widgets/precio_final.dart';
import '../data/anuncio.dart';
import '../providers/mis_anuncios_provider.dart';

/// Flujo v0.5, pantalla 2: antes de marcar el cuarto como alquilado, lo que
/// va a pasar.
///
/// Solo se llega aca si el cuarto tiene solicitudes pendientes. Sin
/// pendientes, marcarlo es un toque: el brief pide que cueste eso y nada mas.
/// Con pendientes deja de ser una decision solo suya, porque cierra lo que
/// otras personas estaban esperando, y eso no puede pasar sin que lo sepa.
///
/// No pregunta "¿estas segura?": dice que va a pasar. La pregunta sola no le
/// da nada para decidir.
class ConfirmarAlquiladoScreen extends StatelessWidget {
  const ConfirmarAlquiladoScreen({super.key, required this.anuncio});

  final Anuncio anuncio;

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<MisAnunciosProvider>();
    final marcando = provider.cambiando(anuncio.id);
    final pendientes = anuncio.solicitudesPendientes;

    Future<void> confirmar() async {
      final ok = await provider.marcarAlquilado(anuncio);
      // Si salio bien vuelve a Mis anuncios, donde el pie cuenta el resultado.
      // Si fallo se queda, con el error en el pie y el boton listo para
      // reintentar.
      if (ok && context.mounted) Navigator.of(context).pop(true);
    }

    return Pagina(
      titulo: 'Marcar como alquilado',
      ancho: AnchoPagina.formulario,
      pie: PieAcciones(
        aviso: provider.error == null
            ? null
            : Aviso(mensaje: provider.error!, tipo: TipoAviso.error),
        botonPrincipal: BotonPrincipal(
          etiqueta: 'MARCAR YA ALQUILADO',
          etiquetaCargando: 'MARCANDO...',
          cargando: marcando,
          alTocar: marcando ? null : confirmar,
        ),
        botonSecundarioAbajo: BotonSecundario(
          etiqueta: 'CANCELAR',
          alTocar: marcando ? null : () => Navigator.of(context).pop(false),
        ),
      ),
      hijos: [
        // AUTO LAYOUT: una columna con 24 entre bloques, como el detalle de
        // una solicitud: primero de que cuarto se habla, despues que pasa.
        _Resumen(anuncio: anuncio),
        const SizedBox(height: Espacio.lg),
        _QueVaAPasar(pendientes: pendientes),
        const SizedBox(height: Espacio.lg),
        const Aviso(
          mensaje: 'Si el inquilino se va, lo volvés a publicar en un toque.',
        ),
      ],
    );
  }
}

class _Resumen extends StatelessWidget {
  const _Resumen({required this.anuncio});

  final Anuncio anuncio;

  @override
  Widget build(BuildContext context) {
    final precio = PrecioFinal.formatear(anuncio.precioFinal);
    return Bloque(
      hijos: [
        Text(
          anuncio.titulo,
          style: AppText.button(context)
              .copyWith(color: AppColors.text, letterSpacing: 0),
        ),
        const SizedBox(height: Espacio.sm),
        Text(
          'Tipo: ${anuncio.tipoEspacio.etiqueta} · $precio Bs/mes',
          style: AppText.caption(context).copyWith(color: AppColors.text70),
        ),
      ],
    );
  }
}

class _QueVaAPasar extends StatelessWidget {
  const _QueVaAPasar({required this.pendientes});

  final int pendientes;

  @override
  Widget build(BuildContext context) {
    Widget paso(IconData icono, String texto) => FilaCondicion(
          icono: icono,
          tamanoIcono: 20,
          colorIcono: AppColors.text70,
          texto: texto,
          estilo: AppText.body(context).copyWith(color: AppColors.text),
        );

    final solicitudes = pendientes == 1
        ? 'Se cierra la solicitud que tenías pendiente.'
        : 'Se cierran las $pendientes solicitudes que tenías pendientes.';
    final aviso = pendientes == 1
        ? 'A esa persona le avisamos que ya se alquiló.'
        : 'A cada persona le avisamos que ya se alquiló.';

    return Bloque(
      hijos: [
        Text(
          'Qué va a pasar',
          style: AppText.caption(context).copyWith(color: AppColors.text70),
        ),
        const SizedBox(height: Espacio.md),
        paso(Icons.search_off, 'Sale de la búsqueda: nadie más lo va a encontrar.'),
        const SizedBox(height: Espacio.sm),
        paso(Icons.cancel_outlined, solicitudes),
        const SizedBox(height: Espacio.sm),
        paso(Icons.mark_email_read_outlined, aviso),
      ],
    );
  }
}
