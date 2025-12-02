import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../bloc/mirroring/mirroring_bloc.dart';
import '../bloc/connection/connection_bloc.dart' as conn;
import '../widgets/connection_card.dart';
import '../widgets/control_panel.dart';
import '../widgets/stats_dashboard.dart';
import '../widgets/animated_background.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          const AnimatedBackground(),
          SafeArea(
            child: BlocBuilder<conn.ConnectionBloc, conn.ConnectionState>(
              builder: (context, connectionState) {
                return BlocConsumer<MirroringBloc, MirroringState>(
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
                  },
                  builder: (context, mirroringState) {
                    return CustomScrollView(
                      physics: const BouncingScrollPhysics(),
                      slivers: [
                        _buildAppBar(context),
                        SliverPadding(
                          padding: const EdgeInsets.all(20),
                          sliver: SliverList(
                            delegate: SliverChildListDelegate([
                              _buildHeader()
                                  .animate()
                                  .fadeIn(duration: 600.ms)
                                  .slideY(begin: -0.2, end: 0),
                              const SizedBox(height: 30),
                              
                              if (connectionState is conn.ConnectionReady)
                                ConnectionCard(
                                  connectionInfo: connectionState.connectionInfo,
                                )
                                    .animate()
                                    .fadeIn(delay: 200.ms, duration: 600.ms)
                                    .slideX(begin: -0.2, end: 0),
                              
                              const SizedBox(height: 20),
                              
                              ControlPanel(
                                mirroringState: mirroringState,
                                connectionInfo: connectionState is conn.ConnectionReady
                                    ? connectionState.connectionInfo
                                    : null,
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
                            ]),
                          ),
                        ),
                      ],
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppBar(BuildContext context) {
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
              Icons.cast_connected,
              color: Theme.of(context).primaryColor,
              size: 28,
            ),
            const SizedBox(width: 12),
            Text(
              'MirrorScreen Pro',
              style: Theme.of(context).textTheme.displayMedium?.copyWith(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ],
        ),
        centerTitle: false,
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh),
          onPressed: () {
            context.read<conn.ConnectionBloc>().add(conn.RefreshConnectionInfo());
          },
        ),
        IconButton(
          icon: const Icon(Icons.settings_outlined),
          onPressed: () {
            // TODO: Navigate to settings
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
          'Connectez votre téléphone à une TV via WiFi',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.white60,
              ),
        ),
      ],
    );
  }
}