import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../domain/entities/image_info_entity.dart';
import '../../../core/extensions/file_extension.dart';
import '../../../widgets/info_row_widget.dart';
import '../../../widgets/section_header.dart';
import '../../../widgets/app_card.dart';
import '../../../widgets/local_image_preview.dart';
import 'widgets/ai_detector_card.dart';

class ImageInfoScreen extends StatelessWidget {
  final ImageInfoEntity imageInfo;

  const ImageInfoScreen({super.key, required this.imageInfo});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Informasi Gambar'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => context.pop(),
        ),
      ),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildImagePreview(context),
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildFileInfoSection(context),
                      const SizedBox(height: 16),
                      // ── AI Detector Card ──────────────────────────────
                      AiDetectorCard(imageInfo: imageInfo),
                      const SizedBox(height: 20),
                      if (imageInfo.hasExif) ...[
                        _buildMetadataSection(context),
                        const SizedBox(height: 20),
                      ],
                      _buildWarningCard(context),
                      const SizedBox(height: 24),
                      _buildActionButtons(context),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImagePreview(BuildContext context) {
    return Hero(
      tag: 'image_preview_${imageInfo.filePath}',
      child: Container(
        width: double.infinity,
        height: 260,
        color: Theme.of(context).colorScheme.surfaceContainerLow,
        child: LocalImagePreview(
          filePath: imageInfo.filePath,
          fit: BoxFit.cover,
          fallback: _buildImagePlaceholder(),
        ),
      ),
    ).animate().fadeIn(duration: 400.ms);
  }

  Widget _buildImagePlaceholder() {
    return const Center(
      child: Icon(
        Icons.broken_image_outlined,
        size: 60,
        color: AppColors.textHintLight,
      ),
    );
  }

  Widget _buildFileInfoSection(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(
          title: 'Informasi File',
          subtitle: 'Detail dasar dari gambar yang dipilih',
        ),
        const SizedBox(height: 12),
        AppCard(
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              InfoRowWidget(label: 'Nama File', value: imageInfo.fileName),
              InfoRowWidget(
                label: 'Ukuran',
                value: imageInfo.fileSize.toReadableSize(),
                valueColor: colorScheme.primary,
              ),
              InfoRowWidget(label: 'Format', value: imageInfo.format),
              InfoRowWidget(label: 'Resolusi', value: imageInfo.resolution),
              InfoRowWidget(label: 'Lebar', value: '${imageInfo.width} px'),
              InfoRowWidget(label: 'Tinggi', value: '${imageInfo.height} px'),
              if (imageInfo.createdAt != null)
                InfoRowWidget(
                  label: 'Terakhir Diubah',
                  value: DateFormat('dd MMM yyyy, HH:mm')
                      .format(imageInfo.createdAt!),
                  isDivided: false,
                ),
            ],
          ),
        )
            .animate()
            .fadeIn(delay: 100.ms, duration: 400.ms)
            .slideY(begin: 0.05, end: 0),
      ],
    );
  }

  Widget _buildMetadataSection(BuildContext context) {
    final entries = imageInfo.exifData.entries.toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          title: 'Metadata EXIF',
          subtitle: '${entries.length} data ditemukan',
          trailing: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.infoSurface,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '${entries.length} item',
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: AppColors.info,
                fontWeight: FontWeight.w500,
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

  Widget _buildWarningCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.warningSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.warning.withValues(alpha: 0.4)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.auto_delete_outlined,
            color: AppColors.warning,
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Metadata akan dihapus',
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF92400E),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Setelah optimasi, semua metadata di atas tidak akan ada di file hasil.',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: const Color(0xFF78350F),
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    )
        .animate()
        .fadeIn(delay: 300.ms, duration: 400.ms);
  }

  Widget _buildActionButtons(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () => context.goNamed('optimize', extra: imageInfo),
            icon: const Icon(Icons.auto_fix_high_rounded),
            label: const Text('Lanjut ke Optimasi'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              textStyle: GoogleFonts.poppins(
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        )
            .animate()
            .fadeIn(delay: 400.ms, duration: 400.ms)
            .slideY(begin: 0.1, end: 0),
        const SizedBox(height: 10),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            onPressed: () => context.pop(),
            child: const Text('Pilih Gambar Lain'),
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
