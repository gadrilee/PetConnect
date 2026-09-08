import 'package:flutter/material.dart';
import '../../core/theme.dart';

class Interruptor extends StatelessWidget {
  const Interruptor({
    super.key,
    required this.etiqueta,
    required this.marcado,
    required this.alCambiar,
  });

  final String etiqueta;
  final bool marcado;
  final ValueChanged<bool> alCambiar;

  @override
  Widget build(BuildContext context) {
    return SwitchListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(
        etiqueta,
        style: AppText.body(context).copyWith(color: AppColors.text),
      ),
      value: marcado,
      onChanged: alCambiar,
      activeTrackColor: AppColors.primary.withValues(alpha: 0.5),
      activeThumbColor: AppColors.primary,
    );
  }
}
