import 'package:equatable/equatable.dart';
import '../../domain/entities/usuario.dart';

abstract class UsuarioEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class LoadUsuarioEvent extends UsuarioEvent {}

class SaveUsuarioEvent extends UsuarioEvent {
  final Usuario usuario;
  SaveUsuarioEvent(this.usuario);
  
  @override
  List<Object?> get props => [usuario];
}

class DeleteUsuarioEvent extends UsuarioEvent {}

class RegisterUsuarioEvent extends UsuarioEvent {
  final String email;
  final String password;
  final String nombres;
  final String apellidos;
  final String telefono;

  RegisterUsuarioEvent({
    required this.email,
    required this.password,
    required this.nombres,
    required this.apellidos,
    required this.telefono,
  });

  @override
  List<Object?> get props => [email, password, nombres, apellidos, telefono];
}

class LoginUsuarioEvent extends UsuarioEvent {
  final String email;
  final String password;

  LoginUsuarioEvent({
    required this.email,
    required this.password,
  });

  @override
  List<Object?> get props => [email, password];
}

abstract class UsuarioState extends Equatable {
  @override
  List<Object?> get props => [];
}

class UsuarioInitial extends UsuarioState {}
class UsuarioLoading extends UsuarioState {}

class UsuarioLoaded extends UsuarioState {
  final Usuario usuario;
  UsuarioLoaded(this.usuario);
  @override
  List<Object?> get props => [usuario];
}

class UsuarioEmpty extends UsuarioState {}

class UsuarioSaved extends UsuarioState {
  final Usuario usuario;
  UsuarioSaved(this.usuario);
  @override
  List<Object?> get props => [usuario];
}

class UsuarioError extends UsuarioState {
  final String message;
  UsuarioError(this.message);
  @override
  List<Object?> get props => [message];
}
