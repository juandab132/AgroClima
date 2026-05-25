import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../prediccion/presentation/bloc/prediction_bloc.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../prediccion/presentation/bloc/prediction_event_state.dart';
import '../../../prediccion/domain/entities/frost_prediction.dart';
import '../../../finca/presentation/bloc/finca_bloc.dart';
import '../../../finca/presentation/bloc/finca_event_state.dart';
import '../../../pronostico/presentation/bloc/weather_bloc.dart';
import '../../../pronostico/presentation/bloc/weather_event_state.dart';

class PredictionPage extends StatefulWidget {
  const PredictionPage({super.key});

  @override
  State<PredictionPage> createState() => _PredictionPageState();
}

class _PredictionPageState extends State<PredictionPage> {
  double _altitud = 2527;
  double _tempMin = 6;
  double _humedad = 75;
  double _viento = 12;
  double _nubosidad = 40;
  int _mes = DateTime.now().month;
  bool _isLoadingGps = false;

  static const _meses = ['Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo', 'Junio',
    'Julio', 'Agosto', 'Septiembre', 'Octubre', 'Noviembre', 'Diciembre'];

  void _predict() {
    context.read<PredictionBloc>().add(PredictFrostEvent(
      altitud: _altitud.round(),
      tempMin: _tempMin,
      humedad: _humedad,
      mes: _mes,
      viento: _viento,
      nubosidad: _nubosidad,
    ));
  }

