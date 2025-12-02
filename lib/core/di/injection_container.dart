import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../presentation/bloc/mirroring/mirroring_bloc.dart';
import '../../presentation/bloc/device_discovery/device_discovery_bloc.dart';
import '../services/device_discovery_service.dart';
import '../services/mirroring_service.dart';
import '../services/permission_service.dart';

final getIt = GetIt.instance;

Future<void> initializeDependencies() async {
  // External
  final sharedPreferences = await SharedPreferences.getInstance();
  getIt.registerLazySingleton(() => sharedPreferences);
  
  // Services
  getIt.registerLazySingleton<DeviceDiscoveryService>(
    () => DeviceDiscoveryService(),
  );
  
  getIt.registerLazySingleton<MirroringService>(
    () => MirroringService(),
  );
  
  getIt.registerLazySingleton<PermissionService>(
    () => PermissionService(),
  );
  
  // Blocs
  getIt.registerFactory(
    () => DeviceDiscoveryBloc(getIt<DeviceDiscoveryService>()),
  );
  
  getIt.registerFactory(
    () => MirroringBloc(getIt<MirroringService>()),
  );
}