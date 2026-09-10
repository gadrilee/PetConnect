import 'package:flutter/material.dart';

import '../../../core/theme.dart';
import '../../../shared/layout/pagina.dart';
import '../../../shared/widgets/boton_principal.dart';
import '../../../shared/widgets/tarjeta_rol.dart';
import '../data/perfil.dart';
import 'registro_screen.dart';

class ElegirRolScreen extends StatefulWidget {
  const ElegirRolScreen({super.key});

  @override
  State<ElegirRolScreen> createState() => _ElegirRolScreenState();
}

class _ElegirRolScreenState extends State<ElegirRolScreen> {
  Rol? _rol;

  void _continuar() {
    if (_rol == null) return;
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => RegistroScreen(rol: _rol!),
    ));
  }

  @override
  Widget build(BuildContext context) {
    // CONSTRAINTS: una columna con el ancho de un formulario y la accion fija
    // al pie. AUTO LAYOUT: las dos tarjetas se apilan con 16 entre ellas.
    return Pagina(
      titulo: '',
      ancho: AnchoPagina.formulario,
      pie: BotonPrincipal(
        etiqueta: 'CONTINUAR',
        alTocar: _rol == null ? null : _continuar,
      ),
      hijos: [
        Text(
          '¿Qué vas a hacer\nen la app?',
          style: AppText.heading(context).copyWith(color: AppColors.text),
        ),
        const SizedBox(height: Espacio.xxl),
        TarjetaRol(
          etiqueta: 'Busco dónde alquilar',
          descripcion: 'Filtrás por precio final, mascotas y ubicación.',
          icono: Icons.search,
          seleccionada: _rol == Rol.inquilino,
          alTocar: () => setState(() => _rol = Rol.inquilino),
        ),
        const SizedBox(height: Espacio.md),
        TarjetaRol(
          etiqueta: 'Quiero publicar',
          descripcion: 'Publicás una vez con las condiciones por delante.',
          icono: Icons.home_work_outlined,
          seleccionada: _rol == Rol.propietario,
          alTocar: () => setState(() => _rol = Rol.propietario),
        ),
      ],
    );
  }
}
