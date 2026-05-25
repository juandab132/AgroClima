import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/services/notification_service.dart';
import '../../../finca/presentation/bloc/finca_bloc.dart';
import '../../../finca/presentation/bloc/finca_event_state.dart';
import '../../../pronostico/presentation/bloc/weather_bloc.dart';
import '../../../pronostico/presentation/bloc/weather_event_state.dart';
import '../../../pronostico/domain/entities/weather_forecast.dart';
import '../../../prediccion/presentation/bloc/prediction_bloc.dart';
import '../../../prediccion/domain/entities/frost_prediction.dart';
import '../../../prediccion/presentation/bloc/prediction_event_state.dart';
import '../../../usuario/presentation/bloc/usuario_bloc.dart';
import '../../../usuario/presentation/bloc/usuario_event_state.dart';
import 'package:get_it/get_it.dart';

class DashboardPage extends StatelessWidget {
  final Function(int)? onNavigate;
  const DashboardPage({super.key, this.onNavigate});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.crema,
      body: BlocBuilder<UsuarioBloc, UsuarioState>(
        builder: (context, usuarioState) {
          if (usuarioState is UsuarioLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (usuarioState is UsuarioEmpty || usuarioState is UsuarioError) {
            return _buildNoUser(context);
          }
          if (usuarioState is UsuarioLoaded) {
            final usuario = usuarioState.usuario;
            
            return BlocBuilder<FincaBloc, FincaState>(
              builder: (context, fincaState) {
                if (fincaState is FincaLoading) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (fincaState is FincaEmpty) {
                  return _buildNoFinca(context, usuario.nombres);
                }
                if (fincaState is FincaLoaded) {
                  final finca = fincaState.finca;
                  return RefreshIndicator(
                    onRefresh: () async {
                      context.read<WeatherBloc>().add(FetchForecastEvent(finca.municipio, altitud: finca.altitud));
                    },
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _Header(nombre: usuario.nombres),
                          const SizedBox(height: 24),
                          _FrostRiskCard(finca: finca),
                          const SizedBox(height: 24),
                          _WeatherStrip(municipio: finca.municipio),
                          const SizedBox(height: 24),
                          _QuickActions(onNavigate: onNavigate),
                        ],
                      ),
                    ),
                  );
                }
                return const Center(child: Text('Algo salió mal al cargar su finca.'));
              },
            );
          }
          return const Center(child: Text('Algo salió mal al cargar su perfil.'));
        },
      ),
    );
  }

  Widget _buildNoUser(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('👨‍🌾', style: TextStyle(fontSize: 64)),
          const SizedBox(height: 16),
          Text('¡Bienvenido a AgroClima!',
              style: GoogleFonts.fraunces(fontSize: 20, fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          Text('Registra tu perfil para comenzar',
              style: GoogleFonts.dmSans(fontSize: 15, color: AppColors.gris)),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => Navigator.pushNamed(context, '/registro_usuario'),
            child: const Text('Registrar Perfil'),
          ),
        ],
      ),
    );
  }

  Widget _buildNoFinca(BuildContext context, String nombre) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('🏡', style: TextStyle(fontSize: 64)),
          const SizedBox(height: 16),
          Text('Hola $nombre, aún no has registrado tu finca',
              style: GoogleFonts.fraunces(fontSize: 18, fontWeight: FontWeight.w700)),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => Navigator.pushNamed(context, '/registro'),
            child: const Text('Registrar mi finca'),
          ),
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final String nombre;
  const _Header({required this.nombre});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('¡Buenas, $nombre! 👨‍🌾',
            style: GoogleFonts.fraunces(
                fontSize: 24,
                fontWeight: FontWeight.w900,
                color: AppColors.verdeOscuro)),
        const SizedBox(height: 4),
        Text('Aquí tiene el resumen de su campo para hoy.',
            style: GoogleFonts.dmSans(fontSize: 14, color: AppColors.gris)),
      ],
    );
  }
}

