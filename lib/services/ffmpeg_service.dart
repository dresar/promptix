import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import '../domain/entities/media_edit_config_entity.dart';

class FFmpegProcessingResult {
  final bool success;
  final String outputPath;
  final String? errorMessage;
  final int executionTimeMs;

  const FFmpegProcessingResult({
    required this.success,
    required this.outputPath,
    this.errorMessage,
    this.executionTimeMs = 0,
  });
}

class FFmpegService {
  String? _resolvedExecutablePath;

  /// Mencari lokasi binary `ffmpeg` di PATH sistem atau lokasi umum Windows
  Future<String?> getExecutablePath() async {
    if (kIsWeb) return null;
    if (_resolvedExecutablePath != null) return _resolvedExecutablePath;

    final candidates = [
      'ffmpeg',
      r'C:\ffmpeg\bin\ffmpeg.exe',
      r'C:\Program Files\ffmpeg\bin\ffmpeg.exe',
      r'C:\tools\ffmpeg\bin\ffmpeg.exe',
      p.join(Directory.current.path, 'ffmpeg.exe'),
    ];

    for (final cmd in candidates) {
      try {
        final result = await Process.run(cmd, ['-version']);
        if (result.exitCode == 0) {
          _resolvedExecutablePath = cmd;
          return cmd;
        }
      } catch (_) {}
    }

    return null;
  }

  /// Memeriksa apakah binary `ffmpeg` tersedia di sistem
  Future<bool> isFFmpegAvailable() async {
    if (kIsWeb) return false;
    final execPath = await getExecutablePath();
    return execPath != null;
  }

  /// Menghasilkan filter complex FFmpeg string berdasarkan konfigurasi
  String buildFilterGraph(MediaEditConfigEntity config, {bool hasWatermark = false}) {
    List<String> videoFilters = [];

    // 1. Brightness & Contrast (eq filter)
    if (config.brightness != 0.0 || config.contrast != 1.0) {
      final b = config.brightness.clamp(-1.0, 1.0).toStringAsFixed(2);
      final c = config.contrast.clamp(0.1, 3.0).toStringAsFixed(2);
      videoFilters.add('eq=brightness=$b:contrast=$c');
    }

    // 2. Rotation
    if (config.rotationDegrees == 90) {
      videoFilters.add('transpose=1');
    } else if (config.rotationDegrees == 180) {
      videoFilters.add('transpose=2,transpose=2');
    } else if (config.rotationDegrees == 270) {
      videoFilters.add('transpose=2');
    }

    // 3. Speed multiplier
    if (config.speedMultiplier != 1.0) {
      final pts = (1.0 / config.speedMultiplier).toStringAsFixed(3);
      videoFilters.add('setpts=$pts*PTS');
    }

    String baseVFilter = videoFilters.isNotEmpty ? videoFilters.join(',') : '';

    if (!hasWatermark) {
      return baseVFilter;
    }

    // Watermark Filter Pipeline
    final opacity = config.watermarkOpacity.clamp(0.05, 1.0).toStringAsFixed(2);
    final scale = config.watermarkScale.clamp(0.05, 0.8).toStringAsFixed(2);
    final coordStr = config.watermarkPosition.toFfmpegOverlayCoordinates();

    String filterGraph = '';
    filterGraph += '[1:v]scale=iw*$scale:-1,format=rgba,colorchannelmixer=aa=$opacity[wm];';
    
    if (baseVFilter.isNotEmpty) {
      filterGraph += '[0:v]$baseVFilter[mainv];[mainv][wm]overlay=$coordStr[outv]';
    } else {
      filterGraph += '[0:v][wm]overlay=$coordStr[outv]';
    }

    return filterGraph;
  }

