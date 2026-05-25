import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:sqflite/sqflite.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:agro_clima/features/finca/data/datasources/finca_sqlite_datasource.dart';
import 'package:agro_clima/features/finca/domain/entities/finca.dart';
import 'package:agro_clima/core/database/app_database.dart';

class MockAppDatabase extends Mock implements AppDatabase {}

void main() {
  late FincaSQLiteDataSource dataSource;
  late Database db;
  late MockAppDatabase mockAppDb;

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    db = await databaseFactoryFfi.openDatabase(
      inMemoryDatabasePath,
      options: OpenDatabaseOptions(
        version: 1,
        onCreate: (db, version) async {
          await db.execute('''
            CREATE TABLE ${AppDatabase.tableF} (
              ${AppDatabase.colId}        INTEGER PRIMARY KEY AUTOINCREMENT,
              ${AppDatabase.colUsuarioId} INTEGER NOT NULL DEFAULT 1,
              ${AppDatabase.colNombreAg}  TEXT    NOT NULL,
              ${AppDatabase.colNombreF}   TEXT    NOT NULL,
              ${AppDatabase.colMunicipio} TEXT    NOT NULL,
              ${AppDatabase.colVereda}    TEXT    NOT NULL DEFAULT '',
              ${AppDatabase.colAltitud}   INTEGER NOT NULL,
              ${AppDatabase.colHectareas} REAL    NOT NULL,
              ${AppDatabase.colTipoRiego} TEXT    NOT NULL,
              ${AppDatabase.colSincronizado} INTEGER NOT NULL DEFAULT 0,
              ${AppDatabase.colModificadoEn} TEXT NOT NULL DEFAULT ''
            )
          ''');
        },
      ),
    );
    mockAppDb = MockAppDatabase();
    when(() => mockAppDb.database).thenAnswer((_) async => db);
    dataSource = FincaSQLiteDataSource(db: mockAppDb);
  });

  tearDown(() async {
    await db.close();
  });

  group('FincaSQLiteDataSource', () {
    const fincaDemo = Finca(
      nombreAgricultero: 'Don José García',
      nombreFinca: 'La Esperanza',
      vereda: 'El Encano',
      municipio: 'Pasto',
      altitud: 2700,
      hectareas: 2.5,
      tipoRiego: 'Lluvia',
    );

    test('loadFinca retorna null cuando la BD está vacía', () async {
      final result = await dataSource.loadFinca();
      expect(result, isNull);
    });

    test('saveFinca guarda y loadFinca recupera correctamente', () async {
      final saved = await dataSource.saveFinca(fincaDemo);
      expect(saved.id, equals(1)); // Forzar ID 1 para MVP

      final loaded = await dataSource.loadFinca();
      expect(loaded, isNotNull);
      expect(loaded!.nombreAgricultero, 'Don José García');
      expect(loaded.nombreFinca, 'La Esperanza');
      expect(loaded.municipio, 'Pasto');
      expect(loaded.altitud, 2700);
      expect(loaded.hectareas, closeTo(2.5, 0.001));
      expect(loaded.tipoRiego, 'Lluvia');
    });

    test('deleteFinca elimina el registro', () async {
      await dataSource.saveFinca(fincaDemo);
      await dataSource.deleteFinca();
      final result = await dataSource.loadFinca();
      expect(result, isNull);
    });
  });
}
