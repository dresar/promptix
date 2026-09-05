import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:file_picker/file_picker.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/extensions/file_extension.dart';
import '../../../domain/entities/image_history_entity.dart';
import '../../../presentation/providers/image_provider.dart';
import '../../../presentation/providers/history_provider.dart';
import '../../../presentation/providers/settings_provider.dart';
import '../../../presentation/providers/watermark_provider.dart';
import '../../../widgets/app_card.dart';
import '../../../widgets/section_header.dart';
import '../../../widgets/local_image_preview.dart';
import '../../../data/datasources/local/web_image_cache.dart';

class BatchCleanScreen extends ConsumerStatefulWidget {
  const BatchCleanScreen({super.key});

  @override
  ConsumerState<BatchCleanScreen> createState() => _BatchCleanScreenState();
}

class _BatchCleanScreenState extends ConsumerState<BatchCleanScreen> {
  final List<PlatformFile> _selectedFiles = [];
  bool _isProcessing = false;
  double _overallProgress = 0.0;
  String _currentStatus = 'Siap memproses...';

  // Configuration
  late String _selectedFormat;
  late int _selectedQuality;
  bool _replaceOld = false;
  String _selectedProfile = 'clean';

  // Watermark
  bool _watermarkEnabled = false;
  File? _selectedWatermarkLogo;
  String _watermarkPosition = 'bottomRight';
  double _watermarkScale = 0.15;
  double _watermarkOpacity = 0.8;

  // Summary State
  bool _isCompleted = false;
  int _totalOriginalSize = 0;
  int _totalOptimizedSize = 0;
  final List<String> _optimizedFilePaths = [];

  @override
  void initState() {
    super.initState();
    final settings = ref.read(settingsNotifierProvider);
    _selectedFormat = settings.outputFormat;
    _selectedQuality = settings.jpgQuality;
  }

