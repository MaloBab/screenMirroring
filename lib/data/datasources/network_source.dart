import 'dart:io';
import 'package:network_info_plus/network_info_plus.dart';
import '../../core/services/websocket_service.dart';
import '../../domain/entities/connection_info.dart';
import 'package:uuid/uuid.dart';

abstract class NetworkSource {
  Future<ConnectionInfo> getConnectionInfo();
  Future<void> startServer({required int port});
  Future<void> stopServer();
  void sendFrame(List<int> frameData);
  Stream<bool> get connectionStream;
  bool get isConnected;
}

class NetworkSourceImpl implements NetworkSource {
  final WebSocketService _webSocketService;
  final _networkInfo = NetworkInfo();
  final _uuid = const Uuid();
  
  String? _currentConnectionId;
  int _currentPort = 8080;

  NetworkSourceImpl(this._webSocketService);

  @override
  Future<ConnectionInfo> getConnectionInfo() async {
    final wifiIP = await _networkInfo.getWifiIP();
    final deviceName = await _getDeviceName();
    
    _currentConnectionId ??= _uuid.v4();
    
    return ConnectionInfo(
      ipAddress: wifiIP ?? '0.0.0.0',
      port: _currentPort,
      deviceName: deviceName,
      connectionId: _currentConnectionId!,
      status: _webSocketService.isConnected 
          ? ConnectionStatus.connected 
          : ConnectionStatus.disconnected,
    );
  }

  @override
  Future<void> startServer({required int port}) async {
    _currentPort = await _webSocketService.startServer(port: port);
  }

  @override
  Future<void> stopServer() async {
    await _webSocketService.close();
  }

  @override
  void sendFrame(List<int> frameData) {
    _webSocketService.sendFrame(frameData);
  }

  @override
  Stream<bool> get connectionStream => _webSocketService.connectionStream;

  @override
  bool get isConnected => _webSocketService.isConnected;

  Future<String> _getDeviceName() async {
    try {
      if (Platform.isAndroid) {
        return 'Android Device';
      } else if (Platform.isIOS) {
        return 'iOS Device';
      }
      return 'Unknown Device';
    } catch (e) {
      return 'Mobile Device';
    }
  }
}