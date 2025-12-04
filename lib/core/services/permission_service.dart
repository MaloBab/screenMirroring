// lib/core/services/permission_service.dart
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';

enum PermissionStatus {
  granted,
  denied,
  permanentlyDenied,
  notRequested,
}

class PermissionResult {
  final PermissionStatus status;
  final String? message;

  const PermissionResult({
    required this.status,
    this.message,
  });

  bool get isGranted => status == PermissionStatus.granted;
  bool get isPermanentlyDenied => status == PermissionStatus.permanentlyDenied;
}

class PermissionService {
  static const platform = MethodChannel('com.mirrorscreen/capture');
  
  /// Vérifie si toutes les permissions sont accordées
  Future<PermissionResult> checkAllPermissions() async {
    if (!Platform.isAndroid) {
      return const PermissionResult(
        status: PermissionStatus.granted,
        message: 'iOS non supporté',
      );
    }

    // Vérifier les permissions de base
    final notification = await Permission.notification.status;
    
    if (notification.isDenied) {
      return const PermissionResult(
        status: PermissionStatus.denied,
        message: 'Permission de notification requise',
      );
    }
    
    if (notification.isPermanentlyDenied) {
      return const PermissionResult(
        status: PermissionStatus.permanentlyDenied,
        message: 'Permission de notification refusée définitivement',
      );
    }

    return const PermissionResult(
      status: PermissionStatus.granted,
    );
  }

  /// Demande toutes les permissions nécessaires
  Future<PermissionResult> requestAllPermissions() async {
    if (!Platform.isAndroid) {
      return const PermissionResult(
        status: PermissionStatus.granted,
        message: 'iOS non supporté',
      );
    }

    try {
      // 1. Demander la permission de notification d'abord
      final notificationStatus = await Permission.notification.request();
      
      if (notificationStatus.isPermanentlyDenied) {
        return const PermissionResult(
          status: PermissionStatus.permanentlyDenied,
          message: 'Veuillez activer les notifications dans les paramètres',
        );
      }
      
      if (notificationStatus.isDenied) {
        return const PermissionResult(
          status: PermissionStatus.denied,
          message: 'Permission de notification refusée',
        );
      }

      // 2. La permission de capture d'écran sera demandée par le code natif
      // via MediaProjection lors du démarrage du mirroring
      
      return const PermissionResult(
        status: PermissionStatus.granted,
      );
    } catch (e) {
      return PermissionResult(
        status: PermissionStatus.denied,
        message: 'Erreur lors de la demande de permissions: $e',
      );
    }
  }

  /// Demande spécifiquement la permission de capture d'écran
  /// Cette méthode déclenche la popup Android native
  Future<PermissionResult> requestScreenCapturePermission() async {
    try {
      // Cette méthode déclenche la popup Android native via MainActivity
      await platform.invokeMethod('requestPermission');
      
      // Attendre un peu pour laisser le temps à l'utilisateur de répondre
      await Future.delayed(const Duration(milliseconds: 500));
      
      return const PermissionResult(
        status: PermissionStatus.granted,
        message: 'Demande envoyée, attendez la popup Android',
      );
    } catch (e) {
      return PermissionResult(
        status: PermissionStatus.denied,
        message: 'Erreur: $e',
      );
    }
  }

  /// Ouvre les paramètres de l'application
  Future<void> openAppSettings() async {
    await openAppSettings();
  }

  /// Vérifie si les permissions ont été définitivement refusées
  Future<bool> arePermissionsPermanentlyDenied() async {
    final notification = await Permission.notification.status;
    return notification.isPermanentlyDenied;
  }
}