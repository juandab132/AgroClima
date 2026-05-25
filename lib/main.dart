import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:get_it/get_it.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:sqflite/sqflite.dart';

import 'injection_container.dart' as di;
import 'core/constants/app_colors.dart';

import 'features/prediccion/presentation/bloc/prediction_bloc.dart';
import 'features/pronostico/presentation/bloc/weather_bloc.dart';
import 'features/pronostico/presentation/bloc/weather_event_state.dart';
import 'features/finca/presentation/bloc/finca_bloc.dart';
import 'features/finca/presentation/bloc/finca_event_state.dart';

// Pages
import 'features/splash/presentation/pages/splash_page.dart';
import 'features/registro/presentation/pages/registro_finca_page.dart';
import 'features/dashboard/presentation/pages/dashboard_page.dart';
import 'features/prediccion/presentation/pages/prediction_page.dart';
import 'features/pronostico/presentation/pages/forecast_page.dart';
import 'features/finca/presentation/pages/finca_page.dart';
import 'features/cultivos/presentation/pages/cultivos_page.dart';
import 'features/historial/presentation/pages/historial_page.dart';
import 'features/calendario/presentation/pages/calendario_page.dart';
import 'features/ajustes/presentation/pages/settings_page.dart';
import 'features/usuario/presentation/pages/registro_usuario_page.dart';

import 'features/cultivos/presentation/bloc/cultivos_bloc.dart';
import 'features/historial/presentation/bloc/historial_bloc.dart';
import 'features/calendario/presentation/bloc/calendario_bloc.dart';
import 'features/usuario/presentation/bloc/usuario_bloc.dart';
import 'features/usuario/presentation/bloc/usuario_event_state.dart';
import 'features/usuario/domain/entities/usuario.dart';
import 'core/services/municipios_service.dart';
import 'core/services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://zkevyksiahiwunrpspbp.supabase.co',
    anonKey: 'sb_publishable_NtSB3xQ6zSb74ssO9A5y_g_K-0aU5QE',
  );

  if (!kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS)) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }

  await di.init();
  await GetIt.I<MunicipiosService>().init();
  await GetIt.I<NotificationService>().init();
  runApp(const AgroClimaApp());
}

class AgroClimaApp extends StatelessWidget {
  const AgroClimaApp({super.key});

  @override
  Widget build(BuildContext context) {
    final textTheme = GoogleFonts.dmSansTextTheme();
    final theme = ThemeData(
      colorScheme: AppColors.colorScheme,
      useMaterial3: true,
      textTheme: textTheme,
      scaffoldBackgroundColor: AppColors.crema,
      cardTheme: CardTheme(
        color: AppColors.blanco,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: AppColors.niebla, width: 1),
        ),
        margin: EdgeInsets.zero,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.blanco,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: GoogleFonts.fraunces(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: AppColors.verdeOscuro,
        ),
        iconTheme: const IconThemeData(color: AppColors.verdeOscuro),
        toolbarHeight: 60,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.verde,
          foregroundColor: AppColors.blanco,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          textStyle:
              GoogleFonts.dmSans(fontSize: 14, fontWeight: FontWeight.w600),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.verde,
          foregroundColor: AppColors.blanco,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          textStyle:
              GoogleFonts.dmSans(fontSize: 14, fontWeight: FontWeight.w600),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.blanco,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFFDDE8E0), width: 1.5),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFFDDE8E0), width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide:
              const BorderSide(color: AppColors.verdeClaro, width: 1.5),
        ),
        labelStyle: GoogleFonts.dmSans(
            fontSize: 13, fontWeight: FontWeight.w600),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      ),
      sliderTheme: SliderThemeData(
        activeTrackColor: AppColors.verdeClaro,
        inactiveTrackColor: const Color(0xFFDDE8E0),
        thumbColor: AppColors.verde,
        overlayColor: AppColors.verde.withOpacity(0.15),
        trackHeight: 6,
        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 9),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.blanco,
        selectedColor: AppColors.verde,
        labelStyle: GoogleFonts.dmSans(
            fontSize: 13, fontWeight: FontWeight.w500),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(50),
          side: const BorderSide(color: AppColors.niebla),
        ),
        checkmarkColor: AppColors.blanco,
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.niebla,
        thickness: 1,
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        backgroundColor: AppColors.verdeOscuro,
        contentTextStyle: GoogleFonts.dmSans(color: AppColors.crema),
      ),
    );

    // BLoCs globales — disponibles en toda la app
    return MultiBlocProvider(
      providers: [
        BlocProvider<FincaBloc>(
          create: (_) => GetIt.I<FincaBloc>(),
        ),
        BlocProvider<PredictionBloc>(
          create: (_) => GetIt.I<PredictionBloc>(),
        ),
        BlocProvider<WeatherBloc>(
          create: (_) => GetIt.I<WeatherBloc>(),
        ),
        BlocProvider<CultivosBloc>(
          create: (_) => GetIt.I<CultivosBloc>(),
        ),
        BlocProvider<HistorialBloc>(
          create: (_) => GetIt.I<HistorialBloc>(),
        ),
        BlocProvider<CalendarioBloc>(
          create: (_) => GetIt.I<CalendarioBloc>(),
        ),
        BlocProvider<UsuarioBloc>(
          create: (_) => GetIt.I<UsuarioBloc>(),
        ),
      ],
      child: MaterialApp(
        title: 'AgroClima Nariño',
        debugShowCheckedModeBanner: false,
        theme: theme,
        // ── Rutas nombradas ─────────────────────────────────────────────────
        initialRoute: '/splash',
        routes: {
          '/splash': (_) => const SplashPage(),
          '/registro_usuario': (_) => const RegistroUsuarioPage(),
          '/registro': (_) => const RegistroFincaPage(),
          '/home': (_) => const AppShell(),
        },
      ),
    );
  }
}

