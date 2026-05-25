import 'package:equatable/equatable.dart';

class CalendarioCultivo extends Equatable {
  final String id;
  final String nombre;
  final List<int> mesesSiembra;
  final List<int> mesesCosecha;
  final List<int> mesesFumigacion;
  final String observaciones;

  const CalendarioCultivo({
    required this.id,
    required this.nombre,
    required this.mesesSiembra,
    required this.mesesCosecha,
    required this.mesesFumigacion,
    required this.observaciones,
  });

  @override
  List<Object?> get props => [id, nombre];
}
