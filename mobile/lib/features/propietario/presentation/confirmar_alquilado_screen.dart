import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme.dart';
import '../../../shared/layout/pagina.dart';
import '../../../shared/widgets/aviso.dart';
import '../../../shared/widgets/bloque.dart';
import '../../../shared/widgets/boton_principal.dart';
import '../../../shared/widgets/boton_secundario.dart';
import '../../../shared/widgets/fila_condicion.dart';
import '../../../shared/widgets/foto_inmueble.dart';
import '../../../shared/widgets/pie_acciones.dart';
import '../../../shared/widgets/precio_final.dart';
import '../data/anuncio.dart';
import '../providers/mis_anuncios_provider.dart';

/// Flujo v0.5, pantalla 2: antes de marcar el cuarto como alquilado, lo que
/// va a pasar.
///
/// Se pasa por aca siempre, con pendientes o sin ellas: es la accion que
/// menos se puede deshacer de Mis anuncios —saca el anuncio de la busqueda y
/// cierra lo que otras personas estaban esperando— y el boton tiene que hacer
/// siempre lo mismo. Lo que cambia es lo que se cuenta: con pendientes, que
/// se cierran y que se les avisa; sin pendientes, que no se cierra ninguna.
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
      // FLEXBOX: la foto mide lo suyo y el texto toma el resto. Antes de
      // apagar un anuncio conviene ver cual es, no solo leer su titulo: los
      // de una misma casa se llaman casi igual.
      hijos: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            FotoInmueble(url: anuncio.fotoPrincipal, ancho: 64, alto: 64),
            const SizedBox(width: Espacio.md),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    anuncio.titulo,
                    style: AppText.button(context)
                        .copyWith(color: AppColors.text, letterSpacing: 0),
                  ),
                  const SizedBox(height: Espacio.sm),
                  Text(
                    'Tipo: ${anuncio.tipoEspacio.etiqueta} · $precio Bs/mes',
                    style: AppText.caption(context)
                        .copyWith(color: AppColors.text70),
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
        // Sin pendientes no se cierra nada, y decirlo es parte de la
        // respuesta: nadie se queda esperando por esto.
        if (pendientes == 0)
          paso(Icons.inbox_outlined, 'No tenés solicitudes pendientes: no se cierra ninguna.')
        else ...[
          paso(Icons.cancel_outlined, solicitudes),
          const SizedBox(height: Espacio.sm),
          paso(Icons.mark_email_read_outlined, aviso),
        ],
      ],
    );
  }
}
