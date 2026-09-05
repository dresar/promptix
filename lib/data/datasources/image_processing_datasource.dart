import 'dart:io';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';
import 'package:image/src/util/rational.dart'; // ignore: implementation_imports
import '../../../core/constants/app_constants.dart';
import '../../../domain/entities/image_info_entity.dart';
import '../../../domain/entities/optimization_result_entity.dart';
import '../../../domain/entities/exif_profile_entity.dart';
import 'c2pa_scrubber.dart';
import 'local/web_image_cache.dart';

class ImageProcessingDatasource {
  Future<ImageInfoEntity> readImageInfo(String filePath) async {
    final Uint8List bytes;
    final int size;
    final String fileName;
    final String extension;
    DateTime modified = DateTime.now();

    if (kIsWeb) {
      final cachedBytes = WebImageCache.get(filePath);
      if (cachedBytes == null) {
        throw Exception('Data gambar tidak ditemukan di cache web');
      }
      bytes = cachedBytes;
      size = bytes.length;
      fileName = filePath.split('/').last.split('\\').last;
      extension = fileName.split('.').last.toUpperCase();
    } else {
      final file = File(filePath);
      if (!await file.exists()) {
        throw Exception('File tidak ditemukan: $filePath');
      }
      bytes = await file.readAsBytes();
      final stat = await file.stat();
      size = stat.size;
      modified = stat.modified;
      fileName = p.basename(filePath);
      extension = p.extension(filePath).replaceFirst('.', '').toUpperCase();
    }

    // ── C2PA + AI Signature scan (di level byte raw) ──────────────────────
    final ext = extension.toLowerCase();
    final c2paScan = C2paScrubber.scrub(bytes, ext);
    final aiSig = C2paScrubber.detectAiSignature(bytes);

    final decoded = img.decodeImage(bytes);

    final exifData = <String, String>{};
    if (decoded != null) {
      _extractExifData(decoded, exifData);
    }

    return ImageInfoEntity(
      filePath: filePath,
      fileName: fileName,
      fileSize: size,
      width: decoded?.width ?? 0,
      height: decoded?.height ?? 0,
      format: extension.isEmpty ? 'JPEG' : extension,
      createdAt: modified,
      modifiedAt: modified,
      exifData: exifData,
      hasC2pa: c2paScan.hasC2pa,
      aiSoftwareDetected: aiSig.software,
      aiSignatureKeywords: aiSig.keywords,
    );
  }

  void _extractExifData(img.Image decoded, Map<String, String> data) {
    try {
      if (!decoded.hasExif) return;
      final exif = decoded.exif;

      for (final name in exif.directories.keys) {
        final directory = exif.directories[name]!;
        for (final tag in directory.keys) {
          final value = directory[tag];
          if (value != null) {
            final tagName = exif.getTagName(tag);
            final str = value.toString().trim();
            if (str.isNotEmpty && str != '0' && str != 'null') {
              data[_formatExifKey(tagName)] = str;
            }
          }
        }
        for (final subName in directory.sub.keys) {
          final subDirectory = directory.sub[subName];
          for (final tag in subDirectory.keys) {
            final value = subDirectory[tag];
            if (value != null) {
              final tagName = exif.getTagName(tag);
              final str = value.toString().trim();
              if (str.isNotEmpty && str != '0' && str != 'null') {
                data[_formatExifKey(tagName)] = str;
              }
            }
          }
        }
      }

      final gpsIfd = exif.gpsIfd;
      if (gpsIfd.keys.isNotEmpty) {
        final lat = gpsIfd['GPSLatitude'];
        final lon = gpsIfd['GPSLongitude'];
        final latRef = gpsIfd['GPSLatitudeRef']?.toString() ?? 'N';
        final lonRef = gpsIfd['GPSLongitudeRef']?.toString() ?? 'E';
        if (lat != null && lon != null) {
          data['Koordinat GPS'] =
              '${lat.toDouble()} $latRef, ${lon.toDouble()} $lonRef';
          data.remove('GPS Latitude');
          data.remove('GPS Longitude');
          data.remove('Arah Lintang GPS');
          data.remove('Arah Bujur GPS');
        }
      }
    } catch (_) {}
  }

