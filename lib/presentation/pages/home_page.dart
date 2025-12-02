import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../bloc/mirroring/mirroring_bloc.dart';
import '../widgets/animated_background.dart';
import '../widgets/control_panel.dart';
import '../widgets/stats_dashboard.dart';
import 'device_list_page.dart';
import '../../domain/entities/discovered_device.dart';
import '../../core/theme/app_theme.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  DiscoveredDevice? _selectedDevice;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          const AnimatedBackground(),
          SafeArea(
            child: BlocConsumer<MirroringBloc, MirroringState>(
              listener: (context, state) {
                if (state is MirroringError) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(state.message),
                      backgroundColor: Theme.of(context).colorScheme.error,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
                
                if (state is MirroringActive) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Row(
                        children: [
                          const Icon(Icons.check_circle, color: Colors.white),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Connecté à ${_selectedDevice?.name ?? "l'appareil"}',
                            ),
                          ),
                        ],
                      ),
                      backgroundColor: AppTheme.successColor,
                      behavior: SnackBarBehavior.floating,
                      duration: const Duration(seconds: 3),
                    ),
                  );
                }
              },
              builder: (context, mirroringState) {
                return CustomScrollView(
                  physics: const BouncingScrollPhysics(),
                  slivers: [
                    _buildAppBar(context, mirroringState),
                    SliverPadding(
                      padding: const EdgeInsets.all(20),
                      sliver: SliverList(
                        delegate: SliverChildListDelegate([
                          _buildHeader()
                              .animate()
                              .fadeIn(duration: 600.ms)
                              .slideY(begin: -0.2, end: 0),
                          const SizedBox(height: 30),
                          
                          if (_selectedDevice == null)
                            _buildDeviceSelectionCard(context)
                                .animate()
                                .fadeIn(delay: 200.ms, duration: 600.ms)
                                .slideX(begin: -0.2, end: 0)
                          else
                            _buildSelectedDeviceCard(context)
                                .animate()
                                .fadeIn(delay: 200.ms, duration: 600.ms)
                                .scale(begin: const Offset(0.9, 0.9)),
                          
                          const SizedBox(height: 20),
                          
                          if (_selectedDevice != null)
                            ControlPanel(
                              mirroringState: mirroringState,
                              selectedDevice: _selectedDevice,
                            )
                                .animate()
                                .fadeIn(delay: 400.ms, duration: 600.ms)
                                .slideX(begin: 0.2, end: 0),
                          
                          if (mirroringState is MirroringActive) ...[
                            const SizedBox(height: 20),
                            StatsDashboard(stats: mirroringState.stats)
                                .animate()
                                .fadeIn(delay: 600.ms, duration: 600.ms)
                                .scale(begin: const Offset(0.8, 0.8)),
                          ],
                          
                          const SizedBox(height: 20),
                          _buildInfoCard(context)
                              .animate()
                              .fadeIn(delay: 800.ms, duration: 600.ms),
                        ]),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppBar(BuildContext context, MirroringState state) {
    final isActive = state is MirroringActive;
    
    return SliverAppBar(
      expandedHeight: 100,
      floating: false,
      pinned: true,
      backgroundColor: Colors.transparent,
      flexibleSpace: FlexibleSpaceBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isActive ? Icons.cast_connected : Icons.cast,
              color: isActive ? AppTheme.successColor : AppTheme.primaryColor,
              size: 24,
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                'MirrorScreen Pro',
                style: Theme.of(context).textTheme.displayMedium?.copyWith(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        centerTitle: false,
        titlePadding: const EdgeInsets.only(left: 16, bottom: 16),
      ),
      actions: [
        if (isActive)
          Container(
            margin: const EdgeInsets.only(right: 8),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppTheme.successColor.withAlpha(20),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: AppTheme.successColor,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                const Text(
                  'En direct',
                  style: TextStyle(
                    color: AppTheme.successColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ).animate(onPlay: (controller) => controller.repeat())
              .fadeIn(duration: 1000.ms)
              .then()
              .fadeOut(duration: 1000.ms),
        IconButton(
          icon: const Icon(Icons.settings_outlined),
          onPressed: () {
            return;
          },
        ),
      ],
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Diffusez votre écran',
          style: Theme.of(context).textTheme.displayLarge,
        ),
        const SizedBox(height: 8),
        Text(
          'Sélectionnez un appareil et commencez le mirroring',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.white60,
              ),
        ),
      ],
    );
  }

  Widget _buildDeviceSelectionCard(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: () => _navigateToDeviceList(context),
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withAlpha(10),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.devices_other,
                  size: 48,
                  color: AppTheme.primaryColor,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Sélectionner un appareil',
                style: Theme.of(context).textTheme.displayMedium?.copyWith(
                      fontSize: 20,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                'Recherchez automatiquement les TV et appareils disponibles sur votre réseau',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.white60,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () => _navigateToDeviceList(context),
                icon: const Icon(Icons.search),
                label: const Text('Rechercher des appareils'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 16,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSelectedDeviceCard(BuildContext context) {
    if (_selectedDevice == null) return const SizedBox.shrink();
    
    return Card(
      child: Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.successColor.withAlpha(10),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: AppTheme.successColor.withAlpha(30),
                      width: 2,
                    ),
                  ),
                  child: Icon(
                    _getDeviceIcon(_selectedDevice!.type),
                    size: 32,
                    color: AppTheme.successColor,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Appareil sélectionné',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Colors.white60,
                              fontSize: 12,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _selectedDevice!.name,
                        style: Theme.of(context).textTheme.displayMedium?.copyWith(
                              fontSize: 18,
                            ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () {
                    setState(() {
                      _selectedDevice = null;
                    });
                  },
                ),
              ],
            ),
            const Divider(height: 32),
            _buildDeviceDetails(),
          ],
        ),
      ),
    );
  }

  Widget _buildDeviceDetails() {
    if (_selectedDevice == null) return const SizedBox.shrink();
    
    return Column(
      children: [
        _buildDetailRow(
          icon: Icons.router,
          label: 'Adresse IP',
          value: _selectedDevice!.ipAddress,
        ),
        const SizedBox(height: 12),
        _buildDetailRow(
          icon: Icons.cast_connected,
          label: 'Type',
          value: _getDeviceTypeLabel(_selectedDevice!.type),
        ),
        if (_selectedDevice!.displayInfo != null) ...[
          const SizedBox(height: 12),
          _buildDetailRow(
            icon: Icons.aspect_ratio,
            label: 'Résolution',
            value: _selectedDevice!.displayInfo!.resolution,
          ),
        ],
      ],
    );
  }

  Widget _buildDetailRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppTheme.secondaryColor),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontSize: 11,
                      color: Colors.white54,
                    ),
              ),
              Text(
                value,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInfoCard(BuildContext context) {
    return Card(
      color: AppTheme.primaryColor.withAlpha(10),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.info_outline,
                  color: AppTheme.primaryColor,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Text(
                  'Conseils d\'utilisation',
                  style: Theme.of(context).textTheme.displayMedium?.copyWith(
                        fontSize: 16,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildTip('Assurez-vous d\'être sur le même réseau WiFi que votre TV'),
            const SizedBox(height: 8),
            _buildTip('La qualité du streaming dépend de votre connexion WiFi'),
            const SizedBox(height: 8),
            _buildTip('Certaines applications peuvent bloquer la capture d\'écran'),
          ],
        ),
      ),
    );
  }

  Widget _buildTip(String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          margin: const EdgeInsets.only(top: 4),
          width: 6,
          height: 6,
          decoration: const BoxDecoration(
            color: AppTheme.primaryColor,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.white70,
                  fontSize: 13,
                ),
          ),
        ),
      ],
    );
  }

  IconData _getDeviceIcon(DeviceType type) {
    switch (type) {
      case DeviceType.tv:
        return Icons.tv;
      case DeviceType.chromecast:
        return Icons.cast_connected;
      case DeviceType.miracast:
        return Icons.screen_share;
      case DeviceType.dlna:
        return Icons.settings_input_antenna;
      default:
        return Icons.devices;
    }
  }

  String _getDeviceTypeLabel(DeviceType type) {
    switch (type) {
      case DeviceType.tv:
        return 'Smart TV';
      case DeviceType.chromecast:
        return 'Chromecast';
      case DeviceType.miracast:
        return 'Miracast';
      case DeviceType.dlna:
        return 'DLNA';
      default:
        return 'Appareil inconnu';
    }
  }

  Future<void> _navigateToDeviceList(BuildContext context) async {
    final device = await Navigator.push<DiscoveredDevice>(
      context,
      MaterialPageRoute(
        builder: (context) => const DeviceListPage(),
      ),
    );
    
    if (device != null) {
      setState(() {
        _selectedDevice = device;
      });
    }
  }
}