import 'package:sqflite/sqflite.dart';
import '../../../../core/database/app_database.dart';
import '../../domain/entities/finca.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FincaSQLiteDataSource {
  final AppDatabase db;

  FincaSQLiteDataSource({required this.db});

  Future<int?> getSelectedFincaId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt('selected_finca_id');
  }

  Future<void> setSelectedFincaId(int id) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('selected_finca_id', id);
  }

  Future<List<Finca>> loadAllFincas() async {
    try {
      final database = await db.database;
      final rows = await database.query(AppDatabase.tableF);
      return rows.map((row) => _fromRow(row)).toList();
    } catch (e) {
      return [];
    }
  }

  Future<Finca?> loadFinca() async {
    try {
      final database = await db.database;
      final selectedId = await getSelectedFincaId();
      if (selectedId != null) {
        final rows = await database.query(
          AppDatabase.tableF,
          where: '${AppDatabase.colId} = ?',
          whereArgs: [selectedId],
        );
        if (rows.isNotEmpty) {
          return _fromRow(rows.first);
        }
      }
      // Si no hay seleccionado o no existe en BD, obtener el primero de la lista
      final rows = await database.query(AppDatabase.tableF);
      if (rows.isEmpty) return null;
      final firstFinca = _fromRow(rows.first);
      if (firstFinca.id != null) {
        await setSelectedFincaId(firstFinca.id!);
      }
      return firstFinca;
    } catch (e) {
      return null;
    }
  }

  Future<Finca> saveFinca(Finca finca) async {
    final database = await db.database;
    final map = _toRow(finca);
    if (finca.id != null) {
      map[AppDatabase.colId] = finca.id;
    }

    final id = await database.insert(
      AppDatabase.tableF,
      map,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    
    final savedFinca = finca.copyWith(id: finca.id ?? id);
    await setSelectedFincaId(savedFinca.id!);
    return savedFinca;
  }

  Future<void> deleteFinca() async {
    final database = await db.database;
    final selectedId = await getSelectedFincaId();
    if (selectedId != null) {
      await database.delete(
        AppDatabase.tableF,
        where: '${AppDatabase.colId} = ?',
        whereArgs: [selectedId],
      );
    } else {
      await database.delete(AppDatabase.tableF);
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('selected_finca_id');
  }

  Map<String, dynamic> _toRow(Finca finca) {
    return {
      AppDatabase.colUsuarioId: 1, // Un solo usuario local para MVP
      AppDatabase.colNombreAg: finca.nombreAgricultero,
      AppDatabase.colNombreF: finca.nombreFinca,
      AppDatabase.colMunicipio: finca.municipio,
      AppDatabase.colVereda: finca.vereda,
      AppDatabase.colAltitud: finca.altitud,
      AppDatabase.colHectareas: finca.hectareas,
      AppDatabase.colTipoRiego: finca.tipoRiego,
      AppDatabase.colSincronizado: 0,
      AppDatabase.colModificadoEn: DateTime.now().toUtc().toIso8601String(),
    };
  }

  Finca _fromRow(Map<String, dynamic> row) => Finca(
        id: row[AppDatabase.colId] as int?,
        nombreAgricultero: row[AppDatabase.colNombreAg] as String? ?? '',
        nombreFinca: row[AppDatabase.colNombreF] as String? ?? '',
        municipio: row[AppDatabase.colMunicipio] as String? ?? 'Pasto',
        vereda: row[AppDatabase.colVereda] as String? ?? '',
        altitud: row[AppDatabase.colAltitud] as int? ?? 2527,
        hectareas: (row[AppDatabase.colHectareas] as num?)?.toDouble() ?? 1.0,
        tipoRiego: row[AppDatabase.colTipoRiego] as String? ?? 'Lluvia',
      );
}