  String _formatExifKey(String tagName) {
    switch (tagName) {
      case 'Make':
        return 'Merek Kamera';
      case 'Model':
        return 'Model Kamera';
      case 'Software':
        return 'Perangkat Lunak';
      case 'Artist':
        return 'Seniman';
      case 'Copyright':
        return 'Hak Cipta';
      case 'DateTime':
        return 'Tanggal Diubah';
      case 'XResolution':
        return 'Resolusi X';
      case 'YResolution':
        return 'Resolusi Y';
      case 'ImageDescription':
        return 'Deskripsi Gambar';
      case 'ExposureTime':
        return 'Waktu Eksposur';
      case 'FNumber':
        return 'Aperture (F-Number)';
      case 'ISOSpeedRatings':
        return 'ISO';
      case 'Flash':
        return 'Flash';
      case 'FocalLength':
        return 'Focal Length';
      case 'ColorSpace':
        return 'Color Space';
      case 'DateTimeOriginal':
        return 'Tanggal Asli Pembuatan';
      case 'DateTimeDigitized':
        return 'Tanggal Digitalisasi';
      case 'PixelXDimension':
        return 'Lebar Pixel';
      case 'PixelYDimension':
        return 'Tinggi Pixel';
      case 'GPSLatitude':
        return 'GPS Latitude';
      case 'GPSLongitude':
        return 'GPS Longitude';
      case 'GPSAltitude':
        return 'GPS Ketinggian';
      case 'GPSTimeStamp':
        return 'GPS Waktu';
      case 'GPSDateStamp':
        return 'GPS Tanggal';
      case 'GPSLatitudeRef':
        return 'Arah Lintang GPS';
      case 'GPSLongitudeRef':
        return 'Arah Bujur GPS';
      case 'UserComment':
        return 'Komentar Pengguna';
      default:
        return tagName.replaceAllMapped(
          RegExp(r'(?<=[a-z])(?=[A-Z])'),
          (Match m) => ' ',
        );
    }
  }

