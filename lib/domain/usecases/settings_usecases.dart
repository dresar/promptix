import '../entities/app_settings_entity.dart';
import '../repositories/settings_repository.dart';

class GetSettingsUsecase {
  final SettingsRepository _repository;

  const GetSettingsUsecase(this._repository);

  Future<AppSettingsEntity> call() {
    return _repository.getSettings();
  }
}

class SaveSettingsUsecase {
  final SettingsRepository _repository;

  const SaveSettingsUsecase(this._repository);

  Future<void> call(AppSettingsEntity settings) {
    return _repository.saveSettings(settings);
  }
}
