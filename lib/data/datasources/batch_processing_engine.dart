import 'dart:io';
import 'package:path/path.dart' as p;

import '../../domain/entities/media_edit_config_entity.dart';
import '../../services/ffmpeg_service.dart';
import 'image_processing_datasource.dart';

class BatchItemStatus {
  final String inputPath;
  final String fileName;
  final bool isVideo;
  final double progress; // 0.0 to 1.0
  final bool isCompleted;
  final bool isFailed;
  final String? outputPath;
  final String? errorMessage;
  final int originalSizeBytes;
  final int outputSizeBytes;

  const BatchItemStatus({
    required this.inputPath,
    required this.fileName,
    required this.isVideo,
    this.progress = 0.0,
    this.isCompleted = false,
    this.isFailed = false,
    this.outputPath,
    this.errorMessage,
    this.originalSizeBytes = 0,
    this.outputSizeBytes = 0,
  });

  BatchItemStatus copyWith({
    double? progress,
    bool? isCompleted,
    bool? isFailed,
    String? outputPath,
    String? errorMessage,
    int? originalSizeBytes,
    int? outputSizeBytes,
  }) {
    return BatchItemStatus(
      inputPath: inputPath,
      fileName: fileName,
      isVideo: isVideo,
      progress: progress ?? this.progress,
      isCompleted: isCompleted ?? this.isCompleted,
      isFailed: isFailed ?? this.isFailed,
      outputPath: outputPath ?? this.outputPath,
      errorMessage: errorMessage ?? this.errorMessage,
      originalSizeBytes: originalSizeBytes ?? this.originalSizeBytes,
      outputSizeBytes: outputSizeBytes ?? this.outputSizeBytes,
    );
  }
}

typedef BatchProgressCallback = void Function(int currentIndex, int totalItems, List<BatchItemStatus> items);

class BatchProcessingEngine {
  final FFmpegService _ffmpegService = FFmpegService();
  final ImageProcessingDatasource _imageDatasource = ImageProcessingDatasource();

  /// Menjalankan pemrosesan massal (batch processing) untuk daftar file foto & video
  Future<List<BatchItemStatus>> processBatch({
    required List<String> inputPaths,
    required MediaEditConfigEntity config,
    BatchProgressCallback? onProgress,
  }) async {
    List<BatchItemStatus> statuses = [];

    for (final path in inputPaths) {
      final name = p.basename(path);
      final isVid = _isVideoFile(path);
      int size = 0;
      try {
        final f = File(path);
        if (await f.exists()) {
          size = await f.length();
        }
      } catch (_) {}

      statuses.add(BatchItemStatus(
        inputPath: path,
        fileName: name,
        isVideo: isVid,
        originalSizeBytes: size,
      ));
    }

    // Trigger initial progress
    onProgress?.call(0, statuses.length, List.from(statuses));

    for (int i = 0; i < inputPaths.length; i++) {
      final path = inputPaths[i];
      final isVid = _isVideoFile(path);
      
      // Update item state to active
      statuses[i] = statuses[i].copyWith(progress: 0.1);
      onProgress?.call(i, statuses.length, List.from(statuses));

      try {
        if (isVid) {
          // Process Video via FFmpeg
          final ffmpegResult = await _ffmpegService.processMedia(
            inputPath: path,
            config: config.copyWith(isVideo: true),
          );

          if (ffmpegResult.success && await File(ffmpegResult.outputPath).exists()) {
            final outLen = await File(ffmpegResult.outputPath).length();
            statuses[i] = statuses[i].copyWith(
              progress: 1.0,
              isCompleted: true,
              outputPath: ffmpegResult.outputPath,
              outputSizeBytes: outLen,
            );
          } else {
            // Fallback error
            statuses[i] = statuses[i].copyWith(
              progress: 1.0,
              isFailed: true,
              errorMessage: ffmpegResult.errorMessage ?? 'Gagal memproses video via FFmpeg',
            );
          }
        } else {
          // Process Photo (Attempt FFmpeg first, fallback to ImageProcessingDatasource)
          bool processedViaFfmpeg = false;
          final ffmpegAvail = await _ffmpegService.isFFmpegAvailable();

          if (ffmpegAvail) {
            final ffmpegResult = await _ffmpegService.processMedia(
              inputPath: path,
              config: config.copyWith(isVideo: false),
            );
            if (ffmpegResult.success && await File(ffmpegResult.outputPath).exists()) {
              final outLen = await File(ffmpegResult.outputPath).length();
              statuses[i] = statuses[i].copyWith(
                progress: 1.0,
                isCompleted: true,
                outputPath: ffmpegResult.outputPath,
                outputSizeBytes: outLen,
              );
              processedViaFfmpeg = true;
            }
          }

          if (!processedViaFfmpeg) {
            // Pure Dart Fallback Pipeline for Photos
            final imgInfo = await _imageDatasource.readImageInfo(path);
            final optResult = await _imageDatasource.optimizeImage(
              imageInfo: imgInfo,
              format: config.outputFormat.isEmpty ? 'JPG' : config.outputFormat,
              quality: config.quality,
              outputPrefix: 'batch_clean_',
              metadataProfile: config.metadataProfilePreset,
              customProfile: config.customExifProfile,
              watermarkEnabled: config.enableWatermark,
              watermarkLogoPath: config.watermarkLogoPath,
              watermarkPosition: config.watermarkPosition.toPositionString(),
              watermarkScale: config.watermarkScale,
              watermarkOpacity: config.watermarkOpacity,
              onProgress: (pVal) {
                statuses[i] = statuses[i].copyWith(progress: pVal);
                onProgress?.call(i, statuses.length, List.from(statuses));
              },
            );

            statuses[i] = statuses[i].copyWith(
              progress: 1.0,
              isCompleted: true,
              outputPath: optResult.optimizedPath,
              outputSizeBytes: optResult.optimizedSize,
            );
          }
        }
      } catch (e) {
        statuses[i] = statuses[i].copyWith(
          progress: 1.0,
          isFailed: true,
          errorMessage: e.toString(),
        );
      }

      onProgress?.call(i + 1, statuses.length, List.from(statuses));
    }

    return statuses;
  }

  bool _isVideoFile(String path) {
    final ext = p.extension(path).toLowerCase();
    return ext == '.mp4' ||
        ext == '.mov' ||
        ext == '.mkv' ||
        ext == '.avi' ||
        ext == '.webm' ||
        ext == '.3gp' ||
        ext == '.flv';
  }
}
