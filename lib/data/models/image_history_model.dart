import '../../domain/entities/image_history_entity.dart';

class ImageHistoryModel extends ImageHistoryEntity {
  const ImageHistoryModel({
    super.id,
    required super.originalName,
    required super.originalPath,
    required super.optimizedPath,
    required super.originalSize,
    required super.optimizedSize,
    required super.width,
    required super.height,
    required super.format,
    required super.createdAt,
    super.isFavorite,
  });

  factory ImageHistoryModel.fromMap(Map<String, dynamic> map) {
    return ImageHistoryModel(
      id: map['id'] as int?,
      originalName: map['original_name'] as String,
      originalPath: map['original_path'] as String,
      optimizedPath: map['optimized_path'] as String,
      originalSize: map['original_size'] as int,
      optimizedSize: map['optimized_size'] as int,
      width: map['width'] as int,
      height: map['height'] as int,
      format: map['format'] as String,
      createdAt: DateTime.parse(map['created_at'] as String),
      isFavorite: (map['is_favorite'] as int) == 1,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'original_name': originalName,
      'original_path': originalPath,
      'optimized_path': optimizedPath,
      'original_size': originalSize,
      'optimized_size': optimizedSize,
      'width': width,
      'height': height,
      'format': format,
      'created_at': createdAt.toIso8601String(),
      'is_favorite': isFavorite ? 1 : 0,
    };
  }

  factory ImageHistoryModel.fromEntity(ImageHistoryEntity entity) {
    return ImageHistoryModel(
      id: entity.id,
      originalName: entity.originalName,
      originalPath: entity.originalPath,
      optimizedPath: entity.optimizedPath,
      originalSize: entity.originalSize,
      optimizedSize: entity.optimizedSize,
      width: entity.width,
      height: entity.height,
      format: entity.format,
      createdAt: entity.createdAt,
      isFavorite: entity.isFavorite,
    );
  }
}