// ── AppShell ──────────────────────────────────────────────────────────────────

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _selectedIndex = 0;
  late final List<Widget> _pages;

  static const _navItems = [
    _NavItem(
        icon: Icons.home_rounded,
        label: 'Panel principal',
        section: 'Principal'),
    _NavItem(
        icon: Icons.wb_sunny_rounded,
        label: 'Pronóstico',
        section: 'Principal'),
    _NavItem(
        icon: Icons.psychology_rounded,
        label: 'Predicción IA',
        section: 'Principal',
        badge: 'IA'),
    _NavItem(
        icon: Icons.cottage_rounded,
        label: 'Mi finca',
        section: 'Mi Finca'),
    _NavItem(
        icon: Icons.spa_rounded,
        label: 'Mis cultivos',
        section: 'Mi Finca'),
    _NavItem(
        icon: Icons.bar_chart_rounded,
        label: 'Historial',
        section: 'Mi Finca'),
    _NavItem(
        icon: Icons.calendar_month_rounded,
        label: 'Calendario',
        section: 'Herramientas'),
    _NavItem(
        icon: Icons.settings_rounded,
        label: 'Ajustes',
        section: 'Herramientas'),
  ];

  @override
  void initState() {
    super.initState();
    _pages = [
      DashboardPage(onNavigate: (i) => setState(() => _selectedIndex = i)),
      const ForecastPage(),
      const PredictionPage(),
      const FincaPage(),
      const CultivosPage(),
      const HistorialPage(),
      const CalendarioPage(),
      const SettingsPage(),
    ];

    // Cargar perfil del usuario si no está cargado.
    final usuarioBloc = context.read<UsuarioBloc>();
    if (usuarioBloc.state is! UsuarioLoaded && usuarioBloc.state is! UsuarioSaved) {
      usuarioBloc.add(LoadUsuarioEvent());
    }

    // Al entrar al shell, cargamos la finca y el pronóstico inicial.
    final fincaBloc = context.read<FincaBloc>();
    final state = fincaBloc.state;
    // Si venimos del splash ya tiene datos; si no, disparamos carga.
    if (state is! FincaLoaded && state is! FincaSaved) {
      fincaBloc.add(LoadFincaEvent());
    }

    // Pronóstico inicial con el municipio de la finca o 'Pasto' por defecto.
    final municipio = state is FincaLoaded ? state.finca.municipio : 'Pasto';
    context.read<WeatherBloc>().add(FetchForecastEvent(municipio));
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
      listeners: [
        BlocListener<UsuarioBloc, UsuarioState>(
          listener: (context, state) {
            if (state is UsuarioLoaded || state is UsuarioEmpty) {
              // Recargar finca al cambiar de usuario o cerrar sesión
              context.read<FincaBloc>().add(LoadFincaEvent());
            }
          },
        ),
        BlocListener<FincaBloc, FincaState>(
          listener: (context, state) {
            if (state is FincaLoaded || state is FincaSaved) {
              final f = state is FincaLoaded
                  ? state.finca
                  : (state as FincaSaved).finca;
              context
                  .read<WeatherBloc>()
                  .add(FetchForecastEvent(f.municipio));
            }
          },
        ),
      ],
      child: PopScope(
        canPop: _selectedIndex == 0,
        onPopInvokedWithResult: (didPop, result) {
          if (didPop) return;
          if (_selectedIndex != 0) {
            setState(() {
              _selectedIndex = 0;
            });
          }
        },
        child: LayoutBuilder(
          builder: (context, constraints) {
          final isWide = constraints.maxWidth > 700;
          if (isWide) {
            return Scaffold(
              body: Row(
                children: [
                  _Sidebar(
                    selectedIndex: _selectedIndex,
                    items: _navItems,
                    onTap: (i) => setState(() => _selectedIndex = i),
                  ),
                  Expanded(child: _pages[_selectedIndex]),
                ],
              ),
            );
          }
          // Móvil: drawer lateral
          return Scaffold(
            appBar: AppBar(
              title: Text(_navItems[_selectedIndex].label),
              leading: Builder(
                builder: (ctx) => IconButton(
                  onPressed: () => Scaffold.of(ctx).openDrawer(),
                  icon: const Icon(Icons.menu_rounded),
                ),
              ),
            ),
            drawer: Drawer(
              backgroundColor: AppColors.verdeOscuro,
              child: _SidebarContent(
                selectedIndex: _selectedIndex,
                items: _navItems,
                onTap: (i) {
                  setState(() => _selectedIndex = i);
                  Navigator.pop(context);
                },
              ),
            ),
            body: _pages[_selectedIndex],
          );
        },
      ),
    ),
  );
}
}

