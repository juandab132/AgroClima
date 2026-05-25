import 'package:equatable/equatable.dart';

class Finca extends Equatable {
  final int? id;
  final String nombreAgricultero;
  final String nombreFinca;
  final String vereda;
  final String municipio;
  final int altitud;
  final double hectareas;
  final String tipoRiego;

  const Finca({
    this.id,
    required this.nombreAgricultero,
    required this.nombreFinca,
    this.vereda = '',
    required this.municipio,
    required this.altitud,
    required this.hectareas,
    required this.tipoRiego,
  });

  Finca copyWith({
    int? id,
    String? nombreAgricultero,
    String? nombreFinca,
    String? vereda,
    String? municipio,
    int? altitud,
    double? hectareas,
    String? tipoRiego,
  }) {
    return Finca(
      id: id ?? this.id,
      nombreAgricultero: nombreAgricultero ?? this.nombreAgricultero,
      nombreFinca: nombreFinca ?? this.nombreFinca,
      vereda: vereda ?? this.vereda,
      municipio: municipio ?? this.municipio,
      altitud: altitud ?? this.altitud,
      hectareas: hectareas ?? this.hectareas,
      tipoRiego: tipoRiego ?? this.tipoRiego,
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'nombreAgricultero': nombreAgricultero,
        'nombreFinca': nombreFinca,
        'vereda': vereda,
        'municipio': municipio,
        'altitud': altitud,
        'hectareas': hectareas,
        'tipoRiego': tipoRiego,
      };

  factory Finca.fromMap(Map<String, dynamic> map) => Finca(
        id: map['id'] as int?,
        nombreAgricultero: map['nombreAgricultero'] ?? '',
        nombreFinca: map['nombreFinca'] ?? '',
        vereda: map['vereda'] ?? '',
        municipio: map['municipio'] ?? 'Pasto',
        altitud: map['altitud'] ?? 2527,
        hectareas: (map['hectareas'] as num?)?.toDouble() ?? 1.0,
        tipoRiego: map['tipoRiego'] ?? 'Lluvia',
      );

  static Finca get ejemplo => const Finca(
        id: 999,
        nombreAgricultero: 'Don José García',
        nombreFinca: 'La Esperanza',
        vereda: 'El Encano',
        municipio: 'Pasto',
        altitud: 2700,
        hectareas: 2.5,
        tipoRiego: 'Lluvia',
      );

  @override
  List<Object?> get props => [
        id,
        nombreAgricultero,
        nombreFinca,
        municipio,
        altitud,
        hectareas,
        tipoRiego,
      ];
}
