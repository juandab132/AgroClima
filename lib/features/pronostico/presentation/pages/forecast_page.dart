import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../features/pronostico/domain/entities/weather_forecast.dart';
import '../../../pronostico/presentation/bloc/weather_bloc.dart';
import '../../../pronostico/presentation/bloc/weather_event_state.dart';

import 'package:get_it/get_it.dart';
import '../../../../core/services/municipios_service.dart';
import '../../../../core/widgets/municipio_search_bottom_sheet.dart';

class ForecastPage extends StatefulWidget {
  const ForecastPage({super.key});

  @override
  State<ForecastPage> createState() => _ForecastPageState();
}

class _ForecastPageState extends State<ForecastPage> {
  String _municipio = 'Pasto';
  final _municipiosService = GetIt.I<MunicipiosService>();
  late final List<String> _municipios;
  List<String> _quickAccess = ['Pasto', 'Túquerres', 'Ipiales', 'Cumbal', 'La Unión'];

  @override
  void initState() {
    super.initState();
    _municipios = _municipiosService.municipios.keys.toList();
    _loadQuickAccess();
  }

  Future<void> _loadQuickAccess() async {
    final prefs = await SharedPreferences.getInstance();
    
    // Cargar coordenadas guardadas de municipios personalizados
    final customJson = prefs.getString('custom_municipios_data');
    if (customJson != null) {
      try {
        final Map<String, dynamic> decoded = json.decode(customJson);
        decoded.forEach((key, val) {
          _municipiosService.registerMunicipio(
            key,
            (val['lat'] as num).toDouble(),
            (val['lon'] as num).toDouble(),
            (val['alt'] as num).toInt(),
          );
        });
      } catch (_) {}
    }

    final saved = prefs.getStringList('quick_access_municipios');
    if (saved != null && saved.isNotEmpty) {
      setState(() {
        _quickAccess = saved;
      });
    }
  }

