import 'package:sqflite/sqflite.dart';
import '../../../../core/database/app_database.dart';
import '../../domain/entities/cultivo.dart';

class CultivosLocalDataSource {
  final AppDatabase db;

  CultivosLocalDataSource({required this.db});

  Future<List<String>> getSelectedCropIds() async {
    final database = await db.database;
    final results = await database.query(
      AppDatabase.tableC,
      where: '${AppDatabase.colCActivo} = ?',
      whereArgs: [1],
    );
    return results.map((r) => r[AppDatabase.colCId] as String).toList();
  }

  Future<void> saveCropStatus(String cropId, String nombre, bool isActive) async {
    final database = await db.database;
    
    // Revisamos si ya existe para no sobrescribir el usuario_id accidentalmente
    final existing = await database.query(
      AppDatabase.tableC,
      where: '${AppDatabase.colCId} = ?',
      whereArgs: [cropId],
    );

    if (existing.isNotEmpty) {
      await database.update(
        AppDatabase.tableC,
        {
          AppDatabase.colCActivo: isActive ? 1 : 0,
          AppDatabase.colModificadoEn: DateTime.now().toIso8601String(),
          AppDatabase.colSincronizado: 0,
        },
        where: '${AppDatabase.colCId} = ?',
        whereArgs: [cropId],
      );
    } else {
      await database.insert(
        AppDatabase.tableC,
        {
          AppDatabase.colCId: cropId,
          AppDatabase.colCNombre: nombre,
          AppDatabase.colCActivo: isActive ? 1 : 0,
          AppDatabase.colUsuarioId: 1, // Fallback por defecto
          AppDatabase.colSincronizado: 0,
          AppDatabase.colModificadoEn: DateTime.now().toIso8601String(),
        },
      );
    }
  }

  Future<void> clearCrops() async {
    final database = await db.database;
    await database.delete(AppDatabase.tableC);
  }
}
