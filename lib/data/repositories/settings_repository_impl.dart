import '../../domain/entities/app_settings_entity.dart';
import '../../domain/repositories/settings_repository.dart';
import '../datasources/local/preferences_datasource.dart';

class SettingsRepositoryImpl implements SettingsRepository {
  final PreferencesDatasource _preferencesDatasource;

  const SettingsRepositoryImpl(this._preferencesDatasource);

  @override
  Future<AppSettingsEntity> getSettings() {
    return _preferencesDatasource.getSettings();
  }

  @override
  Future<void> saveSettings(AppSettingsEntity settings) {
    return _preferencesDatasource.saveSettings(settings);
  }
}
