import 'dart:convert';
import 'package:flutter/services.dart';
import '../../features/pronostico/domain/entities/weather_forecast.dart';

class MunicipiosService {
  Map<String, MunicipioData> _municipios = {};

  Future<void> init() async {
    final String response = await rootBundle.loadString('assets/municipios_narino.json');
    final Map<String, dynamic> data = json.decode(response);
    
    _municipios = data.map((key, value) => MapEntry(
      key, 
      MunicipioData(
        lat: (value['lat'] as num).toDouble(),
        lon: (value['lon'] as num).toDouble(),
        altitud: value['altitud'] as int,
      )
    ));
  }

  Map<String, MunicipioData> get municipios => _municipios;

  void registerMunicipio(String name, double lat, double lon, int altitud) {
    _municipios[name] = MunicipioData(lat: lat, lon: lon, altitud: altitud);
  }

  MunicipioData? getMunicipio(String name) {
    final existing = _municipios[name];
    if (existing != null) return existing;
    if (_municipios.isNotEmpty) {
      return _municipios.values.first;
    }
    return const MunicipioData(lat: 1.214, lon: -77.279, altitud: 2527);
  }
}
