import 'dart:async';
import 'dart:io';
import 'package:multicast_dns/multicast_dns.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../domain/entities/discovered_device.dart';

class SSDPDiscovery {
  static const String searchMessage = 
      'M-SEARCH * HTTP/1.1\r\n'
      'HOST: 239.255.255.250:1900\r\n'
      'MAN: "ssdp:discover"\r\n'
      'MX: 3\r\n'
      'ST: ssdp:all\r\n'
      '\r\n';

  static Future<List<String>> discover() async {
    final devices = <String>[];
    RawDatagramSocket? socket;
    
    try {
      // Bind sans reusePort pour compatibilité Android
      socket = await RawDatagramSocket.bind(
        InternetAddress.anyIPv4, 
        0,
        reuseAddress: true, // Utilisé à la place de reusePort
      );
      
      socket.readEventsEnabled = true;
      socket.broadcastEnabled = true;

      final searchData = searchMessage.codeUnits;
      socket.send(
        searchData,
        InternetAddress('239.255.255.250'),
        1900,
      );

      // Timeout avec gestion propre
      final completer = Completer<void>();
      final timer = Timer(const Duration(seconds: 5), () {
        if (!completer.isCompleted) {
          completer.complete();
        }
      });

      socket.listen(
        (event) {
          if (event == RawSocketEvent.read) {
            final datagram = socket?.receive();
            if (datagram != null) {
              final response = String.fromCharCodes(datagram.data);
              if (response.contains('LOCATION:')) {
                final location = _extractLocation(response);
                if (location != null && !devices.contains(location)) {
                  devices.add(location);
                }
              }
            }
          }
        },
        onError: (error) {
          if (!completer.isCompleted) {
            completer.complete();
          }
        },
        onDone: () {
          if (!completer.isCompleted) {
            completer.complete();
          }
        },
      );

      await completer.future;
      timer.cancel();
      socket.close();
    } catch (e) {
      socket?.close();
    }
    
    return devices;
  }

  static String? _extractLocation(String response) {
    final lines = response.split('\r\n');
    for (final line in lines) {
      if (line.toUpperCase().startsWith('LOCATION:')) {
        return line.substring(9).trim();
      }
    }
    return null;
  }
}

class DeviceDiscoveryService {
  final _deviceController = StreamController<List<DiscoveredDevice>>.broadcast();
  final Map<String, DiscoveredDevice> _discoveredDevices = {};
  
  MDnsClient? _mdnsClient;
  Timer? _discoveryTimer;
  bool _isDiscovering = false;

  Stream<List<DiscoveredDevice>> get devicesStream => _deviceController.stream;
  List<DiscoveredDevice> get currentDevices => _discoveredDevices.values.toList();
  bool get isDiscovering => _isDiscovering;

  /// Démarre la découverte automatique des appareils
  Future<void> startDiscovery() async {
    if (_isDiscovering) return;
    
    _isDiscovering = true;
    _discoveredDevices.clear();
    
    try {
      _mdnsClient = MDnsClient();
      await _mdnsClient!.start();
      
      // Découverte de différents types d'appareils
      await Future.wait([
        _discoverDLNADevices(),
        _discoverChromecastDevices(),
        _discoverMiracastDevices(),
        _discoverSmartTVs(),
      ]);
      
      // Rafraîchissement périodique
      _discoveryTimer = Timer.periodic(
        const Duration(seconds: 10),
        (_) => _refreshDevices(),
      );
    } catch (e) {
      _isDiscovering = false;
    }
  }

  /// Arrête la découverte
  Future<void> stopDiscovery() async {
    _isDiscovering = false;
    _discoveryTimer?.cancel();
    _mdnsClient?.stop();
    _discoveredDevices.clear();
    _deviceController.add([]);
  }

  /// Découverte des appareils DLNA/UPnP
  Future<void> _discoverDLNADevices() async {
      // Utilise SSDP pour découvrir les appareils UPnP/DLNA
      final locations = await SSDPDiscovery.discover();
      
      for (final location in locations) {
        try {
          final uri = Uri.parse(location);
          final response = await http.get(uri).timeout(const Duration(seconds: 3));
          
          if (response.statusCode == 200) {
            final xmlContent = response.body;
            // Parse basic info from UPnP XML
            if (xmlContent.contains('urn:schemas-upnp-org:device')) {
              final device = _parseUPnPDevice(uri.host, xmlContent);
              if (device != null) {
                _addDevice(device);
              }
            }
          }
        } catch (e) {
          // Continue with next device
        }
      }
      
      // Également découverte via mDNS
      await _discoverDLNAViaMDNS();
  }
  
  Future<void> _discoverDLNAViaMDNS() async {
    await for (final PtrResourceRecord ptr in _mdnsClient!.lookup<PtrResourceRecord>(
      ResourceRecordQuery.serverPointer('_dlna._tcp'),
    ).timeout(const Duration(seconds: 5))) {
      await for (final SrvResourceRecord srv in _mdnsClient!.lookup<SrvResourceRecord>(
        ResourceRecordQuery.service(ptr.domainName),
      ).timeout(const Duration(seconds: 3))) {
        final device = await _createDLNADevice(srv);
        if (device != null) {
          _addDevice(device);
        }
      }
    }
  }
  
