import 'package:permission_handler/permission_handler.dart';

class PermissionService {
  /// Demande toutes les permissions nécessaires
  Future<bool> requestAllPermissions() async {
    final permissions = await Future.wait([
      _requestStoragePermission(),
      _requestScreenCapturePermission(),
    ]);
    
    return permissions.every((granted) => granted);
  }

  /// Permission de stockage
  Future<bool> _requestStoragePermission() async {
    final status = await Permission.storage.request();
    return status.isGranted;
  }

  /// Permission de capture d'écran (Android 5.0+)
  Future<bool> _requestScreenCapturePermission() async {
    // Sur Android, la permission de capture d'écran nécessite
    // l'utilisation de MediaProjection API via le code natif
    // Cette méthode servira de placeholder
    return true;
  }

  /// Vérifie si toutes les permissions sont accordées
  Future<bool> checkPermissions() async {
    final storage = await Permission.storage.isGranted;
    return storage;
  }

  /// Ouvre les paramètres de l'application
  Future<void> openAppSettings() async {
    await openAppSettings();
  }
}