  /// Menjalankan pemrosesan media (Video/Foto) menggunakan FFmpeg CLI Runner
  Future<FFmpegProcessingResult> processMedia({
    required String inputPath,
    required MediaEditConfigEntity config,
    String? customOutputPath,
  }) async {
    final startTime = DateTime.now();

    final inputFile = File(inputPath);
    if (!await inputFile.exists()) {
      return FFmpegProcessingResult(
        success: false,
        outputPath: inputPath,
        errorMessage: 'File input tidak ditemukan: $inputPath',
      );
    }

    final execPath = await getExecutablePath();

    if (execPath == null) {
      return FFmpegProcessingResult(
        success: false,
        outputPath: inputPath,
        errorMessage: 'FFmpeg binary belum terdeteksi di PATH sistem atau lokasi C:\\ffmpeg\\bin.',
      );
    }

    // Tentukan output path
    final ext = _getOutputExtension(inputPath, config);
    final dir = await getTemporaryDirectory();
    final timestamp = startTime.millisecondsSinceEpoch;
    final outputPath = customOutputPath ??
        p.join(dir.path, 'promptix_ffmpeg_${timestamp}_${p.basenameWithoutExtension(inputPath)}.$ext');

    // Cek ketersediaan watermark logo
    final hasWm = config.enableWatermark &&
        config.watermarkLogoPath != null &&
        await File(config.watermarkLogoPath!).exists();

    List<String> args = [];

    if (config.trimStartSeconds != null && config.trimStartSeconds! > 0) {
      args.addAll(['-ss', config.trimStartSeconds!.toStringAsFixed(2)]);
    }

    // Input 0: Main File
    args.addAll(['-i', inputPath]);

    // Input 1: Logo File (jika ada)
    if (hasWm) {
      args.addAll(['-i', config.watermarkLogoPath!]);
    }

    if (config.trimEndSeconds != null && config.trimEndSeconds! > 0) {
      final duration = (config.trimEndSeconds! - (config.trimStartSeconds ?? 0)).clamp(0.1, 86400.0);
      args.addAll(['-t', duration.toStringAsFixed(2)]);
    }

    // Build Complex Filter
    final filterGraph = buildFilterGraph(config, hasWatermark: hasWm);

    if (hasWm) {
      args.addAll(['-filter_complex', filterGraph, '-map', '[outv]']);
      if (config.isVideo && !config.muteAudio) {
        args.addAll(['-map', '0:a?']);
      }
    } else if (filterGraph.isNotEmpty) {
      args.addAll(['-vf', filterGraph]);
    }

    // Audio configurations
    if (config.isVideo) {
      if (config.muteAudio) {
        args.add('-an');
      } else if (config.speedMultiplier != 1.0) {
        final tempo = config.speedMultiplier.clamp(0.5, 2.0).toStringAsFixed(2);
        args.addAll(['-af', 'atempo=$tempo']);
      }
    }

    // Container Metadata Handling
    if (config.metadataAction == PostMetadataAction.scrubAndSpoof ||
        config.metadataAction == PostMetadataAction.scrubOnly) {
      args.addAll(['-map_metadata', '-1']);
      
      if (config.metadataAction == PostMetadataAction.scrubAndSpoof) {
        args.addAll([
          '-metadata', 'title=Processed by Promptix Privacy Studio',
          '-metadata', 'artist=${_getDeviceBrand(config)}',
          '-metadata', 'comment=Cleaned & Spoofed Media',
        ]);
      }
    }

    // Quality tuning
    if (config.isVideo) {
      args.addAll([
        '-c:v', 'libx264',
        '-preset', 'fast',
        '-crf', _calculateCrf(config.quality).toString(),
        '-c:a', 'aac',
        '-b:a', '128k',
      ]);
    } else {
      args.addAll([
        '-q:v', ((100 - config.quality) ~/ 5).clamp(1, 31).toString(),
      ]);
    }

    // Overwrite output
    args.addAll(['-y', outputPath]);

    try {
      debugPrint('Running FFmpeg Command: $execPath ${args.join(" ")}');

      final result = await Process.run(execPath, args);
      final elapsed = DateTime.now().difference(startTime).inMilliseconds;

      if (result.exitCode == 0 && await File(outputPath).exists()) {
        return FFmpegProcessingResult(
          success: true,
          outputPath: outputPath,
          executionTimeMs: elapsed,
        );
      } else {
        return FFmpegProcessingResult(
          success: false,
          outputPath: inputPath,
          errorMessage: 'FFmpeg error (${result.exitCode}): ${result.stderr}',
          executionTimeMs: elapsed,
        );
      }
    } catch (e) {
      return FFmpegProcessingResult(
        success: false,
        outputPath: inputPath,
        errorMessage: 'Gagal memproses media via FFmpeg: $e',
      );
    }
  }

  String _getOutputExtension(String inputPath, MediaEditConfigEntity config) {
    if (config.isVideo) {
      return config.outputFormat.toLowerCase();
    }
    final inputExt = p.extension(inputPath).replaceFirst('.', '').toLowerCase();
    if (config.outputFormat.isNotEmpty) {
      return config.outputFormat.toLowerCase();
    }
    return inputExt.isEmpty ? 'jpg' : inputExt;
  }

  int _calculateCrf(int quality) {
    return (35 - ((quality / 100) * 17)).round().clamp(18, 35);
  }

  String _getDeviceBrand(MediaEditConfigEntity config) {
    switch (config.metadataProfilePreset.toLowerCase()) {
      case 'sony':
        return 'Sony ILCE-7RM4';
      case 'canon':
        return 'Canon EOS R5';
      case 'iphone':
        return 'Apple iPhone 15 Pro';
      case 'samsung':
        return 'Samsung Galaxy S24 Ultra';
      default:
        return 'Promptix Device';
    }
  }
}