  Future<OptimizationResultEntity> optimizeImage({
    required ImageInfoEntity imageInfo,
    required String format,
    required int quality,
    required String outputPrefix,
    required String metadataProfile,
    ExifProfileEntity? customProfile,
    String? customOutputPath,
    void Function(double)? onProgress,
    bool watermarkEnabled = false,
    String? watermarkLogoPath,
    String watermarkPosition = 'bottomRight',
    double watermarkScale = 0.15,
    double watermarkOpacity = 0.8,
  }) async {
    onProgress?.call(0.05);

    Uint8List sourceBytes;
    if (kIsWeb) {
      final cachedBytes = WebImageCache.get(imageInfo.filePath);
      if (cachedBytes == null) {
        throw Exception('File sumber tidak ditemukan di cache web');
      }
      sourceBytes = cachedBytes;
    } else {
      final sourceFile = File(imageInfo.filePath);
      if (!await sourceFile.exists()) {
        throw Exception('File sumber tidak ditemukan');
      }
      sourceBytes = await sourceFile.readAsBytes();
    }
    onProgress?.call(0.15);

    // ── C2PA Scrub (byte level, sebelum decode) ───────────────────────────
    final ext = format.toLowerCase() == 'jpg' ? 'jpeg' : format.toLowerCase();
    final scrubResult = C2paScrubber.scrub(sourceBytes, ext);
    if (scrubResult.hasC2pa || scrubResult.removedChunks.isNotEmpty) {
      sourceBytes = scrubResult.cleanBytes;
    }
    onProgress?.call(0.25);

    // Load watermark logo bytes on main thread if enabled
    Uint8List? watermarkLogoBytes;
    if (watermarkEnabled && watermarkLogoPath != null) {
      try {
        final logoFile = File(watermarkLogoPath);
        if (await logoFile.exists()) {
          watermarkLogoBytes = await logoFile.readAsBytes();
        }
      } catch (_) {}
    }

    final params = _OptimizeParams(
      bytes: sourceBytes,
      format: format,
      quality: quality,
      metadataProfile: metadataProfile,
      customProfile: customProfile,
      watermarkEnabled: watermarkEnabled,
      watermarkLogoBytes: watermarkLogoBytes,
      watermarkPosition: watermarkPosition,
      watermarkScale: watermarkScale,
      watermarkOpacity: watermarkOpacity,
    );

    onProgress?.call(0.35);
    final outputBytes = await compute(_optimizeImageInIsolate, params);
    onProgress?.call(0.85);

    final String outputPath;
    if (kIsWeb) {
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final outputFileName = _generateOutputFileName(outputPrefix, format);
      outputPath = 'web_image_optimized_${timestamp}_$outputFileName';
      WebImageCache.put(outputPath, outputBytes);
      onProgress?.call(1.0);
    } else {
      final outputDir = await _resolveOutputDirectory(customOutputPath);
      final outputFileName = _generateOutputFileName(outputPrefix, format);
      final outputFile = File(p.join(outputDir.path, outputFileName));

      await outputFile.writeAsBytes(outputBytes);
      outputPath = outputFile.path;

      // Trigger MediaScanner on Android so that it shows up in gallery/album instantly
      if (Platform.isAndroid) {
        try {
          const channel = MethodChannel('com.example.promptix/media_scanner');
          await channel.invokeMethod('scanFile', {'path': outputPath});
        } catch (e) {
          debugPrint('Gagal melakukan pemindaian media: $e');
        }
      }

      onProgress?.call(1.0);
    }

    return OptimizationResultEntity(
      originalInfo: imageInfo,
      optimizedPath: outputPath,
      optimizedSize: outputBytes.length,
      outputFormat: format.toUpperCase(),
      completedAt: DateTime.now(),
    );
  }

  Future<Directory> _resolveOutputDirectory(String? customPath) async {
    if (customPath != null && customPath.isNotEmpty) {
      final dir = Directory(customPath);
      if (!await dir.exists()) {
        await dir.create(recursive: true);
      }
      return dir;
    }

    final extDir = await getExternalStorageDirectory();
    String basePath =
        extDir?.path ?? (await getApplicationDocumentsDirectory()).path;

    if (!kIsWeb && Platform.isAndroid && extDir != null) {
      final int androidIdx = extDir.path.indexOf('/Android/data');
      if (androidIdx != -1) {
        basePath = p.join(extDir.path.substring(0, androidIdx), 'Pictures');
      }
    }

    final outputDir =
        Directory(p.join(basePath, AppConstants.defaultOutputFolder));
    if (!await outputDir.exists()) {
      await outputDir.create(recursive: true);
    }
    return outputDir;
  }

  String _normalizeExtension(String format) {
    switch (format.toLowerCase()) {
      case 'jpeg':
        return 'jpg';
      case 'webp':
        return 'webp';
      case 'png':
        return 'png';
      default:
        return 'jpg';
    }
  }

  Future<void> deleteFile(String path) async {
    if (kIsWeb) {
      WebImageCache.remove(path);
    } else {
      final file = File(path);
      if (await file.exists()) {
        await file.delete();
      }
    }
  }

  String _generateOutputFileName(String? prefix, String format) {
    final cleanPrefix = prefix ?? AppConstants.defaultFilePrefix;
    final now = DateTime.now();
    final dateStr = '${now.year}${_pad(now.month)}${_pad(now.day)}';
    final timeStr = '${_pad(now.hour)}${_pad(now.minute)}${_pad(now.second)}';
    final ms = now.millisecond.toString().padLeft(3, '0');
    final ext = _normalizeExtension(format);
    return '$cleanPrefix${dateStr}_${timeStr}_$ms.$ext';
  }

