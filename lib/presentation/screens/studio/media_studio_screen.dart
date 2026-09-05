import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:file_picker/file_picker.dart';
import '../../../core/theme/app_colors.dart';

class MediaStudioScreen extends StatelessWidget {
  const MediaStudioScreen({super.key});

  Future<void> _pickSingleMedia(BuildContext context) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.media,
    );
    if (result != null && result.files.single.path != null) {
      final path = result.files.single.path!;
      final ext = path.split('.').last.toLowerCase();
      final isVideo = ext == 'mp4' || ext == 'mov' || ext == 'mkv' || ext == 'avi' || ext == 'webm';
      if (context.mounted) {
        context.pushNamed('video-edit', extra: {
          'inputPath': path,
          'isVideo': isVideo,
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Studio Privacy & Media Editor',
          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 16),
        ),
      ),
      body: ListView(
        padding: EdgeInsets.symmetric(
          horizontal: screenWidth < 360 ? 12 : 16,
          vertical: 14,
        ),
        children: [
          // Studio Hero Card - Ultra Responsive
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: isDark ? AppColors.heroGradientDark : AppColors.heroGradientLight,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.15),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.movie_filter_rounded, color: Colors.white, size: 28),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'FFmpeg Media Studio',
                        style: GoogleFonts.plusJakartaSans(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 17,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Edit video & foto, pasang logo di pojok mana pun, lalu bersihkan dan ganti metadata EXIF secara otomatis.',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.9),
                    fontSize: 12,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ).animate().fadeIn(duration: 350.ms),

          const SizedBox(height: 20),

          Text(
            'Fitur Utama Studio',
            style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 15),
          ),
          const SizedBox(height: 10),

          // Compact Studio Action Cards
          _buildCompactStudioCard(
            context: context,
            title: 'Editor Video & Watermark',
            subtitle: 'Edit visual media, atur trim & rotasi, lalu pasang logo di pojok pilihan.',
            icon: Icons.video_call_rounded,
            badgeText: 'FFmpeg Engine',
            color: const Color(0xFF6C5CE7),
            onTap: () => _pickSingleMedia(context),
          ).animate().fadeIn(delay: 50.ms),

          const SizedBox(height: 10),

          _buildCompactStudioCard(
            context: context,
            title: 'Editan Massal (Batch Edit)',
            subtitle: 'Edit dan bersihkan metadata banyak foto/video secara bersamaan.',
            icon: Icons.dynamic_feed_rounded,
            badgeText: 'Massal / Bulk',
            color: const Color(0xFF00B894),
            onTap: () => context.pushNamed('batch-edit'),
          ).animate().fadeIn(delay: 100.ms),

          const SizedBox(height: 10),

          _buildCompactStudioCard(
            context: context,
            title: 'Manajemen Profil EXIF',
            subtitle: 'Kelola profil kamera palsu untuk menyamarkan jejak perangkat.',
            icon: Icons.camera_enhance_rounded,
            badgeText: 'Privacy Spoofing',
            color: const Color(0xFF0984E3),
            onTap: () => context.pushNamed('exif-profile'),
          ).animate().fadeIn(delay: 150.ms),

          const SizedBox(height: 10),

          _buildCompactStudioCard(
            context: context,
            title: 'Kontrol Audio Video',
            subtitle: 'Ekstrak audio atau bisukan suara video dalam sekali klik.',
            icon: Icons.volume_off_rounded,
            badgeText: 'Audio Mute',
            color: const Color(0xFFE17055),
            onTap: () => _pickSingleMedia(context),
          ).animate().fadeIn(delay: 200.ms),

          const SizedBox(height: 10),

          _buildCompactStudioCard(
            context: context,
            title: 'Konverter Format Media',
            subtitle: 'Ubah format MP4, MOV, JPG, PNG, dan WebP secara cepat.',
            icon: Icons.transform_rounded,
            badgeText: 'Converter',
            color: const Color(0xFF6C5CE7),
            onTap: () => _pickSingleMedia(context),
          ).animate().fadeIn(delay: 250.ms),
        ],
      ),
    );
  }

  Widget _buildCompactStudioCard({
    required BuildContext context,
    required String title,
    required String subtitle,
    required IconData icon,
    required String badgeText,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 1.5,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 24),
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
                            title,
                            style: GoogleFonts.plusJakartaSans(
                              fontWeight: FontWeight.bold,
                              fontSize: 13.5,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            badgeText,
                            style: TextStyle(
                              color: color,
                              fontWeight: FontWeight.bold,
                              fontSize: 9,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: const TextStyle(color: Colors.grey, fontSize: 11, height: 1.25),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }
}
