import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../domain/entities/discovered_device.dart';
import '../../../core/services/device_discovery_service.dart';

// Events
abstract class DeviceDiscoveryEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class StartDeviceDiscovery extends DeviceDiscoveryEvent {}

class StopDeviceDiscovery extends DeviceDiscoveryEvent {}

class RefreshDevices extends DeviceDiscoveryEvent {}

class DevicesUpdated extends DeviceDiscoveryEvent {
  final List<DiscoveredDevice> devices;

  DevicesUpdated(this.devices);

  @override
  List<Object?> get props => [devices];
}

// States
abstract class DeviceDiscoveryState extends Equatable {
  @override
  List<Object?> get props => [];
}

class DeviceDiscoveryInitial extends DeviceDiscoveryState {}

class DeviceDiscoveryLoading extends DeviceDiscoveryState {}

class DeviceDiscoverySuccess extends DeviceDiscoveryState {
  final List<DiscoveredDevice> devices;
  final bool isScanning;

  DeviceDiscoverySuccess({
    required this.devices,
    this.isScanning = false,
  });

  @override
  List<Object?> get props => [devices, isScanning];
}

class DeviceDiscoveryError extends DeviceDiscoveryState {
  final String message;

  DeviceDiscoveryError(this.message);

  @override
  List<Object?> get props => [message];
}

// Bloc
class DeviceDiscoveryBloc extends Bloc<DeviceDiscoveryEvent, DeviceDiscoveryState> {
  final DeviceDiscoveryService _discoveryService;
  StreamSubscription? _devicesSubscription;

  DeviceDiscoveryBloc(this._discoveryService) : super(DeviceDiscoveryInitial()) {
    on<StartDeviceDiscovery>(_onStartDiscovery);
    on<StopDeviceDiscovery>(_onStopDiscovery);
    on<RefreshDevices>(_onRefreshDevices);
    on<DevicesUpdated>(_onDevicesUpdated);
  }

  Future<void> _onStartDiscovery(
    StartDeviceDiscovery event,
    Emitter<DeviceDiscoveryState> emit,
  ) async {
    emit(DeviceDiscoveryLoading());

    try {
      // Démarre le service de découverte
      await _discoveryService.startDiscovery();

      // Écoute les mises à jour des appareils
      await _devicesSubscription?.cancel();
      _devicesSubscription = _discoveryService.devicesStream.listen(
        (devices) => add(DevicesUpdated(devices)),
      );

      // Émet l'état initial (peut être vide au début)
      emit(DeviceDiscoverySuccess(
        devices: _discoveryService.currentDevices,
        isScanning: true,
      ));
    } catch (e) {
      emit(DeviceDiscoveryError('Erreur lors de la découverte: $e'));
    }
  }

  Future<void> _onStopDiscovery(
    StopDeviceDiscovery event,
    Emitter<DeviceDiscoveryState> emit,
  ) async {
    await _devicesSubscription?.cancel();
    await _discoveryService.stopDiscovery();
    emit(DeviceDiscoveryInitial());
  }

  Future<void> _onRefreshDevices(
    RefreshDevices event,
    Emitter<DeviceDiscoveryState> emit,
  ) async {
    if (state is DeviceDiscoverySuccess) {
      final currentState = state as DeviceDiscoverySuccess;
      emit(DeviceDiscoverySuccess(
        devices: currentState.devices,
        isScanning: true,
      ));
    }

    try {
      await _discoveryService.stopDiscovery();
      await _discoveryService.startDiscovery();
    } catch (e) {
      emit(DeviceDiscoveryError('Erreur lors du rafraîchissement: $e'));
    }
  }

  void _onDevicesUpdated(
    DevicesUpdated event,
    Emitter<DeviceDiscoveryState> emit,
  ) {
    emit(DeviceDiscoverySuccess(
      devices: event.devices,
      isScanning: _discoveryService.isDiscovering,
    ));
  }

  @override
  Future<void> close() {
    _devicesSubscription?.cancel();
    _discoveryService.dispose();
    return super.close();
  }
}