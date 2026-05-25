import 'package:flutter_bloc/flutter_bloc.dart';
import 'weather_event_state.dart';
import '../../../pronostico/domain/usecases/get_forecast.dart';
import '../../../historial/domain/usecases/historial_usecases.dart';
import '../../../historial/domain/entities/historial_registro.dart';
import '../../../prediccion/data/datasources/frost_decision_tree.dart';

class WeatherBloc extends Bloc<WeatherEvent, WeatherState> {
  final GetForecast getForecast;
  final GuardarHistorial guardarHistorial;
  final FrostDecisionTree decisionTree;

  WeatherBloc({
    required this.getForecast,
    required this.guardarHistorial,
    required this.decisionTree,
  }) : super(WeatherInitial()) {
    on<FetchForecastEvent>(_onFetch);
  }

  Future<void> _onFetch(
      FetchForecastEvent event, Emitter<WeatherState> emit) async {
    emit(WeatherLoading());
    final result = await getForecast(ForecastParams(municipio: event.municipio));
    
    await result.fold(
      (failure) async => emit(WeatherError(failure.message)),
      (forecast) async {
        if (forecast.days.isNotEmpty) {
          final today = forecast.days.first;
          // Hook: Guardar en historial
          final prediction = decisionTree.predict(
            altitud: event.altitud,
            tempMin: today.tempMin,
            humedad: today.rainProbability > 50 ? 80 : 40,
            viento: today.windSpeed,
            mes: DateTime.now().month,
            nubosidad: 40,
          );

          await guardarHistorial(HistorialRegistro(
            fecha: DateTime.now(),
            municipio: forecast.municipio,
            tempMin: today.tempMin,
            tempMax: today.tempMax,
            riesgoHelada: prediction.level,
            accionRecomendada: prediction.recommendation,
          ));
        }
        
        emit(WeatherLoaded(forecast: forecast, fromCache: forecast.isStale));
      },
    );
  }
}
