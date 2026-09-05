import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/datasources/local/preferences_datasource.dart';
import '../../data/repositories/settings_repository_impl.dart';
import '../../domain/entities/app_settings_entity.dart';
import '../../domain/usecases/settings_usecases.dart';

final preferencesDatasourceProvider =
    Provider<PreferencesDatasource>((ref) => PreferencesDatasource());

final settingsRepositoryProvider = Provider<SettingsRepositoryImpl>((ref) {
  return SettingsRepositoryImpl(ref.read(preferencesDatasourceProvider));
});

final getSettingsUsecaseProvider = Provider<GetSettingsUsecase>((ref) {
  return GetSettingsUsecase(ref.read(settingsRepositoryProvider));
});

final saveSettingsUsecaseProvider = Provider<SaveSettingsUsecase>((ref) {
  return SaveSettingsUsecase(ref.read(settingsRepositoryProvider));
});

class SettingsNotifier extends StateNotifier<AppSettingsEntity> {
  final SaveSettingsUsecase _saveSettings;

  SettingsNotifier(super.initial, this._saveSettings);

  Future<void> toggleTheme() async {
    final updated = state.copyWith(isDarkMode: !state.isDarkMode);
    state = updated;
    await _saveSettings(updated);
  }

  Future<void> setOutputFormat(String format) async {
    final updated = state.copyWith(outputFormat: format);
    state = updated;
    await _saveSettings(updated);
  }

  Future<void> setJpgQuality(int quality) async {
    final updated = state.copyWith(jpgQuality: quality);
    state = updated;
    await _saveSettings(updated);
  }

  Future<void> setFilePrefix(String prefix) async {
    final updated = state.copyWith(filePrefix: prefix);
    state = updated;
    await _saveSettings(updated);
  }

  Future<void> setCustomOutputPath(String? path) async {
    final updated = state.copyWith(customOutputPath: path);
    state = updated;
    await _saveSettings(updated);
  }
}

final settingsNotifierProvider =
    StateNotifierProvider<SettingsNotifier, AppSettingsEntity>((ref) {
  throw UnimplementedError(
    'settingsNotifierProvider must be overridden in main.dart with initial settings.',
  );
});
