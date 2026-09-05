abstract class Failure {
  final String message;
  const Failure(this.message);

  @override
  String toString() => message;
}

class FileFailure extends Failure {
  const FileFailure(super.message);
}

class PermissionFailure extends Failure {
  const PermissionFailure(super.message);
}

class OptimizationFailure extends Failure {
  const OptimizationFailure(super.message);
}

class StorageFailure extends Failure {
  const StorageFailure(super.message);
}

class NotFoundFailure extends Failure {
  const NotFoundFailure(super.message);
}
