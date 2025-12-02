import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;

class ScreenCaptureService {
  static const platform = MethodChannel('com.mirrorscreen/capture');
  
  Timer? _captureTimer;
  bool _isCapturing = false;
  
  final _frameController = StreamController<Uint8List>.broadcast();
  Stream<Uint8List> get frameStream => _frameController.stream;
  
  bool get isCapturing => _isCapturing;

  /// Démarre la capture d'écran à intervalle régulier
  Future<void> startCapture({
    int fps = 30,
    int quality = 70,
  }) async {
    if (_isCapturing) return;
    
    _isCapturing = true;
    final interval = Duration(milliseconds: (1000 / fps).round());
    
    _captureTimer = Timer.periodic(interval, (timer) async {
      try {
        final frameData = await _captureFrame(quality);
        if (frameData != null && !_frameController.isClosed) {
          _frameController.add(frameData);
        }
      } catch (e) {
        // Log error but continue capturing
        print('Capture frame error: $e');
      }
    });
  }

  /// Capture une frame de l'écran
  Future<Uint8List?> _captureFrame(int quality) async {
    try {
      // Appel à la plateforme native pour capturer l'écran
      final Uint8List? rawImage = await platform.invokeMethod('captureScreen');
      
      if (rawImage == null) return null;
      
      // Compression de l'image
      final image = img.decodeImage(rawImage);
      if (image == null) return null;
      
      // Encodage en JPEG avec qualité spécifiée
      final compressed = img.encodeJpg(image, quality: quality);
      return Uint8List.fromList(compressed);
    } catch (e) {
      print('Error capturing frame: $e');
      return null;
    }
  }

  /// Arrête la capture
  void stopCapture() {
    _captureTimer?.cancel();
    _captureTimer = null;
    _isCapturing = false;
  }

  void dispose() {
    stopCapture();
    _frameController.close();
  }
}

// Note: Pour Android, implémentation native nécessaire dans MainActivity.kt
// Pour iOS, implémentation dans AppDelegate.swift