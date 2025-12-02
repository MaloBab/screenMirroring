import 'dart:async';
import 'dart:typed_data';
import '../../core/services/screen_capture_service.dart';

abstract class ScreenCaptureSource {
  Future<void> startCapture({required int fps, required int quality});
  Future<void> stopCapture();
  Stream<Uint8List> get frameStream;
  bool get isCapturing;
}

class ScreenCaptureSourceImpl implements ScreenCaptureSource {
  final ScreenCaptureService _captureService;

  ScreenCaptureSourceImpl(this._captureService);

  @override
  Future<void> startCapture({
    required int fps,
    required int quality,
  }) async {
    await _captureService.startCapture(fps: fps, quality: quality);
  }

  @override
  Future<void> stopCapture() async {
    _captureService.stopCapture();
  }

  @override
  Stream<Uint8List> get frameStream => _captureService.frameStream;

  @override
  bool get isCapturing => _captureService.isCapturing;
}