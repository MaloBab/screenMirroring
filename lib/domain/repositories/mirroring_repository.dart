import 'package:dartz/dartz.dart';
import '../entities/connection_info.dart';
import '../../core/error/failures.dart';

abstract class MirroringRepository {
  /// Démarre le mirroring vers un récepteur
  Future<Either<Failure, Stream<MirroringStats>>> startMirroring({
    required String receiverAddress,
    required int quality,
  });

  /// Arrête le mirroring en cours
  Future<Either<Failure, void>> stopMirroring();

  /// Récupère les informations de connexion actuelles
  Future<Either<Failure, ConnectionInfo>> getConnectionInfo();

  /// Stream de l'état de la connexion
  Stream<ConnectionStatus> get connectionStatusStream;

  /// Vérifie si le mirroring est actif
  bool get isMirroring;
}