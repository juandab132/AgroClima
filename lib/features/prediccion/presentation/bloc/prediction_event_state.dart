import 'package:equatable/equatable.dart';
import '../../../prediccion/domain/entities/frost_prediction.dart';

// ── EVENTS ──────────────────────────────────────────────────────────────────

abstract class PredictionEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class PredictFrostEvent extends PredictionEvent {
  final int altitud;
  final double tempMin;
  final double humedad;
  final int mes;
  final double nubosidad;
  final double viento;

  PredictFrostEvent({
    required this.altitud,
    required this.tempMin,
    required this.humedad,
    required this.mes,
    this.nubosidad = 50.0,
    this.viento = 15.0,
  });

  @override
  List<Object?> get props => [altitud, tempMin, humedad, mes, nubosidad, viento];
}

// ── STATES ──────────────────────────────────────────────────────────────────

abstract class PredictionState extends Equatable {
  @override
  List<Object?> get props => [];
}

class PredictionInitial extends PredictionState {}

class PredictionLoading extends PredictionState {}

class PredictionLoaded extends PredictionState {
  final FrostPrediction prediction;
  final SprayDecision? spray;

  PredictionLoaded({required this.prediction, this.spray});

  @override
  List<Object?> get props => [prediction, spray];
}

class PredictionError extends PredictionState {
  final String message;
  PredictionError({required this.message});

  @override
  List<Object?> get props => [message];
}
