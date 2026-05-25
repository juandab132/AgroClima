import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import '../../../../core/database/app_database.dart';
import '../../domain/entities/weather_forecast.dart';

class WeatherLocalDataSource {
  final AppDatabase db;

  WeatherLocalDataSource({required this.db});

  Future<WeatherForecast?> getCachedForecast(String municipio) async {
    try {
      final database = await db.database;
      final results = await database.query(
        AppDatabase.tableW,
        where: '${AppDatabase.colWMunicipio} = ?',
        whereArgs: [municipio],
      );

      if (results.isEmpty) return null;

      final map = results.first;
      final fetchedAt = DateTime.parse(map[AppDatabase.colWFetchedAt] as String);
      
      // TTL de 1 hora según requerimiento Sprint 2
      if (DateTime.now().difference(fetchedAt).inHours >= 1) {
        return null;
      }

      final daysData = jsonDecode(map[AppDatabase.colWData] as String) as List;
      final days = daysData.map((d) {
        return WeatherDay(
          dayName: d['dayName'] as String,
          date: DateTime.parse(d['date'] as String),
          tempMin: (d['tempMin'] as num).toDouble(),
          tempMax: (d['tempMax'] as num).toDouble(),
          rainProbability: (d['rainProbability'] as num).toDouble(),
          windSpeed: (d['windSpeed'] as num).toDouble(),
          emoji: d['emoji'] as String,
        );
      }).toList();

      return WeatherForecast(
        municipio: municipio,
        days: days,
        fetchedAt: fetchedAt,
      );
    } catch (_) {
      return null;
    }
  }

  Future<void> cacheForecast(WeatherForecast forecast) async {
    try {
      final database = await db.database;
      final daysJson = jsonEncode(forecast.days
          .map((d) => {
                'dayName': d.dayName,
                'date': d.date.toIso8601String(),
                'tempMin': d.tempMin,
                'tempMax': d.tempMax,
                'rainProbability': d.rainProbability,
                'windSpeed': d.windSpeed,
                'emoji': d.emoji,
              })
          .toList());

      await database.insert(
        AppDatabase.tableW,
        {
          AppDatabase.colWMunicipio: forecast.municipio,
          AppDatabase.colWData: daysJson,
          AppDatabase.colWFetchedAt: forecast.fetchedAt.toIso8601String(),
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    } catch (_) {}
  }
}
