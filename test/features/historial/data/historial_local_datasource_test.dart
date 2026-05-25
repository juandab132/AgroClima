import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:agro_clima/core/database/app_database.dart';
import 'package:agro_clima/features/historial/data/datasources/historial_local_datasource.dart';
import 'package:agro_clima/features/historial/data/models/historial_model.dart';
import 'package:agro_clima/features/prediccion/domain/entities/frost_prediction.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  late HistorialLocalDataSource dataSource;
  late Database db;

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  setUp(() async {
    db = await openDatabase(inMemoryDatabasePath, version: 5, onCreate: (db, version) async {
      await db.execute('''
        CREATE TABLE historial_clima (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          usuario_id INTEGER NOT NULL DEFAULT 1,
          fecha TEXT NOT NULL,
          municipio TEXT NOT NULL,
          temp_min REAL NOT NULL,
          temp_max REAL NOT NULL,
          riesgo TEXT NOT NULL,
          accion TEXT NOT NULL,
          sincronizado INTEGER NOT NULL DEFAULT 0,
          modificado_en TEXT NOT NULL DEFAULT ''
        )
      ''');
    });
    
    final appDb = MockAppDatabase();
    when(() => appDb.database).thenAnswer((_) async => db);
    dataSource = HistorialLocalDataSource(db: appDb as dynamic); // bypass for mock
  });

  tearDown(() async {
    await db.close();
  });

  final tModel = HistorialModel(
    fecha: DateTime(2024, 1, 1),
    municipio: 'Pasto',
    tempMin: 5.0,
    tempMax: 15.0,
    riesgoHelada: RiskLevel.low,
    accionRecomendada: 'Ninguna',
  );

  test('should save and retrieve historial registro', () async {
    // Act
    await dataSource.saveRegistro(tModel);
    final result = await dataSource.getHistorial('Pasto');

    // Assert
    expect(result.length, 1);
    expect(result.first.municipio, 'Pasto');
    expect(result.first.tempMin, 5.0);
  });
}

class MockAppDatabase extends Mock implements AppDatabase {}
