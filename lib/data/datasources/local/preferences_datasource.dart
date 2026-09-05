import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/constants/app_constants.dart';
import '../../../domain/entities/app_settings_entity.dart';

class PreferencesDatasource {
  Future<AppSettingsEntity> getSettings() async {
    final prefs = await SharedPreferences.getInstance();

    return AppSettingsEntity(
      isDarkMode: prefs.getBool(AppConstants.prefTheme) ?? false,
      outputFormat: prefs.getString(AppConstants.prefOutputFormat) ??
          AppConstants.defaultOutputFormat,
      jpgQuality: prefs.getInt(AppConstants.prefJpgQuality) ??
          AppConstants.defaultJpgQuality,
      filePrefix: prefs.getString(AppConstants.prefFilePrefix) ??
          AppConstants.defaultFilePrefix,
      customOutputPath: prefs.getString(AppConstants.prefOutputPath),
    );
  }

  Future<void> saveSettings(AppSettingsEntity settings) async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setBool(AppConstants.prefTheme, settings.isDarkMode);
    await prefs.setString(AppConstants.prefOutputFormat, settings.outputFormat);
    await prefs.setInt(AppConstants.prefJpgQuality, settings.jpgQuality);
    await prefs.setString(AppConstants.prefFilePrefix, settings.filePrefix);
    if (settings.customOutputPath != null) {
      await prefs.setString(
          AppConstants.prefOutputPath, settings.customOutputPath!);
    } else {
      await prefs.remove(AppConstants.prefOutputPath);
    }
  }
}
