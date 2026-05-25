import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:agro_clima/features/finca/presentation/bloc/finca_bloc.dart';
import 'package:agro_clima/features/finca/presentation/bloc/finca_event_state.dart';
import 'package:agro_clima/features/finca/domain/usecases/finca_usecases.dart';
import 'package:agro_clima/features/finca/domain/entities/finca.dart';
import 'package:agro_clima/core/errors/failures.dart';
import 'package:agro_clima/core/usecases/usecase.dart';

class MockLoadFinca extends Mock implements LoadFinca {}
class MockSaveFinca extends Mock implements SaveFinca {}
class MockDeleteFinca extends Mock implements DeleteFinca {}

void main() {
  late FincaBloc bloc;
  late MockLoadFinca mockLoad;
  late MockSaveFinca mockSave;
  late MockDeleteFinca mockDelete;

  setUpAll(() {
    registerFallbackValue(NoParams());
    registerFallbackValue(const Finca(
      nombreAgricultero: 'Test',
      nombreFinca: 'Test',
      vereda: '',
      municipio: 'Pasto',
      altitud: 2527,
      hectareas: 1.0,
      tipoRiego: 'Lluvia',
    ));
  });

  setUp(() {
    mockLoad = MockLoadFinca();
    mockSave = MockSaveFinca();
    mockDelete = MockDeleteFinca();
    bloc = FincaBloc(
      saveFinca: mockSave,
      loadFinca: mockLoad,
      deleteFinca: mockDelete,
    );
  });

  tearDown(() => bloc.close());

  const tFinca = Finca(
    id: 1,
    nombreAgricultero: 'Don José García',
    nombreFinca: 'La Esperanza',
    vereda: 'El Encano',
    municipio: 'Pasto',
    altitud: 2700,
    hectareas: 2.5,
    tipoRiego: 'Lluvia',
  );

  test('estado inicial debe ser FincaInitial', () {
    expect(bloc.state, FincaInitial());
  });

  group('LoadFincaEvent — AGRO-15', () {
    blocTest<FincaBloc, FincaState>(
      'emite [Loading, Loaded] cuando existe una finca guardada',
      build: () {
        when(() => mockLoad(any())).thenAnswer((_) async => const Right(tFinca));
        return bloc;
      },
      act: (bloc) => bloc.add(LoadFincaEvent()),
      expect: () => [FincaLoading(), FincaLoaded(tFinca)],
    );

    blocTest<FincaBloc, FincaState>(
      'emite [Loading, Empty] cuando no hay finca guardada',
      build: () {
        when(() => mockLoad(any())).thenAnswer((_) async => const Right(null));
        return bloc;
      },
      act: (bloc) => bloc.add(LoadFincaEvent()),
      expect: () => [FincaLoading(), FincaEmpty()],
    );

    blocTest<FincaBloc, FincaState>(
      'emite [Loading, Error] cuando falla la carga',
      build: () {
        when(() => mockLoad(any()))
            .thenAnswer((_) async => const Left(CacheFailure('Error BD')));
        return bloc;
      },
      act: (bloc) => bloc.add(LoadFincaEvent()),
      expect: () => [FincaLoading(), FincaError('Error BD')],
    );
  });

  group('SaveFincaEvent — AGRO-15', () {
    blocTest<FincaBloc, FincaState>(
      'emite [Loading, Saved, Loaded] al guardar correctamente',
      build: () {
        when(() => mockSave(any())).thenAnswer((_) async => const Right(tFinca));
        return bloc;
      },
      act: (bloc) => bloc.add(SaveFincaEvent(tFinca)),
      expect: () => [FincaLoading(), FincaSaved(tFinca), FincaLoaded(tFinca)],
    );

    blocTest<FincaBloc, FincaState>(
      'emite [Loading, Error] cuando falla el guardado',
      build: () {
        when(() => mockSave(any()))
            .thenAnswer((_) async => const Left(CacheFailure('No se pudo guardar')));
        return bloc;
      },
      act: (bloc) => bloc.add(SaveFincaEvent(tFinca)),
      expect: () => [FincaLoading(), FincaError('No se pudo guardar')],
    );
  });

  group('DeleteFincaEvent — AGRO-15', () {
    blocTest<FincaBloc, FincaState>(
      'emite [Loading, Empty] al eliminar correctamente',
      build: () {
        when(() => mockDelete(any())).thenAnswer((_) async => const Right(null));
        return bloc;
      },
      act: (bloc) => bloc.add(DeleteFincaEvent()),
      expect: () => [FincaLoading(), FincaEmpty()],
    );

    blocTest<FincaBloc, FincaState>(
      'emite [Loading, Error] cuando falla la eliminación',
      build: () {
        when(() => mockDelete(any()))
            .thenAnswer((_) async => const Left(CacheFailure('Error al eliminar')));
        return bloc;
      },
      act: (bloc) => bloc.add(DeleteFincaEvent()),
      expect: () => [FincaLoading(), FincaError('Error al eliminar')],
    );
  });
}
