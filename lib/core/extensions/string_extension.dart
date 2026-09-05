extension StringExtension on String {
  String capitalize() {
    if (isEmpty) return this;
    return '${this[0].toUpperCase()}${substring(1).toLowerCase()}';
  }

  String toFormatLabel() {
    switch (toUpperCase()) {
      case 'JPG':
      case 'JPEG':
        return 'JPEG';
      case 'PNG':
        return 'PNG';
      case 'WEBP':
        return 'WebP';
      default:
        return toUpperCase();
    }
  }

  bool get isImagePath {
    final lower = toLowerCase();
    return lower.endsWith('.jpg') ||
        lower.endsWith('.jpeg') ||
        lower.endsWith('.png') ||
        lower.endsWith('.webp') ||
        lower.endsWith('.gif') ||
        lower.endsWith('.bmp');
  }
}
