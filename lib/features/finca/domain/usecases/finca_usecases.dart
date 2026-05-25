import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/finca.dart';
import '../repositories/i_finca_repository.dart';

class LoadFinca implements UseCase<Either<Failure, Finca?>, NoParams> {
  final IFincaRepository repository;
  LoadFinca(this.repository);

  @override
  Future<Either<Failure, Finca?>> call(NoParams params) async {
    return await repository.loadFinca();
  }
}

class SaveFinca implements UseCase<Either<Failure, Finca>, Finca> {
  final IFincaRepository repository;
  SaveFinca(this.repository);

  @override
  Future<Either<Failure, Finca>> call(Finca finca) async {
    return await repository.saveFinca(finca);
  }
}

class DeleteFinca implements UseCase<Either<Failure, void>, NoParams> {
  final IFincaRepository repository;
  DeleteFinca(this.repository);

  @override
  Future<Either<Failure, void>> call(NoParams params) async {
    return await repository.deleteFinca();
  }
}