  Future<void> _syncWithCoordinates(double lat, double lon) async {
    setState(() => _isLoadingGps = true);
    try {
      final url = 'https://api.open-meteo.com/v1/forecast?latitude=$lat&longitude=$lon&daily=temperature_2m_min,precipitation_probability_mean,windspeed_10m_max&timezone=America/Bogota&forecast_days=1';
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final daily = data['daily'];
        
        setState(() {
          _altitud = (data['elevation'] as num?)?.toDouble().clamp(1500.0, 3600.0) ?? _altitud;
          _tempMin = (daily['temperature_2m_min'][0] as num).toDouble().clamp(-5.0, 20.0);
          _viento = (daily['windspeed_10m_max'][0] as num).toDouble().clamp(0.0, 60.0);
          final rainProb = (daily['precipitation_probability_mean'][0] as num?)?.toDouble() ?? 0.0;
          _humedad = (rainProb > 50 ? 80.0 : 40.0).clamp(20.0, 100.0);
          _nubosidad = (rainProb > 50 ? 80.0 : 30.0).clamp(0.0, 100.0);
        });

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('✅ Datos climáticos obtenidos para Lat: $lat, Lon: $lon'),
              backgroundColor: AppColors.verde,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
        _predict();
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('❌ Error al obtener clima para esas coordenadas'),
            backgroundColor: AppColors.riskHigh,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoadingGps = false);
    }
  }

  Future<void> _showManualCoordinatesDialog() async {
    final latCtrl = TextEditingController(text: '1.2136'); // Pasto default
    final lonCtrl = TextEditingController(text: '-77.2811');

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.blanco,
        title: Text('Ingresar Coordenadas', style: GoogleFonts.fraunces(color: AppColors.verdeOscuro, fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Escribe las coordenadas exactas para consultar el satélite:', style: GoogleFonts.dmSans(fontSize: 13, color: AppColors.gris)),
            const SizedBox(height: 16),
            TextField(
              controller: latCtrl,
              keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
              decoration: const InputDecoration(labelText: 'Latitud (Ej: 1.2136)', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: lonCtrl,
              keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
              decoration: const InputDecoration(labelText: 'Longitud (Ej: -77.2811)', border: OutlineInputBorder()),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text('Cancelar', style: GoogleFonts.dmSans(color: AppColors.gris))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.verde, foregroundColor: Colors.white),
            onPressed: () {
              final lat = double.tryParse(latCtrl.text);
              final lon = double.tryParse(lonCtrl.text);
              Navigator.pop(context);
              if (lat != null && lon != null) {
                _syncWithCoordinates(lat, lon);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Coordenadas inválidas')));
              }
            },
            child: const Text('Consultar'),
          ),
        ],
      ),
    );
  }

  Future<void> _syncWithGPS(BuildContext context) async {
    setState(() => _isLoadingGps = true);
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) throw Exception('Permiso denegado');
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.medium),
      );

      await _syncWithCoordinates(position.latitude, position.longitude);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('❌ Error al obtener ubicación GPS. ¿Tienes el GPS encendido?'),
            backgroundColor: AppColors.riskHigh,
          ),
        );
      }
      if (mounted) setState(() => _isLoadingGps = false);
    }
  }

  @override
  void initState() {
    super.initState();
    _predict();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.crema,
      body: Column(
        children: [
          Container(
            color: AppColors.blanco,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Row(
              children: [
                Text('🤖 Predicción IA',
                    style: GoogleFonts.fraunces(fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.verdeOscuro)),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFCE8E0),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text('NUEVO',
                      style: GoogleFonts.dmSans(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.riskHigh)),
                ),
              ],
            ),
          ),
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final isWide = constraints.maxWidth > 700;
                final inputPanel = _InputPanel(
                  altitud: _altitud, tempMin: _tempMin, humedad: _humedad,
                  viento: _viento, nubosidad: _nubosidad, mes: _mes,
                  meses: _meses,
                  onAltitudChanged: (v) { setState(() => _altitud = v); _predict(); },
                  onTempChanged: (v) { setState(() => _tempMin = v); _predict(); },
                  onHumedadChanged: (v) { setState(() => _humedad = v); _predict(); },
                  onVientoChanged: (v) { setState(() => _viento = v); _predict(); },
                  onNubosidadChanged: (v) { setState(() => _nubosidad = v); _predict(); },
                  onMesChanged: (v) { setState(() => _mes = v); _predict(); },
                  onSync: () => _syncWithGPS(context),
                  onManualSync: _showManualCoordinatesDialog,
                  isLoadingGps: _isLoadingGps,
                );
                final resultPanel = const _ResultPanel();

                if (isWide) {
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: SingleChildScrollView(padding: const EdgeInsets.all(24), child: inputPanel)),
                      Expanded(child: SingleChildScrollView(padding: const EdgeInsets.all(24), child: resultPanel)),
                    ],
                  );
                }
                return SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(children: [inputPanel, const SizedBox(height: 16), resultPanel]),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _InputPanel extends StatelessWidget {
  final double altitud, tempMin, humedad, viento, nubosidad;
  final int mes;
  final List<String> meses;
  final ValueChanged<double> onAltitudChanged, onTempChanged, onHumedadChanged,
      onVientoChanged, onNubosidadChanged;
  final ValueChanged<int> onMesChanged;
  final VoidCallback onSync;
  final VoidCallback onManualSync;
  final bool isLoadingGps;

  const _InputPanel({
    required this.altitud, required this.tempMin, required this.humedad,
    required this.viento, required this.nubosidad, required this.mes,
    required this.meses, required this.onAltitudChanged, required this.onTempChanged,
    required this.onHumedadChanged, required this.onVientoChanged,
    required this.onNubosidadChanged, required this.onMesChanged,
    required this.onSync,
    required this.onManualSync,
    required this.isLoadingGps,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
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
          Text('🌡️ Predicción de Riesgo de Helada',
              style: GoogleFonts.fraunces(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.verdeOscuro)),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: isLoadingGps ? null : onSync,
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        color: AppColors.menta.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.verde.withValues(alpha: 0.5)),
                      ),
                      child: Row(
                        children: [
                          if (isLoadingGps)
                            const Padding(
                              padding: EdgeInsets.only(right: 12),
                              child: SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.verde)),
                            )
                          else
                            const Text('📡 ', style: TextStyle(fontSize: 18)),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(isLoadingGps ? 'Buscando satélites...' : 'Usar mi GPS actual', 
                                    style: GoogleFonts.dmSans(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.verdeOscuro)),
                                Text('Clima exacto', style: GoogleFonts.dmSans(fontSize: 11, color: AppColors.verdeOscuro.withValues(alpha: 0.8))),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                InkWell(
                  onTap: isLoadingGps ? null : onManualSync,
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
                    decoration: BoxDecoration(
                      color: AppColors.niebla,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFDDE8E0)),
                    ),
                    child: const Icon(Icons.edit_location_alt, color: AppColors.verdeOscuro, size: 24),
                  ),
                ),
              ],
            ),
          ),
          _AgroSlider(label: 'Altitud de tu finca', value: altitud, unit: 'm.s.n.m.',
              min: 1500, max: 3600, divisions: 210, onChanged: onAltitudChanged),
          _AgroSlider(label: 'Temperatura mínima esta noche', value: tempMin, unit: '°C',
              min: -5, max: 20, divisions: 50, onChanged: onTempChanged),
          _AgroSlider(label: 'Humedad relativa', value: humedad, unit: '%',
              min: 20, max: 100, divisions: 80, onChanged: onHumedadChanged),
          _AgroSlider(label: 'Velocidad del viento', value: viento, unit: 'km/h',
              min: 0, max: 60, divisions: 60, onChanged: onVientoChanged),
          _AgroSlider(label: 'Nubosidad', value: nubosidad, unit: '%',
              min: 0, max: 100, divisions: 100, onChanged: onNubosidadChanged),
          const SizedBox(height: 4),
          Text('Mes del año',
              style: GoogleFonts.dmSans(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.verdeOscuro)),
          const SizedBox(height: 8),
          DropdownButtonFormField<int>(
            value: mes,
            decoration: InputDecoration(
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Color(0xFFDDE8E0))),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Color(0xFFDDE8E0))),
            ),
            style: GoogleFonts.dmSans(fontSize: 14, color: AppColors.verdeOscuro),
            items: List.generate(12, (i) => DropdownMenuItem(value: i + 1, child: Text(meses[i]))),
            onChanged: (v) { if (v != null) onMesChanged(v); },
          ),
        ],
      ),
    );
  }
}

