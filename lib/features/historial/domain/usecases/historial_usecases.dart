import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/historial_registro.dart';
import '../repositories/i_historial_repository.dart';

class GetHistorial {
  final IHistorialRepository repository;
  GetHistorial(this.repository);

  Future<Either<Failure, List<HistorialRegistro>>> call(String municipio) async {
    return await repository.getHistorial(municipio);
  }
}

class GuardarHistorial {
  final IHistorialRepository repository;
  GuardarHistorial(this.repository);

  Future<Either<Failure, void>> call(HistorialRegistro registro) async {
    return await repository.guardarRegistro(registro);
  }
}

class GetEventosHelada {
  final IHistorialRepository repository;
  GetEventosHelada(this.repository);

  Future<Either<Failure, List<HistorialRegistro>>> call(String municipio) async {
    return await repository.getEventosHelada(municipio);
  }
}
