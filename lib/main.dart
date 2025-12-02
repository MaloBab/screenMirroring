import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'core/di/injection_container.dart';
import 'core/theme/app_theme.dart';
import 'presentation/bloc/mirroring/mirroring_bloc.dart';
import 'presentation/bloc/device_discovery/device_discovery_bloc.dart';
import 'presentation/pages/home_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Configuration système
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ),
  );
  
  // Initialisation des dépendances
  await initializeDependencies();
  
  runApp(const MirrorScreenApp());
}

class MirrorScreenApp extends StatelessWidget {
  const MirrorScreenApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) => getIt<MirroringBloc>(),
        ),
        BlocProvider(
          create: (_) => getIt<DeviceDiscoveryBloc>(),
        ),
      ],
      child: MaterialApp(
        title: 'MirrorScreen Pro',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.darkTheme,
        home: const HomePage(),
      ),
    );
  }
}