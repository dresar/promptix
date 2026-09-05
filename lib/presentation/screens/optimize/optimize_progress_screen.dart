import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_colors.dart';
import '../../../domain/entities/image_info_entity.dart';
import '../../../domain/entities/image_history_entity.dart';
import '../../../domain/entities/optimization_result_entity.dart';
import '../../../domain/entities/exif_profile_entity.dart';
import '../../../presentation/providers/image_provider.dart';
import '../../../presentation/providers/history_provider.dart';

class OptimizeProgressScreen extends ConsumerStatefulWidget {
  final ImageInfoEntity imageInfo;
  final String format;
  final int quality;
  final bool replaceOld;
  final String outputPrefix;
  final String metadataProfile;
  final ExifProfileEntity? customProfile;
  final bool watermarkEnabled;
  final String? watermarkLogoPath;
  final String watermarkPosition;
  final double watermarkScale;
  final double watermarkOpacity;

  const OptimizeProgressScreen({
    super.key,
    required this.imageInfo,
    required this.format,
    required this.quality,
    required this.replaceOld,
    required this.outputPrefix,
    required this.metadataProfile,
    this.customProfile,
    this.watermarkEnabled = false,
    this.watermarkLogoPath,
    this.watermarkPosition = 'bottomRight',
    this.watermarkScale = 0.15,
    this.watermarkOpacity = 0.8,
  });

  @override
  ConsumerState<OptimizeProgressScreen> createState() =>
      _OptimizeProgressScreenState();
}