// ── Nav item model ────────────────────────────────────────────────────────────

class _NavItem {
  final IconData icon;
  final String label;
  final String section;
  final String? badge;
  const _NavItem(
      {required this.icon,
      required this.label,
      required this.section,
      this.badge});
}

// ── Sidebar (tablet/escritorio) ───────────────────────────────────────────────

class _Sidebar extends StatelessWidget {
  final int selectedIndex;
  final List<_NavItem> items;
  final ValueChanged<int> onTap;

  const _Sidebar(
      {required this.selectedIndex,
      required this.items,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 240,
      decoration: const BoxDecoration(
        color: AppColors.verdeOscuro,
        boxShadow: [
          BoxShadow(
              color: Color(0x22000000),
              blurRadius: 16,
              offset: Offset(4, 0))
        ],
      ),
      child: _SidebarContent(
          selectedIndex: selectedIndex, items: items, onTap: onTap),
    );
  }
}

class _SidebarContent extends StatelessWidget {
  final int selectedIndex;
  final List<_NavItem> items;
  final ValueChanged<int> onTap;

  const _SidebarContent(
      {required this.selectedIndex,
      required this.items,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    final sections = <String>[];
    for (final item in items) {
      if (!sections.contains(item.section)) sections.add(item.section);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Logo
        Container(
          padding: const EdgeInsets.fromLTRB(24, 40, 24, 20),
          decoration: BoxDecoration(
            border: Border(
                bottom: BorderSide(
                    color: Colors.white.withValues(alpha: 0.08))),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('🌿 AgroClima\nNariño',
                  style: GoogleFonts.fraunces(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      color: AppColors.menta,
                      height: 1.1)),
              const SizedBox(height: 4),
              Text('IA para el campo andino',
                  style: GoogleFonts.dmSans(
                      fontSize: 11,
                      color: Colors.white.withValues(alpha: 0.4),
                      letterSpacing: 0.8)),
            ],
          ),
        ),

        Expanded(
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              for (final section in sections) ...[
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
                  child: Text(section.toUpperCase(),
                      style: GoogleFonts.dmSans(
                          fontSize: 10,
                          letterSpacing: 2,
                          color: Colors.white.withValues(alpha: 0.3),
                          fontWeight: FontWeight.w500)),
                ),
                for (int i = 0; i < items.length; i++)
                  if (items[i].section == section)
                    _SidebarBtn(
                      item: items[i],
                      selected: selectedIndex == i,
                      onTap: () => onTap(i),
                    ),
              ],
            ],
          ),
        ),

        // Chip de usuario y finca actual
        BlocBuilder<UsuarioBloc, UsuarioState>(
          builder: (context, userState) {
            return BlocBuilder<FincaBloc, FincaState>(
              builder: (context, fincaState) {
                final nombreUsuario = userState is UsuarioLoaded
                    ? userState.usuario.nombres
                    : 'Invitado';
                final nombreFinca = fincaState is FincaLoaded
                    ? fincaState.finca.nombreFinca
                    : 'Sin finca';
                final altitud = fincaState is FincaLoaded
                    ? '${fincaState.finca.altitud} m.s.n.m.'
                    : '— m.s.n.m.';

                return Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    border: Border(
                        top: BorderSide(
                            color: Colors.white.withValues(alpha: 0.08))),
                  ),
                  child: InkWell(
                    onTap: () {
                      if (userState is UsuarioLoaded) {
                        _mostrarEditarPerfil(context, userState.usuario);
                      } else {
                        Navigator.pushNamed(context, '/registro_usuario');
                      }
                    },
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.06),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 32,
                            height: 32,
                            decoration: const BoxDecoration(
                              color: AppColors.verdeClaro,
                              shape: BoxShape.circle,
                            ),
                            child: const Center(
                                child: Text('👨‍🌾',
                                    style: TextStyle(fontSize: 14))),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(nombreUsuario,
                                          style: GoogleFonts.dmSans(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w700,
                                              color: AppColors.menta),
                                          overflow: TextOverflow.ellipsis),
                                    ),
                                    if (userState is UsuarioLoaded)
                                      Icon(Icons.edit_rounded,
                                          size: 11,
                                          color: AppColors.menta.withValues(alpha: 0.6)),
                                  ],
                                ),
                                Text('$nombreFinca • $altitud',
                                    style: GoogleFonts.dmSans(
                                        fontSize: 11,
                                        color: Colors.white
                                            .withValues(alpha: 0.4))),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          IconButton(
                            icon: Icon(
                              userState is UsuarioLoaded
                                  ? Icons.logout_rounded
                                  : Icons.person_add_rounded,
                              color: AppColors.menta.withValues(alpha: 0.8),
                              size: 22,
                            ),
                            onPressed: () {
                              if (userState is UsuarioLoaded) {
                                _confirmarLogout(context);
                              } else {
                                Navigator.pushNamed(
                                    context, '/registro_usuario');
                              }
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            );
          },
        ),
      ],
    );
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
        backgroundColor: AppColors.verdeOscuro,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('¿Cerrar sesión?',
            style: GoogleFonts.fraunces(color: Colors.white)),
        content: Text('Se eliminarán los datos locales de tu perfil y finca.',
            style: GoogleFonts.dmSans(color: Colors.white.withOpacity(0.8))),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancelar', style: TextStyle(color: Colors.white.withOpacity(0.5))),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              
              // Disparar eventos de eliminación
              context.read<UsuarioBloc>().add(DeleteUsuarioEvent());
              context.read<FincaBloc>().add(DeleteFincaEvent());
              
              // Volver a la pantalla de registro
              Navigator.pushReplacementNamed(context, '/registro_usuario');
            },
            child: const Text('Cerrar sesión', style: TextStyle(color: AppColors.riskHigh)),
          ),
        ],
      ),
    );
  }
}

