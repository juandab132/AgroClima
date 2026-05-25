import 'package:get_it/get_it.dart';
import 'package:http/http.dart' as http;

import 'core/database/app_database.dart';
import 'core/services/municipios_service.dart';

import 'features/prediccion/data/datasources/frost_decision_tree.dart';
import 'features/prediccion/presentation/bloc/prediction_bloc.dart';

import 'features/pronostico/data/datasources/weather_remote_datasource.dart';
import 'features/pronostico/data/datasources/weather_local_datasource.dart';
import 'features/pronostico/data/repositories/weather_repository_impl.dart';
import 'features/pronostico/domain/repositories/i_weather_repository.dart';
import 'features/pronostico/domain/usecases/get_forecast.dart';
import 'features/pronostico/presentation/bloc/weather_bloc.dart';

import 'features/finca/data/datasources/finca_sqlite_datasource.dart';
import 'features/finca/data/repositories/finca_repository_impl.dart';
import 'features/finca/domain/repositories/i_finca_repository.dart';
import 'features/finca/domain/usecases/finca_usecases.dart';
import 'features/finca/presentation/bloc/finca_bloc.dart';

import 'features/cultivos/data/datasources/cultivos_local_datasource.dart';
import 'features/cultivos/data/repositories/cultivos_repository_impl.dart';
import 'features/cultivos/domain/repositories/i_cultivos_repository.dart';
import 'features/cultivos/presentation/bloc/cultivos_bloc.dart';

import 'features/usuario/data/datasources/usuario_local_datasource.dart';
import 'features/usuario/data/repositories/usuario_repository_impl.dart';
import 'features/usuario/domain/repositories/i_usuario_repository.dart';
import 'features/usuario/presentation/bloc/usuario_bloc.dart';

import 'core/network/network_info.dart';
import 'core/services/notification_service.dart';

import 'features/historial/data/datasources/historial_local_datasource.dart';
import 'features/historial/data/repositories/historial_repository_impl.dart';
import 'features/historial/domain/repositories/i_historial_repository.dart';
import 'features/historial/domain/usecases/historial_usecases.dart';
import 'features/historial/presentation/bloc/historial_bloc.dart';
import 'features/calendario/data/datasources/calendario_local_datasource.dart';
import 'features/calendario/data/repositories/calendario_repository_impl.dart';
import 'features/calendario/domain/repositories/i_calendario_repository.dart';
import 'features/calendario/domain/usecases/get_calendario.dart';
import 'features/calendario/presentation/bloc/calendario_bloc.dart';

final sl = GetIt.instance;

Future<void> init() async {
  // ── BLoCs ──────────────────────────────────────────────────────────────
  sl.registerFactory(() => PredictionBloc(
        decisionTree: sl(),
        sprayTree: sl(),
      ));
  sl.registerFactory(() => WeatherBloc(
        getForecast: sl(),
        guardarHistorial: sl(),
        decisionTree: sl(),
      ));
  sl.registerFactory(() => FincaBloc(saveFinca: sl(), loadFinca: sl(), deleteFinca: sl()));
  sl.registerFactory(() => CultivosBloc(repository: sl()));
  sl.registerFactory(() => HistorialBloc(
        getHistorial: sl(),
        guardarHistorial: sl(),
        getEventosHelada: sl(),
      ));
  sl.registerFactory(() => CalendarioBloc(getCalendario: sl()));
  sl.registerFactory(() => UsuarioBloc(repository: sl()));

  // ── Use Cases ─────────────────────────────────────────────────────────────
  sl.registerLazySingleton(() => GetForecast(sl()));
  sl.registerLazySingleton(() => SaveFinca(sl()));
  sl.registerLazySingleton(() => LoadFinca(sl()));
  sl.registerLazySingleton(() => DeleteFinca(sl()));
  sl.registerLazySingleton(() => GetHistorial(sl()));
  sl.registerLazySingleton(() => GuardarHistorial(sl()));
  sl.registerLazySingleton(() => GetEventosHelada(sl()));
  sl.registerLazySingleton(() => GetCalendario(sl()));

  // ── Repositories ──────────────────────────────────────────────────────────
  sl.registerLazySingleton<IWeatherRepository>(
    () => WeatherRepositoryImpl(
      remote: sl(),
      local: sl(),
      networkInfo: sl(),
      municipiosService: sl(),
    ),
  );
  sl.registerLazySingleton<IFincaRepository>(
    () => FincaRepositoryImpl(dataSource: sl()),
  );
  sl.registerLazySingleton<ICultivosRepository>(
    () => CultivosRepositoryImpl(localDataSource: sl()),
  );
  sl.registerLazySingleton<IHistorialRepository>(
    () => HistorialRepositoryImpl(localDataSource: sl()),
  );
  sl.registerLazySingleton<ICalendarioRepository>(
    () => CalendarioRepositoryImpl(localDataSource: sl()),
  );
  sl.registerLazySingleton<IUsuarioRepository>(
    () => UsuarioRepositoryImpl(localDataSource: sl()),
  );

  // ── Data Sources ──────────────────────────────────────────────────────────
  sl.registerLazySingleton(() => FrostDecisionTree());
  sl.registerLazySingleton(() => SprayDecisionTree());
  sl.registerLazySingleton(() => WeatherRemoteDataSource(client: sl()));
  sl.registerLazySingleton(() => WeatherLocalDataSource(db: sl()));
  sl.registerLazySingleton(() => FincaSQLiteDataSource(db: sl()));
  sl.registerLazySingleton(() => CultivosLocalDataSource(db: sl()));
  sl.registerLazySingleton(() => HistorialLocalDataSource(db: sl()));
  sl.registerLazySingleton(() => CalendarioLocalDataSource());
  sl.registerLazySingleton(() => UsuarioLocalDataSource(db: sl()));

  // ── Core & Services ───────────────────────────────────────────────────────
  sl.registerLazySingleton<NetworkInfo>(() => NetworkInfoImpl());
  sl.registerLazySingleton(() => http.Client());
  sl.registerLazySingleton(() => AppDatabase.instance);
  sl.registerLazySingleton(() => NotificationService());
  sl.registerLazySingleton(() => MunicipiosService());
}
