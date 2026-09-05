class ImageHistoryEntity {
  final int? id;
  final String originalName;
  final String originalPath;
  final String optimizedPath;
  final int originalSize;
  final int optimizedSize;
  final int width;
  final int height;
  final String format;
  final DateTime createdAt;
  final bool isFavorite;

  const ImageHistoryEntity({
    this.id,
    required this.originalName,
    required this.originalPath,
    required this.optimizedPath,
    required this.originalSize,
    required this.optimizedSize,
    required this.width,
    required this.height,
    required this.format,
    required this.createdAt,
    this.isFavorite = false,
  });

  int get savedBytes => originalSize - optimizedSize;

  double get savedPercentage =>
      originalSize > 0 ? (savedBytes / originalSize) * 100 : 0;

  String get resolution => '$width × $height';

  ImageHistoryEntity copyWith({
    int? id,
    String? originalName,
    String? originalPath,
    String? optimizedPath,
    int? originalSize,
    int? optimizedSize,
    int? width,
    int? height,
    String? format,
    DateTime? createdAt,
    bool? isFavorite,
  }) {
    return ImageHistoryEntity(
      id: id ?? this.id,
      originalName: originalName ?? this.originalName,
      originalPath: originalPath ?? this.originalPath,
      optimizedPath: optimizedPath ?? this.optimizedPath,
      originalSize: originalSize ?? this.originalSize,
      optimizedSize: optimizedSize ?? this.optimizedSize,
      width: width ?? this.width,
      height: height ?? this.height,
      format: format ?? this.format,
      createdAt: createdAt ?? this.createdAt,
      isFavorite: isFavorite ?? this.isFavorite,
    );
  }
}
