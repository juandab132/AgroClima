import 'package:flutter_bloc/flutter_bloc.dart';
import 'prediction_event_state.dart';
import '../../../prediccion/data/datasources/frost_decision_tree.dart';
import '../../../pronostico/domain/entities/weather_forecast.dart';

class PredictionBloc extends Bloc<PredictionEvent, PredictionState> {
  final FrostDecisionTree decisionTree;
  final SprayDecisionTree sprayTree;

  PredictionBloc({
    required this.decisionTree,
    required this.sprayTree,
  }) : super(PredictionInitial()) {
    on<PredictFrostEvent>(_onPredictFrost);
  }

  void _onPredictFrost(
      PredictFrostEvent event, Emitter<PredictionState> emit) {
    emit(PredictionLoading());
    try {
      final prediction = decisionTree.predict(
        altitud: event.altitud,
        tempMin: event.tempMin,
        humedad: event.humedad,
        viento: event.viento,
        mes: event.mes,
        nubosidad: event.nubosidad,
      );

      // Crea un día artificial para la decisión de spray con el viento del evento
      final fakeDay = WeatherDay(
        dayName: 'Hoy',
        date: DateTime.now(),
        tempMin: event.tempMin,
        tempMax: event.tempMin + 8,
        rainProbability: event.humedad > 80 ? 70 : 20,
        windSpeed: event.viento,
        emoji: '🌤️',
      );

      final spray = sprayTree.predictFromForecast([fakeDay]);

      emit(PredictionLoaded(prediction: prediction, spray: spray));
    } catch (e) {
      emit(PredictionError(message: 'Error calculando predicción'));
    }
  }
}
