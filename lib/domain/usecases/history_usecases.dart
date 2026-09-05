import '../entities/image_history_entity.dart';
import '../repositories/image_repository.dart';

class GetHistoryUsecase {
  final ImageRepository _repository;

  const GetHistoryUsecase(this._repository);

  Future<List<ImageHistoryEntity>> call() {
    return _repository.getHistory();
  }
}

class SaveHistoryUsecase {
  final ImageRepository _repository;

  const SaveHistoryUsecase(this._repository);

  Future<void> call(ImageHistoryEntity item) {
    return _repository.saveHistory(item);
  }
}

class DeleteHistoryUsecase {
  final ImageRepository _repository;

  const DeleteHistoryUsecase(this._repository);

  Future<void> call(int id) {
    return _repository.deleteHistory(id);
  }
}

class ClearAllHistoryUsecase {
  final ImageRepository _repository;

  const ClearAllHistoryUsecase(this._repository);

  Future<void> call() {
    return _repository.clearAllHistory();
  }
}