  String _pad(int val) => val.toString().padLeft(2, '0');
}

// ─────────────────────────────────────────────────────────────────────────────
// Isolate params & processing
// ─────────────────────────────────────────────────────────────────────────────

class _OptimizeParams {
  final Uint8List bytes;
  final String format;
  final int quality;
  final String metadataProfile;
  final ExifProfileEntity? customProfile;
  final bool watermarkEnabled;
  final Uint8List? watermarkLogoBytes;
  final String watermarkPosition;
  final double watermarkScale;
  final double watermarkOpacity;

  const _OptimizeParams({
    required this.bytes,
    required this.format,
    required this.quality,
    required this.metadataProfile,
    this.customProfile,
    this.watermarkEnabled = false,
    this.watermarkLogoBytes,
    this.watermarkPosition = 'bottomRight',
    this.watermarkScale = 0.15,
    this.watermarkOpacity = 0.8,
  });
}

Uint8List _optimizeImageInIsolate(_OptimizeParams params) {
  final decoded = img.decodeImage(params.bytes);
  if (decoded == null) {
    throw Exception('Format gambar tidak didukung atau file rusak');
  }

  // WIPE semua metadata lama
  decoded.exif = img.ExifData();
  decoded.textData = null;
  decoded.iccProfile = null;

  final nowDateTime = DateTime.now();
  final String nowStr =
      DateFormat('yyyy:MM:dd HH:mm:ss').format(nowDateTime);

  // Pilih profile yang akan dipakai
  final profile = params.metadataProfile.toLowerCase();

  // Jika ada custom profile dari entity, gunakan itu
  if (params.customProfile != null || profile == 'custom') {
    final cp = params.customProfile;
    if (cp != null && cp.id != 'clean') {
      _applyExifProfile(decoded, cp, nowDateTime, nowStr);
    }
  } else {
    // Built-in profiles (backward compat + tambahan baru)
    _applyBuiltInProfile(decoded, profile, nowStr, nowDateTime);
  }

  // Draw Watermark
  if (params.watermarkEnabled && params.watermarkLogoBytes != null) {
    try {
      final logoImage = img.decodeImage(params.watermarkLogoBytes!);
      if (logoImage != null) {
        final scale = params.watermarkScale;
        final targetWidth = (decoded.width * scale).round();
        final aspectRatio = logoImage.width / logoImage.height;
        final targetHeight = (targetWidth / aspectRatio).round();

        final resizedLogo = img.copyResize(
          logoImage,
          width: targetWidth,
          height: targetHeight,
          interpolation: img.Interpolation.average,
        );

        var watermark = resizedLogo;
        if (watermark.numChannels < 4) {
          final rgba = img.Image(
            width: watermark.width,
            height: watermark.height,
            numChannels: 4,
          );
          img.compositeImage(rgba, watermark);
          watermark = rgba;
        }

        final opacity = params.watermarkOpacity;
        if (opacity < 1.0) {
          for (final pixel in watermark) {
            pixel.a = (pixel.a * opacity).round();
          }
        }

        int x = 0;
        int y = 0;
        const margin = 20;

        switch (params.watermarkPosition) {
          case 'topLeft':
            x = margin;
            y = margin;
            break;
          case 'topRight':
            x = decoded.width - watermark.width - margin;
            y = margin;
            break;
          case 'bottomLeft':
            x = margin;
            y = decoded.height - watermark.height - margin;
            break;
          case 'bottomRight':
          default:
            x = decoded.width - watermark.width - margin;
            y = decoded.height - watermark.height - margin;
            break;
        }

        x = x.clamp(0, decoded.width - watermark.width);
        y = y.clamp(0, decoded.height - watermark.height);

        img.compositeImage(
          decoded,
          watermark,
          dstX: x,
          dstY: y,
        );
      }
    } catch (_) {}
  }

  // Encode output
  switch (params.format.toLowerCase()) {
    case 'jpg':
    case 'jpeg':
      return Uint8List.fromList(
        img.encodeJpg(decoded, quality: params.quality),
      );
    case 'png':
      return Uint8List.fromList(img.encodePng(decoded));
    case 'webp':
      return Uint8List.fromList(img.encodeWebP(decoded));
    default:
      return Uint8List.fromList(
        img.encodeJpg(decoded, quality: params.quality),
      );
  }
}

