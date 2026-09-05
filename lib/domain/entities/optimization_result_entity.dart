import 'image_info_entity.dart';

class OptimizationResultEntity {
  final ImageInfoEntity originalInfo;
  final String optimizedPath;
  final int optimizedSize;
  final String outputFormat;
  final DateTime completedAt;

  const OptimizationResultEntity({
    required this.originalInfo,
    required this.optimizedPath,
    required this.optimizedSize,
    required this.outputFormat,
    required this.completedAt,
  });

  int get savedBytes => originalInfo.fileSize - optimizedSize;

  double get savedPercentage =>
      originalInfo.fileSize > 0
          ? (savedBytes / originalInfo.fileSize) * 100
          : 0;

  bool get isSizeReduced => optimizedSize < originalInfo.fileSize;

  String get optimizedFileName => optimizedPath.split('/').last;
}
