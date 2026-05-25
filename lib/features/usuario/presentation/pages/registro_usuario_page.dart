import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/constants/app_colors.dart';
import '../bloc/usuario_bloc.dart';
import '../bloc/usuario_event_state.dart';
import '../../domain/entities/usuario.dart';

class RegistroUsuarioPage extends StatefulWidget {
  const RegistroUsuarioPage({super.key});

  @override
  State<RegistroUsuarioPage> createState() => _RegistroUsuarioPageState();
}

class _RegistroUsuarioPageState extends State<RegistroUsuarioPage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nombresCtrl;
  late TextEditingController _apellidosCtrl;
  late TextEditingController _telefonoCtrl;
  late TextEditingController _emailCtrl;
  late TextEditingController _passwordCtrl;
  
  bool _isLogin = false;
  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
    _nombresCtrl = TextEditingController();
    _apellidosCtrl = TextEditingController();
    _telefonoCtrl = TextEditingController();
    _emailCtrl = TextEditingController();
    _passwordCtrl = TextEditingController();
  }

  @override
  void dispose() {
    _nombresCtrl.dispose();
    _apellidosCtrl.dispose();
    _telefonoCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<UsuarioBloc, UsuarioState>(
      listener: (context, state) {
        if (state is UsuarioSaved || state is UsuarioLoaded) {
          // Si el login/registro fue exitoso, redirigimos a home
          // AppShell o Dashboard verificarán si el usuario ya tiene fincas.
          Navigator.of(context).pushReplacementNamed('/home');
        } else if (state is UsuarioError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: Colors.redAccent,
            ),
          );
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.crema,
        appBar: AppBar(
          backgroundColor: AppColors.verdeOscuro,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: AppColors.blanco),
            onPressed: () {
              if (Navigator.of(context).canPop()) {
                Navigator.of(context).pop();
              } else {
                Navigator.of(context).pushReplacementNamed('/home');
              }
            },
          ),
          title: Text(
            _isLogin ? 'Iniciar Sesión' : 'Tu Perfil',
            style: GoogleFonts.fraunces(fontWeight: FontWeight.w600, color: AppColors.blanco),
          ),
          centerTitle: true,
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 10),
                Text(
                  _isLogin ? '¡Hola de nuevo!' : '¡Bienvenido a AgroClima Nariño!',
                  style: GoogleFonts.fraunces(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppColors.verdeOscuro,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  _isLogin
                      ? 'Inicia sesión para acceder a tus fincas y pronósticos en la nube.'
                      : 'Cuéntanos sobre ti para registrar tu primera finca y sincronizar tus datos.',
                  style: GoogleFonts.dmSans(
                    fontSize: 15,
                    color: AppColors.gris,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),

                if (!_isLogin) ...[
                  _buildTextField(
                    controller: _nombresCtrl,
                    label: 'Nombres',
                    icon: Icons.person_outline,
                    validator: (v) => v!.isEmpty ? 'Requerido' : null,
                  ),
                  const SizedBox(height: 20),

                  _buildTextField(
                    controller: _apellidosCtrl,
                    label: 'Apellidos',
                    icon: Icons.badge_outlined,
                    validator: (v) => v!.isEmpty ? 'Requerido' : null,
                  ),
                  const SizedBox(height: 20),

                  _buildTextField(
                    controller: _telefonoCtrl,
                    label: 'Teléfono',
                    icon: Icons.phone_outlined,
                    keyboardType: TextInputType.phone,
                    validator: (v) => v!.isEmpty ? 'Requerido' : null,
                  ),
                  const SizedBox(height: 20),
                ],

                _buildTextField(
                  controller: _emailCtrl,
                  label: 'Correo Electrónico',
                  icon: Icons.email_outlined,
                  keyboardType: TextInputType.emailAddress,
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Requerido';
                    if (!v.contains('@')) return 'Ingresa un correo válido';
                    return null;
                  },
                ),
                const SizedBox(height: 20),

                _buildTextField(
                  controller: _passwordCtrl,
                  label: 'Contraseña',
                  icon: Icons.lock_outline,
                  obscureText: _obscurePassword,
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                      color: AppColors.verdeOscuro,
                    ),
                    onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Requerido';
                    if (v.length < 6) return 'Debe tener al menos 6 caracteres';
                    return null;
                  },
                ),
                const SizedBox(height: 40),

                BlocBuilder<UsuarioBloc, UsuarioState>(
                  builder: (context, state) {
                    final isLoading = state is UsuarioLoading;
                    return ElevatedButton(
                      onPressed: isLoading
                          ? null
                          : () {
                              if (_formKey.currentState!.validate()) {
                                if (_isLogin) {
                                  context.read<UsuarioBloc>().add(
                                        LoginUsuarioEvent(
                                          email: _emailCtrl.text.trim(),
                                          password: _passwordCtrl.text.trim(),
                                        ),
                                      );
                                } else {
                                  context.read<UsuarioBloc>().add(
                                        RegisterUsuarioEvent(
                                          email: _emailCtrl.text.trim(),
                                          password: _passwordCtrl.text.trim(),
                                          nombres: _nombresCtrl.text.trim(),
                                          apellidos: _apellidosCtrl.text.trim(),
                                          telefono: _telefonoCtrl.text.trim(),
                                        ),
                                      );
                                }
                              }
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.verde,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: isLoading
                          ? const SizedBox(
                              height: 24,
                              width: 24,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : Text(
                              _isLogin ? 'Iniciar Sesión' : 'Registrarse',
                              style: GoogleFonts.dmSans(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                    );
                  },
                ),
                const SizedBox(height: 24),

                TextButton(
                  onPressed: () {
                    setState(() {
                      _isLogin = !_isLogin;
                      _formKey.currentState?.reset();
                    });
                  },
                  child: Text(
                    _isLogin
                        ? '¿No tienes una cuenta aún? Regístrate aquí'
                        : '¿Ya tienes una cuenta registrada? Inicia sesión',
                    style: GoogleFonts.dmSans(
                      color: AppColors.verdeOscuro,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool obscureText = false,
    Widget? suffixIcon,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscureText,
      validator: validator,
      style: GoogleFonts.dmSans(fontSize: 16),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.dmSans(color: AppColors.gris),
        prefixIcon: Icon(icon, color: AppColors.verdeOscuro),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: AppColors.blanco,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.niebla),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.niebla),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.verde, width: 2),
        ),
      ),
    );
  }
}
