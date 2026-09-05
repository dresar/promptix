import '../entities/image_info_entity.dart';
import '../entities/optimization_result_entity.dart';
import '../entities/exif_profile_entity.dart';
import '../repositories/image_repository.dart';

class OptimizeImageUsecase {
  final ImageRepository _repository;

  const OptimizeImageUsecase(this._repository);

  Future<OptimizationResultEntity> call({
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
    return _repository.optimizeImage(
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
}
