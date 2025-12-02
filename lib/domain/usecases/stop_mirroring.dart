import 'package:dartz/dartz.dart';
import '../repositories/mirroring_repository.dart';
import '../../core/error/failures.dart';

class StopMirroring {
  final MirroringRepository repository;

  StopMirroring(this.repository);

  Future<Either<Failure, void>> call() async {
    try {
      if (!repository.isMirroring) {
        return const Left(
          ValidationFailure('No mirroring session is currently active')
        );
      }
      
      return await repository.stopMirroring();
    } catch (e) {
      return Left(ServerFailure('Unexpected error while stopping mirroring: $e'));
    }
  }
}