import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/io.dart';

class WebSocketService {
  WebSocketChannel? _channel;
  HttpServer? _server;
  final _connectionController = StreamController<bool>.broadcast();
  final _messageController = StreamController<dynamic>.broadcast();
  
  bool _isConnected = false;
  
  Stream<bool> get connectionStream => _connectionController.stream;
  Stream<dynamic> get messageStream => _messageController.stream;
  bool get isConnected => _isConnected;

  /// Démarre un serveur WebSocket local
  Future<int> startServer({int port = 8080}) async {
    try {
      _server = await HttpServer.bind(InternetAddress.anyIPv4, port);
      
      _server!.transform(WebSocketTransformer()).listen((WebSocket webSocket) {
        _channel = IOWebSocketChannel(webSocket);
        _isConnected = true;
        _connectionController.add(true);
        
        _channel!.stream.listen(
          (message) {
            _messageController.add(message);
          },
          onDone: () {
            _isConnected = false;
            _connectionController.add(false);
          },
          onError: (error) {
            _isConnected = false;
            _connectionController.add(false);
          },
        );
      });
      
      return port;
    } catch (e) {
      throw Exception('Failed to start server: $e');
    }
  }

  /// Envoie des données binaires (frames)
  void sendFrame(List<int> frameData) {
    if (_isConnected && _channel != null) {
      try {
        _channel!.sink.add(frameData);
      } catch (e) {
        _isConnected = false;
        _connectionController.add(false);
      }
    }
  }

  /// Envoie des métadonnées JSON
  void sendMetadata(Map<String, dynamic> metadata) {
    if (_isConnected && _channel != null) {
      try {
        _channel!.sink.add(json.encode(metadata));
      } catch (e) {
        _isConnected = false;
        _connectionController.add(false);
      }
    }
  }

  /// Ferme la connexion
  Future<void> close() async {
    _isConnected = false;
    await _channel?.sink.close();
    await _server?.close();
    _channel = null;
    _server = null;
    _connectionController.add(false);
  }

  void dispose() {
    _connectionController.close();
    _messageController.close();
    close();
  }
}