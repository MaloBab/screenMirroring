import 'package:equatable/equatable.dart';

enum DeviceType {
  tv,
  chromecast,
  miracast,
  dlna,
  airplay,
  unknown,
}

enum DeviceCapability {
  screenMirroring,
  videoCasting,
  audioCasting,
  h264Support,
  h265Support,
}

class DiscoveredDevice extends Equatable {
  final String id;
  final String name;
  final String ipAddress;
  final int port;
  final DeviceType type;
  final List<DeviceCapability> capabilities;
  final Map<String, dynamic> metadata;
  final double signalStrength;
  final bool isAvailable;
  final DisplayInfo? displayInfo;

  const DiscoveredDevice({
    required this.id,
    required this.name,
    required this.ipAddress,
    required this.port,
    required this.type,
    required this.capabilities,
    this.metadata = const {},
    this.signalStrength = 0.0,
    this.isAvailable = true,
    this.displayInfo,
  });

  DiscoveredDevice copyWith({
    String? id,
    String? name,
    String? ipAddress,
    int? port,
    DeviceType? type,
    List<DeviceCapability>? capabilities,
    Map<String, dynamic>? metadata,
    double? signalStrength,
    bool? isAvailable,
    DisplayInfo? displayInfo,
  }) {
    return DiscoveredDevice(
      id: id ?? this.id,
      name: name ?? this.name,
      ipAddress: ipAddress ?? this.ipAddress,
      port: port ?? this.port,
      type: type ?? this.type,
      capabilities: capabilities ?? this.capabilities,
      metadata: metadata ?? this.metadata,
      signalStrength: signalStrength ?? this.signalStrength,
      isAvailable: isAvailable ?? this.isAvailable,
      displayInfo: displayInfo ?? this.displayInfo,
    );
  }

  String get fullAddress => '$ipAddress:$port';
  
  bool get supportsScreenMirroring => 
      capabilities.contains(DeviceCapability.screenMirroring);

  @override
  List<Object?> get props => [
        id,
        name,
        ipAddress,
        port,
        type,
        capabilities,
        metadata,
        signalStrength,
        isAvailable,
        displayInfo,
      ];
}

class DisplayInfo extends Equatable {
  final int width;
  final int height;
  final double aspectRatio;
  final int refreshRate;
  final bool hdrSupport;

  const DisplayInfo({
    required this.width,
    required this.height,
    required this.aspectRatio,
    this.refreshRate = 60,
    this.hdrSupport = false,
  });

  String get resolution => '${width}x$height';
  
  bool get is4K => width >= 3840 && height >= 2160;
  bool get isFullHD => width >= 1920 && height >= 1080;
  bool get isHD => width >= 1280 && height >= 720;

  @override
  List<Object?> get props => [width, height, aspectRatio, refreshRate, hdrSupport];
}