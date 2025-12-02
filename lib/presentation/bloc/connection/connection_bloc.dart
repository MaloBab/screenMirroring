import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../domain/entities/connection_info.dart';
import '../../../domain/usecases/start_mirroring.dart';

// Events
abstract class ConnectionEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class InitializeConnection extends ConnectionEvent {}

class RefreshConnectionInfo extends ConnectionEvent {}

// States
abstract class ConnectionState extends Equatable {
  @override
  List<Object?> get props => [];
}

class ConnectionInitial extends ConnectionState {}

class ConnectionLoading extends ConnectionState {}

class ConnectionReady extends ConnectionState {
  final ConnectionInfo connectionInfo;

  ConnectionReady(this.connectionInfo);

  @override
  List<Object?> get props => [connectionInfo];
}

class ConnectionError extends ConnectionState {
  final String message;

  ConnectionError(this.message);

  @override
  List<Object?> get props => [message];
}

// Bloc
class ConnectionBloc extends Bloc<ConnectionEvent, ConnectionState> {
  final GetConnectionInfo getConnectionInfo;

  ConnectionBloc({
    required this.getConnectionInfo,
  }) : super(ConnectionInitial()) {
    on<InitializeConnection>(_onInitialize);
    on<RefreshConnectionInfo>(_onRefresh);
  }

  Future<void> _onInitialize(
    InitializeConnection event,
    Emitter<ConnectionState> emit,
  ) async {
    emit(ConnectionLoading());
    
    final result = await getConnectionInfo();
    
    result.fold(
      (failure) => emit(ConnectionError(failure.message)),
      (connectionInfo) => emit(ConnectionReady(connectionInfo)),
    );
  }

  Future<void> _onRefresh(
    RefreshConnectionInfo event,
    Emitter<ConnectionState> emit,
  ) async {
    final result = await getConnectionInfo();
    
    result.fold(
      (failure) => emit(ConnectionError(failure.message)),
      (connectionInfo) => emit(ConnectionReady(connectionInfo)),
    );
  }
}