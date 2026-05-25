import 'package:flutter_bloc/flutter_bloc.dart';
import 'finca_event_state.dart';
import '../../domain/usecases/finca_usecases.dart';
import '../../../../core/usecases/usecase.dart';
import '../../domain/entities/finca.dart';

class FincaBloc extends Bloc<FincaEvent, FincaState> {
  final SaveFinca saveFinca;
  final LoadFinca loadFinca;
  final DeleteFinca deleteFinca;

  FincaBloc({
    required this.saveFinca,
    required this.loadFinca,
    required this.deleteFinca,
  }) : super(FincaInitial()) {
    on<LoadFincaEvent>(_onLoad);
    on<SaveFincaEvent>(_onSave);
    on<DeleteFincaEvent>(_onDelete);
  }

  Future<void> _onLoad(LoadFincaEvent event, Emitter<FincaState> emit) async {
    emit(FincaLoading());
    final result = await loadFinca(NoParams());
    result.fold(
      (failure) => emit(FincaError(failure.message)),
      (finca) {
        if (finca != null) {
          emit(FincaLoaded(finca));
        } else {
          emit(FincaEmpty());
        }
      },
    );
  }

  Future<void> _onSave(SaveFincaEvent event, Emitter<FincaState> emit) async {
    emit(FincaLoading());
    final result = await saveFinca(event.finca);
    result.fold(
      (failure) => emit(FincaError(failure.message)),
      (savedFinca) {
        emit(FincaSaved(savedFinca));
        emit(FincaLoaded(savedFinca));
      },
    );
  }

  Future<void> _onDelete(DeleteFincaEvent event, Emitter<FincaState> emit) async {
    emit(FincaLoading());
    final result = await deleteFinca(NoParams());
    result.fold(
      (failure) => emit(FincaError(failure.message)),
      (_) => emit(FincaEmpty()),
    );
  }
}
