import 'package:equatable/equatable.dart';

class WeatherDay extends Equatable {
  final String dayName;
  final DateTime date;
  final double tempMin;
  final double tempMax;
  final double rainProbability;
  final double windSpeed;
  final String emoji;

  const WeatherDay({
    required this.dayName,
    required this.date,
    required this.tempMin,
    required this.tempMax,
    required this.rainProbability,
    required this.windSpeed,
    required this.emoji,
  });

  bool get isGoodForSpray => windSpeed < 20 && rainProbability < 40;

  @override
  List<Object?> get props => [date, tempMin, tempMax, rainProbability, windSpeed];
}

class WeatherForecast extends Equatable {
  final String municipio;
  final List<WeatherDay> days;
  final DateTime fetchedAt;

  const WeatherForecast({
    required this.municipio,
    required this.days,
    required this.fetchedAt,
  });

  bool get isStale => DateTime.now().difference(fetchedAt).inHours >= 6;

  @override
  List<Object?> get props => [municipio, days, fetchedAt];
}

class MunicipioData {
  final double lat;
  final double lon;
  final int altitud;
  const MunicipioData({required this.lat, required this.lon, required this.altitud});
}