  Future<void> _pickImages() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: true,
      );

      if (result == null || result.files.isEmpty) return;

      setState(() {
        _isCompleted = false;
        _totalOriginalSize = 0;
        _totalOptimizedSize = 0;
        _optimizedFilePaths.clear();
        
        for (final file in result.files) {
          if (kIsWeb) {
            if (!_selectedFiles.any((existing) => existing.name == file.name)) {
              _selectedFiles.add(file);
            }
          } else {
            if (file.path != null) {
              if (!_selectedFiles.any((existing) => existing.path == file.path)) {
                _selectedFiles.add(file);
              }
            }
          }
        }
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal memilih gambar: $e')),
        );
      }
    }
  }

  void _removeFile(int index) {
    if (_isProcessing) return;
    setState(() {
      _selectedFiles.removeAt(index);
    });
  }

  void _clearList() {
    if (_isProcessing) return;
    setState(() {
      _selectedFiles.clear();
      _isCompleted = false;
      _overallProgress = 0.0;
      _totalOriginalSize = 0;
      _totalOptimizedSize = 0;
      _optimizedFilePaths.clear();
    });
  }

  Future<void> _startBatchCleaning() async {
    if (_selectedFiles.isEmpty) return;

    setState(() {
      _isProcessing = true;
      _isCompleted = false;
      _overallProgress = 0.0;
      _totalOriginalSize = 0;
      _totalOptimizedSize = 0;
      _optimizedFilePaths.clear();
    });

    final optimizeUsecase = ref.read(optimizeImageUsecaseProvider);
    final saveHistory = ref.read(saveHistoryUsecaseProvider);
    final settings = ref.read(settingsNotifierProvider);
    final outputPrefix = settings.filePrefix;

    for (int i = 0; i < _selectedFiles.length; i++) {
      if (!mounted) return;
      final file = _selectedFiles[i];
      final fileName = file.name;

      setState(() {
        _currentStatus = 'Memproses ($i/${_selectedFiles.length}): $fileName';
        _overallProgress = i / _selectedFiles.length;
      });

      try {
        final String filePath;
        if (kIsWeb) {
          if (file.bytes != null) {
            final fakePath = 'web_image_${DateTime.now().millisecondsSinceEpoch}_${file.name}';
            WebImageCache.put(fakePath, file.bytes!);
            filePath = fakePath;
          } else {
            continue;
          }
        } else {
          filePath = file.path!;
        }

        // Read file info first
        final imageNotifier = ref.read(imageNotifierProvider.notifier);
        final info = await imageNotifier.loadImageInfo(filePath);
        
        if (info == null) continue;

        // Perform clean/optimization
        final result = await optimizeUsecase(
          imageInfo: info,
          format: _selectedFormat,
          quality: _selectedQuality,
          outputPrefix: outputPrefix,
          metadataProfile: _selectedProfile,
          watermarkEnabled: _watermarkEnabled,
          watermarkLogoPath: _selectedWatermarkLogo?.path,
          watermarkPosition: _watermarkPosition,
          watermarkScale: _watermarkScale,
          watermarkOpacity: _watermarkOpacity,
          onProgress: (p) {
            if (!mounted) return;
            setState(() {
              _overallProgress = (i + p) / _selectedFiles.length;
            });
          },
        );

        // Record metrics
        _totalOriginalSize += result.originalInfo.fileSize;
        _totalOptimizedSize += result.optimizedSize;
        _optimizedFilePaths.add(result.optimizedPath);

        // Save history item
        await saveHistory(
          ImageHistoryEntity(
            originalName: result.originalInfo.fileName,
            originalPath: result.originalInfo.filePath,
            optimizedPath: result.optimizedPath,
            originalSize: result.originalInfo.fileSize,
            optimizedSize: result.optimizedSize,
            width: result.originalInfo.width,
            height: result.originalInfo.height,
            format: result.outputFormat,
            createdAt: result.completedAt,
          ),
        );

        // Optional delete original file
        if (_replaceOld && !kIsWeb && file.path != null) {
          try {
            final f = File(file.path!);
            if (await f.exists()) {
              await f.delete();
            }
          } catch (e) {
            debugPrint('Gagal menghapus file: $e');
          }
        }
      } catch (e) {
        // Skip failed items but keep going
        debugPrint('Gagal memproses $fileName: $e');
      }
    }

    // Refresh history
    ref.read(historyProvider.notifier).loadHistory();

    if (mounted) {
      setState(() {
        _isProcessing = false;
        _isCompleted = true;
        _overallProgress = 1.0;
        _currentStatus = 'Selesai memproses ${_selectedFiles.length} file!';
        _selectedFiles.clear();
      });
    }
  }

  void _shareBatchResults() async {
    if (_optimizedFilePaths.isEmpty) return;
    try {
      final xFiles = _optimizedFilePaths.map((path) => XFile(path)).toList();
      await Share.shareXFiles(xFiles, text: 'Hasil optimasi gambar Promptix');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal membagikan file: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pembersihan Massal'),
        actions: [
          if (_selectedFiles.isNotEmpty && !_isProcessing)
            IconButton(
              icon: const Icon(Icons.delete_sweep_outlined),
              tooltip: 'Bersihkan Daftar',
              onPressed: _clearList,
            ),
        ],
      ),
      body: Stack(
        children: [
          CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHeaderCard(context, isDark),
                      const SizedBox(height: 24),
                      if (_isCompleted) _buildSummaryCard(context),
                      if (_selectedFiles.isEmpty && !_isProcessing && !_isCompleted)
                        _buildEmptyState(context, isDark)
                      else if (_selectedFiles.isNotEmpty || _isProcessing) ...[
                        _buildQueueListSection(context),
                        const SizedBox(height: 24),
                        _buildBatchConfigSection(context),
                        const SizedBox(height: 24),
                        _buildWatermarkSection(context),
                        const SizedBox(height: 28),
                        _buildActionButtons(context),
                      ],
                      const SizedBox(height: 100), // Account for floating bottom bar
                    ],
                  ),
                ),
              ),
            ],
          ),
          if (_isProcessing) _buildProcessingOverlay(context, colorScheme, isDark),
        ],
      ),
    );
  }

  Widget _buildHeaderCard(BuildContext context, bool isDark) {
    return AppCard(
      padding: const EdgeInsets.all(20),
      backgroundColor: AppColors.primary.withValues(alpha: 0.08),
      hasBorder: false,
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.layers_rounded,
              color: AppColors.primary,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Bersihkan Banyak Gambar',
                  style: GoogleFonts.poppins(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Hapus metadata AI & C2PA dari beberapa file gambar secara bersamaan.',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, bool isDark) {
    return Column(
      children: [
        const SizedBox(height: 40),
        Center(
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: isDark ? AppColors.surfaceDark2 : AppColors.surfaceLight2,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.add_photo_alternate_rounded,
              size: 64,
              color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.7),
            ),
          ),
        ),
        const SizedBox(height: 24),
        Text(
          'Daftar Gambar Kosong',
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Pilih beberapa file gambar untuk memulai pembersihan massal.',
          style: GoogleFonts.poppins(
            fontSize: 13,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 32),
        SizedBox(
          width: 200,
          child: ElevatedButton.icon(
            onPressed: _pickImages,
            icon: const Icon(Icons.photo_library_outlined),
            label: const Text('Pilih Gambar'),
          ),
        ),
      ],
    ).animate().fadeIn(duration: 400.ms);
  }

  Widget _buildQueueListSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          title: 'Gambar Terpilih (${_selectedFiles.length})',
          trailing: IconButton(
            icon: const Icon(Icons.add_photo_alternate_outlined),
            tooltip: 'Tambah Gambar',
            onPressed: _pickImages,
          ),
        ),
        const SizedBox(height: 12),
        AppCard(
          padding: EdgeInsets.zero,
          child: ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _selectedFiles.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final file = _selectedFiles[index];
              final name = file.name;
              final sizeStr = file.size.toReadableSize();

              return ListTile(
                leading: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: SizedBox(
                    width: 44,
                    height: 44,
                    child: LocalImagePreview(
                      filePath: file.path ?? '',
                      bytes: file.bytes,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                title: Text(
                  name,
                  style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w500),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: Text(
                  sizeStr,
                  style: GoogleFonts.poppins(fontSize: 11),
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.close_rounded, size: 18),
                  onPressed: () => _removeFile(index),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildBatchConfigSection(BuildContext context) {
    const formats = AppConstants.outputFormatOptions;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(title: 'Pengaturan Bersih Massal'),
        const SizedBox(height: 12),
        
        // Output Format selector
        Text(
          'Format Output',
          style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        Row(
          children: formats.map((format) {
            final isSelected = _selectedFormat == format;
            return Expanded(
              child: Padding(
                padding: EdgeInsets.only(right: format == formats.last ? 0 : 8),
                child: ChoiceChip(
                  label: Text(format.toUpperCase()),
                  selected: isSelected,
                  onSelected: (_) => setState(() => _selectedFormat = format),
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 18),

        // Quality slider (if not png)
        if (_selectedFormat != 'png') ...[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Kualitas Gambar',
                style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600),
              ),
              Text(
                '$_selectedQuality%',
                style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.primary),
              ),
            ],
          ),
          Slider(
            value: _selectedQuality.toDouble(),
            min: 50,
            max: 100,
            divisions: 10,
            onChanged: (v) => setState(() => _selectedQuality = v.round()),
          ),
          const SizedBox(height: 12),
        ],

        // Metadata Profile Preset
        Text(
          'Profil Metadata Tiruan',
          style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: Theme.of(context).brightness == Brightness.dark ? AppColors.cardDark : AppColors.cardLight,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.5)),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _selectedProfile,
              isExpanded: true,
              style: GoogleFonts.poppins(fontSize: 13, color: Theme.of(context).colorScheme.onSurface),
              items: const [
                DropdownMenuItem(value: 'clean', child: Text('Clean (Wipe Total Metadata)')),
                DropdownMenuItem(value: 'iphone', child: Text('Apple iPhone 15 Pro (Simulasi)')),
                DropdownMenuItem(value: 'samsung', child: Text('Samsung Galaxy S24 Ultra (Simulasi)')),
                DropdownMenuItem(value: 'photoshop', child: Text('Adobe Photoshop (Simulasi)')),
              ],
              onChanged: (val) {
                if (val != null) {
                  setState(() => _selectedProfile = val);
                }
              },
            ),
          ),
        ),
        const SizedBox(height: 18),

        // Storage option
        AppCard(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Hapus File Asli',
                      style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                    Text(
                      'Hapus file asli setelah pembersihan selesai',
                      style: GoogleFonts.poppins(fontSize: 11, color: Theme.of(context).colorScheme.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
              Switch(
                value: _replaceOld,
                onChanged: (v) => setState(() => _replaceOld = v),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: _startBatchCleaning,
        icon: const Icon(Icons.auto_fix_high_rounded),
        label: const Text('Mulai Bersihkan Semua'),
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
        ),
      ),
    );
  }

  Widget _buildSummaryCard(BuildContext context) {
    final savings = _totalOriginalSize > 0 
        ? ((_totalOriginalSize - _totalOptimizedSize) / _totalOriginalSize * 100).round()
        : 0;

    return AppCard(
      padding: const EdgeInsets.all(20),
      backgroundColor: AppColors.success.withValues(alpha: 0.08),
      hasBorder: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.check_circle_rounded, color: AppColors.success, size: 24),
              const SizedBox(width: 10),
              Text(
                'Batch Selesai Diproses!',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.success,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: _buildSummaryStatCard('Ukuran Awal', _totalOriginalSize.toReadableSize()),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildSummaryStatCard('Ukuran Baru', _totalOptimizedSize.toReadableSize()),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            'Total Penghematan: $savings% (${(_totalOriginalSize - _totalOptimizedSize).toReadableSize()})',
            style: GoogleFonts.poppins(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.success,
            ),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _shareBatchResults,
                  icon: const Icon(Icons.share_rounded),
                  label: const Text('Bagikan Semua'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => setState(() => _isCompleted = false),
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text('Selesai'),
                ),
              ),
            ],
          ),
        ],
      ),
    ).animate().scale(duration: 400.ms, curve: Curves.easeOutBack);
  }

  Widget _buildSummaryStatCard(String label, String value) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: GoogleFonts.poppins(fontSize: 11, color: AppColors.textSecondaryLight),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textPrimaryLight),
          ),
        ],
      ),
    );
  }

  Widget _buildProcessingOverlay(BuildContext context, ColorScheme colorScheme, bool isDark) {
    return Container(
      color: Colors.black.withValues(alpha: 0.65),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: AppCard(
            padding: const EdgeInsets.all(28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(strokeWidth: 3),
                const SizedBox(height: 24),
                Text(
                  'Sedang Membersihkan...',
                  style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                Text(
                  _currentStatus,
                  style: GoogleFonts.poppins(fontSize: 12, color: colorScheme.onSurfaceVariant),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Progres Batch',
                      style: GoogleFonts.poppins(fontSize: 12, color: colorScheme.onSurfaceVariant),
                    ),
                    Text(
                      '${(_overallProgress * 100).round()}%',
                      style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w700, color: colorScheme.primary),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: _overallProgress,
                    minHeight: 8,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildWatermarkSection(BuildContext context) {
    final watermarksAsync = ref.watch(watermarkListProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(
          title: 'Watermark Logo',
          subtitle: 'Tambahkan logo watermark pada pojok gambar',
        ),
        const SizedBox(height: 12),
        AppCard(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Aktifkan Watermark',
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  Switch(
                    value: _watermarkEnabled,
                    onChanged: (v) {
                      setState(() {
                        _watermarkEnabled = v;
                      });
                    },
                  ),
                ],
              ),
              if (_watermarkEnabled) ...[
                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 12),
                watermarksAsync.when(
                  data: (files) {
                    if (files.isEmpty) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Belum ada logo watermark terunggah.',
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(height: 8),
                          OutlinedButton.icon(
                            onPressed: () async {
                              try {
                                final picker = ImagePicker();
                                final picked = await picker.pickImage(
                                  source: ImageSource.gallery,
                                  imageQuality: 100,
                                );
                                if (picked != null) {
                                  await ref.read(watermarkListProvider.notifier).addWatermark(picked.path);
                                  final list = await ref.read(watermarkServiceProvider).getWatermarks();
                                  if (list.isNotEmpty) {
                                    setState(() {
                                      _selectedWatermarkLogo = list.last;
                                    });
                                  }
                                }
                              } catch (e) {
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('Gagal mengunggah logo: $e')),
                                  );
                                }
                              }
                            },
                            icon: const Icon(Icons.upload_file_rounded, size: 16),
                            label: const Text('Unggah Logo Baru'),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                        ],
                      );
                    }

                    if (_selectedWatermarkLogo == null || !files.any((f) => f.path == _selectedWatermarkLogo!.path)) {
                      _selectedWatermarkLogo = files.first;
                    }

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Pilih Logo Watermark',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(
                            border: Border.all(color: Theme.of(context).colorScheme.outline),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<File>(
                              value: _selectedWatermarkLogo,
                              isExpanded: true,
                              icon: const Icon(Icons.keyboard_arrow_down_rounded),
                              items: files.map((file) {
                                final baseName = p.basename(file.path);
                                var displayName = baseName;
                                if (baseName.startsWith('wm_')) {
                                  final parts = baseName.split('_');
                                  if (parts.length > 2) {
                                    displayName = parts.sublist(2).join('_');
                                  }
                                }
                                return DropdownMenuItem<File>(
                                  value: file,
                                  child: Row(
                                    children: [
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(4),
                                        child: Container(
                                          width: 32,
                                          height: 32,
                                          color: isDark ? AppColors.surfaceDark2 : AppColors.surfaceLight2,
                                          child: Image.file(
                                            file,
                                            fit: BoxFit.contain,
                                            errorBuilder: (_, __, ___) => const Icon(Icons.broken_image_rounded, size: 16),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Text(
                                          displayName,
                                          style: GoogleFonts.poppins(fontSize: 13),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }).toList(),
                              onChanged: (File? val) {
                                if (val != null) {
                                  setState(() {
                                    _selectedWatermarkLogo = val;
                                  });
                                }
                              },
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (e, _) => Text('Gagal memuat logo: $e', style: GoogleFonts.poppins(color: AppColors.error)),
                ),
                const SizedBox(height: 16),
                Text(
                  'Posisi Watermark',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    border: Border.all(color: Theme.of(context).colorScheme.outline),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _watermarkPosition,
                      isExpanded: true,
                      icon: const Icon(Icons.keyboard_arrow_down_rounded),
                      items: const [
                        DropdownMenuItem(
                          value: 'bottomRight',
                          child: Text('Pojok Kanan Bawah'),
                        ),
                        DropdownMenuItem(
                          value: 'bottomLeft',
                          child: Text('Pojok Kiri Bawah'),
                        ),
                        DropdownMenuItem(
                          value: 'topRight',
                          child: Text('Pojok Kanan Atas'),
                        ),
                        DropdownMenuItem(
                          value: 'topLeft',
                          child: Text('Pojok Kiri Atas'),
                        ),
                      ],
                      onChanged: (val) {
                        if (val != null) {
                          setState(() {
                            _watermarkPosition = val;
                          });
                        }
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Ukuran Watermark (${(_watermarkScale * 100).round()}%)',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
                Slider(
                  value: _watermarkScale,
                  min: 0.05,
                  max: 0.30,
                  divisions: 5,
                  label: '${(_watermarkScale * 100).round()}%',
                  onChanged: (val) {
                    setState(() {
                      _watermarkScale = val;
                    });
                  },
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Transparansi (${(_watermarkOpacity * 100).round()}%)',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
                Slider(
                  value: _watermarkOpacity,
                  min: 0.10,
                  max: 1.0,
                  divisions: 9,
                  label: '${(_watermarkOpacity * 100).round()}%',
                  onChanged: (val) {
                    setState(() {
                      _watermarkOpacity = val;
                    });
                  },
                ),
              ],
            ],
          ),
        ),
      ],
    ).animate().fadeIn(delay: 350.ms, duration: 400.ms);
  }
}