/// Apply profil EXIF dari ExifProfileEntity (untuk custom profiles)
void _applyExifProfile(
  img.Image decoded,
  ExifProfileEntity profile,
  DateTime now,
  String nowStr,
) {
  final exif = img.ExifData();

  // ── Timestamp ──────────────────────────────────────────────────────────
  final targetDate = _resolveTimestamp(now, profile);
  final dateStr = DateFormat('yyyy:MM:dd HH:mm:ss').format(targetDate);

  // ── Kamera ────────────────────────────────────────────────────────────
  if (profile.cameraMake != null && profile.cameraMake!.isNotEmpty) {
    exif.imageIfd.make = profile.cameraMake!;
  }
  if (profile.cameraModel != null && profile.cameraModel!.isNotEmpty) {
    exif.imageIfd.model = profile.cameraModel!;
  }
  if (profile.software != null && profile.software!.isNotEmpty) {
    exif.imageIfd.software = profile.software!;
  }
  if (profile.artistName != null) {
    exif.imageIfd[315] = profile.artistName!; // EXIF Artist tag
  }
  if (profile.copyright != null) {
    exif.imageIfd[33432] = profile.copyright!; // EXIF Copyright tag
  }
  exif.imageIfd.orientation = 1;
  exif.imageIfd[306] = dateStr; // DateTime (Modified)

  // ── Lens ──────────────────────────────────────────────────────────────
  if (profile.lensModel != null && profile.lensModel!.isNotEmpty) {
    exif.exifIfd[42036] = profile.lensModel!; // LensModel
  }

  // ── Exposure ──────────────────────────────────────────────────────────
  if (profile.apertureF != null) {
    final fn = (profile.apertureF! * 10).round();
    exif.exifIfd[33437] = Rational(fn, 10); // FNumber
  }
  if (profile.isoSpeed != null) {
    exif.exifIfd[34855] = profile.isoSpeed!; // ISOSpeedRatings
  }
  if (profile.shutterSpeedDenom != null && profile.shutterSpeedDenom! > 0) {
    exif.exifIfd[33434] =
        Rational(1, profile.shutterSpeedDenom!.round()); // ExposureTime
  }
  if (profile.focalLengthMm != null) {
    final fl = (profile.focalLengthMm! * 100).round();
    exif.exifIfd[37386] = Rational(fl, 100); // FocalLength
  }
  if (profile.whiteBalanceMode != null) {
    exif.exifIfd[41987] = profile.whiteBalanceMode!; // WhiteBalance
  }
  if (profile.flashMode != null) {
    exif.exifIfd[37385] = profile.flashMode!; // Flash
  }

  // ── Tanggal ───────────────────────────────────────────────────────────
  exif.exifIfd[36867] = dateStr; // DateTimeOriginal
  exif.exifIfd[36868] = dateStr; // DateTimeDigitized
  exif.exifIfd[40961] = 1; // ColorSpace: sRGB
  exif.exifIfd[40962] = decoded.width;
  exif.exifIfd[40963] = decoded.height;

  // ── GPS ───────────────────────────────────────────────────────────────
  if (profile.enableGps &&
      profile.gpsLatitude != null &&
      profile.gpsLongitude != null) {
    _injectGps(exif, profile.gpsLatitude!, profile.gpsLongitude!,
        profile.gpsAltitudeM ?? 0.0, targetDate);
  }

  decoded.exif = exif;
}

