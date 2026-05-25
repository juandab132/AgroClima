import '../../domain/entities/historial_registro.dart';
import '../../../prediccion/domain/entities/frost_prediction.dart';

class HistorialModel extends HistorialRegistro {
  const HistorialModel({
    super.id,
    required super.fecha,
    required super.municipio,
    required super.tempMin,
    required super.tempMax,
    required super.riesgoHelada,
    required super.accionRecomendada,
  });

  factory HistorialModel.fromMap(Map<String, dynamic> map) {
    return HistorialModel(
      id: map['id'] as int?,
      fecha: DateTime.parse(map['fecha'] as String),
      municipio: map['municipio'] as String,
      tempMin: (map['temp_min'] as num).toDouble(),
      tempMax: (map['temp_max'] as num).toDouble(),
      riesgoHelada: RiskLevel.values.firstWhere(
        (e) => e.toString().split('.').last == map['riesgo'],
        orElse: () => RiskLevel.low,
      ),
      accionRecomendada: map['accion'] as String,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'fecha': fecha.toIso8601String(),
      'municipio': municipio,
      'temp_min': tempMin,
      'temp_max': tempMax,
      'riesgo': riesgoHelada.toString().split('.').last,
      'accion': accionRecomendada,
    };
  }
}
