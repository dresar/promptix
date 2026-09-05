import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

class WatermarkService {
  Future<String> getWatermarkDir() async {
    final appDir = await getApplicationDocumentsDirectory();
    final dir = Directory(p.join(appDir.path, 'watermarks'));
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir.path;
  }

  Future<List<File>> getWatermarks() async {
    final dirPath = await getWatermarkDir();
    final dir = Directory(dirPath);
    List<FileSystemEntity> entities = await dir.list().toList();
    
    // Hanya ambil file gambar yang didukung (PNG, JPG/JPEG, WebP)
    List<File> files = [];
    for (final entity in entities) {
      if (entity is File) {
        final ext = p.extension(entity.path).toLowerCase();
        if (ext == '.png' || ext == '.jpg' || ext == '.jpeg' || ext == '.webp') {
          files.add(entity);
        }
      }
    }
    
    // Urutkan berdasarkan nama file
    files.sort((a, b) => p.basename(a.path).toLowerCase().compareTo(p.basename(b.path).toLowerCase()));
    return files;
  }

  Future<File> saveWatermark(File originalFile) async {
    final dirPath = await getWatermarkDir();
    
    // Buat nama file unik menggunakan timestamp + nama asli disanitasi
    final originalName = p.basename(originalFile.path);
    final cleanName = originalName.replaceAll(RegExp(r'[^\w\.\-]'), '_');
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final newFileName = 'wm_${timestamp}_$cleanName';
    
    final destinationPath = p.join(dirPath, newFileName);
    return originalFile.copy(destinationPath);
  }

  Future<void> deleteWatermark(File watermarkFile) async {
    if (await watermarkFile.exists()) {
      await watermarkFile.delete();
    }
  }
}
