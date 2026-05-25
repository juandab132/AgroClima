import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/calendario_cultivo.dart';

abstract class ICalendarioRepository {
  Future<Either<Failure, List<CalendarioCultivo>>> getCalendarios();
}