  Future<void> _saveQuickAccess() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('quick_access_municipios', _quickAccess);
  }

  List<String> get _visibleMunicipios {
    if (!_quickAccess.contains(_municipio)) {
      return [_municipio, ..._quickAccess];
    }
    return _quickAccess;
  }

  void _mostrarSelectorMunicipios() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return MunicipioSearchBottomSheet(
          municipios: _municipios,
          onSelected: (m) {
            setState(() => _municipio = m);
            context.read<WeatherBloc>().add(FetchForecastEvent(m));
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.crema,
      body: Column(
        children: [
          // TopBar (Corregido desbordamiento horizontal)
          Container(
            color: AppColors.blanco,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Row(
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Text('🌤️ Clima en ',
                          style: GoogleFonts.fraunces(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: AppColors.verdeOscuro)),
                      Flexible(
                        child: Text(_municipio,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.fraunces(
                                fontSize: 18,
                                fontWeight: FontWeight.w900,
                                color: AppColors.verde)),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        constraints: const BoxConstraints(),
                        padding: EdgeInsets.zero,
                        icon: Icon(
                          _quickAccess.contains(_municipio) ? Icons.star_rounded : Icons.star_outline_rounded,
                          color: AppColors.acento,
                          size: 24,
                        ),
                        onPressed: () {
                          setState(() {
                            if (_quickAccess.contains(_municipio)) {
                              if (_quickAccess.length > 1) {
                                _quickAccess.remove(_municipio);
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Debes tener al menos 1 municipio en el acceso rápido.')),
                                );
                              }
                            } else {
                              _quickAccess.add(_municipio);
                            }
                            _saveQuickAccess();
                          });
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Text('Open-Meteo',
                    style: GoogleFonts.dmSans(fontSize: 12, color: AppColors.gris)),
              ],
            ),
          ),

          // Selector municipio
          Container(
            color: AppColors.blanco,
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  ..._visibleMunicipios.map((m) {
                    final sel = m == _municipio;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        child: ElevatedButton.icon(
                          icon: Text('📍', style: const TextStyle(fontSize: 13)),
                          label: Text(m,
                              style: GoogleFonts.dmSans(
                                  fontWeight: FontWeight.w600, fontSize: 13)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: sel ? AppColors.verde : AppColors.niebla,
                            foregroundColor: sel ? Colors.white : AppColors.verdeOscuro,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8)),
                          ),
                          onPressed: () {
                            setState(() => _municipio = m);
                            context.read<WeatherBloc>().add(FetchForecastEvent(m));
                          },
                        ),
                      ),
                    );
                  }),
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.search_rounded, size: 16),
                      label: Text('Buscar',
                          style: GoogleFonts.dmSans(
                              fontWeight: FontWeight.w600, fontSize: 13)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.niebla,
                        foregroundColor: AppColors.verdeOscuro,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8)),
                      ),
                      onPressed: _mostrarSelectorMunicipios,
                    ),
                  ),
                ],
              ),
            ),
          ),

          const Divider(height: 1, color: AppColors.niebla),

          // Contenido
          Expanded(
            child: BlocBuilder<WeatherBloc, WeatherState>(
              builder: (context, state) {
                if (state is WeatherLoading) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(color: AppColors.verde),
                        SizedBox(height: 12),
                        Text('Consultando el clima...'),
                      ],
                    ),
                  );
                }
                if (state is WeatherError) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.cloud_off_rounded,
                              size: 52, color: AppColors.gris),
                          const SizedBox(height: 12),
                          Text(state.message,
                              textAlign: TextAlign.center,
                              style: GoogleFonts.dmSans(
                                  fontSize: 14, color: AppColors.gris)),
                          const SizedBox(height: 20),
                          ElevatedButton(
                            onPressed: () => context
                                .read<WeatherBloc>()
                                .add(FetchForecastEvent(_municipio)),
                            child: Text('Intentar de nuevo',
                                style: GoogleFonts.dmSans(fontWeight: FontWeight.w600)),
                          ),
                        ],
                      ),
                    ),
                  );
                }
                if (state is WeatherLoaded) {
                  return Column(
                    children: [
                      if (state.fromCache)
                        Container(
                          color: const Color(0xFFFEF3C7),
                          padding: const EdgeInsets.symmetric(
                              vertical: 8, horizontal: 20),
                          child: Row(
                            children: [
                              const Text('⚡ ',
                                  style: TextStyle(fontSize: 14)),
                              Text(
                                  'Mostrando datos guardados (sin conexión)',
                                  style: GoogleFonts.dmSans(
                                      fontSize: 13,
                                      color: AppColors.riskMedium)),
                            ],
                          ),
                        ),
                      Expanded(
                        child: ListView.separated(
                          padding: const EdgeInsets.all(20),
                          itemCount: state.forecast.days.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 12),
                          itemBuilder: (_, i) {
                            final d = state.forecast.days[i];
                            return _ForecastDayCard(
                                day: d, isToday: i == 0);
                          },
                        ),
                      ),
                    ],
                  );
                }
                return Center(
                  child: Text(
                    'Selecciona un municipio arriba para cargar el pronóstico',
                    style: GoogleFonts.dmSans(
                        color: AppColors.gris, fontSize: 14),
                    textAlign: TextAlign.center,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _ForecastDayCard extends StatelessWidget {
  final WeatherDay day;
  final bool isToday;
  const _ForecastDayCard({required this.day, this.isToday = false});

  @override
  Widget build(BuildContext context) {
    final isBest = day.isGoodForSpray;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.blanco,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isBest ? AppColors.acento : AppColors.niebla,
          width: isBest ? 2 : 1,
        ),
        boxShadow: const [
          BoxShadow(
              color: Color(0x0C1A3D2B), blurRadius: 12, offset: Offset(0, 4))
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Text(day.emoji, style: const TextStyle(fontSize: 32)),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isToday ? '${day.dayName} (Hoy)' : day.dayName,
                      style: GoogleFonts.fraunces(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppColors.verdeOscuro),
                    ),
                    Text(
                      '🌡️ ${day.tempMin.toInt()}° – ${day.tempMax.toInt()}°C',
                      style: GoogleFonts.dmSans(
                          fontSize: 14, color: AppColors.gris),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('🌧️ ${day.rainProbability.toInt()}%',
                      style: GoogleFonts.dmSans(
                          fontSize: 14, fontWeight: FontWeight.w600,
                          color: AppColors.azul)),
                  Text('💨 ${day.windSpeed.toInt()} km/h',
                      style: GoogleFonts.dmSans(
                          fontSize: 13, color: AppColors.gris)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: day.rainProbability / 100,
              minHeight: 6,
              backgroundColor: AppColors.niebla,
              valueColor: AlwaysStoppedAnimation<Color>(
                day.rainProbability > 60
                    ? AppColors.riskHigh
                    : day.rainProbability > 30
                        ? AppColors.acento
                        : AppColors.riskLow,
              ),
            ),
          ),
          if (isBest) ...[
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerLeft,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF3C7),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.acento),
                ),
                child: Text('✅ Buen día para fumigar',
                    style: GoogleFonts.dmSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.tierra)),
              ),
            ),
          ],
        ],
      ),
    );
  }
}


