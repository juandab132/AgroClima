import 'package:equatable/equatable.dart';
import '../../domain/entities/historial_registro.dart';

abstract class HistorialEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class LoadHistorialEvent extends HistorialEvent {
  final String municipio;
  LoadHistorialEvent(this.municipio);
  @override
  List<Object?> get props => [municipio];
}

class AddRegistroEvent extends HistorialEvent {
  final HistorialRegistro registro;
  AddRegistroEvent(this.registro);
  @override
  List<Object?> get props => [registro];
}

abstract class HistorialState extends Equatable {
  @override
  List<Object?> get props => [];
}

class HistorialInitial extends HistorialState {}
class HistorialLoading extends HistorialState {}
class HistorialLoaded extends HistorialState {
  final List<HistorialRegistro> historial;
  final List<HistorialRegistro> eventosHelada;
  HistorialLoaded({required this.historial, required this.eventosHelada});
  @override
  List<Object?> get props => [historial, eventosHelada];
}
class HistorialError extends HistorialState {
  final String message;
  HistorialError(this.message);
  @override
  List<Object?> get props => [message];
}
