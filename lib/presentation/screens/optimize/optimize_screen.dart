import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/extensions/file_extension.dart';
import '../../../domain/entities/image_info_entity.dart';
import '../../../domain/entities/exif_profile_entity.dart';
import '../../../presentation/providers/settings_provider.dart';
import '../../../presentation/providers/exif_profile_provider.dart';
import '../../../presentation/providers/watermark_provider.dart';
import '../../../widgets/app_card.dart';
import '../../../widgets/section_header.dart';
import '../../../widgets/local_image_preview.dart';

class OptimizeScreen extends ConsumerStatefulWidget {
  final ImageInfoEntity imageInfo;

  const OptimizeScreen({super.key, required this.imageInfo});

  @override
  ConsumerState<OptimizeScreen> createState() => _OptimizeScreenState();
}

class _OptimizeScreenState extends ConsumerState<OptimizeScreen> {
  late String _selectedFormat;
  late int _selectedQuality;
  bool _replaceOld = false;

  // Profile selection
  String _selectedProfileId = 'clean';
  ExifProfileEntity? _selectedCustomProfile;

  // Watermark selection
  bool _watermarkEnabled = false;
  File? _selectedWatermarkLogo;
  String _watermarkPosition = 'bottomRight';
  double _watermarkScale = 0.15;
  double _watermarkOpacity = 0.8;

  @override
  void initState() {
    super.initState();
    final settings = ref.read(settingsNotifierProvider);
    _selectedFormat = settings.outputFormat;
    _selectedQuality = settings.jpgQuality;
  }

  void _selectProfile(ExifProfileEntity profile) {
    setState(() {
      _selectedProfileId = profile.id;
      _selectedCustomProfile = profile.isBuiltIn ? null : profile;
    });
  }

  Future<void> _openProfileBuilder({ExifProfileEntity? existing}) async {
    final result = await context.pushNamed<ExifProfileEntity?>(
      'exif-profile',
      extra: existing,
    );
    if (result != null) {
      setState(() {
        _selectedProfileId = result.id;
        _selectedCustomProfile = result;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsNotifierProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pengaturan Optimasi'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => context.pop(),
        ),
      ),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildImageSummary(context),
                  const SizedBox(height: 24),
                  _buildFormatSection(context),
                  const SizedBox(height: 24),
                  if (_selectedFormat != 'png') ...[
                    _buildQualitySection(context),
                    const SizedBox(height: 24),
                  ],
                  _buildMetadataProfileSection(context),
                  const SizedBox(height: 24),
                  _buildOptionsSection(context),
                  const SizedBox(height: 24),
                  _buildWatermarkSection(context),
                  const SizedBox(height: 24),
                  _buildEstimationSection(context),
                  const SizedBox(height: 28),
                  _buildOptimizeButton(context, settings),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImageSummary(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AppCard(
      padding: EdgeInsets.zero,
      hasShadow: true,
      child: Row(
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(15),
              bottomLeft: Radius.circular(15),
            ),
            child: SizedBox(
              width: 90,
              height: 90,
              child: LocalImagePreview(
                filePath: widget.imageInfo.filePath,
                fit: BoxFit.cover,
                fallback: Container(
                  color: isDark
                      ? AppColors.surfaceDark2
                      : AppColors.surfaceLight2,
                  child: const Icon(Icons.image_outlined),
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.imageInfo.fileName,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${widget.imageInfo.fileSize.toReadableSize()} · ${widget.imageInfo.resolution}',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 4),
                  // AI badge jika terdeteksi
                  if (widget.imageInfo.hasAiSignature)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.error,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '⚠ AI Terdeteksi — akan dibersihkan',
                        style: GoogleFonts.poppins(
                          fontSize: 10,
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    )
                  else
                    Text(
                      widget.imageInfo.format,
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                ],
              ),
            ),
          ),
          const Padding(
            padding: EdgeInsets.only(right: 14),
            child: Icon(
              Icons.image_rounded,
              color: AppColors.textHintLight,
              size: 20,
            ),
          ),
        ],
      ),
    )
        .animate()
        .fadeIn(duration: 400.ms)
        .slideY(begin: 0.05, end: 0);
  }

