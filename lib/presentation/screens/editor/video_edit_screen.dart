import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as p;

import '../../../core/theme/app_colors.dart';
import '../../../domain/entities/image_info_entity.dart';
import '../../../domain/entities/media_edit_config_entity.dart';
import '../../../domain/entities/watermark_position.dart';
import '../../providers/media_editor_provider.dart';
import '../../providers/watermark_provider.dart';
import '../../providers/exif_profile_provider.dart';

class VideoEditScreen extends ConsumerStatefulWidget {
  final String inputPath;
  final bool isVideo;

  const VideoEditScreen({
    super.key,
    required this.inputPath,
    required this.isVideo,
  });

  @override
  ConsumerState<VideoEditScreen> createState() => _VideoEditScreenState();
}

class _VideoEditScreenState extends ConsumerState<VideoEditScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isProcessing = false;
  String? _selectedLogoPath;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(mediaEditConfigProvider.notifier).initForMedia(
            isVideo: widget.isVideo,
            initialFormat: p.extension(widget.inputPath).replaceFirst('.', '').toUpperCase(),
          );
      final watermarks = ref.read(watermarkListProvider).value ?? [];
      if (watermarks.isNotEmpty) {
        _selectedLogoPath = watermarks.first.path;
        ref.read(mediaEditConfigProvider.notifier).setWatermarkLogo(_selectedLogoPath);
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _pickNewLogo() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['png', 'jpg', 'jpeg', 'webp'],
    );
    if (result != null && result.files.single.path != null) {
      final logoPath = result.files.single.path!;
      await ref.read(watermarkListProvider.notifier).addWatermark(logoPath);
      setState(() {
        _selectedLogoPath = logoPath;
      });
      ref.read(mediaEditConfigProvider.notifier).setWatermarkLogo(logoPath);
    }
  }

  Future<void> _startProcessing() async {
    setState(() => _isProcessing = true);
    final config = ref.read(mediaEditConfigProvider);
    final ffmpegService = ref.read(ffmpegServiceProvider);
    final isFfmpegAvail = await ffmpegService.isFFmpegAvailable();

    if (widget.isVideo) {
      if (!isFfmpegAvail) {
        if (!mounted) return;
        setState(() => _isProcessing = false);
        _showFfmpegMissingDialog();
        return;
      }

      final res = await ffmpegService.processMedia(
        inputPath: widget.inputPath,
        config: config,
      );
      if (!mounted) return;
      setState(() => _isProcessing = false);

      if (res.success) {
        _showSuccessDialog(res.outputPath, res.executionTimeMs);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(res.errorMessage ?? 'Gagal memproses video via FFmpeg'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } else {
      // Photo processing: Use FFmpeg if available, otherwise pure Dart engine fallback
      if (isFfmpegAvail) {
        final res = await ffmpegService.processMedia(
          inputPath: widget.inputPath,
          config: config,
        );
        if (!mounted) return;
        if (res.success) {
          setState(() => _isProcessing = false);
          _showSuccessDialog(res.outputPath, res.executionTimeMs);
          return;
        }
      }

      // Pure Dart Fallback Engine for Photos
      final info = ImageInfoEntity(
        filePath: widget.inputPath,
        fileName: p.basename(widget.inputPath),
        fileSize: await File(widget.inputPath).length(),
        width: 1080,
        height: 1080,
        format: config.outputFormat,
      );

      if (!mounted) return;
      context.pushNamed('optimize-progress', extra: {
        'imageInfo': info,
        'format': config.outputFormat,
        'quality': config.quality,
        'replaceOld': false,
        'outputPrefix': 'clean_',
        'metadataProfile': config.metadataProfilePreset,
        'customProfile': config.customExifProfile,
        'watermarkEnabled': config.enableWatermark,
        'watermarkLogoPath': config.watermarkLogoPath,
        'watermarkPosition': config.watermarkPosition.toPositionString(),
        'watermarkScale': config.watermarkScale,
        'watermarkOpacity': config.watermarkOpacity,
      });
      setState(() => _isProcessing = false);
    }
  }

  void _showFfmpegMissingDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 24),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'FFmpeg Belum Terinstal',
                style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Penyuntingan video membutuhkan binary FFmpeg di komputer/sistem Anda.',
              style: TextStyle(fontSize: 12),
            ),
            SizedBox(height: 10),
            Text(
              'Langkah Cepat Memasang FFmpeg:',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 4),
            Text(
              '1. Unduh ffmpeg.exe dari ffmpeg.org\n'
              '2. Ekstrak & salin ke folder C:\\ffmpeg\\bin\\ffmpeg.exe\n'
              '3. Atau tambahkan lokasi folder ke PATH Windows.',
              style: TextStyle(fontSize: 11, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Mengerti', style: TextStyle(fontSize: 12)),
          ),
        ],
      ),
    );
  }

  void _showSuccessDialog(String outputPath, int elapsedMs) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        contentPadding: const EdgeInsets.all(16),
        title: Row(
          children: [
            const Icon(Icons.check_circle_rounded, color: Colors.green, size: 24),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Selesai!',
                style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Media & metadata berhasil diproses via FFmpeg.', style: TextStyle(fontSize: 12)),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.grey.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Waktu: ${elapsedMs}ms', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
                  const SizedBox(height: 4),
                  Text(outputPath, style: const TextStyle(fontSize: 10, color: Colors.grey), maxLines: 2, overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Tutup', style: TextStyle(fontSize: 12)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () {
              Navigator.pop(ctx);
              context.pop();
            },
            child: const Text('Selesai', style: TextStyle(fontSize: 12)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final config = ref.watch(mediaEditConfigProvider);
    final watermarks = ref.watch(watermarkListProvider).value ?? [];
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.isVideo ? 'Editor Video & Privacy' : 'Editor Foto & Watermark',
          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.primary,
          labelColor: AppColors.primary,
          unselectedLabelColor: isDark ? Colors.grey[400] : Colors.grey[600],
          labelStyle: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 11),
          tabs: const [
            Tab(icon: Icon(Icons.water_drop_rounded, size: 18), text: 'Watermark'),
            Tab(icon: Icon(Icons.tune_rounded, size: 18), text: 'Edit Media'),
            Tab(icon: Icon(Icons.security_rounded, size: 18), text: 'Privacy'),
          ],
        ),
      ),
      body: _isProcessing
          ? _buildProcessingView()
          : Column(
              children: [
                // Live Interactive Visual Preview Box (Dynamic Responsive Height)
                _buildLivePreviewBox(config, screenHeight),

                // Multi-tab Editor Options
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildWatermarkTab(config, watermarks),
                      _buildAdjustmentsTab(config),
                      _buildMetadataTab(config),
                    ],
                  ),
                ),

                // Compact Bottom Action Bar
                _buildBottomAction(config),
              ],
            ),
    );
  }

  Widget _buildProcessingView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(width: 32, height: 32, child: CircularProgressIndicator(strokeWidth: 3)),
          const SizedBox(height: 16),
          Text(
            'Memproses Media via FFmpeg...',
            style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 14),
          ),
          const SizedBox(height: 6),
          const Text('Sedang menempel logo dan membersihkan metadata.', style: TextStyle(fontSize: 12, color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _buildLivePreviewBox(MediaEditConfigEntity config, double screenHeight) {
    final previewHeight = (screenHeight * 0.24).clamp(150.0, 200.0);

    return Container(
      height: previewHeight,
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.black87,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          if (!widget.isVideo && File(widget.inputPath).existsSync())
            ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: Image.file(
                File(widget.inputPath),
                fit: BoxFit.contain,
                width: double.infinity,
                height: double.infinity,
              ),
            )
          else
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    widget.isVideo ? Icons.video_library_rounded : Icons.image_rounded,
                    color: Colors.white54,
                    size: 40,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    p.basename(widget.inputPath),
                    style: const TextStyle(color: Colors.white70, fontSize: 11),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),

          if (config.enableWatermark &&
              config.watermarkLogoPath != null &&
              File(config.watermarkLogoPath!).existsSync())
            _buildWatermarkOverlayPreview(config, previewHeight),

          Positioned(
            top: 8,
            left: 8,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.65),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                'Posisi: ${config.watermarkPosition.label}',
                style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWatermarkOverlayPreview(MediaEditConfigEntity config, double previewHeight) {
    Alignment alignment = Alignment.bottomRight;
    switch (config.watermarkPosition.type) {
      case WatermarkPositionType.topLeft:
        alignment = Alignment.topLeft;
        break;
      case WatermarkPositionType.topRight:
        alignment = Alignment.topRight;
        break;
      case WatermarkPositionType.bottomLeft:
        alignment = Alignment.bottomLeft;
        break;
      case WatermarkPositionType.bottomRight:
        alignment = Alignment.bottomRight;
        break;
      case WatermarkPositionType.center:
        alignment = Alignment.center;
        break;
      case WatermarkPositionType.custom:
        alignment = Alignment(
          (config.watermarkPosition.xPercent * 2) - 1.0,
          (config.watermarkPosition.yPercent * 2) - 1.0,
        );
        break;
    }

    final logoSize = previewHeight * config.watermarkScale.clamp(0.05, 0.5);

    return Align(
      alignment: alignment,
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Opacity(
          opacity: config.watermarkOpacity,
          child: Image.file(
            File(config.watermarkLogoPath!),
            width: logoSize,
            height: logoSize,
            fit: BoxFit.contain,
          ),
        ),
      ),
    );
  }

  Widget _buildWatermarkTab(MediaEditConfigEntity config, List<File> watermarks) {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      children: [
        SwitchListTile(
          dense: true,
          contentPadding: EdgeInsets.zero,
          title: Text('Aktifkan Watermark Logo', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 13)),
          subtitle: const Text('Tempel logo di pojok foto atau video secara otomatis.', style: TextStyle(fontSize: 11)),
          value: config.enableWatermark,
          onChanged: (val) {
            ref.read(mediaEditConfigProvider.notifier).toggleWatermark(val);
          },
        ),
        const Divider(height: 16),

        Text('Pilih Pojok Posisi Logo:', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 12)),
        const SizedBox(height: 8),

        // Corner Choice Grid
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 3,
          childAspectRatio: 2.6,
          crossAxisSpacing: 6,
          mainAxisSpacing: 6,
          children: [
            _buildPositionChoiceTile(config, WatermarkPositionType.topLeft, 'Kiri Atas'),
            _buildPositionChoiceTile(config, WatermarkPositionType.center, 'Tengah'),
            _buildPositionChoiceTile(config, WatermarkPositionType.topRight, 'Kanan Atas'),
            _buildPositionChoiceTile(config, WatermarkPositionType.bottomLeft, 'Kiri Bawah'),
            _buildPositionChoiceTile(config, WatermarkPositionType.custom, 'Kustom'),
            _buildPositionChoiceTile(config, WatermarkPositionType.bottomRight, 'Kanan Bawah'),
          ],
        ),

        const SizedBox(height: 14),

        // Quick Preset Scale Pills
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Ukuran Logo: ${(config.watermarkScale * 100).toInt()}%', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
            Row(
              children: [0.10, 0.18, 0.28].map((sc) {
                return Padding(
                  padding: const EdgeInsets.only(left: 4),
                  child: InkWell(
                    onTap: () => ref.read(mediaEditConfigProvider.notifier).setWatermarkScale(sc),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: config.watermarkScale == sc ? AppColors.primary : Colors.grey.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text('${(sc * 100).toInt()}%', style: TextStyle(fontSize: 9, color: config.watermarkScale == sc ? Colors.white : Colors.grey[800])),
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
        Slider(
          value: config.watermarkScale,
          min: 0.05,
          max: 0.50,
          divisions: 45,
          onChanged: (val) {
            ref.read(mediaEditConfigProvider.notifier).setWatermarkScale(val);
          },
        ),

        Text('Transparansi Logo: ${(config.watermarkOpacity * 100).toInt()}%', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
        Slider(
          value: config.watermarkOpacity,
          min: 0.1,
          max: 1.0,
          divisions: 18,
          onChanged: (val) {
            ref.read(mediaEditConfigProvider.notifier).setWatermarkOpacity(val);
          },
        ),

        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Pilih Berkas Logo PNG/JPG', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 12)),
            TextButton.icon(
              style: TextButton.styleFrom(visualDensity: VisualDensity.compact),
              icon: const Icon(Icons.add_photo_alternate_rounded, size: 16),
              label: const Text('Tambah Logo', style: TextStyle(fontSize: 11)),
              onPressed: _pickNewLogo,
            ),
          ],
        ),
        if (watermarks.isEmpty)
          const Text('Belum ada logo tersimpan. Klik Tambah Logo di atas.', style: TextStyle(fontSize: 11, color: Colors.grey))
        else
          SizedBox(
            height: 54,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: watermarks.length,
              itemBuilder: (ctx, idx) {
                final logo = watermarks[idx];
                final isSelected = _selectedLogoPath == logo.path;
                return GestureDetector(
                  onTap: () {
                    setState(() => _selectedLogoPath = logo.path);
                    ref.read(mediaEditConfigProvider.notifier).setWatermarkLogo(logo.path);
                  },
                  child: Container(
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: isSelected ? AppColors.primary : Colors.grey.withValues(alpha: 0.3),
                        width: isSelected ? 2.5 : 1,
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Image.file(logo, width: 48, height: 48, fit: BoxFit.cover),
                  ),
                );
              },
            ),
          ),
      ],
    );
  }

  Widget _buildPositionChoiceTile(MediaEditConfigEntity config, WatermarkPositionType posType, String title) {
    final isSelected = config.watermarkPosition.type == posType;
    return ChoiceChip(
      visualDensity: VisualDensity.compact,
      padding: EdgeInsets.zero,
      label: Text(title, style: TextStyle(fontSize: 10, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
      selected: isSelected,
      selectedColor: AppColors.primary.withValues(alpha: 0.2),
      onSelected: (_) {
        ref.read(mediaEditConfigProvider.notifier).setWatermarkPosition(
              WatermarkPosition(type: posType),
            );
      },
    );
  }

  Widget _buildAdjustmentsTab(MediaEditConfigEntity config) {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      children: [
        if (widget.isVideo) ...[
          Text('Pengaturan Video', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 14)),
          const SizedBox(height: 6),

          SwitchListTile(
            dense: true,
            contentPadding: EdgeInsets.zero,
            title: const Text('Mute Suara (Hapus Audio Track)', style: TextStyle(fontSize: 12)),
            value: config.muteAudio,
            onChanged: (val) {
              ref.read(mediaEditConfigProvider.notifier).toggleMuteAudio(val);
            },
          ),

          const SizedBox(height: 8),
          Text('Kecepatan Video: ${config.speedMultiplier}x', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [0.5, 1.0, 1.5, 2.0].map((s) {
              return ChoiceChip(
                visualDensity: VisualDensity.compact,
                label: Text('${s}x', style: const TextStyle(fontSize: 10)),
                selected: config.speedMultiplier == s,
                onSelected: (_) {
                  ref.read(mediaEditConfigProvider.notifier).setSpeed(s);
                },
              );
            }).toList(),
          ),

          const SizedBox(height: 10),
          Text('Rotasi Video: ${config.rotationDegrees}°', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [0, 90, 180, 270].map((deg) {
              return ChoiceChip(
                visualDensity: VisualDensity.compact,
                label: Text('$deg°', style: const TextStyle(fontSize: 10)),
                selected: config.rotationDegrees == deg,
                onSelected: (_) {
                  ref.read(mediaEditConfigProvider.notifier).setRotation(deg);
                },
              );
            }).toList(),
          ),
          const Divider(height: 20),
        ],

        Text('Pengaturan Warna & Kualitas', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 14)),
        const SizedBox(height: 8),

        Text('Kecerahan: ${config.brightness.toStringAsFixed(2)}', style: const TextStyle(fontSize: 11)),
        Slider(
          value: config.brightness,
          min: -0.5,
          max: 0.5,
          divisions: 20,
          onChanged: (val) {
            ref.read(mediaEditConfigProvider.notifier).setVisualAdjustments(brightness: val);
          },
        ),

        Text('Kontras: ${config.contrast.toStringAsFixed(2)}', style: const TextStyle(fontSize: 11)),
        Slider(
          value: config.contrast,
          min: 0.5,
          max: 1.8,
          divisions: 26,
          onChanged: (val) {
            ref.read(mediaEditConfigProvider.notifier).setVisualAdjustments(contrast: val);
          },
        ),

        Text('Kualitas File: ${config.quality}%', style: const TextStyle(fontSize: 11)),
        Slider(
          value: config.quality.toDouble(),
          min: 20,
          max: 100,
          divisions: 16,
          onChanged: (val) {
            ref.read(mediaEditConfigProvider.notifier).setVisualAdjustments(quality: val.toInt());
          },
        ),
      ],
    );
  }

  Widget _buildMetadataTab(MediaEditConfigEntity config) {
    final profiles = ref.watch(allExifProfilesProvider);
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      children: [
        Text('Tindakan Metadata & Privasi', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 14)),
        const SizedBox(height: 6),

        RadioGroup<PostMetadataAction>(
          groupValue: config.metadataAction,
          onChanged: (val) => ref.read(mediaEditConfigProvider.notifier).setMetadataAction(val!),
          child: const Column(
            children: [
              RadioListTile<PostMetadataAction>(
                dense: true,
                contentPadding: EdgeInsets.zero,
                title: Text('Babat Metadata & Palsukan EXIF Perangkat', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                subtitle: Text('Hapus C2PA/AI tracking dan suntikkan metadata kamera baru.', style: TextStyle(fontSize: 11)),
                value: PostMetadataAction.scrubAndSpoof,
              ),
              RadioListTile<PostMetadataAction>(
                dense: true,
                contentPadding: EdgeInsets.zero,
                title: Text('Bersihkan Metadata Total (Clean Only)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                subtitle: Text('Kosongkan semua metadata tanpa menyuntikkan data baru.', style: TextStyle(fontSize: 11)),
                value: PostMetadataAction.scrubOnly,
              ),
            ],
          ),
        ),

        const Divider(height: 20),

        if (config.metadataAction == PostMetadataAction.scrubAndSpoof) ...[
          Text('Profil Perangkat EXIF Spoofing:', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 12)),
          const SizedBox(height: 8),

          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              _buildProfileChip(config, 'sony', 'Sony Alpha R4'),
              _buildProfileChip(config, 'canon', 'Canon EOS R5'),
              _buildProfileChip(config, 'iphone', 'iPhone 15 Pro'),
              _buildProfileChip(config, 'samsung', 'Galaxy S24'),
            ],
          ),

          if (profiles.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text('Profil Kustom:', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 11)),
            RadioGroup<String>(
              groupValue: config.metadataProfilePreset,
              onChanged: (val) {
                final matched = profiles.firstWhere((p) => 'custom_${p.id}' == val, orElse: () => profiles.first);
                ref.read(mediaEditConfigProvider.notifier).setMetadataProfile(val!, customProfile: matched);
              },
              child: Column(
                children: profiles.map((p) {
                  return RadioListTile<String>(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    title: Text(p.name, style: const TextStyle(fontSize: 11)),
                    value: 'custom_${p.id}',
                  );
                }).toList(),
              ),
            ),
          ],
        ],
      ],
    );
  }

  Widget _buildProfileChip(MediaEditConfigEntity config, String key, String title) {
    final isSelected = config.metadataProfilePreset == key;
    return ChoiceChip(
      visualDensity: VisualDensity.compact,
      label: Text(title, style: TextStyle(fontSize: 10, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
      selected: isSelected,
      onSelected: (_) {
        ref.read(mediaEditConfigProvider.notifier).setMetadataProfile(key);
      },
    );
  }

  Widget _buildBottomAction(MediaEditConfigEntity config) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, -3),
          ),
        ],
      ),
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
            onPressed: _startProcessing,
            icon: const Icon(Icons.flash_on_rounded, size: 18),
            label: Text(
              'Proses ${widget.isVideo ? "Video" : "Foto"} & Metadata',
              style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 13),
            ),
          ),
        ),
      ),
    );
  }
}