class _AgroSlider extends StatelessWidget {
  final String label;
  final double value, min, max;
  final int divisions;
  final String unit;
  final ValueChanged<double> onChanged;

  const _AgroSlider({required this.label, required this.value, required this.unit,
      required this.min, required this.max, required this.divisions, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label, style: GoogleFonts.dmSans(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.verdeOscuro)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                decoration: BoxDecoration(color: AppColors.niebla, borderRadius: BorderRadius.circular(6)),
                child: Text('${value == value.toInt() ? value.toInt() : value.toStringAsFixed(1)} $unit',
                    style: GoogleFonts.fraunces(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.verde)),
              ),
            ],
          ),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              trackHeight: 6, thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 9),
              activeTrackColor: AppColors.verdeClaro, inactiveTrackColor: const Color(0xFFDDE8E0),
              thumbColor: AppColors.verde,
            ),
            child: Slider(value: value, min: min, max: max, divisions: divisions, onChanged: onChanged),
          ),
        ],
      ),
    );
  }
}

class _ResultPanel extends StatelessWidget {
  const _ResultPanel();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PredictionBloc, PredictionState>(
      builder: (context, state) {
        if (state is PredictionLoading) {
          return const Center(child: CircularProgressIndicator(color: AppColors.verde));
        }
        if (state is PredictionLoaded) {
          return Column(
            children: [
              _FrostResultCard(prediction: state.prediction),
              const SizedBox(height: 16),
              if (state.spray != null) _SprayCard(spray: state.spray!),
              const SizedBox(height: 16),
              _DecisionTreeCard(prediction: state.prediction),
              const SizedBox(height: 16),
              const _TelegramBotCard(),
            ],
          );
        }
        return const SizedBox.shrink();
      },
    );
  }
}

class _TelegramBotCard extends StatelessWidget {
  const _TelegramBotCard();

  Future<void> _launchTelegram() async {
    final Uri url = Uri.parse('https://t.me/AgroClimaNarinoBot');
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      debugPrint('No se pudo abrir $url');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: const Color(0xFFE8F4FA),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFB3D9EA)),
        boxShadow: const [BoxShadow(color: Color(0x0C1A3D2B), blurRadius: 16, offset: Offset(0, 4))],
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Text('🤖', style: TextStyle(fontSize: 28)),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Asistente de Telegram',
                        style: GoogleFonts.fraunces(fontSize: 16, fontWeight: FontWeight.w700, color: const Color(0xFF0C567A))),
                    Text('Consultas rápidas por chat',
                        style: GoogleFonts.dmSans(fontSize: 13, color: const Color(0xFF1E82B1))),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            '¡Nuestro Bot entiende tu forma de hablar campesina! Puedes preguntarle directamente sobre el clima, heladas o si es buen momento para fumigar sin usar comandos difíciles.',
            style: GoogleFonts.dmSans(fontSize: 12.5, color: const Color(0xFF236C8F), height: 1.5),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              icon: const Icon(Icons.telegram, size: 20),
              label: Text('Abrir Chat en Telegram', style: GoogleFonts.dmSans(fontWeight: FontWeight.w700)),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF229ED9), // Telegram Blue
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: _launchTelegram,
            ),
          ),
        ],
      ),
    );
  }
}

