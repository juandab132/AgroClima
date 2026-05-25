import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../features/pronostico/domain/entities/weather_forecast.dart';
import '../../../finca/presentation/bloc/finca_bloc.dart';
import '../bloc/finca_event_state.dart';
import '../../domain/entities/finca.dart';
import '../../../../features/usuario/presentation/bloc/usuario_bloc.dart';
import '../../../../features/usuario/presentation/bloc/usuario_event_state.dart';

import 'package:get_it/get_it.dart';
import '../../../../core/services/municipios_service.dart';
import '../../../../core/widgets/municipio_search_bottom_sheet.dart';
import '../../data/datasources/finca_sqlite_datasource.dart';

import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:supabase_flutter/supabase_flutter.dart' as sb;
import 'package:shared_preferences/shared_preferences.dart';

class FincaPage extends StatefulWidget {
  const FincaPage({super.key});

  @override
  State<FincaPage> createState() => _FincaPageState();
}

class _FincaPageState extends State<FincaPage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _fincaCtrl;
  late TextEditingController _veredaCtrl;
  late TextEditingController _latCtrl;
  late TextEditingController _lonCtrl;
  final _municipiosService = GetIt.I<MunicipiosService>();
  
  String _municipio = 'Pasto';
  double _altitud = 2527;
  double _hectareas = 3.0;
  String _riego = 'Lluvia';

  late final List<String> _municipios;
  final _riegos = ['Lluvia', 'Aspersión', 'Goteo', 'Canal / acequia'];

  List<Finca> _allFincas = [];
  Finca? _selectedFinca;
  bool _isCreatingNew = false;
  bool _isEditingOrAdding = false;

  bool _gpsLoading = false;
  bool _usandoCoordenadas = false;

  @override
  void initState() {
    super.initState();
    _fincaCtrl = TextEditingController();
    _veredaCtrl = TextEditingController();
    _latCtrl = TextEditingController();
    _lonCtrl = TextEditingController();
    _municipios = _municipiosService.municipios.keys.toList();
    _loadAllFincas();
  }

  Future<void> _loadAllFincas() async {
    final sqliteDataSource = GetIt.I<FincaSQLiteDataSource>();
    final fincas = await sqliteDataSource.loadAllFincas();
    final activeFinca = await sqliteDataSource.loadFinca();
    setState(() {
      _allFincas = fincas;
      _selectedFinca = activeFinca;
      if (fincas.isEmpty) {
        _isEditingOrAdding = true;
        _isCreatingNew = true;
        _applyFinca(null);
      } else {
        if (activeFinca != null && !_isCreatingNew) {
          _applyFinca(activeFinca);
        }
      }
    });
  }

  Future<void> _onSelectFinca(Finca finca) async {
    final sqliteDataSource = GetIt.I<FincaSQLiteDataSource>();
    await sqliteDataSource.setSelectedFincaId(finca.id!);
    context.read<FincaBloc>().add(LoadFincaEvent());
    setState(() {
      _isCreatingNew = false;
      _selectedFinca = finca;
      _applyFinca(finca);
    });
  }

  void _startCreatingNew() {
    setState(() {
      _isCreatingNew = true;
      _selectedFinca = null;
      _applyFinca(null);
    });
  }

  void _cancelCreatingNew() {
    setState(() {
      _isCreatingNew = false;
      _loadAllFincas();
    });
  }

  void _applyFinca(Finca? f) {
    _latCtrl.clear();
    _lonCtrl.clear();
    setState(() {
      _usandoCoordenadas = false;
    });
    if (f == null) {
      _fincaCtrl.clear();
      _veredaCtrl.clear();
      setState(() {
        _municipio = 'Pasto';
        _altitud = 2527;
        _hectareas = 3.0;
        _riego = 'Lluvia';
      });
      return;
    }
    _fincaCtrl.text = f.nombreFinca;
    _veredaCtrl.text = f.vereda;
    setState(() {
      _municipio = f.municipio;
      _altitud = f.altitud.toDouble();
      _hectareas = f.hectareas;
      _riego = f.tipoRiego;
    });
  }

  /// Obtiene la altitud real desde la API de Open-Meteo usando lat/lon
  Future<double?> _fetchElevation(double lat, double lon) async {
    try {
      final url = Uri.parse(
          'https://api.open-meteo.com/v1/elevation?latitude=$lat&longitude=$lon');
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final elevation = (data['elevation'] as List).first;
        return (elevation as num).toDouble();
      }
    } catch (_) {}
    return null;
  }

  /// Usa el GPS del dispositivo para obtener coordenadas y altitud automáticamente
  Future<void> _usarGPS() async {
    setState(() => _gpsLoading = true);
    try {
      // Verificar si el servicio de ubicación está habilitado
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _showError('Active la ubicación (GPS) de su celular para continuar.');
        return;
      }

      // Verificar permisos
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          _showError('Necesitamos el permiso de ubicación para detectar la altitud de su finca.');
          return;
        }
      }
      if (permission == LocationPermission.deniedForever) {
        _showError('El permiso de ubicación fue denegado permanentemente. Active la ubicación desde los ajustes de su celular.');
        return;
      }

      // Obtener posición
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 15),
        ),
      );

      final lat = position.latitude;
      final lon = position.longitude;

      // Consultar altitud exacta desde Open-Meteo
      final elevation = await _fetchElevation(lat, lon);

      setState(() {
        _latCtrl.text = lat.toStringAsFixed(6);
        _lonCtrl.text = lon.toStringAsFixed(6);
        _usandoCoordenadas = true;
        if (elevation != null) {
          _altitud = elevation.clamp(1500, 3600);
        }
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('📍 Ubicación detectada: ${elevation?.round() ?? _altitud.round()} m.s.n.m.'),
            backgroundColor: AppColors.verde,
          ),
        );
      }
    } catch (e) {
      _showError('No se pudo obtener la ubicación. Intente de nuevo.');
    } finally {
      if (mounted) setState(() => _gpsLoading = false);
    }
  }

  /// Aplica coordenadas ingresadas manualmente y obtiene altitud de la API
  Future<void> _aplicarCoordenadasManuales() async {
    final lat = double.tryParse(_latCtrl.text.trim());
    final lon = double.tryParse(_lonCtrl.text.trim());
    if (lat == null || lon == null) {
      _showError('Ingrese coordenadas válidas (ej: Lat 1.2136, Lon -77.2811)');
      return;
    }
    if (lat < -5 || lat > 5 || lon < -80 || lon > -74) {
      _showError('Las coordenadas no parecen estar en Nariño. Verifique los valores.');
      return;
    }

    setState(() => _gpsLoading = true);
    final elevation = await _fetchElevation(lat, lon);
    setState(() {
      _gpsLoading = false;
      _usandoCoordenadas = true;
      if (elevation != null) {
        _altitud = elevation.clamp(1500, 3600);
      }
    });

    if (mounted && elevation != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('⛰️ Altitud detectada: ${elevation.round()} m.s.n.m.'),
          backgroundColor: AppColors.verde,
        ),
      );
    }
  }

  void _showError(String msg) {
    if (!mounted) return;
    setState(() => _gpsLoading = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: Colors.red.shade700),
    );
  }

  void _guardar() {
    if (_formKey.currentState!.validate()) {
      final fincaToSave = Finca(
        id: _isCreatingNew ? null : _selectedFinca?.id,
        nombreAgricultero: '', // Deprecated
        nombreFinca: _fincaCtrl.text.trim(),
        vereda: _veredaCtrl.text.trim(),
        municipio: _municipio,
        altitud: _altitud.round(),
        hectareas: _hectareas,
        tipoRiego: _riego,
      );
      context.read<FincaBloc>().add(SaveFincaEvent(fincaToSave));
    }
  }

  Future<void> _eliminarFinca(Finca finca) async {
    final sqliteDataSource = GetIt.I<FincaSQLiteDataSource>();
    final database = await sqliteDataSource.db.database;
    
    // 1. Eliminar localmente de la tabla
    await database.delete(
      'finca',
      where: 'id = ?',
      whereArgs: [finca.id],
    );

    // 2. Intentar eliminar remotamente en Supabase si está online
    try {
      final client = sb.Supabase.instance.client;
      final user = client.auth.currentUser;
      if (user != null) {
        await client
            .from('fincas')
            .delete()
            .eq('usuario_id', user.id)
            .eq('nombre_finca', finca.nombreFinca);
      }
    } catch (e) {
      print('DEBUG: Error al eliminar finca en Supabase (offline): $e');
    }

    // 3. Limpiar selección si era la activa
    final selectedId = await sqliteDataSource.getSelectedFincaId();
    if (selectedId == finca.id) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('selected_finca_id');
      
      final remaining = await sqliteDataSource.loadAllFincas();
      if (remaining.isNotEmpty) {
        await sqliteDataSource.setSelectedFincaId(remaining.first.id!);
      }
    }

    // 4. Refrescar blocs y UI
    context.read<FincaBloc>().add(LoadFincaEvent());
    await _loadAllFincas();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('¡Finca eliminada correctamente! 🗑️'),
          backgroundColor: AppColors.riskHigh,
        ),
      );
    }
  }

  Future<void> _confirmarEliminarFinca(BuildContext context, Finca finca) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Text('⚠️ ', style: TextStyle(fontSize: 22)),
            Expanded(
              child: Text(
                '¿Eliminar finca?',
                style: GoogleFonts.fraunces(
                  fontWeight: FontWeight.bold,
                  color: AppColors.verdeOscuro,
                ),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '¿Estás seguro de que deseas eliminar la finca "${finca.nombreFinca}"?',
              style: GoogleFonts.dmSans(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.verdeOscuro,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.riskHigh.withOpacity(0.08),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.riskHigh.withOpacity(0.2)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.warning_amber_rounded, color: AppColors.riskHigh, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Advertencia: Si la eliminas, todos sus datos y cultivos asociados se perderán de forma permanente y ya no se podrán recuperar.',
                      style: GoogleFonts.dmSans(
                        fontSize: 12,
                        color: AppColors.riskHigh,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(
              'Cancelar',
              style: GoogleFonts.dmSans(
                color: AppColors.gris,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.riskHigh,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              'Sí, eliminar',
              style: GoogleFonts.dmSans(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _eliminarFinca(finca);
    }
  }

  @override
  void dispose() {
    _fincaCtrl.dispose();
    _veredaCtrl.dispose();
    _latCtrl.dispose();
    _lonCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final usuarioState = context.watch<UsuarioBloc>().state;
    final isGuest = usuarioState is UsuarioEmpty;

    if (isGuest) {
      return Scaffold(
        backgroundColor: AppColors.crema,
        body: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.verdeOscuro.withOpacity(0.08),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      )
                    ],
                  ),
                  child: const Text('🏡', style: TextStyle(fontSize: 64)),
                ),
                const SizedBox(height: 32),
                Text(
                  'Gestión de Fincas',
                  style: GoogleFonts.fraunces(
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                    color: AppColors.verdeOscuro,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Para registrar tus fincas, configurar tus cultivos y acceder a pronósticos climáticos y alertas de heladas personalizadas para tu región, necesitas iniciar sesión o registrarte.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.dmSans(
                    fontSize: 14,
                    color: AppColors.gris,
                    height: 1.6,
                  ),
                ),
                const SizedBox(height: 32),
                ElevatedButton.icon(
                  onPressed: () => Navigator.pushNamed(context, '/registro_usuario'),
                  icon: const Icon(Icons.login_rounded, size: 20),
                  label: Text(
                    'Iniciar Sesión / Registrarse',
                    style: GoogleFonts.dmSans(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.verde,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.crema,
      body: BlocListener<FincaBloc, FincaState>(
        listener: (context, state) {
          if (state is FincaSaved) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('¡Finca guardada exitosamente! 🌿')),
            );
            setState(() {
              _isCreatingNew = false;
              _isEditingOrAdding = false;
            });
            _loadAllFincas();
          }
          if (state is FincaLoaded) {
            if (!_isCreatingNew) {
              setState(() {
                _selectedFinca = state.finca;
              });
              _applyFinca(state.finca);
            }
          }
        },
        child: SingleChildScrollView(
          child: Column(
            children: [
              Container(
                color: AppColors.blanco,
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                child: Row(
                  children: [
                    Text('🏡 Mis Fincas',
                        style: GoogleFonts.fraunces(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: AppColors.verdeOscuro)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Datos para predicciones personalizadas',
                        textAlign: TextAlign.end,
                        style: GoogleFonts.dmSans(
                            fontSize: 12, color: AppColors.gris),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(24),
                child: !_isEditingOrAdding
                    ? Column(
                        children: [
                          // 1. Tarjeta con título "📍 Sus Fincas Registradas"
                          Container(
                            width: double.infinity,
                            margin: const EdgeInsets.only(bottom: 20),
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: AppColors.verdeOscuro,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: const [
                                BoxShadow(
                                  color: Color(0x1F000000),
                                  blurRadius: 16,
                                  offset: Offset(0, 4),
                                )
                              ],
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text('📍 Sus Fincas Registradas',
                                          style: GoogleFonts.fraunces(
                                              fontSize: 17,
                                              fontWeight: FontWeight.w700,
                                              color: AppColors.menta)),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Toca una finca para activarla en tus pronósticos',
                                        style: GoogleFonts.dmSans(
                                            fontSize: 11,
                                            color: Colors.white.withOpacity(0.7)),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                ElevatedButton.icon(
                                  onPressed: () {
                                    setState(() {
                                      _isCreatingNew = true;
                                      _selectedFinca = null;
                                      _applyFinca(null);
                                      _isEditingOrAdding = true;
                                    });
                                  },
                                  icon: const Icon(Icons.add_rounded, size: 18),
                                  label: Text('Agregar Finca',
                                      style: GoogleFonts.dmSans(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w700)),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.verde,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 14, vertical: 8),
                                    shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8)),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // 2. Lista de Fincas
                          if (_allFincas.isEmpty)
                            Center(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(vertical: 40),
                                child: Text(
                                  'No tienes fincas registradas aún. ¡Agrega la primera!',
                                  style: GoogleFonts.dmSans(
                                      fontSize: 14, color: AppColors.gris),
                                ),
                              ),
                            )
                          else
                            ..._allFincas.map((f) {
                              final isActive = f.id == _selectedFinca?.id;
                              return Container(
                                margin: const EdgeInsets.only(bottom: 14),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: isActive
                                        ? AppColors.verde
                                        : AppColors.niebla,
                                    width: isActive ? 2.5 : 1.0,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: isActive
                                          ? AppColors.verde.withOpacity(0.08)
                                          : const Color(0x081A3D2B),
                                      blurRadius: 16,
                                      offset: const Offset(0, 4),
                                    )
                                  ],
                                ),
                                child: ListTile(
                                  contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 16, vertical: 8),
                                  leading: Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: isActive
                                          ? AppColors.verde.withOpacity(0.12)
                                          : AppColors.niebla,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Text('🏡',
                                        style: TextStyle(fontSize: 22)),
                                  ),
                                  title: Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          f.nombreFinca,
                                          style: GoogleFonts.fraunces(
                                            fontSize: 17,
                                            fontWeight: FontWeight.w700,
                                            color: AppColors.verdeOscuro,
                                          ),
                                        ),
                                      ),
                                      if (isActive)
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 8, vertical: 3),
                                          decoration: BoxDecoration(
                                            color: AppColors.verde,
                                            borderRadius:
                                                BorderRadius.circular(6),
                                          ),
                                          child: Text(
                                            'ACTIVA',
                                            style: GoogleFonts.dmSans(
                                              fontSize: 9,
                                              fontWeight: FontWeight.w800,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                  subtitle: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const SizedBox(height: 4),
                                      Text(
                                        '📍 Municipio: ${f.municipio}${f.vereda.isNotEmpty ? '  •  Vereda: ${f.vereda}' : ''}',
                                        style: GoogleFonts.dmSans(
                                            fontSize: 13,
                                            color: AppColors.gris,
                                            fontWeight: FontWeight.w500),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        '⛰️ ${f.altitud} m.s.n.m.   •   📐 ${f.hectareas} ha   •   💧 Riego: ${f.tipoRiego}',
                                        style: GoogleFonts.dmSans(
                                            fontSize: 12,
                                            color: AppColors.verdeOscuro
                                                .withOpacity(0.8),
                                            fontWeight: FontWeight.w600),
                                      ),
                                    ],
                                  ),
                                  onTap: () {
                                    _onSelectFinca(f);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                            'Finca seleccionada: ${f.nombreFinca} 🌾'),
                                        duration: const Duration(seconds: 1),
                                      ),
                                    );
                                  },
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        icon: const Icon(Icons.edit_outlined,
                                            color: AppColors.verde),
                                        onPressed: () {
                                          setState(() {
                                            _isCreatingNew = false;
                                            _selectedFinca = f;
                                            _applyFinca(f);
                                            _isEditingOrAdding = true;
                                          });
                                        },
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.delete_outline_rounded,
                                            color: AppColors.riskHigh),
                                        onPressed: () => _confirmarEliminarFinca(context, f),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }).toList(),
                        ],
                      )
                    : Form(
                        key: _formKey,
                        child: Column(
                          children: [
                            // Botón para volver/cancelar
                            if (_allFincas.isNotEmpty)
                              Align(
                                alignment: Alignment.centerLeft,
                                child: Padding(
                                  padding: const EdgeInsets.only(bottom: 16),
                                  child: TextButton.icon(
                                    onPressed: () {
                                      setState(() {
                                        _isEditingOrAdding = false;
                                      });
                                    },
                                    icon: const Icon(
                                        Icons.arrow_back_ios_new_rounded,
                                        size: 16,
                                        color: AppColors.verde),
                                    label: Text(
                                      'Volver a sus fincas',
                                      style: GoogleFonts.dmSans(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w700,
                                          color: AppColors.verde),
                                    ),
                                  ),
                                ),
                              ),
                            LayoutBuilder(
                              builder: (_, constraints) {
                                final isWide = constraints.maxWidth > 600;
                                final col1 = Column(
                                  children: [
                                    _FincaCard(
                                      title: _isCreatingNew
                                          ? 'Nueva Finca — Datos básicos'
                                          : 'Editar Finca — Datos básicos',
                                      children: [
                                        _AgroField(
                                            ctrl: _fincaCtrl,
                                            label: 'Nombre de tu finca',
                                            placeholder: 'Ej: Finca El Mirador',
                                            validator: (v) => v!.isEmpty
                                                ? 'Ingresa el nombre de la finca'
                                                : null),
                                        _AgroField(
                                            ctrl: _veredaCtrl,
                                            label: 'Vereda (opcional)',
                                            placeholder:
                                                'Ej: El Encano, La Cocha...'),
                                        Padding(
                                          padding:
                                              const EdgeInsets.only(bottom: 14),
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text('Municipio',
                                                  style: GoogleFonts.dmSans(
                                                      fontSize: 13,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                      color:
                                                          AppColors.verdeOscuro)),
                                              const SizedBox(height: 6),
                                              InkWell(
                                                onTap: () {
                                                  showModalBottomSheet(
                                                    context: context,
                                                    isScrollControlled: true,
                                                    backgroundColor:
                                                        Colors.transparent,
                                                    builder: (context) {
                                                      return MunicipioSearchBottomSheet(
                                                        municipios: _municipios,
                                                        onSelected: (m) {
                                                          setState(() {
                                                            _municipio = m;
                                                            _altitud =
                                                                _municipiosService
                                                                        .getMunicipio(
                                                                            m)
                                                                        ?.altitud
                                                                        .toDouble() ??
                                                                    2500;
                                                          });
                                                        },
                                                      );
                                                    },
                                                  );
                                                },
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                                child: InputDecorator(
                                                  decoration: InputDecoration(
                                                    border: OutlineInputBorder(
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(8),
                                                        borderSide:
                                                            const BorderSide(
                                                                color: Color(
                                                                    0xFFDDE8E0))),
                                                    enabledBorder:
                                                        OutlineInputBorder(
                                                            borderRadius:
                                                                BorderRadius
                                                                    .circular(
                                                                        8),
                                                            borderSide:
                                                                const BorderSide(
                                                                    color: Color(
                                                                        0xFFDDE8E0))),
                                                    contentPadding:
                                                        const EdgeInsets
                                                            .symmetric(
                                                            horizontal: 14,
                                                            vertical: 10),
                                                    suffixIcon: const Icon(
                                                        Icons.search_rounded,
                                                        color: AppColors.gris),
                                                  ),
                                                  child: Text(
                                                    _municipio,
                                                    style: GoogleFonts.dmSans(
                                                        fontSize: 14,
                                                        color: AppColors
                                                            .verdeOscuro),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(height: 12),
                                        // ── Ubicación exacta (GPS o manual) ──────────────────────
                                        Text('📍 Ubicación exacta (opcional)',
                                            style: GoogleFonts.dmSans(
                                                fontSize: 13,
                                                fontWeight: FontWeight.w600,
                                                color: AppColors.verdeOscuro)),
                                        const SizedBox(height: 4),
                                        Text(
                                          'Use el GPS o ingrese coordenadas para calcular la altitud exacta de su finca.',
                                          style: GoogleFonts.dmSans(
                                              fontSize: 11,
                                              color: AppColors.gris),
                                        ),
                                        const SizedBox(height: 10),

                                        // Botón GPS
                                        SizedBox(
                                          width: double.infinity,
                                          child: ElevatedButton.icon(
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: AppColors.verdeOscuro,
                                              foregroundColor: Colors.white,
                                              padding: const EdgeInsets.symmetric(
                                                  vertical: 12),
                                              shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(8)),
                                              elevation: 0,
                                            ),
                                            icon: _gpsLoading
                                                ? const SizedBox(
                                                    width: 18,
                                                    height: 18,
                                                    child: CircularProgressIndicator(
                                                      strokeWidth: 2,
                                                      color: Colors.white,
                                                    ),
                                                  )
                                                : const Icon(
                                                    Icons.my_location_rounded,
                                                    size: 18),
                                            label: Text(
                                              _gpsLoading
                                                  ? 'Detectando ubicación...'
                                                  : '📍 Usar mi ubicación actual',
                                              style: GoogleFonts.dmSans(
                                                  fontSize: 13,
                                                  fontWeight: FontWeight.w600),
                                            ),
                                            onPressed: _gpsLoading ? null : _usarGPS,
                                          ),
                                        ),

                                        const SizedBox(height: 10),

                                        // Campos Latitud / Longitud
                                        Row(
                                          children: [
                                            Expanded(
                                              child: TextFormField(
                                                controller: _latCtrl,
                                                keyboardType: const TextInputType
                                                    .numberWithOptions(
                                                    decimal: true,
                                                    signed: true),
                                                style: GoogleFonts.dmSans(
                                                    fontSize: 13,
                                                    color: AppColors.verdeOscuro),
                                                decoration: InputDecoration(
                                                  labelText: 'Latitud',
                                                  hintText: 'Ej: 1.2136',
                                                  labelStyle: GoogleFonts.dmSans(
                                                      fontSize: 11,
                                                      color: AppColors.gris),
                                                  hintStyle: GoogleFonts.dmSans(
                                                      fontSize: 11,
                                                      color:
                                                          Colors.grey.shade400),
                                                  prefixIcon: const Icon(
                                                      Icons.north_rounded,
                                                      color: AppColors.verde,
                                                      size: 16),
                                                  contentPadding:
                                                      const EdgeInsets.symmetric(
                                                          horizontal: 10,
                                                          vertical: 10),
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Expanded(
                                              child: TextFormField(
                                                controller: _lonCtrl,
                                                keyboardType: const TextInputType
                                                    .numberWithOptions(
                                                    decimal: true,
                                                    signed: true),
                                                style: GoogleFonts.dmSans(
                                                    fontSize: 13,
                                                    color: AppColors.verdeOscuro),
                                                decoration: InputDecoration(
                                                  labelText: 'Longitud',
                                                  hintText: 'Ej: -77.2811',
                                                  labelStyle: GoogleFonts.dmSans(
                                                      fontSize: 11,
                                                      color: AppColors.gris),
                                                  hintStyle: GoogleFonts.dmSans(
                                                      fontSize: 11,
                                                      color:
                                                          Colors.grey.shade400),
                                                  prefixIcon: const Icon(
                                                      Icons.east_rounded,
                                                      color: AppColors.verde,
                                                      size: 16),
                                                  contentPadding:
                                                      const EdgeInsets.symmetric(
                                                          horizontal: 10,
                                                          vertical: 10),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 6),
                                        Align(
                                          alignment: Alignment.centerRight,
                                          child: TextButton.icon(
                                            onPressed: _gpsLoading
                                                ? null
                                                : _aplicarCoordenadasManuales,
                                            icon: const Icon(Icons.search_rounded,
                                                size: 16),
                                            label: Text('Buscar altitud',
                                                style: GoogleFonts.dmSans(
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.w600)),
                                            style: TextButton.styleFrom(
                                                foregroundColor: AppColors.verde),
                                          ),
                                        ),

                                        // Indicador si se detectaron coordenadas
                                        if (_usandoCoordenadas)
                                          Container(
                                            margin: const EdgeInsets.only(
                                                top: 4, bottom: 8),
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 10, vertical: 8),
                                            decoration: BoxDecoration(
                                              color: AppColors.verde
                                                  .withOpacity(0.1),
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                              border: Border.all(
                                                  color: AppColors.verde
                                                      .withOpacity(0.3)),
                                            ),
                                            child: Row(
                                              children: [
                                                const Icon(
                                                    Icons.check_circle_rounded,
                                                    color: AppColors.verde,
                                                    size: 16),
                                                const SizedBox(width: 6),
                                                Expanded(
                                                  child: Text(
                                                    'Altitud detectada: ${_altitud.round()} m.s.n.m.',
                                                    style: GoogleFonts.dmSans(
                                                        fontSize: 12,
                                                        color:
                                                            AppColors.verdeOscuro,
                                                        fontWeight:
                                                            FontWeight.w600),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                      ],
                                    ),
                                  ],
                                );
                                final col2 = Column(
                                  children: [
                                    _FincaCard(
                                      title: _isCreatingNew
                                          ? 'Nueva Finca — Características'
                                          : 'Editar Finca — Características',
                                      children: [
                                        _AgroSliderSection(
                                          label: 'Altitud',
                                          value: _altitud,
                                          unit: 'm.s.n.m.',
                                          min: 1500,
                                          max: 3600,
                                          divisions: 210,
                                          onChanged: (v) =>
                                              setState(() => _altitud = v),
                                        ),
                                        _AgroSliderSection(
                                          label: 'Tamaño de la finca',
                                          value: _hectareas,
                                          unit: 'ha',
                                          min: 0.5,
                                          max: 50,
                                          divisions: 99,
                                          onChanged: (v) =>
                                              setState(() => _hectareas = v),
                                        ),
                                        const SizedBox(height: 8),
                                        Text('Acceso a riego',
                                            style: GoogleFonts.dmSans(
                                                fontSize: 13,
                                                fontWeight: FontWeight.w600,
                                                color: AppColors.verdeOscuro)),
                                        const SizedBox(height: 8),
                                        Wrap(
                                          spacing: 8,
                                          runSpacing: 8,
                                          children: _riegos.map((r) {
                                            final sel = r == _riego;
                                            return GestureDetector(
                                              onTap: () =>
                                                  setState(() => _riego = r),
                                              child: AnimatedContainer(
                                                duration: const Duration(
                                                    milliseconds: 200),
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                        horizontal: 16,
                                                        vertical: 8),
                                                decoration: BoxDecoration(
                                                  color: sel
                                                      ? AppColors.verde
                                                      : AppColors.blanco,
                                                  borderRadius:
                                                      BorderRadius.circular(50),
                                                  border: Border.all(
                                                      color: sel
                                                          ? AppColors.verde
                                                          : AppColors.niebla,
                                                      width: 2),
                                                ),
                                                child: Text(r,
                                                    style: GoogleFonts.dmSans(
                                                        fontSize: 13,
                                                        fontWeight:
                                                            FontWeight.w500,
                                                        color: sel
                                                            ? Colors.white
                                                            : AppColors
                                                                .verdeOscuro)),
                                              ),
                                            );
                                          }).toList(),
                                        ),
                                      ],
                                    ),
                                  ],
                                );
                                return Column(
                                  children: [
                                    if (isWide)
                                      Row(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Expanded(child: col1),
                                            const SizedBox(width: 20),
                                            Expanded(child: col2)
                                          ])
                                    else ...[
                                      col1,
                                      const SizedBox(height: 16),
                                      col2
                                    ],
                                    const SizedBox(height: 20),
                                    Row(
                                      children: [
                                        if (_allFincas.isNotEmpty) ...[
                                          Expanded(
                                            child: OutlinedButton(
                                              onPressed: () {
                                                setState(() {
                                                  _isEditingOrAdding = false;
                                                });
                                              },
                                              style: OutlinedButton.styleFrom(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                        vertical: 14),
                                                foregroundColor: AppColors.verde,
                                                side: const BorderSide(
                                                    color: AppColors.verde),
                                              ),
                                              child: Text('Cancelar',
                                                  style: GoogleFonts.dmSans(
                                                      fontSize: 15,
                                                      fontWeight:
                                                          FontWeight.w600)),
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                        ],
                                        Expanded(
                                          flex: 2,
                                          child: ElevatedButton.icon(
                                            icon:
                                                const Icon(Icons.save_rounded),
                                            label: Text(
                                                _isCreatingNew
                                                    ? '✅ Guardar nueva finca'
                                                    : 'Guardar cambios',
                                                style: GoogleFonts.dmSans(
                                                    fontSize: 15,
                                                    fontWeight:
                                                        FontWeight.w600)),
                                            style: ElevatedButton.styleFrom(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                        vertical: 14),
                                                backgroundColor:
                                                    AppColors.verde,
                                                foregroundColor: Colors.white),
                                            onPressed: _guardar,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                );
                              },
                            ),
                          ],
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FincaCard extends StatelessWidget {
  final String title;
  final List<Widget> children;
  const _FincaCard({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: AppColors.blanco,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.niebla),
        boxShadow: const [BoxShadow(color: Color(0x0C1A3D2B), blurRadius: 16, offset: Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: GoogleFonts.fraunces(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.verdeOscuro)),
          const SizedBox(height: 18),
          ...children,
        ],
      ),
    );
  }
}

class _AgroField extends StatelessWidget {
  final TextEditingController ctrl;
  final String label, placeholder;
  final String? Function(String?)? validator;
  const _AgroField({required this.ctrl, required this.label, required this.placeholder, this.validator});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: GoogleFonts.dmSans(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.verdeOscuro)),
          const SizedBox(height: 6),
          TextFormField(
            controller: ctrl,
            validator: validator,
            style: GoogleFonts.dmSans(fontSize: 14),
            decoration: InputDecoration(hintText: placeholder,
                hintStyle: GoogleFonts.dmSans(fontSize: 14, color: Colors.grey.shade400)),
          ),
        ],
      ),
    );
  }
}



class _AgroSliderSection extends StatelessWidget {
  final String label, unit;
  final double value, min, max;
  final int divisions;
  final ValueChanged<double> onChanged;
  const _AgroSliderSection({required this.label, required this.value, required this.unit,
      required this.min, required this.max, required this.divisions, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text(label, style: GoogleFonts.dmSans(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.verdeOscuro)),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
              decoration: BoxDecoration(color: AppColors.niebla, borderRadius: BorderRadius.circular(6)),
              child: Text('${value == value.roundToDouble() ? value.toInt() : value.toStringAsFixed(1)} $unit',
                  style: GoogleFonts.fraunces(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.verde)),
            ),
          ]),
          Slider(value: value, min: min, max: max, divisions: divisions, onChanged: onChanged,
              activeColor: AppColors.verdeClaro, inactiveColor: const Color(0xFFDDE8E0)),
        ],
      ),
    );
  }
}
