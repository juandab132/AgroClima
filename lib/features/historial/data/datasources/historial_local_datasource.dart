import 'package:sqflite/sqflite.dart';
import '../../../../core/database/app_database.dart';
import '../models/historial_model.dart';
import '../../domain/entities/historial_registro.dart';

class HistorialLocalDataSource {
  final AppDatabase db;
  HistorialLocalDataSource({required this.db});

  Future<List<HistorialModel>> getHistorial(String municipio) async {
    final database = await db.database;
    final List<Map<String, dynamic>> maps = await database.query(
      AppDatabase.tableH,
      where: '${AppDatabase.colHMunicipio} = ?',
      whereArgs: [municipio],
      orderBy: '${AppDatabase.colHFecha} DESC',
    );

    return List.generate(maps.length, (i) => HistorialModel.fromMap(maps[i]));
  }

  Future<void> saveRegistro(HistorialModel registro) async {
    final database = await db.database;
    final map = registro.toMap();
    map[AppDatabase.colUsuarioId] = 1; // Fallback por defecto para MVP
    map[AppDatabase.colSincronizado] = 0;
    map[AppDatabase.colModificadoEn] = DateTime.now().toUtc().toIso8601String();

    await database.insert(
      AppDatabase.tableH,
      map,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<HistorialModel>> getEventosHelada(String municipio) async {
    final database = await db.database;
    final List<Map<String, dynamic>> maps = await database.query(
      AppDatabase.tableH,
      where: '${AppDatabase.colHMunicipio} = ? AND ${AppDatabase.colHRiesgo} = ?',
      whereArgs: [municipio, 'high'],
      orderBy: '${AppDatabase.colHFecha} DESC',
    );

    return List.generate(maps.length, (i) => HistorialModel.fromMap(maps[i]));
  }
}