class _FrostRiskCard extends StatelessWidget {
  final dynamic finca;
  const _FrostRiskCard({required this.finca});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<WeatherBloc, WeatherState>(
      builder: (context, weatherState) {
        if (weatherState is WeatherLoaded) {
          final today = weatherState.forecast.days.first;
          
          // Disparamos la predicción si no se ha hecho
          context.read<PredictionBloc>().add(PredictFrostEvent(
            altitud: finca.altitud,
            tempMin: today.tempMin,
            humedad: today.rainProbability > 50 ? 80 : 40, // Estimación simple
            mes: DateTime.now().month,
            viento: today.windSpeed,
          ));

          return BlocBuilder<PredictionBloc, PredictionState>(
            builder: (context, predState) {
              if (predState is PredictionLoaded) {
                final risk = predState.prediction.level;
                final color = _getRiskColor(risk);
                
                if (risk == RiskLevel.high) {
                  final service = GetIt.I<NotificationService>();
                  service.showFrostAlert(
                    recommendation: predState.prediction.recommendation
                  );
                  service.scheduleFrostCheck(
                    recommendation: predState.prediction.recommendation
                  );
                }
                
                return Column(
                  children: [
                    if (risk == RiskLevel.high)
                      Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.riskHigh,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.warning_amber_rounded, color: Colors.white),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                '¡ALERTA! Riesgo alto de helada para esta noche.',
                                style: GoogleFonts.dmSans(
                                    color: Colors.white, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ),
                      ),
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: AppColors.blanco,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: color.withOpacity(0.3), width: 2),
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('RIESGO DE HELADA',
                                      style: GoogleFonts.dmSans(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w800,
                                          letterSpacing: 1.2,
                                          color: AppColors.gris)),
                                  const SizedBox(height: 4),
                                  Text(predState.prediction.levelLabel,
                                      style: GoogleFonts.fraunces(
                                          fontSize: 28,
                                          fontWeight: FontWeight.w900,
                                          color: color)),
                                ],
                              ),
                              _RiskIndicator(level: risk),
                            ],
                          ),
                          const Divider(height: 32),
                          Text(predState.prediction.recommendation,
                              textAlign: TextAlign.center,
                              style: GoogleFonts.dmSans(
                                  fontSize: 15, fontStyle: FontStyle.italic, color: AppColors.verdeOscuro)),
                        ],
                      ),
                    ),
                  ],
                );
              }
              return const SizedBox(height: 100, child: Center(child: CircularProgressIndicator()));
            },
          );
        }
        return const SizedBox();
      },
    );
  }

  Color _getRiskColor(RiskLevel level) {
    switch (level) {
      case RiskLevel.high: return AppColors.riskHigh;
      case RiskLevel.medium: return AppColors.riskMedium;
      case RiskLevel.low: return AppColors.riskLow;
    }
  }
}

class _RiskIndicator extends StatelessWidget {
  final RiskLevel level;
  const _RiskIndicator({required this.level});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _Circle(active: level == RiskLevel.low, color: AppColors.riskLow),
        const SizedBox(width: 4),
        _Circle(active: level == RiskLevel.medium, color: AppColors.riskMedium),
        const SizedBox(width: 4),
        _Circle(active: level == RiskLevel.high, color: AppColors.riskHigh),
      ],
    );
  }
}

class _Circle extends StatelessWidget {
  final bool active;
  final Color color;
  const _Circle({required this.active, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 12,
      height: 12,
      decoration: BoxDecoration(
        color: active ? color : AppColors.niebla,
        shape: BoxShape.circle,
      ),
    );
  }
}

class _WeatherStrip extends StatelessWidget {
  final String municipio;
  const _WeatherStrip({required this.municipio});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Pronóstico 3 días',
                style: GoogleFonts.fraunces(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.verdeOscuro)),
            Text(municipio, style: GoogleFonts.dmSans(fontSize: 13, color: AppColors.gris)),
          ],
        ),
        const SizedBox(height: 12),
        BlocBuilder<WeatherBloc, WeatherState>(
          builder: (context, state) {
            if (state is WeatherLoading) {
              return const Center(child: CircularProgressIndicator());
            }
            if (state is WeatherLoaded) {
              final forecast = state.forecast.days.take(3).toList();
              return Row(
                children: forecast.map((day) => Expanded(child: _WeatherSmallCard(day: day))).toList(),
              );
            }
            return const Text('No se pudo cargar el clima');
          },
        ),
      ],
    );
  }
}

class _WeatherSmallCard extends StatelessWidget {
  final WeatherDay day;
  const _WeatherSmallCard({required this.day});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.blanco,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.niebla),
      ),
      child: Column(
        children: [
          Text(day.dayName.substring(0, 3),
              style: GoogleFonts.dmSans(fontSize: 12, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(day.emoji, style: const TextStyle(fontSize: 20)),
          const SizedBox(height: 4),
          Text('${day.tempMin.round()}° / ${day.tempMax.round()}°',
              style: GoogleFonts.dmSans(fontSize: 12, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class _QuickActions extends StatelessWidget {
  final Function(int)? onNavigate;
  const _QuickActions({this.onNavigate});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Acceso rápido',
            style: GoogleFonts.fraunces(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.verdeOscuro)),
        const SizedBox(height: 12),
        _ActionBtn(
          icon: Icons.wb_sunny_rounded,
          label: 'Pronóstico 7 días',
          onTap: () => onNavigate?.call(1),
        ),
        _ActionBtn(
          icon: Icons.bar_chart_rounded,
          label: 'Historial Climático',
          onTap: () => onNavigate?.call(5),
        ),
        _ActionBtn(
          icon: Icons.calendar_month_rounded,
          label: 'Calendario Agrícola',
          onTap: () => onNavigate?.call(6),
        ),
        _ActionBtn(
          icon: Icons.spa_rounded,
          label: 'Mis Cultivos',
          onTap: () => onNavigate?.call(4),
        ),
        _ActionBtn(
          icon: Icons.cottage_rounded,
          label: 'Mi Finca',
          onTap: () => onNavigate?.call(3),
        ),
      ],
    );
  }
}

class _ActionBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ActionBtn({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        onTap: onTap,
        tileColor: AppColors.blanco,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: const BorderSide(color: AppColors.niebla)),
        leading: Icon(icon, color: AppColors.verde),
        title: Text(label, style: GoogleFonts.dmSans(fontSize: 15, fontWeight: FontWeight.w600)),
        trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.gris),
      ),
    );
  }
}
