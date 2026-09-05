import '../../domain/entities/image_info_entity.dart';
import '../../domain/entities/image_history_entity.dart';
import '../../domain/entities/optimization_result_entity.dart';
import '../../domain/entities/exif_profile_entity.dart';
import '../../domain/repositories/image_repository.dart';
import '../datasources/image_processing_datasource.dart';
import '../datasources/local/database_helper.dart';
import '../datasources/local/exif_profile_datasource.dart';
import '../models/image_history_model.dart';
import '../../core/constants/app_constants.dart';

class ImageRepositoryImpl implements ImageRepository {
  final ImageProcessingDatasource _processingDatasource;
  final DatabaseHelper _databaseHelper;
  final ExifProfileDatasource _exifProfileDatasource;

  const ImageRepositoryImpl({
    required ImageProcessingDatasource processingDatasource,
    required DatabaseHelper databaseHelper,
    ExifProfileDatasource? exifProfileDatasource,
  })  : _processingDatasource = processingDatasource,
        _databaseHelper = databaseHelper,
        _exifProfileDatasource =
            exifProfileDatasource ?? const ExifProfileDatasource();

  @override
  Future<ImageInfoEntity> readImageInfo(String filePath) {
    return _processingDatasource.readImageInfo(filePath);
  }

  @override
  Future<OptimizationResultEntity> optimizeImage({
    required ImageInfoEntity imageInfo,
    required String format,
    required int quality,
    required String outputPrefix,
    required String metadataProfile,
    ExifProfileEntity? customProfile,
    String? customOutputPath,
    void Function(double progress)? onProgress,
    bool watermarkEnabled = false,
    String? watermarkLogoPath,
    String watermarkPosition = 'bottomRight',
    double watermarkScale = 0.15,
    double watermarkOpacity = 0.8,
  }) {
    return _processingDatasource.optimizeImage(
      imageInfo: imageInfo,
      format: format,
      quality: quality,
      outputPrefix: outputPrefix,
      metadataProfile: metadataProfile,
      customProfile: customProfile,
      customOutputPath: customOutputPath,
      onProgress: onProgress,
      watermarkEnabled: watermarkEnabled,
      watermarkLogoPath: watermarkLogoPath,
      watermarkPosition: watermarkPosition,
      watermarkScale: watermarkScale,
      watermarkOpacity: watermarkOpacity,
    );
  }

  @override
  Future<List<ExifProfileEntity>> getCustomExifProfiles() =>
      _exifProfileDatasource.getCustomProfiles();

  @override
  Future<void> saveCustomExifProfile(ExifProfileEntity profile) =>
      _exifProfileDatasource.saveProfile(profile);

  @override
  Future<void> deleteCustomExifProfile(String id) =>
      _exifProfileDatasource.deleteProfile(id);

  @override
  Future<List<ImageHistoryEntity>> getHistory() async {
    final rows = await _databaseHelper.queryAll(AppConstants.tableHistory);
    return rows.map((row) => ImageHistoryModel.fromMap(row)).toList();
  }

  @override
  Future<void> saveHistory(ImageHistoryEntity item) async {
    final model = ImageHistoryModel.fromEntity(item);
    await _databaseHelper.insert(AppConstants.tableHistory, model.toMap());
  }

  @override
  Future<void> deleteHistory(int id) async {
    await _databaseHelper.delete(AppConstants.tableHistory, id);
  }

  @override
  Future<void> clearAllHistory() async {
    await _databaseHelper.deleteAll(AppConstants.tableHistory);
  }

  @override
  Future<void> deleteFile(String path) {
    return _processingDatasource.deleteFile(path);
  }
}
