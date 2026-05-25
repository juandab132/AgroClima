import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:agro_clima/features/cultivos/presentation/bloc/cultivos_bloc.dart';
import 'package:agro_clima/features/cultivos/presentation/bloc/cultivos_event_state.dart';
import 'package:agro_clima/features/cultivos/domain/repositories/i_cultivos_repository.dart';
import 'package:agro_clima/features/cultivos/domain/entities/cultivo.dart';
import 'package:agro_clima/core/errors/failures.dart';

class MockICultivosRepository extends Mock implements ICultivosRepository {}

void main() {
  late CultivosBloc bloc;
  late MockICultivosRepository mockRepo;

  const tCultivo = Cultivo(
    id: 'papa',
    nombre: 'Papa',
    altitudMin: 2000,
    altitudMax: 3500,
    tempOptima: 12.0,
    lluviaRequerida: 600,
    cicloCosecha: '4–5 meses',
    consejosLocales: ['Rotar cultivo', 'Fumigar al amanecer'],
    activo: false,
  );

  const tCultivoActivo = Cultivo(
    id: 'papa',
    nombre: 'Papa',
    altitudMin: 2000,
    altitudMax: 3500,
    tempOptima: 12.0,
    lluviaRequerida: 600,
    cicloCosecha: '4–5 meses',
    consejosLocales: ['Rotar cultivo', 'Fumigar al amanecer'],
    activo: true,
  );

  setUp(() {
    mockRepo = MockICultivosRepository();
    bloc = CultivosBloc(repository: mockRepo);
  });

  tearDown(() => bloc.close());

  test('estado inicial debe ser CultivosInitial', () {
    expect(bloc.state, CultivosInitial());
  });

  group('LoadAllCropsEvent — AGRO-34', () {
    blocTest<CultivosBloc, CultivosState>(
      'emite [Loading, Loaded] cuando el repositorio devuelve cultivos',
      build: () {
        when(() => mockRepo.getAllCrops())
            .thenAnswer((_) async => const Right([tCultivo]));
        when(() => mockRepo.getSelectedCrops())
            .thenAnswer((_) async => const Right([]));
        return bloc;
      },
      act: (bloc) => bloc.add(LoadAllCropsEvent()),
      expect: () => [
        CultivosLoading(),
        CultivosLoaded(allCrops: const [tCultivo], selectedCrops: const []),
      ],
    );

    blocTest<CultivosBloc, CultivosState>(
      'emite [Loading, Error] cuando getAllCrops falla',
      build: () {
        when(() => mockRepo.getAllCrops())
            .thenAnswer((_) async => const Left(CacheFailure('Sin datos')));
        when(() => mockRepo.getSelectedCrops())
            .thenAnswer((_) async => const Right([]));
        return bloc;
      },
      act: (bloc) => bloc.add(LoadAllCropsEvent()),
      expect: () => [
        CultivosLoading(),
        CultivosError('Sin datos'),
      ],
    );
  });

  group('ToggleCropEvent — AGRO-34', () {
    blocTest<CultivosBloc, CultivosState>(
      'después de toggle recarga la lista',
      build: () {
        when(() => mockRepo.toggleCropStatus(any(), any()))
            .thenAnswer((_) async => const Right(null));
        when(() => mockRepo.getAllCrops())
            .thenAnswer((_) async => const Right([tCultivoActivo]));
        when(() => mockRepo.getSelectedCrops())
            .thenAnswer((_) async => const Right([tCultivoActivo]));
        return bloc;
      },
      act: (bloc) => bloc.add(ToggleCropEvent(cropId: 'papa', isActive: true)),
      expect: () => [
        CultivosLoading(),
        CultivosLoaded(
          allCrops: const [tCultivoActivo],
          selectedCrops: const [tCultivoActivo],
        ),
      ],
    );

    blocTest<CultivosBloc, CultivosState>(
      'emite Error cuando toggleCropStatus falla',
      build: () {
        when(() => mockRepo.toggleCropStatus(any(), any()))
            .thenAnswer((_) async => const Left(CacheFailure('Error BD')));
        return bloc;
      },
      act: (bloc) => bloc.add(ToggleCropEvent(cropId: 'papa', isActive: true)),
      expect: () => [CultivosError('Error BD')],
    );
  });
}
