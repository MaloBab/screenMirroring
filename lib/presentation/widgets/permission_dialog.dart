// lib/presentation/widgets/permission_dialog.dart
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/theme/app_theme.dart';

class PermissionDialog extends StatelessWidget {
  final VoidCallback onAccept;
  final VoidCallback onDeny;
  final bool isRequired;

  const PermissionDialog({
    super.key,
    required this.onAccept,
    required this.onDeny,
    this.isRequired = true,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
      ),
      backgroundColor: AppTheme.surfaceColor,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.screen_share,
                size: 64,
                color: AppTheme.primaryColor,
              ),
            )
                .animate(onPlay: (controller) => controller.repeat(reverse: true))
                .scale(
                  duration: 1500.ms,
                  begin: const Offset(1.0, 1.0),
                  end: const Offset(1.1, 1.1),
                ),
            
            const SizedBox(height: 24),
            
            Text(
              'Autorisation requise',
              style: Theme.of(context).textTheme.displayMedium?.copyWith(
                    fontSize: 22,
                  ),
              textAlign: TextAlign.center,
            ),
            
            const SizedBox(height: 16),
            
            Text(
              'MirrorScreen Pro a besoin de capturer votre écran pour le diffuser sur votre TV.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.white70,
                  ),
              textAlign: TextAlign.center,
            ),
            
            const SizedBox(height: 24),
            
            _buildPermissionItem(
              context,
              icon: Icons.cast_connected,
              title: 'Capture d\'écran',
              description: 'Pour diffuser votre contenu',
            ),
            
            const SizedBox(height: 12),
            
            _buildPermissionItem(
              context,
              icon: Icons.notifications_active,
              title: 'Notifications',
              description: 'Pour le service en arrière-plan',
            ),
            
            const SizedBox(height: 24),
            
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.amber.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.amber.withOpacity(0.3),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.info_outline,
                    color: Colors.amber,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Android affichera une popup système pour confirmer',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontSize: 12,
                            color: Colors.amber,
                          ),
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            
            Row(
              children: [
                if (!isRequired)
                  Expanded(
                    child: OutlinedButton(
                      onPressed: onDeny,
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        side: const BorderSide(color: Colors.white24),
                      ),
                      child: const Text('Plus tard'),
                    ),
                  ),
                if (!isRequired) const SizedBox(width: 12),
                Expanded(
                  flex: isRequired ? 1 : 1,
                  child: ElevatedButton(
                    onPressed: onAccept,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('Autoriser'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPermissionItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.backgroundColor.withOpacity(0.5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppTheme.secondaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: AppTheme.secondaryColor,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
                Text(
                  description,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontSize: 12,
                        color: Colors.white60,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}