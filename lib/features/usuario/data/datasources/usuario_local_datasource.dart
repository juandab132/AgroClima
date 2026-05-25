import 'package:sqflite/sqflite.dart';
import '../../../../core/database/app_database.dart';
import '../../domain/entities/usuario.dart';

import 'package:shared_preferences/shared_preferences.dart';

class UsuarioLocalDataSource {
  final AppDatabase db;

  UsuarioLocalDataSource({required this.db});

  Future<Usuario?> getUsuario() async {
    try {
      final database = await db.database;
      final rows = await database.query(
        AppDatabase.tableU,
        where: '${AppDatabase.colUId} = ?',
        whereArgs: [1],
      );
      if (rows.isEmpty) return null;
      return _fromRow(rows.first);
    } catch (e) {
      return null;
    }
  }

  Future<Usuario> saveUsuario(Usuario usuario) async {
    final database = await db.database;
    final map = _toRow(usuario);
    map[AppDatabase.colUId] = 1; // Un solo usuario para el MVP

    await database.insert(
      AppDatabase.tableU,
      map,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    
    return usuario.copyWith(id: 1);
  }

  Future<void> deleteUsuario() async {
    final database = await db.database;
    await database.delete(AppDatabase.tableU);
    await database.delete(AppDatabase.tableF);
    await database.delete(AppDatabase.tableC);
    await database.delete(AppDatabase.tableH);
    await database.delete(AppDatabase.tableW);

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('selected_finca_id');
  }

  Map<String, dynamic> _toRow(Usuario usuario) {
    return {
      AppDatabase.colUNombres: usuario.nombres,
      AppDatabase.colUApellidos: usuario.apellidos,
      AppDatabase.colUTelefono: usuario.telefono,
      AppDatabase.colUEmail: usuario.email,
      if (usuario.contrasenaHash != null)
        AppDatabase.colUContrasenaHash: usuario.contrasenaHash,
      AppDatabase.colUFechaRegistro: usuario.fechaRegistro.toIso8601String(),
    };
  }

  Usuario _fromRow(Map<String, dynamic> row) => Usuario(
        id: row[AppDatabase.colUId] as int?,
        nombres: row[AppDatabase.colUNombres] as String,
        apellidos: row[AppDatabase.colUApellidos] as String,
        telefono: row[AppDatabase.colUTelefono] as String,
        email: row[AppDatabase.colUEmail] as String? ?? '',
        contrasenaHash: row[AppDatabase.colUContrasenaHash] as String?,
        fechaRegistro: DateTime.parse(row[AppDatabase.colUFechaRegistro] as String),
      );
}
