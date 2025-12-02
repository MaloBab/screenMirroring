import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/discovered_device.dart';
import '../bloc/mirroring/mirroring_bloc.dart';
import '../../core/theme/app_theme.dart';

class ControlPanel extends StatefulWidget {
  final MirroringState mirroringState;
  final DiscoveredDevice? selectedDevice;

  const ControlPanel({
    super.key,
    required this.mirroringState,
    this.selectedDevice,
  });

  @override
  State<ControlPanel> createState() => _ControlPanelState();
}

class _ControlPanelState extends State<ControlPanel> {
  double _quality = 70;
  bool _showSettings = false;
  bool _adaptiveQuality = true;

  @override
  Widget build(BuildContext context) {
    final isActive = widget.mirroringState is MirroringActive;
    final isLoading = widget.mirroringState is MirroringLoading;
    final hasDevice = widget.selectedDevice != null;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Row(
              children: [
                const Icon(
                  Icons.tune,
                  color: AppTheme.secondaryColor,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Text(
                  'Panneau de contrôle',
                  style: Theme.of(context).textTheme.displayMedium?.copyWith(
                        fontSize: 18,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            
            // Bouton principal
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              child: ElevatedButton(
                onPressed: (isLoading || !hasDevice)
                    ? null
                    : () => _toggleMirroring(context, isActive),
                style: ElevatedButton.styleFrom(
                  backgroundColor: isActive ? AppTheme.errorColor : AppTheme.primaryColor,
                  disabledBackgroundColor: Colors.grey.shade800,
                  minimumSize: const Size(double.infinity, 64),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                child: isLoading
                    ? const SizedBox(
                        height: 24,
                        width: 24,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            isActive ? Icons.stop : Icons.play_arrow,
                            size: 32,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            !hasDevice
                                ? 'Sélectionnez un appareil'
                                : (isActive
                                    ? 'Arrêter le mirroring'
                                    : 'Démarrer le mirroring'),
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
            
            if (hasDevice && !isActive) ...[
              const SizedBox(height: 16),
              
              // Recommandations basées sur l'appareil
              _buildDeviceRecommendations(context),
              
              const SizedBox(height: 16),
              
              // Bouton des paramètres
              TextButton.icon(
                onPressed: () {
                  setState(() {
                    _showSettings = !_showSettings;
                  });
                },
                icon: Icon(
                  _showSettings ? Icons.expand_less : Icons.tune,
                  color: AppTheme.secondaryColor,
                ),
                label: Text(
                  _showSettings ? 'Masquer les paramètres' : 'Paramètres avancés',
                  style: const TextStyle(color: AppTheme.secondaryColor),
                ),
              ),
              
              // Paramètres
              AnimatedCrossFade(
                firstChild: const SizedBox.shrink(),
                secondChild: _buildSettings(context),
                crossFadeState: _showSettings
                    ? CrossFadeState.showSecond
                    : CrossFadeState.showFirst,
                duration: const Duration(milliseconds: 300),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDeviceRecommendations(BuildContext context) {
    if (widget.selectedDevice == null) return const SizedBox.shrink();
    
    final device = widget.selectedDevice!;
    final displayInfo = device.displayInfo;
    
    String recommendation = '';
    Color color = AppTheme.primaryColor;
    IconData icon = Icons.info_outline;
    
    if (displayInfo != null) {
      if (displayInfo.is4K) {
        recommendation = 'Appareil 4K détecté - Qualité maximale recommandée';
        color = AppTheme.successColor;
        icon = Icons.signal_wifi_4_bar_outlined;
        _quality = 90;
      } else if (displayInfo.isFullHD) {
        recommendation = 'Appareil Full HD - Qualité élevée recommandée';
        color = AppTheme.primaryColor;
        icon = Icons.hd;
        _quality = 75;
      } else {
        recommendation = 'Qualité standard recommandée pour cet appareil';
        color = AppTheme.secondaryColor;
        icon = Icons.sd;
        _quality = 60;
      }
    }
    
    if (recommendation.isNotEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withAlpha(10),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: color.withAlpha(30),
          ),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                recommendation,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontSize: 12,
                      color: color,
                    ),
              ),
            ),
          ],
        ),
      );
    }
    
    return const SizedBox.shrink();
  }

  Widget _buildSettings(BuildContext context) {
    return Column(
      children: [
        const Divider(height: 32),
        
        // Qualité adaptative
        SwitchListTile(
          title: Text(
            'Qualité adaptative',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
          subtitle: Text(
            'Ajuste automatiquement la qualité selon la connexion',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontSize: 12,
                  color: Colors.white54,
                ),
          ),
          value: _adaptiveQuality,
          activeThumbColor: AppTheme.primaryColor,
          onChanged: (value) {
            setState(() {
              _adaptiveQuality = value;
            });
          },
          contentPadding: EdgeInsets.zero,
        ),
        
        const SizedBox(height: 16),
        
        // Contrôle manuel de la qualité
        AnimatedOpacity(
          opacity: _adaptiveQuality ? 0.5 : 1.0,
          duration: const Duration(milliseconds: 200),
          child: AbsorbPointer(
            absorbing: _adaptiveQuality,
            child: Column(
              children: [
                Row(
                  children: [
                    const Icon(Icons.high_quality, color: AppTheme.secondaryColor),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Qualité manuelle',
                            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                          Text(
                            '${_quality.round()}% - ${_getQualityLabel()}',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: Colors.white54,
                                ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                Slider(
                  value: _quality,
                  min: 10,
                  max: 100,
                  divisions: 9,
                  activeColor: AppTheme.primaryColor,
                  inactiveColor: AppTheme.surfaceColor,
                  label: '${_quality.round()}%',
                  onChanged: (value) {
                    setState(() {
                      _quality = value;
                    });
                  },
                ),
              ],
            ),
          ),
        ),
        
        const SizedBox(height: 16),
        
        // Informations de performance
        _buildPerformanceInfo(context),
      ],
    );
  }

  Widget _buildPerformanceInfo(BuildContext context) {
    final device = widget.selectedDevice;
    if (device == null) return const SizedBox.shrink();
    
    final fps = _estimateFPS(device);
    final bitrate = _estimateBitrate(device);
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.primaryColor.withAlpha(10),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppTheme.primaryColor.withAlpha(30),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.speed,
                color: AppTheme.primaryColor,
                size: 18,
              ),
              const SizedBox(width: 8),
              Text(
                'Performance estimée',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildPerformanceStat(
                context,
                icon: Icons.video_settings,
                label: 'FPS',
                value: '$fps',
              ),
              Container(width: 1, height: 30, color: Colors.white24),
              _buildPerformanceStat(
                context,
                icon: Icons.network_check,
                label: 'Débit',
                value: '${bitrate.toStringAsFixed(1)} Mbps',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPerformanceStat(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Column(
      children: [
        Icon(icon, size: 16, color: AppTheme.secondaryColor),
        const SizedBox(height: 4),
        Text(
          value,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppTheme.secondaryColor,
              ),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontSize: 11,
                color: Colors.white54,
              ),
        ),
      ],
    );
  }

  String _getQualityLabel() {
    if (_quality >= 85) return 'Excellente';
    if (_quality >= 70) return 'Élevée';
    if (_quality >= 50) return 'Moyenne';
    if (_quality >= 30) return 'Basse';
    return 'Minimale';
  }

  int _estimateFPS(DiscoveredDevice device) {
    final displayInfo = device.displayInfo;
    if (displayInfo == null) return 30;
    
    if (displayInfo.is4K && _quality > 80) return 60;
    if (displayInfo.isFullHD) return 30;
    return 24;
  }

  double _estimateBitrate(DiscoveredDevice device) {
    final displayInfo = device.displayInfo;
    if (displayInfo == null) return 5.0;
    
    final pixels = displayInfo.width * displayInfo.height;
    final fps = _estimateFPS(device);
    final qualityFactor = _quality / 100;
    
    return (pixels * fps * qualityFactor * 0.3) / 1000000;
  }

  void _toggleMirroring(BuildContext context, bool isActive) {
    if (isActive) {
      context.read<MirroringBloc>().add(StopMirroringEvent());
    } else {
      if (widget.selectedDevice == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Veuillez sélectionner un appareil'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
        return;
      }
      
      context.read<MirroringBloc>().add(
            StartMirroringEvent(
              device: widget.selectedDevice!,
              quality: _quality.round(),
              adaptiveQuality: _adaptiveQuality,
            ),
          );
    }
  }
}