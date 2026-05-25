import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/calendario_cultivo.dart';
import '../repositories/i_calendario_repository.dart';

class GetCalendario {
  final ICalendarioRepository repository;
  GetCalendario(this.repository);

  Future<Either<Failure, List<CalendarioCultivo>>> call() async {
    return await repository.getCalendarios();
  }
}
