import 'package:dartz/dartz.dart';
import '../../domain/entities/weather_forecast.dart';
import '../../domain/repositories/i_weather_repository.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/network/network_info.dart';
import '../datasources/weather_remote_datasource.dart';
import '../datasources/weather_local_datasource.dart';
import '../../../../core/services/municipios_service.dart';

class WeatherRepositoryImpl implements IWeatherRepository {
  final WeatherRemoteDataSource remote;
  final WeatherLocalDataSource local;
  final NetworkInfo networkInfo;
  final MunicipiosService municipiosService;

  WeatherRepositoryImpl({
    required this.remote,
    required this.local,
    required this.networkInfo,
    required this.municipiosService,
  });

  @override
  Future<Either<Failure, WeatherForecast>> getForecast(
      String municipio) async {
    final mun = municipiosService.getMunicipio(municipio);
    if (mun == null) {
      return Left(InputFailure('Municipio "$municipio" no encontrado.'));
    }

    final isConnected = await networkInfo.isConnected;

    if (isConnected) {
      try {
        final data = await remote.getForecast(
          municipio: municipio,
          lat: mun.lat,
          lon: mun.lon,
        );
        await local.cacheForecast(data);
        return Right(data);
      } catch (e) {
        final cached = await local.getCachedForecast(municipio);
        if (cached != null) return Right(cached);
        return Left(ServerFailure(
            'Error al conectar con el servidor. Sin datos guardados.'));
      }
    } else {
      final cached = await local.getCachedForecast(municipio);
      if (cached != null) return Right(cached);
      return Left(
          CacheFailure('Sin conexión y sin datos guardados para $municipio.'));
    }
  }
}
