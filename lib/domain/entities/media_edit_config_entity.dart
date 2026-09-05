import 'watermark_position.dart';
import 'exif_profile_entity.dart';

enum PostMetadataAction {
  scrubAndSpoof, // Clean old metadata & write new spoofed EXIF/Device profile
  scrubOnly,     // Clean all metadata (leave empty)
  keepOriginal,  // Keep original metadata
}

class MediaEditConfigEntity {
  final bool isVideo;
  
  // Watermark / Logo Overlay
  final bool enableWatermark;
  final String? watermarkLogoPath;
  final WatermarkPosition watermarkPosition;
  final double watermarkScale;   // 0.05 to 0.5 (relative to video/image width)
  final double watermarkOpacity; // 0.1 to 1.0

  // Video Specific Edits
  final double? trimStartSeconds;
  final double? trimEndSeconds;
  final int rotationDegrees;     // 0, 90, 180, 270
  final double speedMultiplier;  // 0.5x, 1.0x, 1.5x, 2.0x
  final bool muteAudio;
  final String? backgroundAudioPath;

  // Photo & Visual Adjustments
  final double brightness;       // -1.0 to 1.0 (0 is normal)
  final double contrast;         // 0.5 to 2.0 (1 is normal)
  final int quality;             // 1 to 100
  final String outputFormat;     // 'MP4', 'MOV', 'JPG', 'PNG', 'WEBP'

  // Post Metadata & Privacy
  final PostMetadataAction metadataAction;
  final String metadataProfilePreset; // 'clean', 'sony', 'canon', 'iphone', 'samsung', 'custom'
  final ExifProfileEntity? customExifProfile;

  const MediaEditConfigEntity({
    required this.isVideo,
    this.enableWatermark = false,
    this.watermarkLogoPath,
    this.watermarkPosition = const WatermarkPosition(type: WatermarkPositionType.bottomRight),
    this.watermarkScale = 0.18,
    this.watermarkOpacity = 0.85,
    this.trimStartSeconds,
    this.trimEndSeconds,
    this.rotationDegrees = 0,
    this.speedMultiplier = 1.0,
    this.muteAudio = false,
    this.backgroundAudioPath,
    this.brightness = 0.0,
    this.contrast = 1.0,
    this.quality = 90,
    this.outputFormat = 'MP4',
    this.metadataAction = PostMetadataAction.scrubAndSpoof,
    this.metadataProfilePreset = 'sony',
    this.customExifProfile,
  });

  MediaEditConfigEntity copyWith({
    bool? isVideo,
    bool? enableWatermark,
    String? watermarkLogoPath,
    WatermarkPosition? watermarkPosition,
    double? watermarkScale,
    double? watermarkOpacity,
    double? trimStartSeconds,
    double? trimEndSeconds,
    int? rotationDegrees,
    double? speedMultiplier,
    bool? muteAudio,
    String? backgroundAudioPath,
    double? brightness,
    double? contrast,
    int? quality,
    String? outputFormat,
    PostMetadataAction? metadataAction,
    String? metadataProfilePreset,
    ExifProfileEntity? customExifProfile,
  }) {
    return MediaEditConfigEntity(
      isVideo: isVideo ?? this.isVideo,
      enableWatermark: enableWatermark ?? this.enableWatermark,
      watermarkLogoPath: watermarkLogoPath ?? this.watermarkLogoPath,
      watermarkPosition: watermarkPosition ?? this.watermarkPosition,
      watermarkScale: watermarkScale ?? this.watermarkScale,
      watermarkOpacity: watermarkOpacity ?? this.watermarkOpacity,
      trimStartSeconds: trimStartSeconds ?? this.trimStartSeconds,
      trimEndSeconds: trimEndSeconds ?? this.trimEndSeconds,
      rotationDegrees: rotationDegrees ?? this.rotationDegrees,
      speedMultiplier: speedMultiplier ?? this.speedMultiplier,
      muteAudio: muteAudio ?? this.muteAudio,
      backgroundAudioPath: backgroundAudioPath ?? this.backgroundAudioPath,
      brightness: brightness ?? this.brightness,
      contrast: contrast ?? this.contrast,
      quality: quality ?? this.quality,
      outputFormat: outputFormat ?? this.outputFormat,
      metadataAction: metadataAction ?? this.metadataAction,
      metadataProfilePreset: metadataProfilePreset ?? this.metadataProfilePreset,
      customExifProfile: customExifProfile ?? this.customExifProfile,
    );
  }
}
