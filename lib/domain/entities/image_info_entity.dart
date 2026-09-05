class ImageInfoEntity {
  final String filePath;
  final String fileName;
  final int fileSize;
  final int width;
  final int height;
  final String format;
  final DateTime? createdAt;
  final DateTime? modifiedAt;
  final Map<String, String> exifData;

  /// C2PA / Content Credentials provenance data terdeteksi
  final bool hasC2pa;

  /// Software AI yang terdeteksi dari metadata (mis: "Midjourney", "DALL-E")
  final String? aiSoftwareDetected;

  /// Keyword-keyword AI yang ditemukan di metadata
  final List<String> aiSignatureKeywords;

  const ImageInfoEntity({
    required this.filePath,
    required this.fileName,
    required this.fileSize,
    required this.width,
    required this.height,
    required this.format,
    this.createdAt,
    this.modifiedAt,
    this.exifData = const {},
    this.hasC2pa = false,
    this.aiSoftwareDetected,
    this.aiSignatureKeywords = const [],
  });

  double get fileSizeMB => fileSize / (1024 * 1024);

  String get resolution => '$width × $height';

  bool get hasExif => exifData.isNotEmpty;

  /// True jika ada tanda AI (C2PA atau keyword)
  bool get hasAiSignature => hasC2pa || aiSignatureKeywords.isNotEmpty;
}
