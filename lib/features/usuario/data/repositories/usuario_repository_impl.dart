import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:dartz/dartz.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as sb;
import '../../../../core/errors/failures.dart';
import '../../domain/entities/usuario.dart';
import '../../domain/repositories/i_usuario_repository.dart';
import '../datasources/usuario_local_datasource.dart';

class UsuarioRepositoryImpl implements IUsuarioRepository {
  final UsuarioLocalDataSource localDataSource;

  UsuarioRepositoryImpl({required this.localDataSource});

  @override
  Future<Either<Failure, Usuario?>> getUsuario() async {
    try {
      final user = await localDataSource.getUsuario();
      return Right(user);
    } catch (e) {
      return Left(CacheFailure('Error al cargar el usuario local'));
    }
  }

  @override
  Future<Either<Failure, Usuario>> saveUsuario(Usuario usuario) async {
    try {
      final savedUser = await localDataSource.saveUsuario(usuario);
      
      // Intentar actualizar en Supabase si está autenticado
      try {
        final client = sb.Supabase.instance.client;
        final currentUser = client.auth.currentUser;
        if (currentUser != null) {
          // 1. Actualizar metadata del usuario en auth
          await client.auth.updateUser(sb.UserAttributes(
            data: {
              'nombres': usuario.nombres,
              'apellidos': usuario.apellidos,
              'telefono': usuario.telefono,
            },
          ));
          
          // 2. Actualizar tabla public.usuarios
          await client.from('usuarios').upsert({
            'id': currentUser.id,
            'nombres': usuario.nombres,
            'apellidos': usuario.apellidos,
            'telefono': usuario.telefono,
          });
        }
      } catch (e) {
        print('DEBUG: Error syncing updated profile to Supabase: $e');
      }

      return Right(savedUser);
    } catch (e) {
      print('DEBUG: Error saving user: $e');
      return Left(CacheFailure('Error al guardar el usuario local'));
    }
  }

  @override
  Future<Either<Failure, bool>> deleteUsuario() async {
    try {
      await localDataSource.deleteUsuario();
      return const Right(true);
    } catch (e) {
      return Left(CacheFailure('Error al eliminar el usuario local'));
    }
  }

  @override
  Future<Either<Failure, Usuario>> registrar({
    required String email,
    required String password,
    required String nombres,
    required String apellidos,
    required String telefono,
  }) async {
    try {
      final client = sb.Supabase.instance.client;

      // 1. Registrar en Supabase Auth con metadata de usuario
      final authResponse = await client.auth.signUp(
        email: email,
        password: password,
        data: {
          'nombres': nombres,
          'apellidos': apellidos,
          'telefono': telefono,
        },
      );
      final user = authResponse.user;
      if (user == null) {
        return const Left(ServerFailure('No se pudo registrar el usuario en el servidor.'));
      }

      // 2. Guardar perfil público en Supabase public.usuarios
      await client.from('usuarios').insert({
        'id': user.id,
        'nombres': nombres,
        'apellidos': apellidos,
        'telefono': telefono,
      });

      // 3. Hashear la contraseña para login offline
      final passwordHash = sha256.convert(utf8.encode(password)).toString();

      // 4. Guardar localmente en SQLite
      final usuarioLocal = Usuario(
        id: 1,
        nombres: nombres,
        apellidos: apellidos,
        telefono: telefono,
        email: email,
        contrasenaHash: passwordHash,
        fechaRegistro: DateTime.now(),
      );
      final savedUser = await localDataSource.saveUsuario(usuarioLocal);

      return Right(savedUser);
    } catch (e) {
      return Left(ServerFailure('Error en registro: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, Usuario>> iniciarSesion({
    required String email,
    required String password,
  }) async {
    final client = sb.Supabase.instance.client;
    final passwordHash = sha256.convert(utf8.encode(password)).toString();

    try {
      // 1. Intentar iniciar sesión en Supabase Auth
      final authResponse = await client.auth.signInWithPassword(
        email: email,
        password: password,
      );
      final user = authResponse.user;
      if (user == null) {
        return const Left(ServerFailure('Email o contraseña incorrectos.'));
      }

      // 2. Descargar perfil del usuario desde Supabase public.usuarios
      final profileData = await client
          .from('usuarios')
          .select()
          .eq('id', user.id)
          .maybeSingle();

      final metadata = user.userMetadata ?? {};
      final metaNombres = metadata['nombres'] as String? ?? 'Usuario';
      final metaApellidos = metadata['apellidos'] as String? ?? 'AgroClima';
      final metaTelefono = metadata['telefono'] as String? ?? '';

      // 3. Guardar en la base de datos local SQLite (con fallback si el perfil en la nube se corrompió)
      final usuarioLocal = Usuario(
        id: 1,
        nombres: profileData != null ? profileData['nombres'] as String : metaNombres,
        apellidos: profileData != null ? profileData['apellidos'] as String : metaApellidos,
        telefono: profileData != null ? profileData['telefono'] as String : metaTelefono,
        email: email,
        contrasenaHash: passwordHash,
        fechaRegistro: profileData != null 
            ? DateTime.parse(profileData['fecha_registro'] as String) 
            : DateTime.now(),
      );
      final savedUser = await localDataSource.saveUsuario(usuarioLocal);

      return Right(savedUser);
    } catch (e) {
      // Si falla la conexión u otro error, intentamos el login local offline
      try {
        final cachedUser = await localDataSource.getUsuario();
        if (cachedUser != null && cachedUser.email == email) {
          if (cachedUser.contrasenaHash == passwordHash) {
            return Right(cachedUser);
          } else {
            return const Left(InputFailure('Contraseña incorrecta.'));
          }
        }
      } catch (_) {}
      return Left(ServerFailure('Error al iniciar sesión: ${e.toString()}'));
    }
  }
}