  Widget _buildFormatSection(BuildContext context) {
    const formats = AppConstants.outputFormatOptions;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(
          title: 'Format Output',
          subtitle: 'Pilih format file hasil optimasi',
        ),
        const SizedBox(height: 12),
        Row(
          children: formats.map((format) {
            final isSelected = _selectedFormat == format;
            return Expanded(
              child: Padding(
                padding: EdgeInsets.only(
                  right: format == formats.last ? 0 : 10,
                ),
                child: _FormatOptionCard(
                  format: format,
                  isSelected: isSelected,
                  onTap: () => setState(() => _selectedFormat = format),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    )
        .animate()
        .fadeIn(delay: 100.ms, duration: 400.ms);
  }

  Widget _buildQualitySection(BuildContext context) {
    const qualities = AppConstants.jpgQualityOptions;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          title: 'Kualitas Output',
          subtitle: 'Berlaku untuk format JPG dan WebP',
          trailing: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Theme.of(context)
                  .colorScheme
                  .primary
                  .withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '$_selectedQuality%',
              style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        AppCard(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Wrap(
                spacing: 8,
                children: qualities.map((q) {
                  final isSelected = _selectedQuality == q;
                  return ChoiceChip(
                    label: Text('$q%'),
                    selected: isSelected,
                    onSelected: (_) =>
                        setState(() => _selectedQuality = q),
                    selectedColor: Theme.of(context)
                        .colorScheme
                        .primary
                        .withValues(alpha: 0.15),
                    labelStyle: GoogleFonts.poppins(
                      fontWeight: isSelected
                          ? FontWeight.w700
                          : FontWeight.w400,
                      color: isSelected
                          ? Theme.of(context).colorScheme.primary
                          : Theme.of(context)
                              .colorScheme
                              .onSurfaceVariant,
                    ),
                    side: BorderSide(
                      color: isSelected
                          ? Theme.of(context).colorScheme.primary
                          : Theme.of(context).colorScheme.outline,
                      width: isSelected ? 1.5 : 1,
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 12),
              _QualityLegendRow(quality: _selectedQuality),
            ],
          ),
        ),
      ],
    )
        .animate()
        .fadeIn(delay: 200.ms, duration: 400.ms);
  }

  /// ─── SECTION UTAMA: Profil Metadata (redesign total) ──────────────────────
  Widget _buildMetadataProfileSection(BuildContext context) {
    final allProfiles = ref.watch(allExifProfilesProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          title: 'Profil Metadata Hasil',
          subtitle: 'Pilih metadata tiruan yang akan disisipkan',
          trailing: TextButton.icon(
            onPressed: () => _openProfileBuilder(),
            icon: const Icon(Icons.add_rounded, size: 16),
            label: Text(
              'Buat Baru',
              style: GoogleFonts.poppins(fontSize: 12),
            ),
          ),
        ),
        const SizedBox(height: 12),

        // Grid / list profil
        AppCard(
          padding: const EdgeInsets.all(8),
          child: Column(
            children: allProfiles.map((profile) {
              final isSelected = _selectedProfileId == profile.id;
              return _ProfileTile(
                profile: profile,
                isSelected: isSelected,
                onTap: () => _selectProfile(profile),
                onEdit: profile.isBuiltIn
                    ? null
                    : () => _openProfileBuilder(existing: profile),
                onDelete: profile.isBuiltIn
                    ? null
                    : () async {
                        await ref
                            .read(exifProfileProvider.notifier)
                            .deleteProfile(profile.id);
                        if (_selectedProfileId == profile.id) {
                          setState(() {
                            _selectedProfileId = 'clean';
                            _selectedCustomProfile = null;
                          });
                        }
                      },
              );
            }).toList(),
          ),
        ),

        // Detail profil terpilih
        if (_selectedProfileId != 'clean') ...[
          const SizedBox(height: 10),
          _SelectedProfileDetail(
            profile: allProfiles.firstWhere(
              (p) => p.id == _selectedProfileId,
              orElse: () => BuiltInProfiles.all.first,
            ),
          ),
        ],
      ],
    ).animate().fadeIn(delay: 250.ms, duration: 400.ms);
  }

  Widget _buildOptionsSection(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.cardDark : AppColors.cardLight;
    final border = isDark ? AppColors.borderDark : AppColors.borderLight;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(title: 'Opsi Penyimpanan'),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: border),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Tawarkan ganti file lama',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    Text(
                      'Setelah optimasi berhasil, kamu dapat memilih untuk menghapus file asli',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Switch(
                value: _replaceOld,
                onChanged: (v) => setState(() => _replaceOld = v),
              ),
            ],
          ),
        ),
      ],
    )
        .animate()
        .fadeIn(delay: 300.ms, duration: 400.ms);
  }

  Widget _buildEstimationSection(BuildContext context) {
    final origSize = widget.imageInfo.fileSize;
    final estReduction = _selectedFormat == 'png'
        ? 0.05
        : _selectedQuality >= 95
            ? 0.1
            : _selectedQuality >= 90
                ? 0.2
                : _selectedQuality >= 80
                    ? 0.35
                    : 0.5;

    final estSize = (origSize * (1 - estReduction)).round();

    return AppCard(
      backgroundColor: AppColors.primarySurface,
      hasBorder: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.lightbulb_outline_rounded,
                color: AppColors.primary,
                size: 18,
              ),
              const SizedBox(width: 8),
              Text(
                'Estimasi Hasil',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primaryDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _SizeEstCard(
                  label: 'Asli',
                  size: origSize.toReadableSize(),
                  color: AppColors.textPrimaryLight,
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 12),
                child: Icon(
                  Icons.arrow_forward_rounded,
                  color: AppColors.primary,
                  size: 20,
                ),
              ),
              Expanded(
                child: _SizeEstCard(
                  label: 'Estimasi',
                  size: estSize.toReadableSize(),
                  color: AppColors.success,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Estimasi persentase pengurangan: ~${(estReduction * 100).round()}%',
            style: GoogleFonts.poppins(
              fontSize: 11,
              color: AppColors.textSecondaryLight,
            ),
          ),
        ],
      ),
    )
        .animate()
        .fadeIn(delay: 400.ms, duration: 400.ms);
  }

  Widget _buildOptimizeButton(BuildContext context, dynamic settings) {
    // Resolve the "metadataProfile" string untuk backward compat
    final metaProfileId = _selectedCustomProfile != null
        ? 'custom'
        : _selectedProfileId;

    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: () {
          context.goNamed(
            'optimize-progress',
            extra: {
              'imageInfo': widget.imageInfo,
              'format': _selectedFormat,
              'quality': _selectedQuality,
              'replaceOld': _replaceOld,
              'outputPrefix':
                  settings.filePrefix ?? AppConstants.defaultFilePrefix,
              'metadataProfile': metaProfileId,
              'customProfile': _selectedCustomProfile,
              'watermarkEnabled': _watermarkEnabled,
              'watermarkLogoPath': _selectedWatermarkLogo?.path,
              'watermarkPosition': _watermarkPosition,
              'watermarkScale': _watermarkScale,
              'watermarkOpacity': _watermarkOpacity,
            },
          );
        },
        icon: const Icon(Icons.auto_fix_high_rounded),
        label: const Text('Mulai Optimasi'),
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
          textStyle: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    )
        .animate()
        .fadeIn(delay: 500.ms, duration: 400.ms)
        .slideY(begin: 0.1, end: 0);
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
                      fontSize: 14,
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

