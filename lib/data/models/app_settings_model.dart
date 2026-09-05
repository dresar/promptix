import '../../domain/entities/app_settings_entity.dart';

class AppSettingsModel extends AppSettingsEntity {
  const AppSettingsModel({
    super.isDarkMode,
    super.outputFormat,
    super.jpgQuality,
    super.filePrefix,
    super.customOutputPath,
  });

  factory AppSettingsModel.fromEntity(AppSettingsEntity entity) {
    return AppSettingsModel(
      isDarkMode: entity.isDarkMode,
      outputFormat: entity.outputFormat,
      jpgQuality: entity.jpgQuality,
      filePrefix: entity.filePrefix,
      customOutputPath: entity.customOutputPath,
    );
  }
}
