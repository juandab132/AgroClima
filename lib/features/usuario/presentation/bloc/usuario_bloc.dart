import 'package:flutter_bloc/flutter_bloc.dart';
import 'usuario_event_state.dart';
import '../../domain/repositories/i_usuario_repository.dart';

class UsuarioBloc extends Bloc<UsuarioEvent, UsuarioState> {
  final IUsuarioRepository repository;

  UsuarioBloc({required this.repository}) : super(UsuarioInitial()) {
    on<LoadUsuarioEvent>(_onLoad);
    on<SaveUsuarioEvent>(_onSave);
    on<DeleteUsuarioEvent>(_onDelete);
    on<RegisterUsuarioEvent>(_onRegister);
    on<LoginUsuarioEvent>(_onLogin);
  }

  Future<void> _onLoad(LoadUsuarioEvent event, Emitter<UsuarioState> emit) async {
    emit(UsuarioLoading());
    final result = await repository.getUsuario();
    
    result.fold(
      (failure) => emit(UsuarioError(failure.message)),
      (usuario) {
        if (usuario != null) {
          emit(UsuarioLoaded(usuario));
        } else {
          emit(UsuarioEmpty());
        }
      },
    );
  }

  Future<void> _onSave(SaveUsuarioEvent event, Emitter<UsuarioState> emit) async {
    emit(UsuarioLoading());
    final result = await repository.saveUsuario(event.usuario);
    
    result.fold(
      (failure) => emit(UsuarioError(failure.message)),
      (savedUser) {
        emit(UsuarioSaved(savedUser));
        emit(UsuarioLoaded(savedUser));
      },
    );
  }

  Future<void> _onDelete(DeleteUsuarioEvent event, Emitter<UsuarioState> emit) async {
    emit(UsuarioLoading());
    final result = await repository.deleteUsuario();
    
    result.fold(
      (failure) => emit(UsuarioError(failure.message)),
      (_) => emit(UsuarioEmpty()),
    );
  }

  Future<void> _onRegister(RegisterUsuarioEvent event, Emitter<UsuarioState> emit) async {
    emit(UsuarioLoading());
    final result = await repository.registrar(
      email: event.email,
      password: event.password,
      nombres: event.nombres,
      apellidos: event.apellidos,
      telefono: event.telefono,
    );

    result.fold(
      (failure) => emit(UsuarioError(failure.message)),
      (savedUser) {
        emit(UsuarioSaved(savedUser));
        emit(UsuarioLoaded(savedUser));
      },
    );
  }

  Future<void> _onLogin(LoginUsuarioEvent event, Emitter<UsuarioState> emit) async {
    emit(UsuarioLoading());
    final result = await repository.iniciarSesion(
      email: event.email,
      password: event.password,
    );

    result.fold(
      (failure) => emit(UsuarioError(failure.message)),
      (savedUser) {
        emit(UsuarioSaved(savedUser));
        emit(UsuarioLoaded(savedUser));
      },
    );
  }
}
