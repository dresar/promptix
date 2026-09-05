import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../data/datasources/local/web_image_cache.dart';

class LocalImagePreview extends StatelessWidget {
  final String filePath;
  final Uint8List? bytes;
  final BoxFit fit;
  final Widget? fallback;

  const LocalImagePreview({
    super.key,
    required this.filePath,
    this.bytes,
    this.fit = BoxFit.cover,
    this.fallback,
  });

  @override
  Widget build(BuildContext context) {
    if (kIsWeb) {
      if (bytes != null) {
        return Image.memory(bytes!, fit: fit);
      }
      final cachedBytes = WebImageCache.get(filePath);
      if (cachedBytes != null) {
        return Image.memory(cachedBytes, fit: fit);
      }
      return fallback ?? const Center(child: Icon(Icons.broken_image_outlined));
    } else {
      final file = File(filePath);
      if (file.existsSync()) {
        return Image.file(file, fit: fit);
      }
      return fallback ?? const Center(child: Icon(Icons.broken_image_outlined));
    }
  }
}
