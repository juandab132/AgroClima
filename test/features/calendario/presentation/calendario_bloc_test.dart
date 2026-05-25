import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:agro_clima/features/calendario/domain/entities/calendario_cultivo.dart';
import 'package:agro_clima/features/calendario/domain/usecases/get_calendario.dart';
import 'package:agro_clima/features/calendario/presentation/bloc/calendario_bloc.dart';
import 'package:agro_clima/core/errors/failures.dart';

class MockGetCalendario extends Mock implements GetCalendario {}

void main() {
  late CalendarioBloc bloc;
  late MockGetCalendario mockGetCalendario;

  setUp(() {
    mockGetCalendario = MockGetCalendario();
    bloc = CalendarioBloc(getCalendario: mockGetCalendario);
  });

  const tCalendario = CalendarioCultivo(
    id: 'papa',
    nombre: 'Papa',
    mesesSiembra: [1, 2],
    mesesCosecha: [6, 7],
    mesesFumigacion: [3, 4],
    observaciones: 'Test',
  );

  test('initial state should be CalendarioInitial', () {
    expect(bloc.state, CalendarioInitial());
  });

  blocTest<CalendarioBloc, CalendarioState>(
    'should emit [Loading, Loaded] when LoadCalendarioEvent is successful',
    build: () {
      when(() => mockGetCalendario()).thenAnswer((_) async => const Right([tCalendario]));
      return bloc;
    },
    act: (bloc) => bloc.add(LoadCalendarioEvent()),
    expect: () => [
      CalendarioLoading(),
      CalendarioLoaded(const [tCalendario]),
    ],
  );
}
