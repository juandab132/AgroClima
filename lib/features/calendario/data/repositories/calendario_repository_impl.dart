import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../domain/entities/calendario_cultivo.dart';
import '../../domain/repositories/i_calendario_repository.dart';
import '../datasources/calendario_local_datasource.dart';

class CalendarioRepositoryImpl implements ICalendarioRepository {
  final CalendarioLocalDataSource localDataSource;

  CalendarioRepositoryImpl({required this.localDataSource});

  @override
  Future<Either<Failure, List<CalendarioCultivo>>> getCalendarios() async {
    try {
      final results = await localDataSource.getCalendarios();
      return Right(results);
    } catch (e) {
      return Left(CacheFailure('Error al cargar el calendario agrícola'));
    }
  }
}
