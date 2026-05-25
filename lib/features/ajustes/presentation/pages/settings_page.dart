import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../usuario/presentation/bloc/usuario_bloc.dart';
import '../../../usuario/presentation/bloc/usuario_event_state.dart';
import '../../../usuario/domain/entities/usuario.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool _alertas = true;
  bool _modoOscuro = false;
  String _fuente = 'Normal';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.crema,
      body: SingleChildScrollView(
        child: Column(
          children: [
            Container(
              color: AppColors.blanco,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Row(children: [
                Text('⚙️ Ajustes',
                    style: GoogleFonts.fraunces(fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.verdeOscuro)),
                const Spacer(),
                Text('Personaliza tu experiencia',
                    style: GoogleFonts.dmSans(fontSize: 12, color: AppColors.gris)),
              ]),
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Perfil de Usuario
                  BlocBuilder<UsuarioBloc, UsuarioState>(
                    builder: (context, state) {
                      if (state is UsuarioLoaded) {
                        final usuario = state.usuario;
                        return Container(
                          margin: const EdgeInsets.only(bottom: 20),
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: AppColors.blanco,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: AppColors.niebla),
                            boxShadow: const [
                              BoxShadow(
                                color: Color(0x0C1A3D2B),
                                blurRadius: 16,
                                offset: Offset(0, 4),
                              )
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    width: 50,
                                    height: 50,
                                    decoration: const BoxDecoration(
                                      color: AppColors.verdeClaro,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Center(
                                      child: Text('👨‍🌾', style: TextStyle(fontSize: 24)),
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          '${usuario.nombres} ${usuario.apellidos}',
                                          style: GoogleFonts.fraunces(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                            color: AppColors.verdeOscuro,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          usuario.email,
                                          style: GoogleFonts.dmSans(
                                            fontSize: 13,
                                            color: AppColors.gris,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const Divider(height: 32, color: AppColors.niebla),
                              if (usuario.telefono.isNotEmpty) ...[
                                Row(
                                  children: [
                                    const Text('📞', style: TextStyle(fontSize: 16)),
                                    const SizedBox(width: 10),
                                    Text(
                                      usuario.telefono,
                                      style: GoogleFonts.dmSans(
                                        fontSize: 14,
                                        color: AppColors.verdeOscuro,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                              ],
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  OutlinedButton.icon(
                                    onPressed: () => _mostrarEditarPerfil(context, usuario),
                                    icon: const Icon(Icons.edit_rounded, size: 16),
                                    label: Text(
                                      'Editar Perfil',
                                      style: GoogleFonts.dmSans(fontWeight: FontWeight.bold),
                                    ),
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: AppColors.verde,
                                      side: const BorderSide(color: AppColors.verde),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 16,
                                        vertical: 8,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  ElevatedButton.icon(
                                    onPressed: () => _confirmarLogout(context),
                                    icon: const Icon(Icons.logout_rounded, size: 16),
                                    label: Text(
                                      'Cerrar Sesión',
                                      style: GoogleFonts.dmSans(fontWeight: FontWeight.bold),
                                    ),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppColors.riskHigh,
                                      foregroundColor: Colors.white,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 16,
                                        vertical: 8,
                                      ),
                                      elevation: 0,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );
                      } else {
                        return Container(
                          margin: const EdgeInsets.only(bottom: 20),
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: AppColors.blanco,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: AppColors.niebla),
                            boxShadow: const [
                              BoxShadow(
                                color: Color(0x0C1A3D2B),
                                blurRadius: 16,
                                offset: Offset(0, 4),
                              )
                            ],
                          ),
                          child: Column(
                            children: [
                              const Text('👨‍🌾', style: TextStyle(fontSize: 48)),
                              const SizedBox(height: 12),
                              Text(
                                'Invitado',
                                style: GoogleFonts.fraunces(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.verdeOscuro,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Registra tu perfil para sincronizar tus fincas y pronósticos.',
                                textAlign: TextAlign.center,
                                style: GoogleFonts.dmSans(
                                  fontSize: 13,
                                  color: AppColors.gris,
                                ),
                              ),
                              const SizedBox(height: 16),
                              ElevatedButton.icon(
                                onPressed: () => Navigator.pushNamed(context, '/registro_usuario'),
                                icon: const Icon(Icons.login_rounded, size: 18),
                                label: Text(
                                  'Iniciar Sesión / Registrarse',
                                  style: GoogleFonts.dmSans(fontWeight: FontWeight.bold),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.verde,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 20,
                                    vertical: 12,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      }
                    },
                  ),
                  const SizedBox(height: 8),

                  // Notificaciones
                  _SettingsCard(
                    title: '🔔 Notificaciones',
                    children: [
                      _SwitchTile(
                        icon: '❄️',
                        label: 'Alertas de helada',
                        subtitle: 'Recibe avisos cuando haya riesgo alto',
                        value: _alertas,
                        onChanged: (v) => setState(() => _alertas = v),
                      ),
                      const Divider(color: AppColors.niebla, height: 1),
                      _SwitchTile(
                        icon: '🌙',
                        label: 'Modo oscuro',
                        subtitle: 'Cambia el tema visual de la app',
                        value: _modoOscuro,
                        onChanged: (v) => setState(() => _modoOscuro = v),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Apariencia
                  _SettingsCard(
                    title: '🎨 Apariencia',
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                        child: Row(
                          children: [
                            const Text('🔤', style: TextStyle(fontSize: 20)),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Tamaño de letra',
                                      style: GoogleFonts.dmSans(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.verdeOscuro)),
                                  Text('Ajusta el texto de la app',
                                      style: GoogleFonts.dmSans(fontSize: 12, color: AppColors.gris)),
                                ],
                              ),
                            ),
                            DropdownButton<String>(
                              value: _fuente,
                              underline: const SizedBox.shrink(),
                              style: GoogleFonts.dmSans(fontSize: 14, color: AppColors.verdeOscuro),
                              items: const [
                                DropdownMenuItem(value: 'Pequeño', child: Text('Pequeño')),
                                DropdownMenuItem(value: 'Normal', child: Text('Normal')),
                                DropdownMenuItem(value: 'Grande', child: Text('Grande')),
                              ],
                              onChanged: (v) { if (v != null) setState(() => _fuente = v); },
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Datos
                  _SettingsCard(
                    title: '💾 Datos',
                    children: [
                      ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 4),
                        leading: const Text('🗑️', style: TextStyle(fontSize: 20)),
                        title: Text('Borrar datos de finca',
                            style: GoogleFonts.dmSans(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.riskHigh)),
                        subtitle: Text('Elimina toda la configuración guardada',
                            style: GoogleFonts.dmSans(fontSize: 12, color: AppColors.gris)),
                        trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.gris),
                        onTap: () => _confirmarBorrar(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Información
                  _SettingsCard(
                    title: 'ℹ️ Acerca de la app',
                    children: [
                      _InfoRow(label: 'Versión', value: '1.0.0'),
                      const Divider(color: AppColors.niebla, height: 1),
                      _InfoRow(label: 'Fuente de pronóstico', value: 'Open-Meteo API (gratuita)'),
                      const Divider(color: AppColors.niebla, height: 1),
                      _InfoRow(label: 'Modelo ML', value: 'Árbol de decisión (Dart puro)'),
                      const Divider(color: AppColors.niebla, height: 1),
                      _InfoRow(label: 'Precisión del modelo', value: '87% validado IDEAM'),
                      const Divider(color: AppColors.niebla, height: 1),
                      _InfoRow(label: 'Modo offline', value: 'Predicción 100% local'),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Créditos
                  Center(
                    child: Column(
                      children: [
                        Text('🌿 AgroClima Nariño',
                            style: GoogleFonts.fraunces(fontSize: 18, fontWeight: FontWeight.w900, color: AppColors.verde)),
                        const SizedBox(height: 4),
                        Text('Hecho con ❤️ para el campo andino',
                            style: GoogleFonts.dmSans(fontSize: 13, color: AppColors.gris)),
                        const SizedBox(height: 2),
                        Text('Nariño, Colombia 🇨🇴',
                            style: GoogleFonts.dmSans(fontSize: 12, color: AppColors.gris)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmarBorrar(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Borrar datos de finca',
            style: GoogleFonts.fraunces(fontSize: 18, fontWeight: FontWeight.w700)),
        content: Text('¿Estás seguro? Se eliminarán todos los datos de tu finca guardados. Esta acción no se puede deshacer.',
            style: GoogleFonts.dmSans(fontSize: 14, height: 1.6)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Cancelar', style: GoogleFonts.dmSans(color: AppColors.gris)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.riskHigh),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('Borrar', style: GoogleFonts.dmSans(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('finca_data');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Datos de finca borrados correctamente.')),
        );
      }
    }
  }

  void _mostrarEditarPerfil(BuildContext context, Usuario usuario) {
    final formKey = GlobalKey<FormState>();
    final nombresCtrl = TextEditingController(text: usuario.nombres);
    final apellidosCtrl = TextEditingController(text: usuario.apellidos);
    final telefonoCtrl = TextEditingController(text: usuario.telefono);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.crema,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom,
            top: 24,
            left: 24,
            right: 24,
          ),
          child: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '✏️ Editar Perfil',
                        style: GoogleFonts.fraunces(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppColors.verdeOscuro,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: nombresCtrl,
                    decoration: InputDecoration(
                      labelText: 'Nombres',
                      labelStyle: GoogleFonts.dmSans(color: AppColors.gris),
                      prefixIcon: const Icon(Icons.person_outline, color: AppColors.verdeOscuro),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: AppColors.niebla),
                      ),
                    ),
                    validator: (v) => v!.isEmpty ? 'Campo requerido' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: apellidosCtrl,
                    decoration: InputDecoration(
                      labelText: 'Apellidos',
                      labelStyle: GoogleFonts.dmSans(color: AppColors.gris),
                      prefixIcon: const Icon(Icons.badge_outlined, color: AppColors.verdeOscuro),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: AppColors.niebla),
                      ),
                    ),
                    validator: (v) => v!.isEmpty ? 'Campo requerido' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: telefonoCtrl,
                    keyboardType: TextInputType.phone,
                    decoration: InputDecoration(
                      labelText: 'Teléfono',
                      labelStyle: GoogleFonts.dmSans(color: AppColors.gris),
                      prefixIcon: const Icon(Icons.phone_outlined, color: AppColors.verdeOscuro),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: AppColors.niebla),
                      ),
                    ),
                    validator: (v) => v!.isEmpty ? 'Campo requerido' : null,
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.verde,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () {
                      if (formKey.currentState!.validate()) {
                        final updatedUser = usuario.copyWith(
                          nombres: nombresCtrl.text.trim(),
                          apellidos: apellidosCtrl.text.trim(),
                          telefono: telefonoCtrl.text.trim(),
                        );
                        context.read<UsuarioBloc>().add(SaveUsuarioEvent(updatedUser));
                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('¡Perfil actualizado con éxito! 🌾'),
                            backgroundColor: AppColors.verde,
                          ),
                        );
                      }
                    },
                    child: Text(
                      'Guardar Cambios',
                      style: GoogleFonts.dmSans(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _confirmarLogout(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Cerrar Sesión', style: GoogleFonts.fraunces(fontWeight: FontWeight.bold)),
        content: Text('¿Seguro que deseas cerrar la sesión actual? Se borrará tu información de este dispositivo.',
            style: GoogleFonts.dmSans(fontSize: 14)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancelar', style: GoogleFonts.dmSans(color: AppColors.gris, fontWeight: FontWeight.bold)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.riskHigh,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () {
              context.read<UsuarioBloc>().add(DeleteUsuarioEvent());
              Navigator.pop(ctx);
            },
            child: Text('Cerrar Sesión', style: GoogleFonts.dmSans(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}

class _SettingsCard extends StatelessWidget {
  final String title;
  final List<Widget> children;
  const _SettingsCard({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.blanco,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.niebla),
        boxShadow: const [BoxShadow(color: Color(0x0C1A3D2B), blurRadius: 16, offset: Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
            child: Text(title,
                style: GoogleFonts.fraunces(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.verdeOscuro)),
          ),
          const SizedBox(height: 8),
          ...children,
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

class _SwitchTile extends StatelessWidget {
  final String icon, label, subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _SwitchTile({required this.icon, required this.label, required this.subtitle,
      required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return SwitchListTile.adaptive(
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 4),
      secondary: Text(icon, style: const TextStyle(fontSize: 20)),
      title: Text(label,
          style: GoogleFonts.dmSans(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.verdeOscuro)),
      subtitle: Text(subtitle, style: GoogleFonts.dmSans(fontSize: 12, color: AppColors.gris)),
      value: value,
      activeColor: AppColors.verde,
      onChanged: onChanged,
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label, value;
  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: GoogleFonts.dmSans(fontSize: 13, color: AppColors.gris)),
          Text(value, style: GoogleFonts.dmSans(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.verdeOscuro)),
        ],
      ),
    );
  }
}
