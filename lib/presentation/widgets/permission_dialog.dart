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
              'Capture d\'écran requise',
              style: Theme.of(context).textTheme.displayMedium?.copyWith(
                    fontSize: 22,
                  ),
              textAlign: TextAlign.center,
            ),
            
            const SizedBox(height: 16),
            
            Text(
              'MirrorScreen va capturer votre écran pour le diffuser sur votre TV.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.white70,
                  ),
              textAlign: TextAlign.center,
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
              child: Column(
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.info_outline,
                        color: Colors.amber,
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'À la prochaine étape',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                fontSize: 13,
                                color: Colors.amber,
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Android affichera une popup système pour confirmer la capture d\'écran. Vous devez accepter cette autorisation pour que le mirroring fonctionne.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontSize: 12,
                          color: Colors.amber.shade300,
                        ),
                    textAlign: TextAlign.left,
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
                      child: const Text('Annuler'),
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
                    child: const Text('Continuer'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}