import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

/// Singleton que gestiona la base de datos SQLite de AgroClima.
class AppDatabase {
  AppDatabase._();
  static final AppDatabase instance = AppDatabase._();

  Database? _db;

  static const _dbName = 'agro_clima.db';
  static const _dbVersion = 5; 

  // ── Tablas ────────────────────────────────────────────────────────────────
  static const tableU = 'usuario';
  static const tableF = 'finca';
  static const tableW = 'weather_cache';
  static const tableC = 'cultivos';
  static const tableH = 'historial_clima';

  // Columnas Usuario
  static const colUId = 'id';
  static const colUNombres = 'nombres';
  static const colUApellidos = 'apellidos';
  static const colUTelefono = 'telefono';
  static const colUEmail = 'email';
  static const colUContrasenaHash = 'contrasena_hash';
  static const colUFechaRegistro = 'fecha_registro';

  // Columnas Comunes de Sincronización
  static const colUsuarioId = 'usuario_id';
  static const colSincronizado = 'sincronizado';
  static const colModificadoEn = 'modificado_en';

  // Columnas Finca
  static const colId = 'id';
  static const colNombreAg = 'nombre_agricultor'; // Deprecated
  static const colNombreF = 'nombre_finca';
  static const colMunicipio = 'municipio';
  static const colVereda = 'vereda';
  static const colAltitud = 'altitud';
  static const colHectareas = 'hectareas';
  static const colTipoRiego = 'tipo_riego';

  // Columnas Weather Cache
  static const colWId = 'id';
  static const colWMunicipio = 'municipio';
  static const colWData = 'data_json';
  static const colWFetchedAt = 'fetched_at';

  // Columnas Cultivos
  static const colCId = 'id';
  static const colCNombre = 'nombre';
  static const colCActivo = 'activo';

  // Columnas Historial
  static const colHId = 'id';
  static const colHFecha = 'fecha';
  static const colHMunicipio = 'municipio';
  static const colHTempMin = 'temp_min';
  static const colHTempMax = 'temp_max';
  static const colHRiesgo = 'riesgo';
  static const colHAccion = 'accion';

  Future<Database> get database async {
    _db ??= await _initDb();
    return _db!;
  }

