import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:agro_clima/features/historial/domain/entities/historial_registro.dart';
import 'package:agro_clima/features/historial/domain/usecases/historial_usecases.dart';
import 'package:agro_clima/features/historial/presentation/bloc/historial_bloc.dart';
import 'package:agro_clima/features/historial/presentation/bloc/historial_event_state.dart';
import 'package:agro_clima/features/prediccion/domain/entities/frost_prediction.dart';
import 'package:agro_clima/core/errors/failures.dart';

class MockGetHistorial extends Mock implements GetHistorial {}
class MockGuardarHistorial extends Mock implements GuardarHistorial {}
class MockGetEventosHelada extends Mock implements GetEventosHelada {}

void main() {
  late HistorialBloc bloc;
  late MockGetHistorial mockGetHistorial;
  late MockGuardarHistorial mockGuardarHistorial;
  late MockGetEventosHelada mockGetEventosHelada;

  setUp(() {
    mockGetHistorial = MockGetHistorial();
    mockGuardarHistorial = MockGuardarHistorial();
    mockGetEventosHelada = MockGetEventosHelada();
    bloc = HistorialBloc(
      getHistorial: mockGetHistorial,
      guardarHistorial: mockGuardarHistorial,
      getEventosHelada: mockGetEventosHelada,
    );
  });

  final tRegistro = HistorialRegistro(
    fecha: DateTime(2024, 1, 1),
    municipio: 'Pasto',
    tempMin: 5.0,
    tempMax: 15.0,
    riesgoHelada: RiskLevel.low,
    accionRecomendada: 'Ninguna',
  );

  test('initial state should be HistorialInitial', () {
    expect(bloc.state, HistorialInitial());
  });

  blocTest<HistorialBloc, HistorialState>(
    'should emit [Loading, Loaded] when LoadHistorialEvent is successful',
    build: () {
      when(() => mockGetHistorial(any())).thenAnswer((_) async => Right([tRegistro]));
      when(() => mockGetEventosHelada(any())).thenAnswer((_) async => const Right([]));
      return bloc;
    },
    act: (bloc) => bloc.add(LoadHistorialEvent('Pasto')),
    expect: () => [
      HistorialLoading(),
      HistorialLoaded(historial: [tRegistro], eventosHelada: const []),
    ],
  );

  blocTest<HistorialBloc, HistorialState>(
    'should emit [Loading, Error] when LoadHistorialEvent fails',
    build: () {
      when(() => mockGetHistorial(any())).thenAnswer((_) async => const Left(ServerFailure('Error')));
      when(() => mockGetEventosHelada(any())).thenAnswer((_) async => const Right([]));
      return bloc;
    },
    act: (bloc) => bloc.add(LoadHistorialEvent('Pasto')),
    expect: () => [
      HistorialLoading(),
      HistorialError('Error'),
    ],
  );
}


