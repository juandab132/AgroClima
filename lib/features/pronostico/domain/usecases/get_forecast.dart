import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/weather_forecast.dart';
import '../repositories/i_weather_repository.dart';

class ForecastParams {
  final String municipio;
  const ForecastParams({required this.municipio});
}

class GetForecast implements UseCase<Either<Failure, WeatherForecast>, ForecastParams> {
  final IWeatherRepository repository;
  GetForecast(this.repository);

  @override
  Future<Either<Failure, WeatherForecast>> call(ForecastParams params) {
    return repository.getForecast(params.municipio);
  }
}