/// Apply built-in profiles (termasuk yang baru: pixel9pro, sony, canon, dll)
void _applyBuiltInProfile(
  img.Image decoded,
  String profile,
  String nowStr,
  DateTime now,
) {
  if (profile == 'clean') return; // no metadata

  final exif = img.ExifData();

  // Semua profil share base setup
  exif.imageIfd.orientation = 1;
  exif.imageIfd[306] = nowStr;
  exif.exifIfd[36867] = nowStr;
  exif.exifIfd[36868] = nowStr;
  exif.exifIfd[40961] = 1;
  exif.exifIfd[40962] = decoded.width;
  exif.exifIfd[40963] = decoded.height;

  switch (profile) {
    case 'iphone':
    case 'iphone15pro':
      exif.imageIfd.make = 'Apple';
      exif.imageIfd.model = 'iPhone 15 Pro';
      exif.imageIfd.software = '17.5.1';
      exif.exifIfd[33437] = Rational(178, 100); // F1.78
      exif.exifIfd[34855] = 100;
      exif.exifIfd[33434] = Rational(1, 120);
      exif.exifIfd[37386] = Rational(676, 100);
      exif.exifIfd[42036] =
          'iPhone 15 Pro back triple camera 6.765mm f/1.78';
      exif.exifIfd[41987] = 0; // Auto WB
      exif.exifIfd[37385] = 16; // Flash not fired
      break;

    case 'samsung':
    case 'samsungs24ultra':
      exif.imageIfd.make = 'samsung';
      exif.imageIfd.model = 'SM-S928B';
      exif.imageIfd.software = 'SM-S928BXXU1AXB5';
      exif.exifIfd[33437] = Rational(17, 10);
      exif.exifIfd[34855] = 50;
      exif.exifIfd[33434] = Rational(1, 180);
      exif.exifIfd[37386] = Rational(63, 10);
      exif.exifIfd[41987] = 0;
      exif.exifIfd[37385] = 16;
      break;

    case 'pixel9pro':
      exif.imageIfd.make = 'Google';
      exif.imageIfd.model = 'Pixel 9 Pro';
      exif.imageIfd.software = 'Pixel Experience 14';
      exif.exifIfd[33437] = Rational(168, 100); // F1.68
      exif.exifIfd[34855] = 66;
      exif.exifIfd[33434] = Rational(1, 200);
      exif.exifIfd[37386] = Rational(600, 100); // 6mm
      exif.exifIfd[42036] = 'rear';
      exif.exifIfd[41987] = 0;
      exif.exifIfd[37385] = 0;
      break;

    case 'sonyxperia1vi':
      exif.imageIfd.make = 'Sony';
      exif.imageIfd.model = 'XQ-EC54';
      exif.imageIfd.software = '65.2.A.0.404';
      exif.exifIfd[33437] = Rational(19, 10); // F1.9
      exif.exifIfd[34855] = 125;
      exif.exifIfd[33434] = Rational(1, 250);
      exif.exifIfd[37386] = Rational(400, 100); // 4mm
      exif.exifIfd[41987] = 0;
      exif.exifIfd[37385] = 0;
      break;

    case 'canoneosr6':
      exif.imageIfd.make = 'Canon';
      exif.imageIfd.model = 'Canon EOS R6 Mark II';
      exif.imageIfd.software = 'Digital Photo Professional 4.22.30';
      exif.exifIfd[33437] = Rational(28, 10); // F2.8
      exif.exifIfd[34855] = 400;
      exif.exifIfd[33434] = Rational(1, 500);
      exif.exifIfd[37386] = Rational(5000, 100); // 50mm
      exif.exifIfd[42036] = 'RF 50mm F1.8 STM';
      exif.exifIfd[41987] = 0;
      exif.exifIfd[37385] = 0;
      break;

    case 'nikonz8':
      exif.imageIfd.make = 'NIKON CORPORATION';
      exif.imageIfd.model = 'NIKON Z 8';
      exif.imageIfd.software = 'Ver.1.30';
      exif.exifIfd[33437] = Rational(20, 10); // F2.0
      exif.exifIfd[34855] = 200;
      exif.exifIfd[33434] = Rational(1, 640);
      exif.exifIfd[37386] = Rational(5000, 100); // 50mm
      exif.exifIfd[42036] = 'NIKKOR Z 50mm f/1.8 S';
      exif.exifIfd[41987] = 0;
      exif.exifIfd[37385] = 0;
      break;

    case 'fujifilmxt5':
      exif.imageIfd.make = 'FUJIFILM';
      exif.imageIfd.model = 'X-T5';
      exif.imageIfd.software = 'Fujifilm X RAW STUDIO';
      exif.exifIfd[33437] = Rational(20, 10); // F2.0
      exif.exifIfd[34855] = 160;
      exif.exifIfd[33434] = Rational(1, 400);
      exif.exifIfd[37386] = Rational(2300, 100); // 23mm
      exif.exifIfd[42036] = 'XF23mmF1.4 R LM WR';
      exif.exifIfd[41987] = 0;
      exif.exifIfd[37385] = 0;
      break;

    case 'djimini4pro':
      exif.imageIfd.make = 'DJI';
      exif.imageIfd.model = 'FC4582';
      exif.imageIfd.software = '01.00.0500';
      exif.exifIfd[33437] = Rational(17, 10); // F1.7
      exif.exifIfd[34855] = 100;
      exif.exifIfd[33434] = Rational(1, 1000);
      exif.exifIfd[37386] = Rational(450, 100); // 4.5mm
      exif.exifIfd[41987] = 0;
      exif.exifIfd[37385] = 0;
      break;

    case 'photoshop':
      exif.imageIfd.software = 'Adobe Photoshop 26.0 (Windows)';
      exif.imageIfd.make = '';
      exif.imageIfd.model = '';
      break;
  }

  decoded.exif = exif;
}

