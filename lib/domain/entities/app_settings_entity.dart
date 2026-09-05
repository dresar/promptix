class AppSettingsEntity {
  final bool isDarkMode;
  final String outputFormat;
  final int jpgQuality;
  final String filePrefix;
  final String? customOutputPath;

  const AppSettingsEntity({
    this.isDarkMode = false,
    this.outputFormat = 'jpg',
    this.jpgQuality = 90,
    this.filePrefix = 'promptix_',
    this.customOutputPath,
  });

  AppSettingsEntity copyWith({
    bool? isDarkMode,
    String? outputFormat,
    int? jpgQuality,
    String? filePrefix,
    String? customOutputPath,
  }) {
    return AppSettingsEntity(
      isDarkMode: isDarkMode ?? this.isDarkMode,
      outputFormat: outputFormat ?? this.outputFormat,
      jpgQuality: jpgQuality ?? this.jpgQuality,
      filePrefix: filePrefix ?? this.filePrefix,
      customOutputPath: customOutputPath ?? this.customOutputPath,
    );
  }
}
