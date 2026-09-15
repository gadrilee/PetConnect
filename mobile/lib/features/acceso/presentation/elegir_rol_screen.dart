import 'package:flutter/material.dart';

import '../../../core/theme.dart';
import '../../../shared/layout/pagina.dart';
import '../../../shared/widgets/boton_principal.dart';
import '../../../shared/widgets/pie_acciones.dart';
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
    // CONSTRAINTS: una columna con el ancho de un formulario y el pie fijo
    // abajo, armado con PieAcciones: solo CONTINUAR, apagado hasta elegir un
    // rol (Figma, Elegir rol · sin elegir: sin motivo debajo).
    // AUTO LAYOUT: la pregunta en Heading, 24 hasta las tarjetas (la regla de
    // espaciado: 24 entre bloques de la pantalla; 48 no es un rol de la
    // escala) y 16 entre las dos tarjetas (una lista de tarjetas).
    return Pagina(
      titulo: 'Elegir rol',
      ancho: AnchoPagina.formulario,
      pie: PieAcciones(
        botonPrincipal: BotonPrincipal(
          etiqueta: 'CONTINUAR',
          alTocar: _rol == null ? null : _continuar,
        ),
      ),
      hijos: [
        Text(
          '¿Qué vas a hacer\nen la app?',
          style: AppText.heading(context).copyWith(color: AppColors.text),
        ),
        const SizedBox(height: Espacio.lg),
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
