import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../../domain/entities/connection_info.dart';
import '../../../../domain/usecases/start_mirroring.dart' as start_mirroring;
import '../../../domain/usecases/stop_mirroring.dart' as stop_mirroring;

// Events
abstract class MirroringEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class StartMirroringEvent extends MirroringEvent {
  final String receiverAddress;
  final int quality;

  StartMirroringEvent({
    required this.receiverAddress,
    this.quality = 70,
  });

  @override
  List<Object?> get props => [receiverAddress, quality];
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
  final String receiverAddress;

  MirroringActive({
    required this.stats,
    required this.receiverAddress,
  });

  @override
  List<Object?> get props => [stats, receiverAddress];
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
  final start_mirroring.StartMirroring startMirroring;
  final stop_mirroring.StopMirroring stopMirroring;
  
  StreamSubscription? _statsSubscription;

  MirroringBloc({
    required this.startMirroring,
    required this.stopMirroring,
  }) : super(MirroringInitial()) {
    on<StartMirroringEvent>(_onStartMirroring);
    on<StopMirroringEvent>(_onStopMirroring);
    on<UpdateStatsEvent>(_onUpdateStats);
  }

  Future<void> _onStartMirroring(
    StartMirroringEvent event,
    Emitter<MirroringState> emit,
  ) async {
    emit(MirroringLoading());
    
    final result = await startMirroring(
      receiverAddress: event.receiverAddress,
      quality: event.quality,
    );
    
    result.fold(
      (failure) => emit(MirroringError(failure.message)),
      (statsStream) {
        _statsSubscription = statsStream.listen((stats) {
          add(UpdateStatsEvent(stats));
        });
        
        emit(MirroringActive(
          stats: const MirroringStats(
            framesPerSecond: 0,
            bitrate: 0,
            duration: Duration.zero,
            totalFrames: 0,
          ),
          receiverAddress: event.receiverAddress,
        ));
      },
    );
  }

  Future<void> _onStopMirroring(
    StopMirroringEvent event,
    Emitter<MirroringState> emit,
  ) async {
    await _statsSubscription?.cancel();
    _statsSubscription = null;
    
    final result = await stopMirroring();
    
    result.fold(
      (failure) => emit(MirroringError(failure.message)),
      (_) => emit(MirroringStopped()),
    );
  }

  void _onUpdateStats(
    UpdateStatsEvent event,
    Emitter<MirroringState> emit,
  ) {
    if (state is MirroringActive) {
      final currentState = state as MirroringActive;
      emit(MirroringActive(
        stats: event.stats,
        receiverAddress: currentState.receiverAddress,
      ));
    }
  }

  @override
  Future<void> close() {
    _statsSubscription?.cancel();
    return super.close();
  }
}