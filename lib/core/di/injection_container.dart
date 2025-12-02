import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../data/datasources/screen_capture_source.dart';
import '../../data/datasources/network_source.dart';
import '../../domain/repositories/mirroring_repository_impl.dart';
import '../../domain/repositories/mirroring_repository.dart';
import '../../domain/usecases/start_mirroring.dart' as start_mirroring;
import '../../domain/usecases/stop_mirroring.dart' as stop_mirroring;
import '../../domain/usecases/get_connection_info.dart';
import '../../presentation/bloc/mirroring/mirroring_bloc.dart';
import '../../presentation/bloc/connection/connection_bloc.dart';
import '../services/websocket_service.dart';
import '../services/screen_capture_service.dart';
import '../services/permission_service.dart';

final getIt = GetIt.instance;

Future<void> initializeDependencies() async {
  // External
  final sharedPreferences = await SharedPreferences.getInstance();
  getIt.registerLazySingleton(() => sharedPreferences);
  
  // Services
  getIt.registerLazySingleton<WebSocketService>(() => WebSocketService());
  getIt.registerLazySingleton<ScreenCaptureService>(() => ScreenCaptureService());
  getIt.registerLazySingleton<PermissionService>(() => PermissionService());
  
  // Data Sources
  getIt.registerLazySingleton<ScreenCaptureSource>(
    () => ScreenCaptureSourceImpl(getIt()),
  );
  getIt.registerLazySingleton<NetworkSource>(
    () => NetworkSourceImpl(getIt()),
  );
  
  // Repository
  getIt.registerLazySingleton<MirroringRepository>(
    () => MirroringRepositoryImpl(
      screenCaptureSource: getIt(),
      networkSource: getIt(),
    ),
  );
  
  // Use Cases
  getIt.registerLazySingleton(() => start_mirroring.StartMirroring(getIt()));
  getIt.registerLazySingleton(() => stop_mirroring.StopMirroring(getIt()));
  getIt.registerLazySingleton(() => GetConnectionInfo(getIt()));
  
  // Bloc
  getIt.registerFactory(
    () => MirroringBloc(
      startMirroring: getIt(),
      stopMirroring: getIt(),
    ),
  );
  
  getIt.registerFactory(
    () => ConnectionBloc(
      getConnectionInfo: getIt(),
    ),
  );
}