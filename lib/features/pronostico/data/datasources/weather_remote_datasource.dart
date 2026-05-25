import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../domain/entities/weather_forecast.dart';
import '../../../../core/errors/failures.dart';

class WeatherRemoteDataSource {
  static const _base = 'https://api.open-meteo.com/v1/forecast';
  final http.Client client;

  WeatherRemoteDataSource({required this.client});

  Future<WeatherForecast> getForecast({
    required String municipio,
    required double lat,
    required double lon,
  }) async {
    final uri = Uri.parse(_base).replace(queryParameters: {
      'latitude': lat.toString(),
      'longitude': lon.toString(),
      'daily':
          'temperature_2m_min,temperature_2m_max,precipitation_probability_mean,windspeed_10m_max',
      'timezone': 'America/Bogota',
      'forecast_days': '7',
    });

    try {
      final response =
          await client.get(uri).timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        return _parseResponse(municipio, jsonDecode(response.body));
      }
      throw ServerException(
          'Error al consultar el clima. Código: ${response.statusCode}');
    } catch (e) {
      if (e is ServerException) rethrow;
      throw ServerException('No se pudo conectar al servidor de clima.');
    }
  }

  WeatherForecast _parseResponse(
      String municipio, Map<String, dynamic> json) {
    final daily = json['daily'] as Map<String, dynamic>;
    final dates = daily['time'] as List;
    final tempMin = daily['temperature_2m_min'] as List;
    final tempMax = daily['temperature_2m_max'] as List;
    final rain = daily['precipitation_probability_mean'] as List;
    final wind = daily['windspeed_10m_max'] as List;

    final List<String> dayNames = [
      'Lunes', 'Martes', 'Miércoles', 'Jueves', 'Viernes', 'Sábado', 'Domingo'
    ];

    final days = List.generate(dates.length, (i) {
      final date = DateTime.parse(dates[i] as String);
      final weekday = date.weekday - 1;
      final tm = (tempMin[i] as num).toDouble();
      final tmax = (tempMax[i] as num).toDouble();
      final r = (rain[i] as num?)?.toDouble() ?? 0.0;
      final w = (wind[i] as num).toDouble();

      String emoji = '☀️';
      if (r > 70) emoji = '⛈️';
      else if (r > 40) emoji = '🌧️';
      else if (r > 20) emoji = '🌤️';

      return WeatherDay(
        dayName: dayNames[weekday],
        date: date,
        tempMin: tm,
        tempMax: tmax,
        rainProbability: r,
        windSpeed: w,
        emoji: emoji,
      );
    });

    return WeatherForecast(
      municipio: municipio,
      days: days,
      fetchedAt: DateTime.now(),
    );
  }
}
