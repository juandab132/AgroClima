import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:agro_clima/features/pronostico/presentation/bloc/weather_bloc.dart';
import 'package:agro_clima/features/pronostico/presentation/bloc/weather_event_state.dart';
import 'package:agro_clima/features/pronostico/domain/usecases/get_forecast.dart';
import 'package:agro_clima/features/pronostico/domain/entities/weather_forecast.dart';
import 'package:agro_clima/features/historial/domain/usecases/historial_usecases.dart';
import 'package:agro_clima/features/historial/domain/entities/historial_registro.dart';
import 'package:agro_clima/features/prediccion/data/datasources/frost_decision_tree.dart';
import 'package:agro_clima/core/errors/failures.dart';

class MockGetForecast extends Mock implements GetForecast {}
class MockGuardarHistorial extends Mock implements GuardarHistorial {}
class MockFrostDecisionTree extends Mock implements FrostDecisionTree {}

void main() {
  late WeatherBloc bloc;
  late MockGetForecast mockGetForecast;
  late MockGuardarHistorial mockGuardarHistorial;
  late MockFrostDecisionTree mockDecisionTree;

  setUpAll(() {
    registerFallbackValue(const ForecastParams(municipio: 'Pasto'));
    registerFallbackValue(HistorialRegistro(
      fecha: DateTime(2025, 1, 1),
      municipio: 'Pasto',
      tempMin: 5.0,
      tempMax: 15.0,
      riesgoHelada: RiskLevel.low,
      accionRecomendada: 'Ninguna',
    ));
  });

  setUp(() {
    mockGetForecast = MockGetForecast();
    mockGuardarHistorial = MockGuardarHistorial();
    mockDecisionTree = MockFrostDecisionTree();
    bloc = WeatherBloc(
      getForecast: mockGetForecast,
      guardarHistorial: mockGuardarHistorial,
      decisionTree: mockDecisionTree,
    );
  });

  tearDown(() => bloc.close());

  final tForecast = WeatherForecast(
    municipio: 'Pasto',
    fetchedAt: DateTime(2025, 5, 1),
    days: [
      DayForecast(
        date: DateTime(2025, 5, 1),
        tempMin: 5.0,
        tempMax: 15.0,
        rainProbability: 30,
        windSpeed: 10.0,
        emoji: '🌤️',
      ),
    ],
  );

  final tPrediction = FrostPrediction(
    level: RiskLevel.low,
    confidence: 0.85,
    recommendation: 'Sin riesgo',
    factors: ['Condiciones térmicas normales'],
  );

  test('estado inicial debe ser WeatherInitial', () {
    expect(bloc.state, WeatherInitial());
  });

  group('FetchForecastEvent', () {
    blocTest<WeatherBloc, WeatherState>(
      'emite [Loading, Loaded] cuando el pronóstico es exitoso',
      build: () {
        when(() => mockGetForecast(any())).thenAnswer((_) async => Right(tForecast));
        when(() => mockDecisionTree.predict(
          altitud: any(named: 'altitud'),
          tempMin: any(named: 'tempMin'),
          humedad: any(named: 'humedad'),
          viento: any(named: 'viento'),
          mes: any(named: 'mes'),
          nubosidad: any(named: 'nubosidad'),
        )).thenReturn(tPrediction);
        when(() => mockGuardarHistorial(any())).thenAnswer((_) async => const Right(null));
        return bloc;
      },
      act: (bloc) => bloc.add(FetchForecastEvent('Pasto', altitud: 2527)),
      expect: () => [
        WeatherLoading(),
        WeatherLoaded(forecast: tForecast, fromCache: false),
      ],
    );

    blocTest<WeatherBloc, WeatherState>(
      'emite [Loading, Error] cuando el repositorio falla',
      build: () {
        when(() => mockGetForecast(any()))
            .thenAnswer((_) async => const Left(ServerFailure('Sin conexión')));
        return bloc;
      },
      act: (bloc) => bloc.add(FetchForecastEvent('Pasto')),
      expect: () => [
        WeatherLoading(),
        WeatherError('Sin conexión'),
      ],
    );
  });
}