class _OptimizeProgressScreenState
    extends ConsumerState<OptimizeProgressScreen>
    with SingleTickerProviderStateMixin {
  double _progress = 0.0;
  String _statusText = 'Mempersiapkan...';
  bool _hasError = false;
  String? _errorMessage;
  late AnimationController _iconController;

  @override
  void initState() {
    super.initState();
    _iconController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
    _startOptimization();
  }

  @override
  void dispose() {
    _iconController.dispose();
    super.dispose();
  }

  Future<void> _startOptimization() async {
    final optimizeUsecase = ref.read(optimizeImageUsecaseProvider);

    try {
      _updateStatus(0.05, 'Membaca file gambar...');
      await Future.delayed(const Duration(milliseconds: 300));

      _updateStatus(0.15, 'Menganalisis metadata...');
      await Future.delayed(const Duration(milliseconds: 300));

      final result = await optimizeUsecase(
        imageInfo: widget.imageInfo,
        format: widget.format,
        quality: widget.quality,
        outputPrefix: widget.outputPrefix,
        metadataProfile: widget.metadataProfile,
        customProfile: widget.customProfile,
        watermarkEnabled: widget.watermarkEnabled,
        watermarkLogoPath: widget.watermarkLogoPath,
        watermarkPosition: widget.watermarkPosition,
        watermarkScale: widget.watermarkScale,
        watermarkOpacity: widget.watermarkOpacity,
        onProgress: (p) {
          if (p <= 0.35) {
            _updateStatus(0.15 + p * 0.5, 'Mendekode gambar...');
          } else if (p <= 0.85) {
            _updateStatus(0.5 + p * 0.3, 'Mengenkode file baru...');
          } else {
            _updateStatus(0.9 + p * 0.05, 'Menyimpan hasil...');
          }
        },
      );

      _updateStatus(0.95, 'Menyimpan ke riwayat...');

      final saveHistory = ref.read(saveHistoryUsecaseProvider);
      await saveHistory(
        ImageHistoryEntity(
          originalName: widget.imageInfo.fileName,
          originalPath: widget.imageInfo.filePath,
          optimizedPath: result.optimizedPath,
          originalSize: result.originalInfo.fileSize,
          optimizedSize: result.optimizedSize,
          width: result.originalInfo.width,
          height: result.originalInfo.height,
          format: result.outputFormat,
          createdAt: result.completedAt,
        ),
      );

      ref.read(historyProvider.notifier).loadHistory();

      _updateStatus(1.0, 'Selesai!');
      await Future.delayed(const Duration(milliseconds: 600));

      if (!mounted) return;

      if (widget.replaceOld) {
        _showReplaceOldDialog(result.optimizedPath, result);
      } else {
        context.goNamed('result', extra: result);
      }
    } catch (e) {
      setState(() {
        _hasError = true;
        _errorMessage = e.toString().replaceAll('Exception: ', '');
        _statusText = 'Optimasi gagal';
      });
    }
  }

  void _updateStatus(double progress, String text) {
    if (!mounted) return;
    setState(() {
      _progress = progress;
      _statusText = text;
    });
  }

  void _showReplaceOldDialog(
    String newPath,
    OptimizationResultEntity result,
  ) {
    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: Text(
          'Hapus File Asli?',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        content: Text(
          'File baru berhasil dibuat. Apakah kamu ingin menghapus file asli "${widget.imageInfo.fileName}"?',
          style: GoogleFonts.poppins(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              context.goNamed('result', extra: result);
            },
            child: const Text('Tidak'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop();
              if (!kIsWeb) {
                try {
                  final file = File(widget.imageInfo.filePath);
                  if (await file.exists()) {
                    await file.delete();
                  }
                } catch (e) {
                  debugPrint('Gagal menghapus file: $e');
                }
              }
              if (mounted) context.goNamed('result', extra: result);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
            ),
            child: const Text('Ya, Hapus'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mengoptimasi'),
        automaticallyImplyLeading: false,
      ),
      body: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (!_hasError) ...[
              _buildProcessingAnimation(colorScheme),
              const SizedBox(height: 40),
              _buildProgressBar(colorScheme),
              const SizedBox(height: 20),
              _buildStatusText(colorScheme),
              const SizedBox(height: 12),
              _buildFileInfo(colorScheme),
            ] else
              _buildErrorState(colorScheme),
          ],
        ),
      ),
    );
  }

  Widget _buildProcessingAnimation(ColorScheme colorScheme) {
    return AnimatedBuilder(
      animation: _iconController,
      builder: (context, child) {
        return Transform.rotate(
          angle: _iconController.value * 6.28,
          child: child,
        );
      },
      child: Container(
        width: 110,
        height: 110,
        decoration: BoxDecoration(
          gradient: AppColors.accentGradient,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.3),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: const Icon(
          Icons.auto_fix_high_rounded,
          color: Colors.white,
          size: 52,
        ),
      ),
    )
        .animate()
        .scale(
          duration: 600.ms,
          curve: Curves.easeOutBack,
        );
  }

  Widget _buildProgressBar(ColorScheme colorScheme) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Progress',
              style: GoogleFonts.poppins(
                fontSize: 13,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            Text(
              '${(_progress * 100).round()}%',
              style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: colorScheme.primary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            value: _progress,
            minHeight: 10,
            backgroundColor: colorScheme.outline.withValues(alpha: 0.2),
            valueColor: AlwaysStoppedAnimation<Color>(colorScheme.primary),
          ),
        ),
      ],
    );
  }

  Widget _buildStatusText(ColorScheme colorScheme) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      child: Text(
        _statusText,
        key: ValueKey(_statusText),
        style: GoogleFonts.poppins(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: colorScheme.onSurface,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildFileInfo(ColorScheme colorScheme) {
    return Text(
      widget.imageInfo.fileName,
      style: GoogleFonts.poppins(
        fontSize: 13,
        color: colorScheme.onSurfaceVariant,
      ),
      textAlign: TextAlign.center,
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
    );
  }

  Widget _buildErrorState(ColorScheme colorScheme) {
    return Column(
      children: [
        Container(
          width: 88,
          height: 88,
          decoration: const BoxDecoration(
            color: AppColors.errorSurface,
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.error_outline_rounded,
            color: AppColors.error,
            size: 44,
          ),
        )
            .animate()
            .scale(duration: 400.ms, curve: Curves.easeOutBack),
        const SizedBox(height: 24),
        Text(
          'Optimasi Gagal',
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          _errorMessage ?? 'Terjadi kesalahan yang tidak diketahui',
          style: GoogleFonts.poppins(
            fontSize: 14,
            color: colorScheme.onSurfaceVariant,
            height: 1.5,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 32),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () => context.pop(),
            child: const Text('Kembali'),
          ),
        ),
      ],
    );
  }
}
