import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/historial_registro.dart';

abstract class IHistorialRepository {
  Future<Either<Failure, List<HistorialRegistro>>> getHistorial(String municipio);
  Future<Either<Failure, void>> guardarRegistro(HistorialRegistro registro);
  Future<Either<Failure, List<HistorialRegistro>>> getEventosHelada(String municipio);
}
