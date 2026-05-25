import 'package:equatable/equatable.dart';
import '../../../prediccion/domain/entities/frost_prediction.dart';

class HistorialRegistro extends Equatable {
  final int? id;
  final DateTime fecha;
  final String municipio;
  final double tempMin;
  final double tempMax;
  final RiskLevel riesgoHelada;
  final String accionRecomendada;

  const HistorialRegistro({
    this.id,
    required this.fecha,
    required this.municipio,
    required this.tempMin,
    required this.tempMax,
    required this.riesgoHelada,
    required this.accionRecomendada,
  });

  @override
  List<Object?> get props => [id, fecha, municipio, riesgoHelada];
}