class _FrostResultCard extends StatelessWidget {
  final FrostPrediction prediction;
  const _FrostResultCard({required this.prediction});

  Color get _riskColor {
    switch (prediction.level) {
      case RiskLevel.high: return AppColors.riskHigh;
      case RiskLevel.medium: return AppColors.riskMedium;
      case RiskLevel.low: return AppColors.riskLow;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: AppColors.blanco,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.niebla),
        boxShadow: const [BoxShadow(color: Color(0x0C1A3D2B), blurRadius: 16, offset: Offset(0, 4))],
      ),
      child: Column(
        children: [
          Text('Resultado: Riesgo de Helada',
              style: GoogleFonts.fraunces(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.verdeOscuro)),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _SemaforoDot2(emoji: '❄️', label: 'ALTO', active: prediction.level == RiskLevel.high, color: AppColors.riskHigh),
              const SizedBox(width: 12),
              _SemaforoDot2(emoji: '⚠️', label: 'MEDIO', active: prediction.level == RiskLevel.medium, color: AppColors.riskMedium),
              const SizedBox(width: 12),
              _SemaforoDot2(emoji: '✅', label: 'BAJO', active: prediction.level == RiskLevel.low, color: AppColors.riskLow),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
            decoration: BoxDecoration(
              color: _riskColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: _riskColor),
            ),
            child: Text(
              '${prediction.level == RiskLevel.high ? '🔴' : prediction.level == RiskLevel.medium ? '🟡' : '🟢'} Riesgo ${prediction.levelLabel}',
              style: GoogleFonts.dmSans(fontSize: 15, fontWeight: FontWeight.w700, color: _riskColor),
            ),
          ),
          const SizedBox(height: 12),
          Text(prediction.recommendation,
              style: GoogleFonts.dmSans(fontSize: 13, color: AppColors.gris, height: 1.6),
              textAlign: TextAlign.center),
          const SizedBox(height: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Text('Confianza del modelo',
                    style: GoogleFonts.dmSans(fontSize: 11, letterSpacing: 0.5, color: AppColors.gris, fontWeight: FontWeight.w600)),
                Text('${(prediction.confidence * 100).toInt()}%',
                    style: GoogleFonts.fraunces(fontSize: 14, fontWeight: FontWeight.w700)),
              ]),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: prediction.confidence,
                  minHeight: 8,
                  backgroundColor: AppColors.niebla,
                  valueColor: AlwaysStoppedAnimation<Color>(_riskColor),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SemaforoDot2 extends StatelessWidget {
  final String emoji, label;
  final bool active;
  final Color color;
  const _SemaforoDot2({required this.emoji, required this.label, required this.active, required this.color});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 400),
      width: 56, height: 56,
      decoration: BoxDecoration(
        color: active ? color.withValues(alpha: 0.18) : AppColors.niebla,
        shape: BoxShape.circle,
        boxShadow: active ? [BoxShadow(color: color.withValues(alpha: 0.45), blurRadius: 18, spreadRadius: 2)] : null,
      ),
      child: Center(child: Text(emoji, style: TextStyle(fontSize: 24, color: active ? color : Colors.grey.shade400))),
    );
  }
}

