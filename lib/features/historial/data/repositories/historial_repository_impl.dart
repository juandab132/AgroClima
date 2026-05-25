import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../domain/entities/historial_registro.dart';
import '../../domain/repositories/i_historial_repository.dart';
import '../datasources/historial_local_datasource.dart';
import '../models/historial_model.dart';

class HistorialRepositoryImpl implements IHistorialRepository {
  final HistorialLocalDataSource localDataSource;

  HistorialRepositoryImpl({required this.localDataSource});

  @override
  Future<Either<Failure, List<HistorialRegistro>>> getHistorial(String municipio) async {
    try {
      final results = await localDataSource.getHistorial(municipio);
      return Right(results);
    } catch (e) {
      return Left(CacheFailure('Error al leer el historial'));
    }
  }

  @override
  Future<Either<Failure, void>> guardarRegistro(HistorialRegistro registro) async {
    try {
      final model = HistorialModel(
        fecha: registro.fecha,
        municipio: registro.municipio,
        tempMin: registro.tempMin,
        tempMax: registro.tempMax,
        riesgoHelada: registro.riesgoHelada,
        accionRecomendada: registro.accionRecomendada,
      );
      await localDataSource.saveRegistro(model);
      return const Right(null);
    } catch (e) {
      return Left(CacheFailure('Error al guardar en el historial'));
    }
  }

  @override
  Future<Either<Failure, List<HistorialRegistro>>> getEventosHelada(String municipio) async {
    try {
      final results = await localDataSource.getEventosHelada(municipio);
      return Right(results);
    } catch (e) {
      return Left(CacheFailure('Error al leer eventos de helada'));
    }
  }
}