  Future<Database> _initDb() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, _dbName);

    return openDatabase(
      path,
      version: _dbVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE $tableU (
        $colUId        INTEGER PRIMARY KEY AUTOINCREMENT,
        $colUNombres   TEXT    NOT NULL,
        $colUApellidos TEXT    NOT NULL,
        $colUTelefono  TEXT    NOT NULL,
        $colUEmail     TEXT    NOT NULL UNIQUE,
        $colUContrasenaHash TEXT NOT NULL,
        $colUFechaRegistro TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE $tableF (
        $colId       INTEGER PRIMARY KEY AUTOINCREMENT,
        $colUsuarioId INTEGER NOT NULL DEFAULT 1,
        $colNombreAg TEXT    NOT NULL,
        $colNombreF  TEXT    NOT NULL,
        $colMunicipio TEXT   NOT NULL,
        $colVereda   TEXT    NOT NULL DEFAULT '',
        $colAltitud  INTEGER NOT NULL,
        $colHectareas REAL   NOT NULL,
        $colTipoRiego TEXT   NOT NULL,
        $colSincronizado INTEGER NOT NULL DEFAULT 0,
        $colModificadoEn TEXT NOT NULL DEFAULT ''
      )
    ''');

    await db.execute('''
      CREATE TABLE $tableW (
        $colWId        INTEGER PRIMARY KEY AUTOINCREMENT,
        $colWMunicipio TEXT    NOT NULL UNIQUE,
        $colWData      TEXT    NOT NULL,
        $colWFetchedAt TEXT    NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE $tableC (
        $colCId     TEXT PRIMARY KEY,
        $colUsuarioId INTEGER NOT NULL DEFAULT 1,
        $colCNombre TEXT NOT NULL,
        $colCActivo INTEGER NOT NULL DEFAULT 0,
        $colSincronizado INTEGER NOT NULL DEFAULT 0,
        $colModificadoEn TEXT NOT NULL DEFAULT ''
      )
    ''');

    await db.execute('''
      CREATE TABLE $tableH (
        $colHId        INTEGER PRIMARY KEY AUTOINCREMENT,
        $colUsuarioId  INTEGER NOT NULL DEFAULT 1,
        $colHFecha     TEXT    NOT NULL,
        $colHMunicipio TEXT    NOT NULL,
        $colHTempMin   REAL    NOT NULL,
        $colHTempMax   REAL    NOT NULL,
        $colHRiesgo    TEXT    NOT NULL,
        $colHAccion    TEXT    NOT NULL,
        $colSincronizado INTEGER NOT NULL DEFAULT 0,
        $colModificadoEn TEXT NOT NULL DEFAULT ''
      )
    ''');
    await db.execute('CREATE INDEX idx_fecha ON $tableH($colHFecha)');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('''
        CREATE TABLE $tableW (
          $colWId        INTEGER PRIMARY KEY AUTOINCREMENT,
          $colWMunicipio TEXT    NOT NULL UNIQUE,
          $colWData      TEXT    NOT NULL,
          $colWFetchedAt TEXT    NOT NULL
        )
      ''');
      await db.execute('''
        CREATE TABLE $tableC (
          $colCId     TEXT PRIMARY KEY,
          $colCNombre TEXT NOT NULL,
          $colCActivo INTEGER NOT NULL DEFAULT 0
        )
      ''');
    }
    if (oldVersion < 3) {
      await db.execute('''
        CREATE TABLE $tableH (
          $colHId        INTEGER PRIMARY KEY AUTOINCREMENT,
          $colHFecha     TEXT    NOT NULL,
          $colHMunicipio TEXT    NOT NULL,
          $colHTempMin   REAL    NOT NULL,
          $colHTempMax   REAL    NOT NULL,
          $colHRiesgo    TEXT    NOT NULL,
          $colHAccion    TEXT    NOT NULL
        )
      ''');
      await db.execute('CREATE INDEX idx_fecha ON $tableH($colHFecha)');
    }
    if (oldVersion < 4) {
      await db.execute('''
        CREATE TABLE $tableU (
          $colUId        INTEGER PRIMARY KEY AUTOINCREMENT,
          $colUNombres   TEXT    NOT NULL,
          $colUApellidos TEXT    NOT NULL,
          $colUTelefono  TEXT    NOT NULL,
          $colUFechaRegistro TEXT NOT NULL
        )
      ''');
    }
    if (oldVersion < 5) {
      // 1. Agregar campos a usuario
      await db.execute('ALTER TABLE $tableU ADD COLUMN $colUEmail TEXT NOT NULL DEFAULT ""');
      await db.execute('ALTER TABLE $tableU ADD COLUMN $colUContrasenaHash TEXT NOT NULL DEFAULT ""');
      
      // 2. Agregar campos a finca
      await db.execute('ALTER TABLE $tableF ADD COLUMN $colUsuarioId INTEGER NOT NULL DEFAULT 1');
      await db.execute('ALTER TABLE $tableF ADD COLUMN $colSincronizado INTEGER NOT NULL DEFAULT 0');
      await db.execute('ALTER TABLE $tableF ADD COLUMN $colModificadoEn TEXT NOT NULL DEFAULT ""');
      
      // 3. Agregar campos a cultivos
      await db.execute('ALTER TABLE $tableC ADD COLUMN $colUsuarioId INTEGER NOT NULL DEFAULT 1');
      await db.execute('ALTER TABLE $tableC ADD COLUMN $colSincronizado INTEGER NOT NULL DEFAULT 0');
      await db.execute('ALTER TABLE $tableC ADD COLUMN $colModificadoEn TEXT NOT NULL DEFAULT ""');
      
      // 4. Agregar campos a historial_clima
      await db.execute('ALTER TABLE $tableH ADD COLUMN $colUsuarioId INTEGER NOT NULL DEFAULT 1');
      await db.execute('ALTER TABLE $tableH ADD COLUMN $colSincronizado INTEGER NOT NULL DEFAULT 0');
      await db.execute('ALTER TABLE $tableH ADD COLUMN $colModificadoEn TEXT NOT NULL DEFAULT ""');
    }
  }

  Future<void> close() async {
    final db = _db;
    if (db != null) {
      await db.close();
      _db = null;
    }
  }
}
