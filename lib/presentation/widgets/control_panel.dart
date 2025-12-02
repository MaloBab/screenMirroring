import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/connection_info.dart';
import '../bloc/mirroring/mirroring_bloc.dart';
import '../../core/theme/app_theme.dart';

class ControlPanel extends StatefulWidget {
  final MirroringState mirroringState;
  final ConnectionInfo? connectionInfo;

  const ControlPanel({
    super.key,
    required this.mirroringState,
    this.connectionInfo,
  });

  @override
  State<ControlPanel> createState() => _ControlPanelState();
}

class _ControlPanelState extends State<ControlPanel> {
  double _quality = 70;
  bool _showSettings = false;

  @override
  Widget build(BuildContext context) {
    final isActive = widget.mirroringState is MirroringActive;
    final isLoading = widget.mirroringState is MirroringLoading;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Text(
              'Panneau de contrôle',
              style: Theme.of(context).textTheme.displayMedium?.copyWith(
                    fontSize: 18,
                  ),
            ),
            const SizedBox(height: 24),
            
            // Bouton principal
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              child: ElevatedButton(
                onPressed: isLoading ? null : () => _toggleMirroring(context, isActive),
                style: ElevatedButton.styleFrom(
                  backgroundColor: isActive ? AppTheme.errorColor : AppTheme.primaryColor,
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
                            isActive ? 'Arrêter le mirroring' : 'Démarrer le mirroring',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
            
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
                style: TextStyle(color: AppTheme.secondaryColor),
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
        ),
      ),
    );
  }

  Widget _buildSettings(BuildContext context) {
    return Column(
      children: [
        const Divider(height: 32),
        Row(
          children: [
            Icon(Icons.high_quality, color: AppTheme.secondaryColor),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Qualité',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  Text(
                    '${_quality.round()}%',
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
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.primaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppTheme.primaryColor.withOpacity(0.3),
            ),
          ),
          child: Row(
            children: [
              Icon(
                Icons.info_outline,
                color: AppTheme.primaryColor,
                size: 20,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Une qualité plus élevée offre une meilleure image mais consomme plus de bande passante',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontSize: 12,
                      ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _toggleMirroring(BuildContext context, bool isActive) {
    if (isActive) {
      context.read<MirroringBloc>().add(StopMirroringEvent());
    } else {
      if (widget.connectionInfo == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Aucune information de connexion disponible'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
      
      context.read<MirroringBloc>().add(
            StartMirroringEvent(
              receiverAddress: widget.connectionInfo!.fullAddress,
              quality: _quality.round(),
            ),
          );
    }
  }
}