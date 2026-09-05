import '../entities/image_info_entity.dart';
import '../entities/image_history_entity.dart';
import '../entities/optimization_result_entity.dart';
import '../entities/exif_profile_entity.dart';

abstract class ImageRepository {
  Future<ImageInfoEntity> readImageInfo(String filePath);

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
  });

  Future<List<ExifProfileEntity>> getCustomExifProfiles();
  Future<void> saveCustomExifProfile(ExifProfileEntity profile);
  Future<void> deleteCustomExifProfile(String id);

  Future<List<ImageHistoryEntity>> getHistory();

  Future<void> saveHistory(ImageHistoryEntity item);

  Future<void> deleteHistory(int id);

  Future<void> clearAllHistory();

  Future<void> deleteFile(String path);
}
