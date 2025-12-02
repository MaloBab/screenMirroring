import 'package:dartz/dartz.dart';
import '../entities/connection_info.dart';
import '../repositories/mirroring_repository.dart';
import '../../core/error/failures.dart';

class GetConnectionInfo {
  final MirroringRepository repository;

  GetConnectionInfo(this.repository);

  Future<Either<Failure, ConnectionInfo>> call() async {
    try {
      return await repository.getConnectionInfo();
    } catch (e) {
      return Left(
        NetworkFailure('Failed to retrieve connection information: $e')
      );
    }
  }

  Stream<ConnectionStatus> getConnectionStatusStream() {
    return repository.connectionStatusStream;
  }
}