class _SidebarBtn extends StatelessWidget {
  final _NavItem item;
  final bool selected;
  final VoidCallback onTap;

  const _SidebarBtn(
      {required this.item,
      required this.selected,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding:
            const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.verdeClaro.withValues(alpha: 0.15)
              : Colors.transparent,
          border: Border(
            left: BorderSide(
              color:
                  selected ? AppColors.verdeClaro : Colors.transparent,
              width: 3,
            ),
          ),
        ),
        child: Row(
          children: [
            Icon(item.icon,
                size: 18,
                color: selected
                    ? AppColors.menta
                    : Colors.white.withValues(alpha: 0.65)),
            const SizedBox(width: 12),
            Expanded(
              child: Text(item.label,
                  style: GoogleFonts.dmSans(
                      fontSize: 14,
                      color: selected
                          ? AppColors.menta
                          : Colors.white.withValues(alpha: 0.65),
                      fontWeight: selected
                          ? FontWeight.w600
                          : FontWeight.w400)),
            ),
            if (item.badge != null)
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.riskHigh,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(item.badge!,
                    style: GoogleFonts.dmSans(
                        fontSize: 10,
                        color: Colors.white,
                        fontWeight: FontWeight.w700)),
              ),
          ],
        ),
      ),
    );
  }
}
