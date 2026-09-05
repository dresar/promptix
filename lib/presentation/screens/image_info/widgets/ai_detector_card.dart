import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../domain/entities/image_info_entity.dart';

/// Card yang menampilkan hasil deteksi AI dan C2PA pada gambar
class AiDetectorCard extends StatelessWidget {
  final ImageInfoEntity imageInfo;

  const AiDetectorCard({super.key, required this.imageInfo});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final hasThreat = imageInfo.hasAiSignature;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: hasThreat
            ? AppColors.errorSurface
            : (isDark
                ? const Color(0xFF0D2B1A)
                : const Color(0xFFECFDF5)),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: hasThreat
              ? AppColors.error.withValues(alpha: 0.4)
              : AppColors.success.withValues(alpha: 0.4),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(context, hasThreat),
          if (hasThreat) ...[
            const SizedBox(height: 12),
            _buildThreatDetails(context),
          ],
          const SizedBox(height: 10),
          _buildFooterNote(context, hasThreat),
        ],
      ),
    )
        .animate()
        .fadeIn(delay: 150.ms, duration: 400.ms)
        .slideY(begin: 0.05, end: 0);
  }

  Widget _buildHeader(BuildContext context, bool hasThreat) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: hasThreat
                ? AppColors.error.withValues(alpha: 0.12)
                : AppColors.success.withValues(alpha: 0.12),
            shape: BoxShape.circle,
          ),
          child: Icon(
            hasThreat
                ? Icons.auto_awesome_outlined
                : Icons.verified_rounded,
            color: hasThreat ? AppColors.error : AppColors.success,
            size: 22,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                hasThreat ? 'Tanda AI Terdeteksi' : 'Metadata Aman',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: hasThreat ? AppColors.error : AppColors.success,
                ),
              ),
              Text(
                hasThreat
                    ? 'Gambar ini mengandung metadata yang mengidentifikasi AI'
                    : 'Tidak ada tanda AI atau C2PA yang ditemukan',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: hasThreat
                      ? AppColors.error.withValues(alpha: 0.8)
                      : AppColors.success.withValues(alpha: 0.8),
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
        _StatusBadge(isAi: hasThreat),
      ],
    );
  }

  Widget _buildThreatDetails(BuildContext context) {
    final items = <_ThreatItem>[];

    if (imageInfo.hasC2pa) {
      items.add(const _ThreatItem(
        icon: Icons.security_outlined,
        label: 'C2PA / Content Credentials',
        detail: 'Provenance AI ditemukan di file',
        color: AppColors.error,
      ));
    }

    if (imageInfo.aiSoftwareDetected != null) {
      items.add(_ThreatItem(
        icon: Icons.apps_rounded,
        label: 'Software AI: ${imageInfo.aiSoftwareDetected}',
        detail: 'Terdeteksi dari metadata software',
        color: AppColors.warning,
      ));
    }

    if (imageInfo.aiSignatureKeywords.isNotEmpty) {
      items.add(_ThreatItem(
        icon: Icons.label_outline_rounded,
        label: 'Keyword: ${imageInfo.aiSignatureKeywords.take(3).join(", ")}${imageInfo.aiSignatureKeywords.length > 3 ? "…" : ""}',
        detail: '${imageInfo.aiSignatureKeywords.length} kata kunci AI ditemukan',
        color: AppColors.warning,
      ));
    }

    return Column(
      children: items.map((item) => _ThreatRow(item: item)).toList(),
    );
  }

  Widget _buildFooterNote(BuildContext context, bool hasThreat) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: hasThreat
            ? AppColors.error.withValues(alpha: 0.08)
            : AppColors.success.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(
            hasThreat
                ? Icons.auto_fix_high_rounded
                : Icons.check_circle_outline_rounded,
            size: 14,
            color: hasThreat ? AppColors.error : AppColors.success,
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              hasThreat
                  ? 'Lanjut ke Optimasi untuk menghapus semua tanda ini secara otomatis'
                  : 'Gambar ini aman untuk diproses lebih lanjut',
              style: GoogleFonts.poppins(
                fontSize: 11,
                color: hasThreat ? AppColors.error : AppColors.success,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final bool isAi;
  const _StatusBadge({required this.isAi});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: isAi ? AppColors.error : AppColors.success,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        isAi ? 'AI' : 'AMAN',
        style: GoogleFonts.poppins(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: Colors.white,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

class _ThreatItem {
  final IconData icon;
  final String label;
  final String detail;
  final Color color;

  const _ThreatItem({
    required this.icon,
    required this.label,
    required this.detail,
    required this.color,
  });
}

class _ThreatRow extends StatelessWidget {
  final _ThreatItem item;
  const _ThreatRow({required this.item});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(item.icon, color: item.color, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.label,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: item.color,
                  ),
                ),
                Text(
                  item.detail,
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    color: item.color.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
