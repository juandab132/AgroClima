import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/cultivo.dart';

abstract class ICultivosRepository {
  Future<Either<Failure, List<Cultivo>>> getSelectedCrops();
  Future<Either<Failure, void>> toggleCropStatus(String cropId, bool isActive);
  Future<Either<Failure, List<Cultivo>>> getAllCrops();
}
