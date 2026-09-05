import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:file_picker/file_picker.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/theme/app_colors.dart';
import '../../../domain/entities/media_edit_config_entity.dart';
import '../../../domain/entities/watermark_position.dart';
import '../../../data/datasources/batch_processing_engine.dart';
import '../../providers/media_editor_provider.dart';
import '../../providers/watermark_provider.dart';

class BatchEditScreen extends ConsumerStatefulWidget {
  const BatchEditScreen({super.key});

  @override
  ConsumerState<BatchEditScreen> createState() => _BatchEditScreenState();
}

class _BatchEditScreenState extends ConsumerState<BatchEditScreen> {
  List<String> _selectedFiles = [];
  bool _enableWatermark = false;
  String? _selectedLogoPath;
  WatermarkPositionType _watermarkPosType = WatermarkPositionType.bottomRight;
  double _watermarkScale = 0.18;
  double _watermarkOpacity = 0.85;
  String _metadataPreset = 'sony';

  Future<void> _pickFiles() async {
    final result = await FilePicker.platform.pickFiles(
      allowMultiple: true,
      type: FileType.media,
    );

    if (result != null && result.paths.isNotEmpty) {
      setState(() {
        _selectedFiles = result.paths.whereType<String>().toList();
      });
    }
  }

  Future<void> _pickWatermarkLogo() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['png', 'jpg', 'jpeg', 'webp'],
    );
    if (result != null && result.files.single.path != null) {
      final logoPath = result.files.single.path!;
      await ref.read(watermarkListProvider.notifier).addWatermark(logoPath);
      setState(() {
        _selectedLogoPath = logoPath;
        _enableWatermark = true;
      });
    }
  }

  void _runBatchEditing() {
    if (_selectedFiles.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pilih minimal 1 file untuk diedit massal')),
      );
      return;
    }

    final config = MediaEditConfigEntity(
      isVideo: false,
      enableWatermark: _enableWatermark,
      watermarkLogoPath: _selectedLogoPath,
      watermarkPosition: WatermarkPosition(type: _watermarkPosType),
      watermarkScale: _watermarkScale,
      watermarkOpacity: _watermarkOpacity,
      metadataAction: PostMetadataAction.scrubAndSpoof,
      metadataProfilePreset: _metadataPreset,
      quality: 90,
    );

    ref.read(batchNotifierProvider.notifier).startBatch(
          inputPaths: _selectedFiles,
          config: config,
        );
  }

  void _shareCompletedFiles(List<BatchItemStatus> items) {
    final paths = items
        .where((e) => e.isCompleted && e.outputPath != null)
        .map((e) => XFile(e.outputPath!))
        .toList();
    if (paths.isNotEmpty) {
      Share.shareXFiles(paths, text: 'Hasil Editing Massal Promptix');
    }
  }

  @override
  Widget build(BuildContext context) {
    final batchState = ref.watch(batchNotifierProvider);
    final watermarks = ref.watch(watermarkListProvider).value ?? [];
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Studio Editing Massal',
          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        actions: [
          if (batchState.items.any((e) => e.isCompleted))
            IconButton(
              icon: const Icon(Icons.share_rounded, size: 20),
              onPressed: () => _shareCompletedFiles(batchState.items),
              tooltip: 'Bagikan Hasil',
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(
          horizontal: screenWidth < 360 ? 12 : 14,
          vertical: 12,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Compact Mobile Banner Card
            _buildSelectionCard(isDark),

            const SizedBox(height: 14),

            // Mass Batch Config Section
            if (_selectedFiles.isNotEmpty && !batchState.isProcessing) ...[
              _buildBatchConfigCard(watermarks, isDark),
              const SizedBox(height: 14),
            ],

            // Active Batch Progress Bar & Dashboard
            if (batchState.isProcessing || batchState.items.isNotEmpty) ...[
              _buildProgressDashboard(batchState),
              const SizedBox(height: 14),
            ],

            // Item Status Cards List
            if (batchState.items.isNotEmpty) ...[
              Text(
                'Daftar Berkas Massal (${batchState.items.length})',
                style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              const SizedBox(height: 8),
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: batchState.items.length,
                itemBuilder: (ctx, idx) {
                  final item = batchState.items[idx];
                  return _buildBatchItemTile(item);
                },
              ),
            ],
          ],
        ),
      ),
      bottomNavigationBar: _selectedFiles.isNotEmpty
          ? Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              color: Theme.of(context).scaffoldBackgroundColor,
              child: SafeArea(
                child: SizedBox(
                  width: double.infinity,
                  height: 42,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      visualDensity: VisualDensity.compact,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: batchState.isProcessing ? null : _runBatchEditing,
                    icon: Icon(batchState.isProcessing ? Icons.hourglass_top_rounded : Icons.dynamic_feed_rounded, size: 18),
                    label: Text(
                      batchState.isProcessing
                          ? 'Sedang Memproses Massal...'
                          : 'Mulai Editan Massal (${_selectedFiles.length} Berkas)',
                      style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                  ),
                ),
              ),
            )
          : null,
    );
  }

  Widget _buildSelectionCard(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primary,
            AppColors.primary.withValues(alpha: 0.85),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.collections_rounded, color: Colors.white, size: 24),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Mass Editing & Privacy Scrubber',
                  style: GoogleFonts.plusJakartaSans(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          const Text(
            'Edit puluhan foto & video sekaligus, tempel logo di pojok, dan bersihkan metadata secara massal.',
            style: TextStyle(color: Colors.white70, fontSize: 11.5, height: 1.25),
          ),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: AppColors.primary,
              visualDensity: VisualDensity.compact,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: _pickFiles,
            icon: const Icon(Icons.add_circle_outline_rounded, size: 16),
            label: Text(
              _selectedFiles.isEmpty
                  ? 'Pilih Berkas Massal'
                  : 'Ubah Pilihan (${_selectedFiles.length} File)',
              style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBatchConfigCard(List<File> watermarks, bool isDark) {
    return Card(
      elevation: 1,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Konfigurasi Editan Massal',
              style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            const SizedBox(height: 8),

            SwitchListTile(
              dense: true,
              contentPadding: EdgeInsets.zero,
              title: const Text('Tempel Watermark Logo pada Berkas Massal', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
              subtitle: const Text('Tempel logo watermark di pojok semua berkas secara kolektif.', style: TextStyle(fontSize: 10.5)),
              value: _enableWatermark,
              onChanged: (val) => setState(() => _enableWatermark = val),
            ),

            if (_enableWatermark) ...[
              const SizedBox(height: 6),
              Text('Posisikan Logo di Pojok:', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 11)),
              const SizedBox(height: 6),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  _buildCornerChip(WatermarkPositionType.bottomRight, 'Kanan Bawah'),
                  _buildCornerChip(WatermarkPositionType.bottomLeft, 'Kiri Bawah'),
                  _buildCornerChip(WatermarkPositionType.topRight, 'Kanan Atas'),
                  _buildCornerChip(WatermarkPositionType.topLeft, 'Kiri Atas'),
                  _buildCornerChip(WatermarkPositionType.center, 'Tengah'),
                ],
              ),
              const SizedBox(height: 10),

              Row(
                children: [
                  Expanded(child: Text('Ukuran: ${(_watermarkScale * 100).toInt()}%', style: const TextStyle(fontSize: 10.5))),
                  Expanded(child: Text('Transparansi: ${(_watermarkOpacity * 100).toInt()}%', style: const TextStyle(fontSize: 10.5))),
                ],
              ),
              Row(
                children: [
                  Expanded(
                    child: Slider(
                      value: _watermarkScale,
                      min: 0.05,
                      max: 0.4,
                      onChanged: (v) => setState(() => _watermarkScale = v),
                    ),
                  ),
                  Expanded(
                    child: Slider(
                      value: _watermarkOpacity,
                      min: 0.1,
                      max: 1.0,
                      onChanged: (v) => setState(() => _watermarkOpacity = v),
                    ),
                  ),
                ],
              ),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Pilih Berkas Logo:', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 11)),
                  TextButton.icon(
                    style: TextButton.styleFrom(visualDensity: VisualDensity.compact),
                    onPressed: _pickWatermarkLogo,
                    icon: const Icon(Icons.file_upload_outlined, size: 14),
                    label: const Text('Pilih Berkas', style: TextStyle(fontSize: 10.5)),
                  ),
                ],
              ),
            ],

            const Divider(height: 18),

            Text('Profil Metadata EXIF Spoofing:', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 11)),
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              children: [
                _buildProfileChip('sony', 'Sony Alpha R4'),
                _buildProfileChip('canon', 'Canon EOS R5'),
                _buildProfileChip('iphone', 'iPhone 15 Pro'),
                _buildProfileChip('samsung', 'Galaxy S24'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCornerChip(WatermarkPositionType posType, String title) {
    final isSelected = _watermarkPosType == posType;
    return ChoiceChip(
      visualDensity: VisualDensity.compact,
      label: Text(title, style: TextStyle(fontSize: 10, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
      selected: isSelected,
      onSelected: (_) => setState(() => _watermarkPosType = posType),
    );
  }

  Widget _buildProfileChip(String key, String title) {
    final isSelected = _metadataPreset == key;
    return ChoiceChip(
      visualDensity: VisualDensity.compact,
      label: Text(title, style: TextStyle(fontSize: 10, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
      selected: isSelected,
      onSelected: (_) => setState(() => _metadataPreset = key),
    );
  }

  Widget _buildProgressDashboard(BatchState state) {
    final percentInt = (state.overallProgress * 100).toInt();
    return Card(
      elevation: 1,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: AppColors.primary.withValues(alpha: 0.08),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Progres Pemrosesan Massal',
                  style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 12),
                ),
                Text(
                  '$percentInt%',
                  style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, color: AppColors.primary, fontSize: 12),
                ),
              ],
            ),
            const SizedBox(height: 6),
            LinearProgressIndicator(
              value: state.overallProgress,
              borderRadius: BorderRadius.circular(6),
              minHeight: 8,
              backgroundColor: Colors.grey.withValues(alpha: 0.2),
              color: AppColors.primary,
            ),
            const SizedBox(height: 6),
            Text(
              'Diproses ${state.currentIndex} dari ${state.totalItems} berkas media',
              style: const TextStyle(fontSize: 10.5, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBatchItemTile(BatchItemStatus item) {
    IconData iconData = item.isVideo ? Icons.movie_rounded : Icons.image_rounded;
    Color statusColor = Colors.grey;
    String statusText = 'Dalam antrean';

    if (item.isCompleted) {
      statusColor = Colors.green;
      statusText = 'Selesai (${_formatBytes(item.outputSizeBytes)})';
    } else if (item.isFailed) {
      statusColor = Colors.red;
      statusText = 'Gagal: ${item.errorMessage ?? "Error"}';
    } else if (item.progress > 0) {
      statusColor = AppColors.primary;
      statusText = 'Memproses ${(item.progress * 100).toInt()}%';
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 6),
      elevation: 0.5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: ListTile(
        dense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
        leading: CircleAvatar(
          radius: 16,
          backgroundColor: statusColor.withValues(alpha: 0.15),
          child: Icon(iconData, color: statusColor, size: 16),
        ),
        title: Text(
          item.fileName,
          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600, fontSize: 12),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(statusText, style: TextStyle(color: statusColor, fontSize: 10)),
        trailing: item.isCompleted
            ? const Icon(Icons.check_circle_rounded, color: Colors.green, size: 18)
            : item.isFailed
                ? const Icon(Icons.error_rounded, color: Colors.red, size: 18)
                : SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(strokeWidth: 2, color: statusColor),
                  ),
      ),
    );
  }

  String _formatBytes(int bytes) {
    if (bytes <= 0) return '0 B';
    final kb = bytes / 1024;
    if (kb < 1024) return '${kb.toStringAsFixed(1)} KB';
    final mb = kb / 1024;
    return '${mb.toStringAsFixed(1)} MB';
  }
}
