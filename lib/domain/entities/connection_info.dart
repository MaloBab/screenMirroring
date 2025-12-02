import 'package:equatable/equatable.dart';

class ConnectionInfo extends Equatable {
  final String ipAddress;
  final int port;
  final String deviceName;
  final String connectionId;
  final ConnectionStatus status;
  final String? qrCode;

  const ConnectionInfo({
    required this.ipAddress,
    required this.port,
    required this.deviceName,
    required this.connectionId,
    required this.status,
    this.qrCode,
  });

  ConnectionInfo copyWith({
    String? ipAddress,
    int? port,
    String? deviceName,
    String? connectionId,
    ConnectionStatus? status,
    String? qrCode,
  }) {
    return ConnectionInfo(
      ipAddress: ipAddress ?? this.ipAddress,
      port: port ?? this.port,
      deviceName: deviceName ?? this.deviceName,
      connectionId: connectionId ?? this.connectionId,
      status: status ?? this.status,
      qrCode: qrCode ?? this.qrCode,
    );
  }

  String get fullAddress => 'ws://$ipAddress:$port';

  @override
  List<Object?> get props => [
        ipAddress,
        port,
        deviceName,
        connectionId,
        status,
        qrCode,
      ];
}

enum ConnectionStatus {
  disconnected,
  connecting,
  connected,
  error,
}

class MirroringStats extends Equatable {
  final int framesPerSecond;
  final double bitrate;
  final Duration duration;
  final int totalFrames;

  const MirroringStats({
    required this.framesPerSecond,
    required this.bitrate,
    required this.duration,
    required this.totalFrames,
  });

  @override
  List<Object> get props => [framesPerSecond, bitrate, duration, totalFrames];
}