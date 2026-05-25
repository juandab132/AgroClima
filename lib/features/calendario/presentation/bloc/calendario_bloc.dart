import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../domain/entities/calendario_cultivo.dart';
import '../../domain/usecases/get_calendario.dart';

// Events
abstract class CalendarioEvent extends Equatable {
  @override
  List<Object?> get props => [];
}
class LoadCalendarioEvent extends CalendarioEvent {}

// States
abstract class CalendarioState extends Equatable {
  @override
  List<Object?> get props => [];
}
class CalendarioInitial extends CalendarioState {}
class CalendarioLoading extends CalendarioState {}
class CalendarioLoaded extends CalendarioState {
  final List<CalendarioCultivo> calendarios;
  CalendarioLoaded(this.calendarios);
  @override
  List<Object?> get props => [calendarios];
}
class CalendarioError extends CalendarioState {
  final String message;
  CalendarioError(this.message);
  @override
  List<Object?> get props => [message];
}

// BLoC
class CalendarioBloc extends Bloc<CalendarioEvent, CalendarioState> {
  final GetCalendario getCalendario;

  CalendarioBloc({required this.getCalendario}) : super(CalendarioInitial()) {
    on<LoadCalendarioEvent>((event, emit) async {
      emit(CalendarioLoading());
      final result = await getCalendario();
      result.fold(
        (failure) => emit(CalendarioError(failure.message)),
        (calendarios) => emit(CalendarioLoaded(calendarios)),
      );
    });
  }
}
