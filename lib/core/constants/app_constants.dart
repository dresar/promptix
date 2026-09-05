class AppConstants {
  AppConstants._();

  static const String appName = 'Promptix';
  static const String appVersion = '1.0.0';
  static const String appTagline = 'Optimasi Gambar AI\nLokal & Aman';
  static const String appDescription =
      'Simpan, kelola, dan optimalkan koleksi gambar AI kamu '
      'sepenuhnya di perangkat — tanpa internet, tanpa akun.';

  static const String defaultOutputFolder = 'Promptix';
  static const String defaultFilePrefix = 'promptix_';

  static const int defaultJpgQuality = 90;
  static const String defaultOutputFormat = 'jpg';

  static const int splashDurationMs = 2800;

  static const List<int> jpgQualityOptions = [100, 95, 90, 80, 70];
  static const List<String> outputFormatOptions = ['jpg', 'png', 'webp'];

  static const double cardBorderRadius = 16.0;
  static const double buttonBorderRadius = 14.0;
  static const double pagePadding = 20.0;
  static const double cardElevation = 0.0;

  static const String dbName = 'promptix.db';
  static const int dbVersion = 1;
  static const String tableHistory = 'image_history';

  static const String prefTheme = 'pref_theme';
  static const String prefOutputFormat = 'pref_output_format';
  static const String prefJpgQuality = 'pref_jpg_quality';
  static const String prefFilePrefix = 'pref_file_prefix';
  static const String prefOutputPath = 'pref_output_path';
}
