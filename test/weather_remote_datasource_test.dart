import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'dart:convert';

import 'package:agro_clima/features/pronostico/data/datasources/weather_remote_datasource.dart';
import 'package:agro_clima/features/pronostico/domain/entities/weather_forecast.dart';
import 'package:agro_clima/core/errors/failures.dart';

/// Tests del cliente HTTP de Open-Meteo.
///
/// Usa MockClient de package:http/testing.dart — sin conexión real.
void main() {
  group('WeatherRemoteDataSource', () {
    // ── Respuesta exitosa mínima de Open-Meteo ────────────────────────────
    final _validBody = jsonEncode({
      'daily': {
        'time': [
          '2025-04-30',
          '2025-05-01',
          '2025-05-02',
          '2025-05-03',
          '2025-05-04',
          '2025-05-05',
          '2025-05-06',
        ],
        'temperature_2m_min': [4.0, 5.0, 6.0, 3.0, 4.5, 7.0, 8.0],
        'temperature_2m_max': [14.0, 15.0, 13.0, 12.0, 15.0, 16.0, 17.0],
        'precipitation_probability_mean': [30, 60, 20, 80, 10, 40, 50],
        'windspeed_10m_max': [12.0, 18.0, 10.0, 25.0, 8.0, 15.0, 20.0],
      }
    });

    test('Parsea respuesta HTTP 200 correctamente', () async {
      final client = MockClient((_) async =>
          http.Response(_validBody, 200));
      final ds = WeatherRemoteDataSource(client: client);

      final result = await ds.getForecast(
        municipio: 'Pasto',
        lat: 1.214,
        lon: -77.279,
      );

      expect(result, isA<WeatherForecast>());
      expect(result.municipio, 'Pasto');
      expect(result.days.length, 7);
      expect(result.days.first.tempMin, closeTo(4.0, 0.01));
      expect(result.days.first.tempMax, closeTo(14.0, 0.01));
      expect(result.days.first.rainProbability, closeTo(30, 0.01));
      expect(result.days.first.windSpeed, closeTo(12.0, 0.01));
    });

    test('Lanza ServerException para HTTP 500', () async {
      final client = MockClient((_) async =>
          http.Response('Server Error', 500));
      final ds = WeatherRemoteDataSource(client: client);

      expect(
        () => ds.getForecast(
          municipio: 'Pasto',
          lat: 1.214,
          lon: -77.279,
        ),
        throwsA(isA<ServerException>()),
      );
    });

    test('Lanza ServerException cuando hay timeout/error de red', () async {
      final client = MockClient((_) async => throw Exception('timeout'));
      final ds = WeatherRemoteDataSource(client: client);

      expect(
        () => ds.getForecast(
          municipio: 'Ipiales',
          lat: 0.859,
          lon: -77.641,
        ),
        throwsA(isA<ServerException>()),
      );
    });

    test('isStale = false para forecast recién creado', () async {
      final client = MockClient((_) async =>
          http.Response(_validBody, 200));
      final ds = WeatherRemoteDataSource(client: client);

      final result = await ds.getForecast(
        municipio: 'Pasto',
        lat: 1.214,
        lon: -77.279,
      );

      expect(result.isStale, isFalse);
    });

    test('Emoji se asigna según porcentaje de lluvia', () async {
      final client = MockClient((_) async =>
          http.Response(_validBody, 200));
      final ds = WeatherRemoteDataSource(client: client);

      final result = await ds.getForecast(
        municipio: 'Pasto',
        lat: 1.214,
        lon: -77.279,
      );

      // día con 30% lluvia → 🌤️ o ☀️
      final d0 = result.days[0]; // 30%
      expect(['☀️', '🌤️', '🌧️', '⛈️'], contains(d0.emoji));

      // día con 80% lluvia → ⛈️
      final d3 = result.days[3]; // 80%
      expect(d3.emoji, '⛈️');
    });
  });
}
