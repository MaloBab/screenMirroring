import 'dart:async';
import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;
import '../../domain/entities/discovered_device.dart';

class MirroringService {
  static const platform = MethodChannel('com.mirrorscreen/capture');
  
  Timer? _captureTimer;
  bool _isCapturing = false;
  DiscoveredDevice? _targetDevice;
  
  final _frameController = StreamController<Uint8List>.broadcast();
  final _statsController = StreamController<MirroringStats>.broadcast();
  
  Stream<Uint8List> get frameStream => _frameController.stream;
  Stream<MirroringStats> get statsStream => _statsController.stream;
  bool get isCapturing => _isCapturing;
  
  int _frameCount = 0;
  int _totalFrames = 0;
  DateTime? _startTime;
  int _lastSecondFrameCount = 0;
  DateTime _lastSecondTime = DateTime.now();

  /// Démarre le mirroring vers un appareil
  Future<void> startMirroring({
    required DiscoveredDevice device,
    int quality = 70,
  }) async {
    if (_isCapturing) return;
    
    _targetDevice = device;
    _isCapturing = true;
    _startTime = DateTime.now();
    _frameCount = 0;
    _totalFrames = 0;
    
    // Calcule le FPS optimal selon l'appareil
    final fps = _calculateOptimalFPS(device);
    final interval = Duration(milliseconds: (1000 / fps).round());
    
    // Calcule la résolution optimale
    final targetResolution = _calculateOptimalResolution(device);
    
    // Démarre la permission de capture d'écran
    await platform.invokeMethod('requestPermission');
    await platform.invokeMethod('startCapture');
    
    _captureTimer = Timer.periodic(interval, (timer) async {

      final frameData = await _captureAndProcessFrame(
        quality: quality,
        targetWidth: targetResolution.width,
        targetHeight: targetResolution.height,
      );
      
      if (frameData != null && !_frameController.isClosed) {
        _frameController.add(frameData);
        _updateStats();
      }
    });
    
    // Démarre le timer de statistiques
    Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!_isCapturing) {
        timer.cancel();
      } else {
        _emitStats();
      }
    });
  }

  /// Capture et traite une frame
  Future<Uint8List?> _captureAndProcessFrame({
    required int quality,
    required int targetWidth,
    required int targetHeight,
  }) async {
    try {
      // Capture de l'écran via la plateforme native
      final Uint8List? rawImage = await platform.invokeMethod('captureScreen');
      if (rawImage == null) return null;
      
      // Décode l'image
      final image = img.decodeImage(rawImage);
      if (image == null) return null;
      
      // Redimensionne l'image selon la résolution cible
      final resized = img.copyResize(
        image,
        width: targetWidth,
        height: targetHeight,
        interpolation: img.Interpolation.linear,
      );
      
      // Optimise selon le type d'appareil
      final optimized = _optimizeForDevice(resized);
      
      // Encode en JPEG avec la qualité spécifiée
      final encoded = img.encodeJpg(optimized, quality: quality);
      return Uint8List.fromList(encoded);
    } catch (e) {
      return null;
    }
  }

  /// Calcule le FPS optimal selon l'appareil
  int _calculateOptimalFPS(DiscoveredDevice device) {
    // Pour les Chromecast et appareils 4K
    if (device.type == DeviceType.chromecast || 
        (device.displayInfo?.is4K ?? false)) {
      return 60;
    }
    
    // Pour les appareils Full HD
    if (device.displayInfo?.isFullHD ?? false) {
      return 30;
    }
    
    // Pour les autres appareils
    return 24;
  }

  /// Calcule la résolution optimale
  ({int width, int height}) _calculateOptimalResolution(DiscoveredDevice device) {
    final displayInfo = device.displayInfo;
    
    if (displayInfo == null) {
      return (width: 1920, height: 1080); // Full HD par défaut
    }
    
    // Adaptation selon la résolution de l'écran cible
    if (displayInfo.is4K) {
      return (width: 3840, height: 2160);
    } else if (displayInfo.isFullHD) {
      return (width: 1920, height: 1080);
    } else if (displayInfo.isHD) {
      return (width: 1280, height: 720);
    } else {
      // Utilise la résolution native
      return (width: displayInfo.width, height: displayInfo.height);
    }
  }

  /// Optimise l'image selon le type d'appareil
  img.Image _optimizeForDevice(img.Image image) {
    if (_targetDevice == null) return image;
    
    // Ajuste la netteté pour les grands écrans
    if (_targetDevice!.displayInfo?.is4K ?? false) {
      return img.adjustColor(
        image,
        contrast: 1.1,
        saturation: 1.05,
      );
    }
    
    // Optimisation pour Chromecast
    if (_targetDevice!.type == DeviceType.chromecast) {
      return img.adjustColor(
        image,
        brightness: 1.02,
        contrast: 1.05,
      );
    }
    
    return image;
  }

  /// Met à jour les statistiques
  void _updateStats() {
    _frameCount++;
    _totalFrames++;
    
    final now = DateTime.now();
    final diff = now.difference(_lastSecondTime);
    
    if (diff.inMilliseconds >= 1000) {
      _lastSecondFrameCount = _frameCount;
      _frameCount = 0;
      _lastSecondTime = now;
    }
  }

  /// Émet les statistiques
  void _emitStats() {
    if (_startTime == null) return;
    
    final duration = DateTime.now().difference(_startTime!);
    final fps = _lastSecondFrameCount;
    
    // Estime le débit (bitrate approximatif)
    final resolution = _targetDevice?.displayInfo;
    final pixelCount = (resolution?.width ?? 1920) * (resolution?.height ?? 1080);
    final bitrate = (pixelCount * fps * 0.5) / 1000000; // Mbps approximatif
    
    final stats = MirroringStats(
      framesPerSecond: fps,
      bitrate: bitrate,
      duration: duration,
      totalFrames: _totalFrames,
      droppedFrames: 0,
      averageLatency: 50, // ms
      resolution: resolution != null 
          ? '${resolution.width}x${resolution.height}'
          : '1920x1080',
    );
    
    if (!_statsController.isClosed) {
      _statsController.add(stats);
    }
  }

  /// Arrête le mirroring
  Future<void> stopMirroring() async {
    _captureTimer?.cancel();
    _captureTimer = null;
    _isCapturing = false;
    _targetDevice = null;
    
    await platform.invokeMethod('stopCapture');
  }

  void dispose() {
    stopMirroring();
    _frameController.close();
    _statsController.close();
  }
}

class MirroringStats {
  final int framesPerSecond;
  final double bitrate;
  final Duration duration;
  final int totalFrames;
  final int droppedFrames;
  final int averageLatency;
  final String resolution;

  const MirroringStats({
    required this.framesPerSecond,
    required this.bitrate,
    required this.duration,
    required this.totalFrames,
    required this.droppedFrames,
    required this.averageLatency,
    required this.resolution,
  });

  double get quality {
    final droppedRate = totalFrames > 0 ? droppedFrames / totalFrames : 0;
    return (1 - droppedRate) * 100;
  }
}