// ─────────────────────────────────────────────────────────────────────────────
// Profile Tile Widget
// ─────────────────────────────────────────────────────────────────────────────

class _ProfileTile extends StatelessWidget {
  final ExifProfileEntity profile;
  final bool isSelected;
  final VoidCallback onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const _ProfileTile({
    required this.profile,
    required this.isSelected,
    required this.onTap,
    this.onEdit,
    this.onDelete,
  });

  static const Map<String, IconData> _iconMap = {
    'camera_alt': Icons.camera_alt_rounded,
    'phone_iphone': Icons.phone_iphone_rounded,
    'phone_android': Icons.phone_android_rounded,
    'camera': Icons.camera_rounded,
    'brush': Icons.brush_rounded,
    'cleaning_services': Icons.cleaning_services_rounded,
    'airplanemode_active': Icons.airplanemode_active_rounded,
  };

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final icon = _iconMap[profile.iconKey] ?? Icons.camera_alt_rounded;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          decoration: BoxDecoration(
            color: isSelected
                ? cs.primary.withValues(alpha: 0.08)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            border: isSelected
                ? Border.all(color: cs.primary.withValues(alpha: 0.3))
                : null,
          ),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: isSelected
                      ? cs.primary.withValues(alpha: 0.12)
                      : cs.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon,
                    color: isSelected ? cs.primary : cs.onSurfaceVariant,
                    size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            profile.name,
                            style: GoogleFonts.poppins(
                              fontSize: 13,
                              fontWeight: isSelected
                                  ? FontWeight.w600
                                  : FontWeight.w400,
                              color: isSelected
                                  ? cs.primary
                                  : cs.onSurface,
                            ),
                          ),
                        ),
                        if (!profile.isBuiltIn)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.info.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              'Custom',
                              style: GoogleFonts.poppins(
                                fontSize: 10,
                                color: AppColors.info,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                      ],
                    ),
                    Text(
                      _subtitle(profile),
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              // Actions untuk custom profiles
              if (!profile.isBuiltIn && (onEdit != null || onDelete != null)) ...[
                if (onEdit != null)
                  IconButton(
                    icon: const Icon(Icons.edit_outlined, size: 18),
                    color: cs.onSurfaceVariant,
                    onPressed: onEdit,
                    tooltip: 'Edit',
                    visualDensity: VisualDensity.compact,
                  ),
                if (onDelete != null)
                  IconButton(
                    icon: const Icon(Icons.delete_outline_rounded, size: 18),
                    color: AppColors.error,
                    onPressed: onDelete,
                    tooltip: 'Hapus',
                    visualDensity: VisualDensity.compact,
                  ),
              ],
              // Radio indicator
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 18,
                height: 18,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isSelected ? cs.primary : cs.outline,
                    width: isSelected ? 5 : 2,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _subtitle(ExifProfileEntity p) {
    if (p.id == 'clean') return 'Hapus total semua metadata';
    if (p.cameraMake != null && p.cameraModel != null) {
      return '${p.cameraMake} ${p.cameraModel}';
    }
    if (p.software != null) return p.software!;
    return 'Profil custom';
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Selected Profile Detail Card
// ─────────────────────────────────────────────────────────────────────────────

class _SelectedProfileDetail extends StatelessWidget {
  final ExifProfileEntity profile;
  const _SelectedProfileDetail({required this.profile});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tags = _buildTagList(profile);
    if (tags.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.primarySurface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Tag yang akan disisipkan:',
            style: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.primaryDark,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: tags.map((tag) {
              return Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: cs.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  tag,
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    color: cs.primary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 250.ms);
  }

  List<String> _buildTagList(ExifProfileEntity p) {
    final tags = <String>[];
    if (p.cameraMake != null) tags.add('Make: ${p.cameraMake}');
    if (p.cameraModel != null) tags.add('Model: ${p.cameraModel}');
    if (p.software != null) tags.add('Software');
    if (p.lensModel != null) tags.add('Lens');
    if (p.isoSpeed != null) tags.add('ISO ${p.isoSpeed}');
    if (p.apertureF != null) tags.add('f/${p.apertureF}');
    if (p.shutterSpeedDenom != null) {
      tags.add('1/${p.shutterSpeedDenom!.round()}s');
    }
    if (p.focalLengthMm != null) tags.add('${p.focalLengthMm}mm');
    if (p.artistName != null && p.artistName!.isNotEmpty) tags.add('Artist');
    if (p.copyright != null && p.copyright!.isNotEmpty) tags.add('Copyright');
    if (p.enableGps) tags.add('GPS: ${p.gpsLocationName.isNotEmpty ? p.gpsLocationName : "Custom Coords"}');
    if (p.timestampMode != TimestampMode.current) {
      tags.add('Timestamp: ${p.timestampMode == TimestampMode.random ? "Random" : "Offset"}');
    }
    return tags;
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Small helper widgets (unchanged from original)
// ─────────────────────────────────────────────────────────────────────────────

class _FormatOptionCard extends StatelessWidget {
  final String format;
  final bool isSelected;
  final VoidCallback onTap;

  const _FormatOptionCard({
    required this.format,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: isSelected
              ? colorScheme.primary.withValues(alpha: 0.08)
              : colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? colorScheme.primary
                : colorScheme.outline,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(
              _formatIcon(format),
              size: 24,
              color: isSelected
                  ? colorScheme.primary
                  : colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 6),
            Text(
              format.toUpperCase(),
              style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight:
                    isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected
                    ? colorScheme.primary
                    : colorScheme.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _formatIcon(String f) {
    switch (f) {
      case 'jpg':
        return Icons.photo_outlined;
      case 'png':
        return Icons.image_outlined;
      case 'webp':
        return Icons.web_outlined;
      default:
        return Icons.image_outlined;
    }
  }
}

class _QualityLegendRow extends StatelessWidget {
  final int quality;
  const _QualityLegendRow({required this.quality});

  @override
  Widget build(BuildContext context) {
    String label;
    Color color;

    if (quality >= 95) {
      label = 'Kualitas sangat tinggi — perubahan ukuran minimal';
      color = AppColors.info;
    } else if (quality >= 90) {
      label = 'Kualitas tinggi — pengurangan ukuran baik';
      color = AppColors.success;
    } else if (quality >= 80) {
      label = 'Kualitas sedang — pengurangan ukuran signifikan';
      color = AppColors.warning;
    } else {
      label = 'Kualitas rendah — pengurangan ukuran maksimal';
      color = AppColors.error;
    }

    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ],
    );
  }
}

class _SizeEstCard extends StatelessWidget {
  final String label;
  final String size;
  final Color color;

  const _SizeEstCard({
    required this.label,
    required this.size,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 11,
              color: AppColors.textSecondaryLight,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            size,
            style: GoogleFonts.poppins(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
