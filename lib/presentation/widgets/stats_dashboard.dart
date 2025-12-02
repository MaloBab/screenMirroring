import 'package:flutter/material.dart';
import '../../core/services/mirroring_service.dart';
import '../../core/theme/app_theme.dart';

class StatsDashboard extends StatelessWidget {
  final MirroringStats stats;

  const StatsDashboard({
    super.key,
    required this.stats,
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
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppTheme.successColor.withAlpha(10),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.analytics_outlined,
                    color: AppTheme.successColor,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Statistiques en direct',
                        style: Theme.of(context).textTheme.displayMedium?.copyWith(
                              fontSize: 18,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Qualité: ${stats.quality.toStringAsFixed(1)}%',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: _getQualityColor(stats.quality),
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
              childAspectRatio: 1.5,
              children: [
                _buildStatCard(
                  context,
                  icon: Icons.speed,
                  label: 'FPS',
                  value: '${stats.framesPerSecond}',
                  color: AppTheme.primaryColor,
                ),
                _buildStatCard(
                  context,
                  icon: Icons.data_usage,
                  label: 'Débit',
                  value: '${stats.bitrate.toStringAsFixed(1)} Mbps',
                  color: AppTheme.secondaryColor,
                ),
                _buildStatCard(
                  context,
                  icon: Icons.timer_outlined,
                  label: 'Durée',
                  value: _formatDuration(stats.duration),
                  color: AppTheme.successColor,
                ),
                _buildStatCard(
                  context,
                  icon: Icons.photo_library_outlined,
                  label: 'Images',
                  value: _formatNumber(stats.totalFrames),
                  color: Colors.purple,
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildAdditionalStats(context),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            color.withAlpha(10),
            color.withAlpha(5),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color.withAlpha(30),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 24),
              const Spacer(),
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: color.withAlpha(20),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.trending_up, color: color, size: 16),
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: Theme.of(context).textTheme.displayMedium?.copyWith(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontSize: 12,
                      color: Colors.white60,
                    ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAdditionalStats(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor.withAlpha(50),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildMiniStat(
            context,
            icon: Icons.aspect_ratio,
            label: 'Résolution',
            value: stats.resolution,
          ),
          Container(width: 1, height: 40, color: Colors.white24),
          _buildMiniStat(
            context,
            icon: Icons.network_check,
            label: 'Latence',
            value: '${stats.averageLatency}ms',
          ),
          Container(width: 1, height: 40, color: Colors.white24),
          _buildMiniStat(
            context,
            icon: Icons.warning_amber_outlined,
            label: 'Perdues',
            value: '${stats.droppedFrames}',
          ),
        ],
      ),
    );
  }

  Widget _buildMiniStat(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Column(
      children: [
        Icon(icon, size: 20, color: AppTheme.secondaryColor),
        const SizedBox(height: 6),
        Text(
          value,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontSize: 10,
                color: Colors.white54,
              ),
        ),
      ],
    );
  }

  Color _getQualityColor(double quality) {
    if (quality >= 80) return AppTheme.successColor;
    if (quality >= 60) return Colors.orange;
    return AppTheme.errorColor;
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;
    final seconds = duration.inSeconds % 60;
    
    if (hours > 0) {
      return '${hours}h ${minutes}m';
    } else if (minutes > 0) {
      return '${minutes}m ${seconds}s';
    } else {
      return '${seconds}s';
    }
  }

  String _formatNumber(int number) {
    if (number >= 1000000) {
      return '${(number / 1000000).toStringAsFixed(1)}M';
    } else if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(1)}K';
    }
    return number.toString();
  }
}