class _SprayCard extends StatelessWidget {
  final SprayDecision spray;
  const _SprayCard({required this.spray});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: AppColors.blanco,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.niebla),
        boxShadow: const [BoxShadow(color: Color(0x0C1A3D2B), blurRadius: 16, offset: Offset(0, 4))],
      ),
      child: Column(
        children: [
          Text('💊 ¿Es buen día para fumigar?',
              style: GoogleFonts.fraunces(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.verdeOscuro)),
          const SizedBox(height: 14),
          Text(spray.isGood ? '✅' : '❌', style: const TextStyle(fontSize: 48)),
          const SizedBox(height: 6),
          Text(
            spray.isGood ? 'SÍ — Condiciones ideales' : 'NO — Espera otro día',
            style: GoogleFonts.fraunces(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.verdeOscuro),
          ),
          const SizedBox(height: 10),
          Text(spray.isGood
              ? 'Viento bajo y sin lluvia pronosticada. El agroquímico no se desperdiciaría.'
              : spray.windOk ? 'Alta probabilidad de lluvia. El producto se lavaría.' : 'Viento muy fuerte. El producto no llegaría bien.',
              style: GoogleFonts.dmSans(fontSize: 13, color: AppColors.gris, height: 1.6),
              textAlign: TextAlign.center),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(child: _IndBox(label: '💨 Viento', ok: spray.windOk)),
              const SizedBox(width: 10),
              Expanded(child: _IndBox(label: '🌧️ Lluvia', ok: spray.rainOk)),
            ],
          ),
        ],
      ),
    );
  }
}

class _IndBox extends StatelessWidget {
  final String label;
  final bool ok;
  const _IndBox({required this.label, required this.ok});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(color: AppColors.niebla, borderRadius: BorderRadius.circular(8)),
      child: Column(
        children: [
          Text(label, style: GoogleFonts.dmSans(fontSize: 11, color: AppColors.gris, letterSpacing: 0.5)),
          const SizedBox(height: 4),
          Text(ok ? '✅ OK' : '❌',
              style: GoogleFonts.fraunces(fontSize: 15, fontWeight: FontWeight.w700,
                  color: ok ? AppColors.riskLow : AppColors.riskHigh)),
        ],
      ),
    );
  }
}

class _DecisionTreeCard extends StatelessWidget {
  final FrostPrediction prediction;
  const _DecisionTreeCard({required this.prediction});

  @override
  Widget build(BuildContext context) {
    return Container(
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
          Text('🌳 Árbol de Decisión Experto',
              style: GoogleFonts.fraunces(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.verdeOscuro)),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF132A1D),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFF284835)),
            ),
            child: Text(
              'Altitud > 2800m → SÍ\n'
              '└─ Temp.min < 2°C → SÍ\n'
              '   └─ Humedad < 50% y Nubosidad < 30% → SÍ\n'
              '      └─ Viento < 3 km/h → ALTO RIESGO 🔴❄️\n'
              '      └─ Viento > 15 km/h → RIESGO MEDIO 🟡\n'
              '└─ Temp.min ≥ 4°C → BAJO RIESGO 🟢',
              style: GoogleFonts.robotoMono(
                  fontSize: 11.5, color: const Color(0xFFD1F0DB), height: 1.8),
            ),
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFF0FDF4),
              border: const Border(left: BorderSide(color: AppColors.verde, width: 4)),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('💡 ', style: TextStyle(fontSize: 18)),
                Expanded(
                  child: Text.rich(
                    TextSpan(
                      style: GoogleFonts.dmSans(fontSize: 12, height: 1.6, color: AppColors.verdeOscuro),
                      children: const [
                        TextSpan(text: 'Modelo agronómico local entrenado con '),
                        TextSpan(text: '2 años de datos del IDEAM ', style: TextStyle(fontWeight: FontWeight.w700)),
                        TextSpan(text: 'para la orografía de Nariño. Considera que el '),
                        TextSpan(text: 'viento fuerte (>15 km/h) ', style: TextStyle(fontWeight: FontWeight.w700)),
                        TextSpan(text: 'mezcla el aire frío superficial y disminuye drásticamente la probabilidad de helada radiativa.'),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (prediction.factors.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text('🔍 Análisis de factores:',
                style: GoogleFonts.dmSans(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.verdeOscuro)),
            const SizedBox(height: 8),
            ...prediction.factors.map((f) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('• ', style: TextStyle(color: AppColors.verde, fontSize: 16, height: 1.2)),
                  Expanded(child: Text(f, style: GoogleFonts.dmSans(fontSize: 13, color: AppColors.gris, height: 1.4))),
                ],
              ),
            )),
          ],
        ],
      ),
    );
  }
}
