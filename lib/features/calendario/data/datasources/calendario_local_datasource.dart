import 'dart:convert';
import 'package:flutter/services.dart';
import '../../domain/entities/calendario_cultivo.dart';

class CalendarioLocalDataSource {
  Future<List<CalendarioCultivo>> getCalendarios() async {
    final String response = await rootBundle.loadString('assets/calendario_agricola.json');
    final List<dynamic> data = json.decode(response);
    
    return data.map((json) => CalendarioCultivo(
      id: json['id'] as String,
      nombre: json['nombre'] as String,
      mesesSiembra: List<int>.from(json['mesesSiembra']),
      mesesCosecha: List<int>.from(json['mesesCosecha']),
      mesesFumigacion: List<int>.from(json['mesesFumigacion']),
      observaciones: json['observaciones'] as String,
    )).toList();
  }
}
