import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/media_edit_config_entity.dart';
import '../../domain/entities/watermark_position.dart';
import '../../domain/entities/exif_profile_entity.dart';
import '../../services/ffmpeg_service.dart';
import '../../data/datasources/batch_processing_engine.dart';

final ffmpegServiceProvider = Provider<FFmpegService>((ref) {
  return FFmpegService();
});

final ffmpegAvailableProvider = FutureProvider<bool>((ref) async {
  final service = ref.watch(ffmpegServiceProvider);
  return await service.isFFmpegAvailable();
});

final batchEngineProvider = Provider<BatchProcessingEngine>((ref) {
  return BatchProcessingEngine();
});

// ── State Notifier untuk Media Edit Configuration ────────────────────────────
class MediaEditConfigNotifier extends StateNotifier<MediaEditConfigEntity> {
  MediaEditConfigNotifier()
      : super(const MediaEditConfigEntity(
          isVideo: false,
          enableWatermark: false,
          watermarkPosition: WatermarkPosition(type: WatermarkPositionType.bottomRight),
          watermarkScale: 0.18,
          watermarkOpacity: 0.85,
          metadataProfilePreset: 'sony',
        ));

  void initForMedia({required bool isVideo, String? initialFormat}) {
    state = state.copyWith(
      isVideo: isVideo,
      outputFormat: isVideo ? 'MP4' : (initialFormat ?? 'JPG'),
    );
  }

  void toggleWatermark(bool enabled) {
    state = state.copyWith(enableWatermark: enabled);
  }

  void setWatermarkLogo(String? logoPath) {
    state = state.copyWith(
      watermarkLogoPath: logoPath,
      enableWatermark: logoPath != null,
    );
  }

  void setWatermarkPosition(WatermarkPosition position) {
    state = state.copyWith(watermarkPosition: position);
  }

  void setWatermarkScale(double scale) {
    state = state.copyWith(watermarkScale: scale);
  }

  void setWatermarkOpacity(double opacity) {
    state = state.copyWith(watermarkOpacity: opacity);
  }

  void setTrim(double? start, double? end) {
    state = state.copyWith(
      trimStartSeconds: start,
      trimEndSeconds: end,
    );
  }

  void setRotation(int degrees) {
    state = state.copyWith(rotationDegrees: degrees);
  }

  void setSpeed(double speed) {
    state = state.copyWith(speedMultiplier: speed);
  }

  void toggleMuteAudio(bool mute) {
    state = state.copyWith(muteAudio: mute);
  }

  void setVisualAdjustments({double? brightness, double? contrast, int? quality}) {
    state = state.copyWith(
      brightness: brightness ?? state.brightness,
      contrast: contrast ?? state.contrast,
      quality: quality ?? state.quality,
    );
  }

  void setMetadataAction(PostMetadataAction action) {
    state = state.copyWith(metadataAction: action);
  }

  void setMetadataProfile(String profilePreset, {ExifProfileEntity? customProfile}) {
    state = state.copyWith(
      metadataProfilePreset: profilePreset,
      customExifProfile: customProfile,
    );
  }
}

final mediaEditConfigProvider =
    StateNotifierProvider<MediaEditConfigNotifier, MediaEditConfigEntity>((ref) {
  return MediaEditConfigNotifier();
});

// ── Batch Processing State ──────────────────────────────────────────────────
class BatchState {
  final bool isProcessing;
  final int currentIndex;
  final int totalItems;
  final List<BatchItemStatus> items;
  final String? errorMessage;

  const BatchState({
    this.isProcessing = false,
    this.currentIndex = 0,
    this.totalItems = 0,
    this.items = const [],
    this.errorMessage,
  });

  double get overallProgress {
    if (totalItems == 0) return 0.0;
    double completedSum = 0.0;
    for (final item in items) {
      completedSum += item.progress;
    }
    return (completedSum / totalItems).clamp(0.0, 1.0);
  }
}

class BatchNotifier extends StateNotifier<BatchState> {
  final BatchProcessingEngine _engine;

  BatchNotifier(this._engine) : super(const BatchState());

  Future<List<BatchItemStatus>> startBatch({
    required List<String> inputPaths,
    required MediaEditConfigEntity config,
  }) async {
    state = BatchState(
      isProcessing: true,
      currentIndex: 0,
      totalItems: inputPaths.length,
      items: [],
    );

    final results = await _engine.processBatch(
      inputPaths: inputPaths,
      config: config,
      onProgress: (current, total, itemList) {
        state = BatchState(
          isProcessing: current < total,
          currentIndex: current,
          totalItems: total,
          items: itemList,
        );
      },
    );

    state = BatchState(
      isProcessing: false,
      currentIndex: results.length,
      totalItems: results.length,
      items: results,
    );

    return results;
  }

  void reset() {
    state = const BatchState();
  }
}

final batchNotifierProvider = StateNotifierProvider<BatchNotifier, BatchState>((ref) {
  final engine = ref.watch(batchEngineProvider);
  return BatchNotifier(engine);
});