/// Inject GPS coordinates ke EXIF
void _injectGps(
  img.ExifData exif,
  double lat,
  double lon,
  double altM,
  DateTime date,
) {
  final absLat = lat.abs();
  final absLon = lon.abs();

  exif.gpsIfd[1] = lat >= 0 ? 'N' : 'S'; // GPSLatitudeRef
  exif.gpsIfd[2] = _decimalToGpsRational(absLat); // GPSLatitude
  exif.gpsIfd[3] = lon >= 0 ? 'E' : 'W'; // GPSLongitudeRef
  exif.gpsIfd[4] = _decimalToGpsRational(absLon); // GPSLongitude
  exif.gpsIfd[5] = 0; // GPSAltitudeRef (above sea level)
  exif.gpsIfd[6] = Rational(altM.round(), 1); // GPSAltitude
  exif.gpsIfd[7] = DateFormat('HH:mm:ss').format(date); // GPSTimeStamp
  exif.gpsIfd[29] = DateFormat('yyyy:MM:dd').format(date); // GPSDateStamp
}

/// Convert decimal degrees to Rational (degrees as fraction, stored as deg/1)
/// The image package stores GPS lat/lon as a single Rational of total seconds * 100
Rational _decimalToGpsRational(double decimalDeg) {
  // Store as total seconds * 100 over 360000 (= 100 * 3600)
  final totalSeconds = (decimalDeg * 3600 * 100).round();
  return Rational(totalSeconds, 360000);
}


/// Hitung target timestamp berdasarkan mode profil
DateTime _resolveTimestamp(DateTime now, ExifProfileEntity profile) {
  switch (profile.timestampMode) {
    case TimestampMode.current:
      return now;
    case TimestampMode.fixed:
      return now.subtract(Duration(days: profile.timestampOffsetDays));
    case TimestampMode.random:
      final rng = Random.secure();
      final maxOffset = profile.timestampOffsetDays.clamp(1, 365);
      final offsetDays = rng.nextInt(maxOffset) + 1;
      final offsetHours = rng.nextInt(12);
      final offsetMinutes = rng.nextInt(60);
      return now.subtract(Duration(
        days: offsetDays,
        hours: offsetHours,
        minutes: offsetMinutes,
      ));
  }
}
