import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../domain/entities/cultivo.dart';
import '../../domain/repositories/i_cultivos_repository.dart';
import '../datasources/cultivos_local_datasource.dart';

class CultivosRepositoryImpl implements ICultivosRepository {
  final CultivosLocalDataSource localDataSource;

  CultivosRepositoryImpl({required this.localDataSource});

  @override
  Future<Either<Failure, List<Cultivo>>> getAllCrops() async {
    try {
      final activeIds = await localDataSource.getSelectedCropIds();
      final allCrops = cultivosList.map((crop) {
        return crop.copyWith(activo: activeIds.contains(crop.id));
      }).toList();
      return Right(allCrops);
    } catch (e) {
      return const Left(CacheFailure('Error al cargar cultivos.'));
    }
  }

  @override
  Future<Either<Failure, List<Cultivo>>> getSelectedCrops() async {
    try {
      final activeIds = await localDataSource.getSelectedCropIds();
      final selected = cultivosList
          .where((crop) => activeIds.contains(crop.id))
          .map((crop) => crop.copyWith(activo: true))
          .toList();
      return Right(selected);
    } catch (e) {
      return const Left(CacheFailure('Error al cargar sus cultivos.'));
    }
  }

  @override
  Future<Either<Failure, void>> toggleCropStatus(String cropId, bool isActive) async {
    try {
      final crop = cultivosList.firstWhere((c) => c.id == cropId);
      await localDataSource.saveCropStatus(cropId, crop.nombre, isActive);
      return const Right(null);
    } catch (e) {
      return const Left(CacheFailure('No se pudo guardar el cambio.'));
    }
  }
}
