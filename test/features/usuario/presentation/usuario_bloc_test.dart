import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:agro_clima/features/usuario/presentation/bloc/usuario_bloc.dart';
import 'package:agro_clima/features/usuario/presentation/bloc/usuario_event_state.dart';
import 'package:agro_clima/features/usuario/domain/repositories/i_usuario_repository.dart';
import 'package:agro_clima/features/usuario/domain/entities/usuario.dart';
import 'package:agro_clima/core/errors/failures.dart';

class MockIUsuarioRepository extends Mock implements IUsuarioRepository {}

void main() {
  late UsuarioBloc bloc;
  late MockIUsuarioRepository mockRepo;

  final tUsuario = Usuario(
    id: 1,
    nombres: 'María',
    apellidos: 'Jiménez',
    telefono: '3001234567',
    email: 'maria@example.com',
    fechaRegistro: DateTime(2025, 1, 1),
  );

  setUp(() {
    mockRepo = MockIUsuarioRepository();
    bloc = UsuarioBloc(repository: mockRepo);
  });

  tearDown(() => bloc.close());

  test('estado inicial debe ser UsuarioInitial', () {
    expect(bloc.state, UsuarioInitial());
  });

  group('LoadUsuarioEvent — AGRO-15', () {
    blocTest<UsuarioBloc, UsuarioState>(
      'emite [Loading, Loaded] cuando existe un usuario guardado',
      build: () {
        when(() => mockRepo.getUsuario()).thenAnswer((_) async => Right(tUsuario));
        return bloc;
      },
      act: (bloc) => bloc.add(LoadUsuarioEvent()),
      expect: () => [UsuarioLoading(), UsuarioLoaded(tUsuario)],
    );

    blocTest<UsuarioBloc, UsuarioState>(
      'emite [Loading, Empty] cuando no hay usuario guardado',
      build: () {
        when(() => mockRepo.getUsuario()).thenAnswer((_) async => const Right(null));
        return bloc;
      },
      act: (bloc) => bloc.add(LoadUsuarioEvent()),
      expect: () => [UsuarioLoading(), UsuarioEmpty()],
    );

    blocTest<UsuarioBloc, UsuarioState>(
      'emite [Loading, Error] cuando falla la carga',
      build: () {
        when(() => mockRepo.getUsuario())
            .thenAnswer((_) async => const Left(CacheFailure('Error BD')));
        return bloc;
      },
      act: (bloc) => bloc.add(LoadUsuarioEvent()),
      expect: () => [UsuarioLoading(), UsuarioError('Error BD')],
    );
  });

  group('RegisterUsuarioEvent — AGRO-15', () {
    blocTest<UsuarioBloc, UsuarioState>(
      'emite [Loading, Saved, Loaded] cuando el registro es exitoso',
      build: () {
        when(() => mockRepo.registrar(
          email: any(named: 'email'),
          password: any(named: 'password'),
          nombres: any(named: 'nombres'),
          apellidos: any(named: 'apellidos'),
          telefono: any(named: 'telefono'),
        )).thenAnswer((_) async => Right(tUsuario));
        return bloc;
      },
      act: (bloc) => bloc.add(RegisterUsuarioEvent(
        email: 'maria@example.com',
        password: 'segura123',
        nombres: 'María',
        apellidos: 'Jiménez',
        telefono: '3001234567',
      )),
      expect: () => [UsuarioLoading(), UsuarioSaved(tUsuario), UsuarioLoaded(tUsuario)],
    );

    blocTest<UsuarioBloc, UsuarioState>(
      'emite [Loading, Error] cuando el registro falla',
      build: () {
        when(() => mockRepo.registrar(
          email: any(named: 'email'),
          password: any(named: 'password'),
          nombres: any(named: 'nombres'),
          apellidos: any(named: 'apellidos'),
          telefono: any(named: 'telefono'),
        )).thenAnswer((_) async => const Left(ServerFailure('Email ya registrado')));
        return bloc;
      },
      act: (bloc) => bloc.add(RegisterUsuarioEvent(
        email: 'maria@example.com',
        password: 'segura123',
        nombres: 'María',
        apellidos: 'Jiménez',
        telefono: '3001234567',
      )),
      expect: () => [UsuarioLoading(), UsuarioError('Email ya registrado')],
    );
  });

  group('LoginUsuarioEvent — AGRO-15', () {
    blocTest<UsuarioBloc, UsuarioState>(
      'emite [Loading, Saved, Loaded] cuando el login es exitoso',
      build: () {
        when(() => mockRepo.iniciarSesion(
          email: any(named: 'email'),
          password: any(named: 'password'),
        )).thenAnswer((_) async => Right(tUsuario));
        return bloc;
      },
      act: (bloc) => bloc.add(LoginUsuarioEvent(
        email: 'maria@example.com',
        password: 'segura123',
      )),
      expect: () => [UsuarioLoading(), UsuarioSaved(tUsuario), UsuarioLoaded(tUsuario)],
    );

    blocTest<UsuarioBloc, UsuarioState>(
      'emite [Loading, Error] cuando las credenciales son incorrectas',
      build: () {
        when(() => mockRepo.iniciarSesion(
          email: any(named: 'email'),
          password: any(named: 'password'),
        )).thenAnswer((_) async => const Left(ServerFailure('Contraseña incorrecta')));
        return bloc;
      },
      act: (bloc) => bloc.add(LoginUsuarioEvent(
        email: 'maria@example.com',
        password: 'incorrecta',
      )),
      expect: () => [UsuarioLoading(), UsuarioError('Contraseña incorrecta')],
    );
  });

  group('DeleteUsuarioEvent — AGRO-15', () {
    blocTest<UsuarioBloc, UsuarioState>(
      'emite [Loading, Empty] al eliminar el usuario',
      build: () {
        when(() => mockRepo.deleteUsuario()).thenAnswer((_) async => const Right(true));
        return bloc;
      },
      act: (bloc) => bloc.add(DeleteUsuarioEvent()),
      expect: () => [UsuarioLoading(), UsuarioEmpty()],
    );
  });
}
