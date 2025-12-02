import 'dart:async';
import 'package:dartz/dartz.dart';
import '../../core/error/failures.dart';
import '../../domain/entities/connection_info.dart';
import '../../domain/repositories/mirroring_repository.dart';
import '../../data/datasources/screen_capture_source.dart';
import '../../data/datasources/network_source.dart';

class MirroringRepositoryImpl implements MirroringRepository {
  final ScreenCaptureSource screenCaptureSource;
  final NetworkSource networkSource;
  
  final _statusController = StreamController<ConnectionStatus>.broadcast();
  bool _isMirroring = false;
  StreamSubscription? _frameSubscription;

  MirroringRepositoryImpl({
    required this.screenCaptureSource,
    required this.networkSource,
  });

  @override
  Future<Either<Failure, Stream<MirroringStats>>> startMirroring({
    required String receiverAddress,
    required int quality,
  }) async {
    try {
      if (_isMirroring) {
        return Left(ValidationFailure('Mirroring already in progress'));
      }

      // Démarrer le serveur WebSocket
      await networkSource.startServer(port: 8080);
      
      // Démarrer la capture d'écran
      await screenCaptureSource.startCapture(
        fps: 30,
        quality: quality,
      );

      _isMirroring = true;
      _statusController.add(ConnectionStatus.connected);

      // Créer le stream de statistiques
      final statsStream = _createStatsStream();

      // Commencer à envoyer les frames
      _frameSubscription = screenCaptureSource.frameStream.listen(
        (frameData) {
          networkSource.sendFrame(frameData);
        },
        onError: (error) {
          _statusController.add(ConnectionStatus.error);
        },
      );

      // Écouter l'état de la connexion
      networkSource.connectionStream.listen((isConnected) {
        _statusController.add(
          isConnected ? ConnectionStatus.connected : ConnectionStatus.disconnected,
        );
      });

      return Right(statsStream);
    } catch (e) {
      _isMirroring = false;
      return Left(ServerFailure('Failed to start mirroring: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> stopMirroring() async {
    try {
      await _frameSubscription?.cancel();
      await screenCaptureSource.stopCapture();
      await networkSource.stopServer();
      
      _isMirroring = false;
      _statusController.add(ConnectionStatus.disconnected);
      
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure('Failed to stop mirroring: $e'));
    }
  }

  @override
  Future<Either<Failure, ConnectionInfo>> getConnectionInfo() async {
    try {
      final info = await networkSource.getConnectionInfo();
      return Right(info);
    } catch (e) {
      return Left(NetworkFailure('Failed to get connection info: $e'));
    }
  }

  @override
  Stream<ConnectionStatus> get connectionStatusStream => _statusController.stream;

  @override
  bool get isMirroring => _isMirroring;

  Stream<MirroringStats> _createStatsStream() {
    return Stream.periodic(const Duration(seconds: 1), (count) {
      return MirroringStats(
        framesPerSecond: 30,
        bitrate: 2.5,
        duration: Duration(seconds: count),
        totalFrames: count * 30,
      );
    });
  }

  void dispose() {
    _frameSubscription?.cancel();
    _statusController.close();
  }
}