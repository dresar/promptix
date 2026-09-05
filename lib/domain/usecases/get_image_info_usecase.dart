import '../entities/image_info_entity.dart';
import '../repositories/image_repository.dart';

class GetImageInfoUsecase {
  final ImageRepository _repository;

  const GetImageInfoUsecase(this._repository);

  Future<ImageInfoEntity> call(String filePath) {
    return _repository.readImageInfo(filePath);
  }
}
