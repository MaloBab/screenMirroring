import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:shimmer/shimmer.dart';
import '../../domain/entities/discovered_device.dart';
import '../bloc/device_discovery/device_discovery_bloc.dart';
import '../widgets/device_card.dart';
import '../widgets/animated_background.dart';
import '../../core/theme/app_theme.dart';

class DeviceListPage extends StatefulWidget {
  const DeviceListPage({super.key});

  @override
  State<DeviceListPage> createState() => _DeviceListPageState();
}

class _DeviceListPageState extends State<DeviceListPage> {
  @override
  void initState() {
    super.initState();
    // Démarre la découverte automatiquement
    context.read<DeviceDiscoveryBloc>().add(StartDeviceDiscovery());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          const AnimatedBackground(),
          SafeArea(
            child: Column(
              children: [
                _buildAppBar(context),
                Expanded(
                  child: BlocConsumer<DeviceDiscoveryBloc, DeviceDiscoveryState>(
                    listener: (context, state) {
                      if (state is DeviceDiscoveryError) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(state.message),
                            backgroundColor: AppTheme.errorColor,
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      }
                    },
                    builder: (context, state) {
                      if (state is DeviceDiscoveryLoading) {
                        return _buildLoadingState();
                      }
                      
                      if (state is DeviceDiscoverySuccess) {
                        if (state.devices.isEmpty) {
                          return _buildEmptyState(context);
                        }
                        return _buildDeviceList(context, state.devices);
                      }
                      
                      return _buildEmptyState(context);
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppBar(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, size: 28),
            onPressed: () => Navigator.pop(context),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Appareils disponibles',
                  style: Theme.of(context).textTheme.displayMedium,
                ),
                const SizedBox(height: 4),
                BlocBuilder<DeviceDiscoveryBloc, DeviceDiscoveryState>(
                  builder: (context, state) {
                    if (state is DeviceDiscoverySuccess) {
                      return Text(
                        '${state.devices.length} appareil${state.devices.length > 1 ? 's' : ''} trouvé${state.devices.length > 1 ? 's' : ''}',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: AppTheme.secondaryColor,
                            ),
                      );
                    }
                    return Text(
                      'Recherche en cours...',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.white60,
                          ),
                    );
                  },
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.refresh, size: 28),
            onPressed: () {
              context.read<DeviceDiscoveryBloc>().add(RefreshDevices());
            },
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms).slideY(begin: -0.2, end: 0);
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: AppTheme.surfaceColor,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppTheme.primaryColor.withAlpha(30),
                  blurRadius: 30,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: const CircularProgressIndicator(
              strokeWidth: 3,
              valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
            ),
          ),
          const SizedBox(height: 32),
          Text(
            'Recherche des appareils...',
            style: Theme.of(context).textTheme.displayMedium,
          ),
          const SizedBox(height: 12),
          Text(
            'Assurez-vous que votre TV est allumée',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.white60,
                ),
          ),
          const SizedBox(height: 40),
          _buildShimmerCards(),
        ],
      ).animate().fadeIn(duration: 600.ms),
    );
  }

  Widget _buildShimmerCards() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: List.generate(3, (index) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Shimmer.fromColors(
              baseColor: AppTheme.surfaceColor,
              highlightColor: AppTheme.surfaceColor.withAlpha(50),
              child: Container(
                height: 120,
                decoration: BoxDecoration(
                  color: AppTheme.surfaceColor,
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
            ),
          );
        }).animate(interval: 200.ms).fadeIn().slideX(begin: -0.1, end: 0),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(40),
              decoration: BoxDecoration(
                color: AppTheme.surfaceColor,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.errorColor.withAlpha(20),
                    blurRadius: 30,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: Icon(
                Icons.devices_other,
                size: 80,
                color: AppTheme.errorColor.withAlpha(70),
              ),
            ),
            const SizedBox(height: 32),
            Text(
              'Aucun appareil trouvé',
              style: Theme.of(context).textTheme.displayMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              'Assurez-vous que votre TV ou décodeur est:\n'
              '• Allumé et connecté au même WiFi\n'
              '• Compatible avec le mirroring\n'
              '• À portée du réseau',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.white60,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 40),
            ElevatedButton.icon(
              onPressed: () {
                context.read<DeviceDiscoveryBloc>().add(StartDeviceDiscovery());
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Rechercher à nouveau'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
              ),
            ),
          ],
        ),
      ).animate().fadeIn(duration: 600.ms).scale(begin: const Offset(0.9, 0.9)),
    );
  }

  Widget _buildDeviceList(BuildContext context, List<DiscoveredDevice> devices) {
    // Trie les appareils par type et signal
    final sortedDevices = List<DiscoveredDevice>.from(devices)
      ..sort((a, b) {
        // Priorité aux appareils compatibles screen mirroring
        if (a.supportsScreenMirroring != b.supportsScreenMirroring) {
          return a.supportsScreenMirroring ? -1 : 1;
        }
        // Puis par type d'appareil
        if (a.type != b.type) {
          return _getDeviceTypePriority(a.type).compareTo(_getDeviceTypePriority(b.type));
        }
        // Enfin par force du signal
        return b.signalStrength.compareTo(a.signalStrength);
      });

    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.all(20),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final device = sortedDevices[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: DeviceCard(
                    device: device,
                    onTap: () => _connectToDevice(context, device),
                  ),
                ).animate(delay: (index * 100).ms).fadeIn(duration: 400.ms).slideX(begin: -0.2, end: 0);
              },
              childCount: sortedDevices.length,
            ),
          ),
        ),
      ],
    );
  }

  int _getDeviceTypePriority(DeviceType type) {
    switch (type) {
      case DeviceType.chromecast:
        return 0;
      case DeviceType.miracast:
        return 1;
      case DeviceType.dlna:
        return 2;
      case DeviceType.tv:
        return 3;
      case DeviceType.airplay:
        return 4;
      default:
        return 5;
    }
  }

  void _connectToDevice(BuildContext context, DiscoveredDevice device) {
    // Vérifie la compatibilité
    if (!device.supportsScreenMirroring) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cet appareil ne supporte pas le screen mirroring'),
          backgroundColor: AppTheme.errorColor,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    // Navigation vers la page de mirroring avec l'appareil sélectionné
    Navigator.pop(context, device);
  }
}