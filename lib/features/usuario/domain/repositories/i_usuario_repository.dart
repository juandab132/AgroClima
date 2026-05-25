import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/usuario.dart';

abstract class IUsuarioRepository {
  Future<Either<Failure, Usuario?>> getUsuario();
  Future<Either<Failure, Usuario>> saveUsuario(Usuario usuario);
  Future<Either<Failure, bool>> deleteUsuario();

  Future<Either<Failure, Usuario>> registrar({
    required String email,
    required String password,
    required String nombres,
    required String apellidos,
    required String telefono,
  });

  Future<Either<Failure, Usuario>> iniciarSesion({
    required String email,
    required String password,
  });
}