  DiscoveredDevice? _parseUPnPDevice(String host, String xmlContent) {
    try {
      // Simple XML parsing (vous pouvez utiliser xml package pour plus de robustesse)
      final friendlyNameMatch = RegExp(r'<friendlyName>(.*?)</friendlyName>').firstMatch(xmlContent);
      final modelNameMatch = RegExp(r'<modelName>(.*?)</modelName>').firstMatch(xmlContent);
      
      final name = friendlyNameMatch?.group(1) ?? modelNameMatch?.group(1) ?? 'DLNA Device';
      
      return DiscoveredDevice(
        id: 'dlna_$host',
        name: name,
        ipAddress: host,
        port: 8080,
        type: DeviceType.dlna,
        capabilities: const [
          DeviceCapability.screenMirroring,
          DeviceCapability.videoCasting,
          DeviceCapability.h264Support,
        ],
        signalStrength: 1.0,
      );
    } catch (e) {
      return null;
    }
  }

  /// Découverte des Chromecast
  Future<void> _discoverChromecastDevices() async {
    await for (final PtrResourceRecord ptr in _mdnsClient!.lookup<PtrResourceRecord>(
      ResourceRecordQuery.serverPointer('_googlecast._tcp'),
    ).timeout(const Duration(seconds: 5))) {
      await for (final SrvResourceRecord srv in _mdnsClient!.lookup<SrvResourceRecord>(
        ResourceRecordQuery.service(ptr.domainName),
      ).timeout(const Duration(seconds: 3))) {
        final device = await _createChromecastDevice(srv);
        if (device != null) {
          _addDevice(device);
        }
      }
    }
  }

  /// Découverte des appareils Miracast
  Future<void> _discoverMiracastDevices() async {

    await for (final PtrResourceRecord ptr in _mdnsClient!.lookup<PtrResourceRecord>(
      ResourceRecordQuery.serverPointer('_miracast._tcp'),
    ).timeout(const Duration(seconds: 5))) {
      await for (final SrvResourceRecord srv in _mdnsClient!.lookup<SrvResourceRecord>(
        ResourceRecordQuery.service(ptr.domainName),
      ).timeout(const Duration(seconds: 3))) {
        final device = await _createMiracastDevice(srv);
        if (device != null) {
          _addDevice(device);
        }
      }
    }
  }

  /// Découverte des Smart TV génériques
  Future<void> _discoverSmartTVs() async {
    // Scan du réseau local pour les appareils avec ports communs
    final subnet = await _getLocalSubnet();
    if (subnet == null) return;

    final ports = [8008, 8080, 8009, 9080, 7000, 55000]; // Ports communs des Smart TV
    
    // Limite à 50 IPs pour éviter de bloquer
    for (int i = 1; i < 50; i++) {
      final ip = '$subnet.$i';
      for (final port in ports) {
        _checkSmartTV(ip, port);
      }
    }
  }

  /// Vérifie si une IP:Port correspond à une Smart TV
  Future<void> _checkSmartTV(String ip, int port) async {
    try {
      final socket = await Socket.connect(
        ip,
        port,
        timeout: const Duration(seconds: 2),
      );
      
      // Tentative de récupération des infos via HTTP
      final response = await http.get(
        Uri.parse('http://$ip:$port/info'),
        headers: {'Accept': 'application/json'},
      ).timeout(const Duration(seconds: 3));
      
      if (response.statusCode == 200) {
        final info = json.decode(response.body);
        final device = _createSmartTVDevice(ip, port, info);
        if (device != null) {
          _addDevice(device);
        }
      }
      
      socket.close();
    } catch (e) {
      // Ignoré - appareil non compatible
    }
  }

  /// Crée un objet DiscoveredDevice pour DLNA
  Future<DiscoveredDevice?> _createDLNADevice(SrvResourceRecord srv) async {
    try {
      final ipAddress = await _resolveIPAddress(srv.target);
      if (ipAddress == null) return null;

      final displayInfo = await _getDisplayInfo(ipAddress, srv.port);
      
      return DiscoveredDevice(
        id: 'dlna_${ipAddress}_${srv.port}',
        name: srv.name.split('.').first,
        ipAddress: ipAddress,
        port: srv.port,
        type: DeviceType.dlna,
        capabilities: const [
          DeviceCapability.screenMirroring,
          DeviceCapability.videoCasting,
          DeviceCapability.h264Support,
        ],
        displayInfo: displayInfo,
        signalStrength: 1.0,
      );
    } catch (e) {
      return null;
    }
  }

