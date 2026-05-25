import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/weather_forecast.dart';

abstract class IWeatherRepository {
  Future<Either<Failure, WeatherForecast>> getForecast(String municipio);
}
