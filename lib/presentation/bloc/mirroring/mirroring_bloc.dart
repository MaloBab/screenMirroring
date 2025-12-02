import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../domain/entities/discovered_device.dart';
import '../../../core/services/mirroring_service.dart';

// Events
abstract class MirroringEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class StartMirroringEvent extends MirroringEvent {
  final DiscoveredDevice device;
  final int quality;
  final bool adaptiveQuality;

  StartMirroringEvent({
    required this.device,
    this.quality = 70,
    this.adaptiveQuality = true,
  });

  @override
  List<Object?> get props => [device, quality, adaptiveQuality];
}

class StopMirroringEvent extends MirroringEvent {}

class UpdateStatsEvent extends MirroringEvent {
  final MirroringStats stats;

  UpdateStatsEvent(this.stats);

  @override
  List<Object?> get props => [stats];
}

// States
abstract class MirroringState extends Equatable {
  @override
  List<Object?> get props => [];
}

class MirroringInitial extends MirroringState {}

class MirroringLoading extends MirroringState {}

class MirroringActive extends MirroringState {
  final MirroringStats stats;
  final DiscoveredDevice device;

  MirroringActive({
    required this.stats,
    required this.device,
  });

  @override
  List<Object?> get props => [stats, device];
}

class MirroringStopped extends MirroringState {}

class MirroringError extends MirroringState {
  final String message;

  MirroringError(this.message);

  @override
  List<Object?> get props => [message];
}

// Bloc
class MirroringBloc extends Bloc<MirroringEvent, MirroringState> {
  final MirroringService _mirroringService;
  StreamSubscription? _statsSubscription;

  MirroringBloc(this._mirroringService) : super(MirroringInitial()) {
    on<StartMirroringEvent>(_onStartMirroring);
    on<StopMirroringEvent>(_onStopMirroring);
    on<UpdateStatsEvent>(_onUpdateStats);
  }

  Future<void> _onStartMirroring(
    StartMirroringEvent event,
    Emitter<MirroringState> emit,
  ) async {
    emit(MirroringLoading());
    
    try {
      // Démarre le service de mirroring
      await _mirroringService.startMirroring(
        device: event.device,
        quality: event.quality,
      );
      
      // Écoute les statistiques
      _statsSubscription = _mirroringService.statsStream.listen((stats) {
        add(UpdateStatsEvent(stats));
      });
      
      // Émet l'état initial actif
      emit(MirroringActive(
        stats: const MirroringStats(
          framesPerSecond: 0,
          bitrate: 0,
          duration: Duration.zero,
          totalFrames: 0,
          droppedFrames: 0,
          averageLatency: 0,
          resolution: '0x0',
        ),
        device: event.device,
      ));
    } catch (e) {
      emit(MirroringError('Erreur lors du démarrage: $e'));
    }
  }

  Future<void> _onStopMirroring(
    StopMirroringEvent event,
    Emitter<MirroringState> emit,
  ) async {
    try {
      await _statsSubscription?.cancel();
      _statsSubscription = null;
      
      await _mirroringService.stopMirroring();
      
      emit(MirroringStopped());
    } catch (e) {
      emit(MirroringError('Erreur lors de l\'arrêt: $e'));
    }
  }

  void _onUpdateStats(
    UpdateStatsEvent event,
    Emitter<MirroringState> emit,
  ) {
    if (state is MirroringActive) {
      final currentState = state as MirroringActive;
      emit(MirroringActive(
        stats: event.stats,
        device: currentState.device,
      ));
    }
  }

  @override
  Future<void> close() {
    _statsSubscription?.cancel();
    _mirroringService.dispose();
    return super.close();
  }
}