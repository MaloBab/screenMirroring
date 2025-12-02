import 'package:dartz/dartz.dart';
import '../entities/connection_info.dart';
import '../repositories/mirroring_repository.dart';
import '../../core/error/failures.dart';

class StartMirroring {
  final MirroringRepository repository;

  StartMirroring(this.repository);

  Future<Either<Failure, Stream<MirroringStats>>> call({
    required String receiverAddress,
    int quality = 70,
  }) async {
    if (quality < 10 || quality > 100) {
      return Left(ValidationFailure('Quality must be between 10 and 100'));
    }
    
    return await repository.startMirroring(
      receiverAddress: receiverAddress,
      quality: quality,
    );
  }
}

class StopMirroring {
  final MirroringRepository repository;

  StopMirroring(this.repository);

  Future<Either<Failure, void>> call() async {
    return await repository.stopMirroring();
  }
}

class GetConnectionInfo {
  final MirroringRepository repository;

  GetConnectionInfo(this.repository);

  Future<Either<Failure, ConnectionInfo>> call() async {
    return await repository.getConnectionInfo();
  }
}