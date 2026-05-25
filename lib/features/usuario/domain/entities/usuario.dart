import 'package:equatable/equatable.dart';

class Usuario extends Equatable {
  final int? id;
  final String nombres;
  final String apellidos;
  final String telefono;
  final String email;
  final String? contrasenaHash;
  final DateTime fechaRegistro;

  const Usuario({
    this.id,
    required this.nombres,
    required this.apellidos,
    required this.telefono,
    required this.email,
    this.contrasenaHash,
    required this.fechaRegistro,
  });

  Usuario copyWith({
    int? id,
    String? nombres,
    String? apellidos,
    String? telefono,
    String? email,
    String? contrasenaHash,
    DateTime? fechaRegistro,
  }) {
    return Usuario(
      id: id ?? this.id,
      nombres: nombres ?? this.nombres,
      apellidos: apellidos ?? this.apellidos,
      telefono: telefono ?? this.telefono,
      email: email ?? this.email,
      contrasenaHash: contrasenaHash ?? this.contrasenaHash,
      fechaRegistro: fechaRegistro ?? this.fechaRegistro,
    );
  }

  @override
  List<Object?> get props => [
        id,
        nombres,
        apellidos,
        telefono,
        email,
        contrasenaHash,
        fechaRegistro,
      ];
}
