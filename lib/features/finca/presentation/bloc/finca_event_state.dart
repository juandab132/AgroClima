import 'package:equatable/equatable.dart';
import '../../domain/entities/finca.dart';

// ── EVENTS ──────────────────────────────────────────────────────────────────

abstract class FincaEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class LoadFincaEvent extends FincaEvent {}

class SaveFincaEvent extends FincaEvent {
  final Finca finca;
  SaveFincaEvent(this.finca);
  @override
  List<Object?> get props => [finca];
}

class DeleteFincaEvent extends FincaEvent {}

// ── STATES ──────────────────────────────────────────────────────────────────

abstract class FincaState extends Equatable {
  @override
  List<Object?> get props => [];
}

class FincaInitial extends FincaState {}
class FincaLoading extends FincaState {}

class FincaLoaded extends FincaState {
  final Finca finca;
  FincaLoaded(this.finca);
  @override
  List<Object?> get props => [finca];
}

class FincaEmpty extends FincaState {}

class FincaSaved extends FincaState {
  final Finca finca;
  FincaSaved(this.finca);
  @override
  List<Object?> get props => [finca];
}

class FincaError extends FincaState {
  final String message;
  FincaError(this.message);
  @override
  List<Object?> get props => [message];
}