  /// Crée un objet DiscoveredDevice pour Chromecast
  Future<DiscoveredDevice?> _createChromecastDevice(SrvResourceRecord srv) async {
    try {
      final ipAddress = await _resolveIPAddress(srv.target);
      if (ipAddress == null) return null;

      final displayInfo = await _getDisplayInfo(ipAddress, srv.port);
      
      return DiscoveredDevice(
        id: 'cast_${ipAddress}_${srv.port}',
        name: srv.name.split('.').first,
        ipAddress: ipAddress,
        port: srv.port,
        type: DeviceType.chromecast,
        capabilities: const [
          DeviceCapability.screenMirroring,
          DeviceCapability.videoCasting,
          DeviceCapability.audioCasting,
          DeviceCapability.h264Support,
          DeviceCapability.h265Support,
        ],
        displayInfo: displayInfo,
        signalStrength: 1.0,
      );
    } catch (e) {
      return null;
    }
  }

  /// Crée un objet DiscoveredDevice pour Miracast
  Future<DiscoveredDevice?> _createMiracastDevice(SrvResourceRecord srv) async {
    try {
      final ipAddress = await _resolveIPAddress(srv.target);
      if (ipAddress == null) return null;

      final displayInfo = await _getDisplayInfo(ipAddress, srv.port);
      
      return DiscoveredDevice(
        id: 'miracast_${ipAddress}_${srv.port}',
        name: srv.name.split('.').first,
        ipAddress: ipAddress,
        port: srv.port,
        type: DeviceType.miracast,
        capabilities: const [
          DeviceCapability.screenMirroring,
          DeviceCapability.h264Support,
        ],
        displayInfo: displayInfo,
        signalStrength: 1.0,
      );
    } catch (e) {
      return null;
    }
  }

  /// Crée un objet DiscoveredDevice pour Smart TV générique
  DiscoveredDevice? _createSmartTVDevice(String ip, int port, Map<String, dynamic> info) {
    try {
      return DiscoveredDevice(
        id: 'tv_${ip}_$port',
        name: info['name'] ?? 'Smart TV',
        ipAddress: ip,
        port: port,
        type: DeviceType.tv,
        capabilities: const [
          DeviceCapability.screenMirroring,
          DeviceCapability.videoCasting,
        ],
        metadata: info,
        signalStrength: 1.0,
      );
    } catch (e) {
      return null;
    }
  }

  /// Résout l'adresse IP à partir du nom de domaine
  Future<String?> _resolveIPAddress(String hostname) async {
    try {
      final addresses = await InternetAddress.lookup(hostname);
      return addresses.isNotEmpty ? addresses.first.address : null;
    } catch (e) {
      return null;
    }
  }

  /// Récupère les informations d'affichage de l'appareil
  Future<DisplayInfo?> _getDisplayInfo(String ip, int port) async {
    try {
      final response = await http.get(
        Uri.parse('http://$ip:$port/display/info'),
      ).timeout(const Duration(seconds: 3));
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return DisplayInfo(
          width: data['width'] ?? 1920,
          height: data['height'] ?? 1080,
          aspectRatio: (data['width'] ?? 1920) / (data['height'] ?? 1080),
          refreshRate: data['refreshRate'] ?? 60,
          hdrSupport: data['hdrSupport'] ?? false,
        );
      }
    } catch (e) {
      // Utilise des valeurs par défaut Full HD
    }
    
    return const DisplayInfo(
      width: 1920,
      height: 1080,
      aspectRatio: 16 / 9,
      refreshRate: 60,
    );
  }

  /// Obtient le sous-réseau local
  Future<String?> _getLocalSubnet() async {
    final interfaces = await NetworkInterface.list();
    for (final interface in interfaces) {
      for (final addr in interface.addresses) {
        if (addr.type == InternetAddressType.IPv4 && !addr.isLoopback) {
          final parts = addr.address.split('.');
          return '${parts[0]}.${parts[1]}.${parts[2]}';
        }
      }
    }

    return null;
  }

  void _addDevice(DiscoveredDevice device) {
    _discoveredDevices[device.id] = device;
    _deviceController.add(currentDevices);
  }

  Future<void> _refreshDevices() async {
    final devicesToCheck = List<DiscoveredDevice>.from(currentDevices);
    
    for (final device in devicesToCheck) {
      final isAvailable = await _checkDeviceAvailability(device);
      if (!isAvailable) {
        _discoveredDevices.remove(device.id);
      } else if (!device.isAvailable) {
        _discoveredDevices[device.id] = device.copyWith(isAvailable: true);
      }
    }
    
    _deviceController.add(currentDevices);
  }

  /// Vérifie la disponibilité d'un appareil
  Future<bool> _checkDeviceAvailability(DiscoveredDevice device) async {
    try {
      final socket = await Socket.connect(
        device.ipAddress,
        device.port,
        timeout: const Duration(seconds: 2),
      );
      socket.close();
      return true;
    } catch (e) {
      return false;
    }
  }

  void dispose() {
    stopDiscovery();
    _deviceController.close();
  }
}
