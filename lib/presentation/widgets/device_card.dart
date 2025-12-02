import 'package:flutter/material.dart';
import '../../domain/entities/discovered_device.dart';
import '../../core/theme/app_theme.dart';

class DeviceCard extends StatelessWidget {
  final DiscoveredDevice device;
  final VoidCallback onTap;

  const DeviceCard({
    super.key,
    required this.device,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 8,
      shadowColor: _getDeviceColor().withAlpha(30),
      child: InkWell(
        onTap: device.isAvailable ? onTap : null,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppTheme.surfaceColor,
                AppTheme.surfaceColor.withAlpha(80),
              ],
            ),
          ),
          child: Row(
            children: [
              _buildDeviceIcon(),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            device.name,
                            style: Theme.of(context).textTheme.displayMedium?.copyWith(
                                  fontSize: 18,
                                ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (!device.isAvailable)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.grey.withAlpha(20),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Text(
                              'Indisponible',
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.grey,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _getDeviceTypeLabel(),
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: _getDeviceColor(),
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    const SizedBox(height: 8),
                    _buildDeviceInfo(context),
                    if (device.displayInfo != null) ...[
                      const SizedBox(height: 8),
                      _buildDisplayInfo(context),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 12),
              _buildActionButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDeviceIcon() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _getDeviceColor().withAlpha(10),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _getDeviceColor().withAlpha(30),
          width: 2,
        ),
      ),
      child: Icon(
        _getDeviceIcon(),
        size: 32,
        color: _getDeviceColor(),
      ),
    );
  }

  Widget _buildDeviceInfo(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Ligne 1: IP address
        Row(
          children: [
            Icon(
              Icons.wifi,
              size: 16,
              color: _getSignalColor(),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                device.ipAddress,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontSize: 12,
                      color: Colors.white70,
                    ),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ),
          ],
        ),
        // Ligne 2: Badge compatible (si applicable)
        if (device.supportsScreenMirroring) ...[
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: AppTheme.successColor.withAlpha(20),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.check_circle,
                  size: 12,
                  color: AppTheme.successColor,
                ),
                SizedBox(width: 4),
                Text(
                  'Compatible',
                  style: TextStyle(
                    fontSize: 10,
                    color: AppTheme.successColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildDisplayInfo(BuildContext context) {
    final displayInfo = device.displayInfo!;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppTheme.primaryColor.withAlpha(10),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: AppTheme.primaryColor.withAlpha(20),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.aspect_ratio,
            size: 14,
            color: AppTheme.primaryColor,
          ),
          const SizedBox(width: 6),
          Text(
            displayInfo.resolution,
            style: const TextStyle(
              fontSize: 11,
              color: AppTheme.primaryColor,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (displayInfo.is4K) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: AppTheme.secondaryColor.withAlpha(20),
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Text(
                '4K',
                style: TextStyle(
                  fontSize: 9,
                  color: AppTheme.secondaryColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
          if (displayInfo.hdrSupport) ...[
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.amber.withAlpha(20),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                'HDR',
                style: TextStyle(
                  fontSize: 9,
                  color: Colors.amber[700],
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildActionButton() {
    if (!device.isAvailable) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.grey.withAlpha(10),
          shape: BoxShape.circle,
        ),
        child: const Icon(
          Icons.block,
          color: Colors.grey,
          size: 24,
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _getDeviceColor().withAlpha(20),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: _getDeviceColor().withAlpha(30),
            blurRadius: 8,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Icon(
        Icons.cast,
        color: _getDeviceColor(),
        size: 24,
      ),
    );
  }

  IconData _getDeviceIcon() {
    switch (device.type) {
      case DeviceType.tv:
        return Icons.tv;
      case DeviceType.chromecast:
        return Icons.cast_connected;
      case DeviceType.miracast:
        return Icons.screen_share;
      case DeviceType.dlna:
        return Icons.settings_input_antenna;
      case DeviceType.airplay:
        return Icons.airplay;
      default:
        return Icons.devices;
    }
  }

  String _getDeviceTypeLabel() {
    switch (device.type) {
      case DeviceType.tv:
        return 'Smart TV';
      case DeviceType.chromecast:
        return 'Chromecast';
      case DeviceType.miracast:
        return 'Miracast';
      case DeviceType.dlna:
        return 'DLNA';
      case DeviceType.airplay:
        return 'AirPlay';
      default:
        return 'Appareil inconnu';
    }
  }

  Color _getDeviceColor() {
    switch (device.type) {
      case DeviceType.chromecast:
        return AppTheme.primaryColor;
      case DeviceType.miracast:
        return AppTheme.secondaryColor;
      case DeviceType.dlna:
        return AppTheme.successColor;
      case DeviceType.tv:
        return Colors.purple;
      case DeviceType.airplay:
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  Color _getSignalColor() {
    if (device.signalStrength >= 0.8) {
      return AppTheme.successColor;
    } else if (device.signalStrength >= 0.5) {
      return Colors.orange;
    } else {
      return AppTheme.errorColor;
    }
  }
}