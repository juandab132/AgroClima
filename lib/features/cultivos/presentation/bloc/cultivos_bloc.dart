import 'package:flutter_bloc/flutter_bloc.dart';
import 'cultivos_event_state.dart';
import '../../domain/repositories/i_cultivos_repository.dart';

class CultivosBloc extends Bloc<CultivosEvent, CultivosState> {
  final ICultivosRepository repository;

  CultivosBloc({required this.repository}) : super(CultivosInitial()) {
    on<LoadAllCropsEvent>(_onLoad);
    on<ToggleCropEvent>(_onToggle);
  }

  Future<void> _onLoad(LoadAllCropsEvent event, Emitter<CultivosState> emit) async {
    emit(CultivosLoading());
    final result = await repository.getAllCrops();
    final resultSelected = await repository.getSelectedCrops();
    
    result.fold(
      (failure) => emit(CultivosError(failure.message)),
      (all) {
        resultSelected.fold(
          (failure) => emit(CultivosError(failure.message)),
          (selected) => emit(CultivosLoaded(allCrops: all, selectedCrops: selected)),
        );
      },
    );
  }

  Future<void> _onToggle(ToggleCropEvent event, Emitter<CultivosState> emit) async {
    final result = await repository.toggleCropStatus(event.cropId, event.isActive);
    result.fold(
      (failure) => emit(CultivosError(failure.message)),
      (_) => add(LoadAllCropsEvent()),
    );
  }
}
