import 'package:flutter/material.dart';
import '../../core/theme.dart';

class Casilla extends StatelessWidget {
  const Casilla({
    super.key,
    required this.etiqueta,
    required this.marcado,
    required this.alCambiar,
  });

  final String etiqueta;
  final bool marcado;
  final ValueChanged<bool?> alCambiar;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => alCambiar(!marcado),
      borderRadius: BorderRadius.circular(Medida.radioSm),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: Espacio.sm),
        child: Row(
          children: [
            SizedBox(
              width: 24,
              height: 24,
              child: Checkbox(
                value: marcado,
                onChanged: alCambiar,
                activeColor: AppColors.primary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
              ),
            ),
            const SizedBox(width: Espacio.sm),
            Expanded(
              child: Text(
                etiqueta,
                style: AppText.body(context).copyWith(color: AppColors.text),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
