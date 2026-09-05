
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/extensions/file_extension.dart';
import '../../../domain/entities/image_history_entity.dart';
import '../../../domain/entities/image_info_entity.dart';
import '../../../presentation/providers/image_provider.dart';
import '../../../services/share_service.dart';
import '../../../widgets/app_card.dart';
import '../../../widgets/info_row_widget.dart';
import '../../../widgets/local_image_preview.dart';
import '../../../widgets/section_header.dart';
import '../image_info/widgets/ai_detector_card.dart';

class HistoryDetailScreen extends ConsumerStatefulWidget {
  final ImageHistoryEntity item;

  const HistoryDetailScreen({super.key, required this.item});

  @override
  ConsumerState<HistoryDetailScreen> createState() => _HistoryDetailScreenState();
}

class _HistoryDetailScreenState extends ConsumerState<HistoryDetailScreen> {
  ImageInfoEntity? _optimizedInfo;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadOptimizedFileInfo();
  }

  Future<void> _loadOptimizedFileInfo() async {
    try {
      final imageNotifier = ref.read(imageNotifierProvider.notifier);
      final info = await imageNotifier.loadImageInfo(widget.item.optimizedPath);
      if (mounted) {
        setState(() {
          _optimizedInfo = info;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Detail Hasil'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => context.pop(),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildImagePreview(context),
                        const SizedBox(height: 20),
                        _buildSavingsBanner(context),
                        const SizedBox(height: 20),
                        _buildInfoSection(context),
                        const SizedBox(height: 20),
                        if (_optimizedInfo != null) ...[
                          AiDetectorCard(imageInfo: _optimizedInfo!),
                          const SizedBox(height: 20),
                          if (_optimizedInfo!.hasExif) ...[
                            _buildMetadataSection(context),
                            const SizedBox(height: 20),
                          ],
                        ] else ...[
                          _buildDeletedFileWarningCard(context),
                          const SizedBox(height: 20),
                        ],
                        _buildFilePathSection(context),
                        const SizedBox(height: 28),
                        _buildActionButtons(context),
                        const SizedBox(height: 32),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildImagePreview(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: SizedBox(
        width: double.infinity,
        height: 240,
        child: LocalImagePreview(
          filePath: widget.item.optimizedPath,
          fit: BoxFit.cover,
          fallback: Container(
            color: isDark ? AppColors.surfaceDark2 : AppColors.surfaceLight2,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.broken_image_outlined,
                  size: 48,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                const SizedBox(height: 8),
                Text(
                  'File tidak ditemukan',
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    )
        .animate()
        .fadeIn(duration: 400.ms);
  }

  Widget _buildSavingsBanner(BuildContext context) {
    final pct = widget.item.savedPercentage;
    final saved = widget.item.savedBytes;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: AppColors.successGradient,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          const Icon(Icons.compress_outlined, color: Colors.white, size: 28),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Penghematan ${pct.toStringAsFixed(1)}%',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              Text(
                'Berkurang ${saved.toReadableSize()}',
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  color: Colors.white.withValues(alpha: 0.9),
                ),
              ),
            ],
          ),
        ],
      ),
    )
        .animate()
        .fadeIn(delay: 100.ms, duration: 400.ms)
        .slideY(begin: 0.05, end: 0);
  }

  Widget _buildInfoSection(BuildContext context) {
    final name = _optimizedInfo?.fileName ?? widget.item.originalName;
    final size = _optimizedInfo?.fileSize.toReadableSize() ?? widget.item.optimizedSize.toReadableSize();
    final resolution = _optimizedInfo?.resolution ?? widget.item.resolution;
    final format = _optimizedInfo?.format.toUpperCase() ?? widget.item.format.toUpperCase();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Informasi File Hasil',
          style: GoogleFonts.poppins(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 12),
        AppCard(
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              InfoRowWidget(label: 'Nama File', value: name),
              InfoRowWidget(
                label: 'Ukuran Asli',
                value: widget.item.originalSize.toReadableSize(),
                valueColor: AppColors.error,
              ),
              InfoRowWidget(
                label: 'Ukuran Baru',
                value: size,
                valueColor: AppColors.success,
              ),
              InfoRowWidget(label: 'Resolusi', value: resolution),
              InfoRowWidget(label: 'Format', value: format),
              InfoRowWidget(
                label: 'Tanggal Optimasi',
                value: DateFormat('dd MMMM yyyy, HH:mm').format(widget.item.createdAt),
                isDivided: false,
              ),
            ],
          ),
        )
            .animate()
            .fadeIn(delay: 200.ms, duration: 400.ms),
      ],
    );
  }

  Widget _buildDeletedFileWarningCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.errorSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.error.withValues(alpha: 0.4)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.warning_amber_rounded,
            color: AppColors.error,
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'File Gambar Tidak Ditemukan',
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF991B1B),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'File hasil optimasi telah dihapus, dipindahkan, atau tidak dapat diakses lagi di penyimpanan perangkat.',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: const Color(0xFF7F1D1D),
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetadataSection(BuildContext context) {
    if (_optimizedInfo == null) return const SizedBox.shrink();
    final entries = _optimizedInfo!.exifData.entries.toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          title: 'Metadata Terbaru (EXIF)',
          subtitle: '${entries.length} data ditemukan pada file hasil',
          trailing: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.success.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '${entries.length} item',
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: AppColors.success,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        AppCard(
          padding: EdgeInsets.zero,
          child: Column(
            children: entries.mapIndexed((i, entry) {
              return InfoRowWidget(
                label: entry.key,
                value: entry.value,
                isDivided: i < entries.length - 1,
              );
            }).toList(),
          ),
        )
            .animate()
            .fadeIn(delay: 200.ms, duration: 400.ms),
      ],
    );
  }

  Widget _buildFilePathSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Lokasi File',
          style: GoogleFonts.poppins(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 12),
        AppCard(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.image_search_rounded,
                    size: 16,
                    color: AppColors.textHintLight,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'File Asli (Sebelum)',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                widget.item.originalPath,
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
              const Divider(height: 20),
              Row(
                children: [
                  const Icon(
                    Icons.save_alt_rounded,
                    size: 16,
                    color: AppColors.textHintLight,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'File Hasil (Setelah)',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                widget.item.optimizedPath,
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        )
            .animate()
            .fadeIn(delay: 300.ms, duration: 400.ms),
      ],
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    final shareService = ShareService();
    final fileExists = _optimizedInfo != null;

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: fileExists
                    ? () async {
                        try {
                          await shareService.openFile(widget.item.optimizedPath);
                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(e.toString())),
                            );
                          }
                        }
                      }
                    : null,
                icon: const Icon(Icons.open_in_new_rounded, size: 18),
                label: const Text('Lihat'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: fileExists
                    ? () async {
                        try {
                          await shareService.shareFile(widget.item.optimizedPath);
                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(e.toString())),
                            );
                          }
                        }
                      }
                    : null,
                icon: const Icon(Icons.share_rounded, size: 18),
                label: const Text('Bagikan'),
              ),
            ),
          ],
        )
            .animate()
            .fadeIn(delay: 400.ms, duration: 400.ms),
        const SizedBox(height: 10),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () => context.pop(),
            icon: const Icon(Icons.arrow_back_rounded, size: 18),
            label: const Text('Kembali ke Riwayat'),
          ),
        )
            .animate()
            .fadeIn(delay: 500.ms, duration: 400.ms),
      ],
    );
  }
}

extension on List {
  Iterable<T> mapIndexed<T>(T Function(int index, dynamic item) f) sync* {
    for (int i = 0; i < length; i++) {
      yield f(i, this[i]);
    }
  }
}
