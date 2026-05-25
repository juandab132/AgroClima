import 'package:equatable/equatable.dart';
import '../../domain/entities/cultivo.dart';

abstract class CultivosEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class LoadAllCropsEvent extends CultivosEvent {}

class ToggleCropEvent extends CultivosEvent {
  final String cropId;
  final bool isActive;
  ToggleCropEvent({required this.cropId, required this.isActive});
  @override
  List<Object?> get props => [cropId, isActive];
}

abstract class CultivosState extends Equatable {
  @override
  List<Object?> get props => [];
}

class CultivosInitial extends CultivosState {}
class CultivosLoading extends CultivosState {}
class CultivosLoaded extends CultivosState {
  final List<Cultivo> allCrops;
  final List<Cultivo> selectedCrops;
  CultivosLoaded({required this.allCrops, required this.selectedCrops});
  @override
  List<Object?> get props => [allCrops, selectedCrops];
}
class CultivosError extends CultivosState {
  final String message;
  CultivosError(this.message);
  @override
  List<Object?> get props => [message];
}
