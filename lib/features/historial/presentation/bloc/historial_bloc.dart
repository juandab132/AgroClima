import 'package:flutter_bloc/flutter_bloc.dart';
import 'historial_event_state.dart';
import '../../domain/usecases/historial_usecases.dart';

class HistorialBloc extends Bloc<HistorialEvent, HistorialState> {
  final GetHistorial getHistorial;
  final GuardarHistorial guardarHistorial;
  final GetEventosHelada getEventosHelada;

  HistorialBloc({
    required this.getHistorial,
    required this.guardarHistorial,
    required this.getEventosHelada,
  }) : super(HistorialInitial()) {
    on<LoadHistorialEvent>(_onLoadHistorial);
    on<AddRegistroEvent>(_onAddRegistro);
  }

  Future<void> _onLoadHistorial(
      LoadHistorialEvent event, Emitter<HistorialState> emit) async {
    emit(HistorialLoading());
    
    final histResult = await getHistorial(event.municipio);
    final eventResult = await getEventosHelada(event.municipio);

    histResult.fold(
      (failure) => emit(HistorialError(failure.message)),
      (historial) {
        eventResult.fold(
          (failure) => emit(HistorialError(failure.message)),
          (eventos) => emit(HistorialLoaded(
            historial: historial,
            eventosHelada: eventos,
          )),
        );
      },
    );
  }

  Future<void> _onAddRegistro(
      AddRegistroEvent event, Emitter<HistorialState> emit) async {
    final result = await guardarHistorial(event.registro);
    result.fold(
      (failure) => emit(HistorialError(failure.message)),
      (_) => add(LoadHistorialEvent(event.registro.municipio)),
    );
  }
}
