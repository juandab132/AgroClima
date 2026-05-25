import 'package:dartz/dartz.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as sb;
import '../../domain/entities/finca.dart';
import '../../domain/repositories/i_finca_repository.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/database/app_database.dart';
import '../datasources/finca_sqlite_datasource.dart';

class FincaRepositoryImpl implements IFincaRepository {
  final FincaSQLiteDataSource dataSource;

  FincaRepositoryImpl({required this.dataSource});

  @override
  Future<Either<Failure, Finca?>> loadFinca() async {
    try {
      // 1. Cargar localmente de SQLite
      var finca = await dataSource.loadFinca();

      // 2. Si no hay finca local pero hay usuario en la nube, intentar restaurar de Supabase
      if (finca == null) {
        final client = sb.Supabase.instance.client;
        final user = client.auth.currentUser;
        if (user != null) {
          try {
            final remoteData = await client
                .from('fincas')
                .select()
                .eq('usuario_id', user.id);

            if (remoteData.isNotEmpty) {
              for (var remoteFincaMap in remoteData) {
                final remoteId = remoteFincaMap['id'];
                final restoredFinca = Finca(
                  id: null, // Dejar que SQLite asigne un nuevo ID local
                  nombreAgricultero: '',
                  nombreFinca: remoteFincaMap['nombre_finca'] as String? ?? '',
                  municipio: remoteFincaMap['municipio'] as String? ?? 'Pasto',
                  vereda: remoteFincaMap['vereda'] as String? ?? '',
                  altitud: remoteFincaMap['altitud'] as int? ?? 2527,
                  hectareas: (remoteFincaMap['hectareas'] as num?)?.toDouble() ?? 1.0,
                  tipoRiego: remoteFincaMap['tipo_riego'] as String? ?? 'Lluvia',
                );

                // Guardar en la base de datos local SQLite
                final saved = await dataSource.saveFinca(restoredFinca);
                // Guardar mapeo de supabase_id para sincronización futura
                final database = await dataSource.db.database;
                try {
                  await database.update(
                    AppDatabase.tableF,
                    {
                      AppDatabase.colSincronizado: 1,
                      'supabase_id': remoteId.toString(),
                    },
                    where: '${AppDatabase.colId} = ?',
                    whereArgs: [saved.id],
                  );
                } catch (_) {
                  // La columna supabase_id puede no existir aún, OK
                  await database.update(
                    AppDatabase.tableF,
                    {AppDatabase.colSincronizado: 1},
                    where: '${AppDatabase.colId} = ?',
                    whereArgs: [saved.id],
                  );
                }

                finca = saved;
              }
            }
          } catch (e) {
            print('DEBUG: Error al restaurar fincas desde Supabase: $e');
          }
        }
      }

      return Right(finca);
    } catch (e, stack) {
      print('DEBUG: Error al cargar finca en repositorio: $e');
      print(stack);
      return const Left(CacheFailure('Error al cargar datos de su finca.'));
    }
  }

  @override
  Future<Either<Failure, Finca>> saveFinca(Finca finca) async {
    try {
      // 1. Guardar localmente en SQLite
      final saved = await dataSource.saveFinca(finca);

      // 2. Sincronizar con Supabase si el usuario está autenticado
      final client = sb.Supabase.instance.client;
      final user = client.auth.currentUser;
      if (user != null) {
        try {
          // Buscar si ya existe esta finca para este usuario en Supabase
          // usando nombre_finca + usuario_id como clave natural
          final existingRemote = await client
              .from('fincas')
              .select('id')
              .eq('usuario_id', user.id)
              .eq('nombre_finca', saved.nombreFinca);

          final data = {
            'usuario_id': user.id,
            'nombre_finca': saved.nombreFinca,
            'municipio': saved.municipio,
            'vereda': saved.vereda,
            'altitud': saved.altitud,
            'hectareas': saved.hectareas,
            'tipo_riego': saved.tipoRiego,
            'modificado_en': DateTime.now().toUtc().toIso8601String(),
          };

          if (existingRemote.isNotEmpty) {
            // Actualizar la finca existente en Supabase
            final remoteId = existingRemote.first['id'];
            await client.from('fincas').update(data).eq('id', remoteId);
          } else {
            // Insertar nueva finca en Supabase (sin enviar el ID local)
            await client.from('fincas').insert(data);
          }

          // Marcar como sincronizado localmente
          final database = await dataSource.db.database;
          await database.update(
            AppDatabase.tableF,
            {AppDatabase.colSincronizado: 1},
            where: '${AppDatabase.colId} = ?',
            whereArgs: [saved.id],
          );
        } catch (e) {
          print('DEBUG: Error al sincronizar finca con Supabase (trabajando offline): $e');
        }
      }

      return Right(saved);
    } catch (e, stack) {
      print('DEBUG: Error al guardar finca en repositorio: $e');
      print(stack);
      return const Left(CacheFailure('Error al guardar datos de su finca.'));
    }
  }

  @override
  Future<Either<Failure, void>> deleteFinca() async {
    try {
      final selectedId = await dataSource.getSelectedFincaId();

      // Obtener datos de la finca antes de eliminar para buscarla en Supabase
      Finca? fincaToDelete;
      if (selectedId != null) {
        final database = await dataSource.db.database;
        final rows = await database.query(
          AppDatabase.tableF,
          where: '${AppDatabase.colId} = ?',
          whereArgs: [selectedId],
        );
        if (rows.isNotEmpty) {
          fincaToDelete = Finca(
            id: rows.first[AppDatabase.colId] as int?,
            nombreAgricultero: '',
            nombreFinca: rows.first[AppDatabase.colNombreF] as String? ?? '',
            municipio: rows.first[AppDatabase.colMunicipio] as String? ?? '',
            vereda: rows.first[AppDatabase.colVereda] as String? ?? '',
            altitud: rows.first[AppDatabase.colAltitud] as int? ?? 2527,
            hectareas: (rows.first[AppDatabase.colHectareas] as num?)?.toDouble() ?? 1.0,
            tipoRiego: rows.first[AppDatabase.colTipoRiego] as String? ?? 'Lluvia',
          );
        }
      }

      // 1. Eliminar localmente
      await dataSource.deleteFinca();

      // 2. Eliminar de Supabase si está online
      final client = sb.Supabase.instance.client;
      final user = client.auth.currentUser;
      if (user != null && fincaToDelete != null) {
        try {
          await client
              .from('fincas')
              .delete()
              .eq('usuario_id', user.id)
              .eq('nombre_finca', fincaToDelete.nombreFinca);
        } catch (e) {
          print('DEBUG: Error al eliminar finca de Supabase: $e');
        }
      }

      return const Right(null);
    } catch (e) {
      return const Left(CacheFailure('Error al eliminar datos de su finca.'));
    }
  }
}
