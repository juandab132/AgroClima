import 'package:equatable/equatable.dart';
import '../../../pronostico/domain/entities/weather_forecast.dart';

// ── EVENTS ──────────────────────────────────────────────────────────────────

abstract class WeatherEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class FetchForecastEvent extends WeatherEvent {
  final String municipio;
  final int altitud;
  FetchForecastEvent(this.municipio, {this.altitud = 2527});
  @override
  List<Object?> get props => [municipio, altitud];
}

// ── STATES ──────────────────────────────────────────────────────────────────

abstract class WeatherState extends Equatable {
  @override
  List<Object?> get props => [];
}

class WeatherInitial extends WeatherState {}

class WeatherLoading extends WeatherState {}

class WeatherLoaded extends WeatherState {
  final WeatherForecast forecast;
  final bool fromCache;
  WeatherLoaded({required this.forecast, this.fromCache = false});
  @override
  List<Object?> get props => [forecast, fromCache];
}

class WeatherError extends WeatherState {
  final String message;
  WeatherError(this.message);
  @override
  List<Object?> get props => [message];
}
