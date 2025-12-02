import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../domain/entities/connection_info.dart';
import '../../core/theme/app_theme.dart';

class ConnectionCard extends StatelessWidget {
  final ConnectionInfo connectionInfo;

  const ConnectionCard({
    super.key,
    required this.connectionInfo,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withAlpha(10),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.wifi,
                    color: AppTheme.primaryColor,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Informations de connexion',
                        style: Theme.of(context).textTheme.displayMedium?.copyWith(
                              fontSize: 18,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        connectionInfo.deviceName,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
                _buildStatusBadge(context),
              ],
            ),
            const Divider(height: 32),
            _buildInfoRow(
              context,
              icon: Icons.computer,
              label: 'Adresse IP',
              value: connectionInfo.ipAddress,
            ),
            const SizedBox(height: 12),
            _buildInfoRow(
              context,
              icon: Icons.router,
              label: 'Port',
              value: connectionInfo.port.toString(),
            ),
            const SizedBox(height: 12),
            _buildInfoRow(
              context,
              icon: Icons.link,
              label: 'URL Complète',
              value: connectionInfo.fullAddress,
              copyable: true,
            ),
            const SizedBox(height: 24),
            Center(
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: QrImageView(
                  data: connectionInfo.fullAddress,
                  version: QrVersions.auto,
                  size: 200,
                  backgroundColor: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Center(
              child: Text(
                'Scannez ce QR code depuis votre TV',
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge(BuildContext context) {
    final color = connectionInfo.status == ConnectionStatus.connected
        ? AppTheme.successColor
        : Colors.grey;
    
    final text = connectionInfo.status == ConnectionStatus.connected
        ? 'Connecté'
        : 'Déconnecté';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withAlpha(10),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            text,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
    bool copyable = false,
  }) {
    return Row(
      children: [
        Icon(icon, size: 20, color: AppTheme.secondaryColor),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontSize: 12,
                      color: Colors.white54,
                    ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
              ),
            ],
          ),
        ),
        if (copyable)
          IconButton(
            icon: const Icon(Icons.copy, size: 20),
            onPressed: () {
              Clipboard.setData(ClipboardData(text: value));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Copié dans le presse-papier'),
                  duration: Duration(seconds: 2),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
          ),
      ],
    );
  }
}