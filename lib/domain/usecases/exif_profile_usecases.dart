import '../entities/exif_profile_entity.dart';
import '../repositories/image_repository.dart';

class GetCustomExifProfilesUsecase {
  final ImageRepository _repository;
  const GetCustomExifProfilesUsecase(this._repository);

  Future<List<ExifProfileEntity>> call() =>
      _repository.getCustomExifProfiles();
}

class SaveCustomExifProfileUsecase {
  final ImageRepository _repository;
  const SaveCustomExifProfileUsecase(this._repository);

  Future<void> call(ExifProfileEntity profile) =>
      _repository.saveCustomExifProfile(profile);
}

class DeleteCustomExifProfileUsecase {
  final ImageRepository _repository;
  const DeleteCustomExifProfileUsecase(this._repository);

  Future<void> call(String id) =>
      _repository.deleteCustomExifProfile(id);
}
