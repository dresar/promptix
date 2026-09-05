import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:uuid/uuid.dart';
import '../../../core/theme/app_colors.dart';
import '../../../domain/entities/exif_profile_entity.dart';
import '../../../presentation/providers/exif_profile_provider.dart';

/// Mode tampilan form
enum _FormMode { basic, advanced }

/// Screen untuk membuat / mengedit custom EXIF profile
class ExifProfileScreen extends ConsumerStatefulWidget {
  /// Jika null → mode baru. Jika ada → mode edit.
  final ExifProfileEntity? existingProfile;

  const ExifProfileScreen({super.key, this.existingProfile});

  @override
  ConsumerState<ExifProfileScreen> createState() => _ExifProfileScreenState();
}

class _ExifProfileScreenState extends ConsumerState<ExifProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  _FormMode _mode = _FormMode.basic;

  // ── Controllers ────────────────────────────────────────────────────────────
  late TextEditingController _nameCtrl;
  late TextEditingController _makeCtrl;
  late TextEditingController _modelCtrl;
  late TextEditingController _lensCtrl;
  late TextEditingController _softwareCtrl;
  late TextEditingController _isoCtrl;
  late TextEditingController _apertureCtrl;
  late TextEditingController _shutterCtrl;
  late TextEditingController _focalCtrl;
  late TextEditingController _artistCtrl;
  late TextEditingController _copyrightCtrl;
  late TextEditingController _gpsLatCtrl;
  late TextEditingController _gpsLonCtrl;
  late TextEditingController _gpsAltCtrl;
  late TextEditingController _gpsLocationCtrl;
  late TextEditingController _offsetDaysCtrl;

  // ── State fields ───────────────────────────────────────────────────────────
  int _whiteBalance = 0;
  int _flashMode = 16;
  TimestampMode _timestampMode = TimestampMode.current;
  bool _enableGps = false;

  bool get _isEdit => widget.existingProfile != null;

  @override
  void initState() {
    super.initState();
    final p = widget.existingProfile;
    _nameCtrl = TextEditingController(text: p?.name ?? '');
    _makeCtrl = TextEditingController(text: p?.cameraMake ?? '');
    _modelCtrl = TextEditingController(text: p?.cameraModel ?? '');
    _lensCtrl = TextEditingController(text: p?.lensModel ?? '');
    _softwareCtrl = TextEditingController(text: p?.software ?? '');
    _isoCtrl = TextEditingController(
        text: p?.isoSpeed != null ? '${p!.isoSpeed}' : '');
    _apertureCtrl = TextEditingController(
        text: p?.apertureF != null ? '${p!.apertureF}' : '');
    _shutterCtrl = TextEditingController(
        text: p?.shutterSpeedDenom != null ? '${p!.shutterSpeedDenom!.round()}' : '');
    _focalCtrl = TextEditingController(
        text: p?.focalLengthMm != null ? '${p!.focalLengthMm}' : '');
    _artistCtrl = TextEditingController(text: p?.artistName ?? '');
    _copyrightCtrl = TextEditingController(text: p?.copyright ?? '');
    _gpsLatCtrl = TextEditingController(
        text: p?.gpsLatitude != null ? '${p!.gpsLatitude}' : '');
    _gpsLonCtrl = TextEditingController(
        text: p?.gpsLongitude != null ? '${p!.gpsLongitude}' : '');
    _gpsAltCtrl = TextEditingController(
        text: p?.gpsAltitudeM != null ? '${p!.gpsAltitudeM}' : '');
    _gpsLocationCtrl =
        TextEditingController(text: p?.gpsLocationName ?? '');
    _offsetDaysCtrl = TextEditingController(
        text: p?.timestampOffsetDays != null
            ? '${p!.timestampOffsetDays}'
            : '0');

    _whiteBalance = p?.whiteBalanceMode ?? 0;
    _flashMode = p?.flashMode ?? 16;
    _timestampMode = p?.timestampMode ?? TimestampMode.current;
    _enableGps = p?.enableGps ?? false;
  }

  @override
  void dispose() {
    for (final c in [
      _nameCtrl, _makeCtrl, _modelCtrl, _lensCtrl, _softwareCtrl,
      _isoCtrl, _apertureCtrl, _shutterCtrl, _focalCtrl,
      _artistCtrl, _copyrightCtrl,
      _gpsLatCtrl, _gpsLonCtrl, _gpsAltCtrl, _gpsLocationCtrl,
      _offsetDaysCtrl,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final profile = ExifProfileEntity(
      id: widget.existingProfile?.id ?? const Uuid().v4(),
      name: _nameCtrl.text.trim(),
      iconKey: 'camera_alt',
      isBuiltIn: false,
      cameraMake: _makeCtrl.text.trim().isEmpty ? null : _makeCtrl.text.trim(),
      cameraModel: _modelCtrl.text.trim().isEmpty ? null : _modelCtrl.text.trim(),
      lensModel: _lensCtrl.text.trim().isEmpty ? null : _lensCtrl.text.trim(),
      software: _softwareCtrl.text.trim().isEmpty ? null : _softwareCtrl.text.trim(),
      isoSpeed: int.tryParse(_isoCtrl.text.trim()),
      apertureF: double.tryParse(_apertureCtrl.text.trim()),
      shutterSpeedDenom: double.tryParse(_shutterCtrl.text.trim()),
      focalLengthMm: double.tryParse(_focalCtrl.text.trim()),
      whiteBalanceMode: _whiteBalance,
      flashMode: _flashMode,
      artistName: _artistCtrl.text.trim().isEmpty ? null : _artistCtrl.text.trim(),
      copyright: _copyrightCtrl.text.trim().isEmpty ? null : _copyrightCtrl.text.trim(),
      timestampMode: _timestampMode,
      timestampOffsetDays: int.tryParse(_offsetDaysCtrl.text.trim()) ?? 0,
      enableGps: _enableGps,
      gpsLatitude: _enableGps ? double.tryParse(_gpsLatCtrl.text.trim()) : null,
      gpsLongitude: _enableGps ? double.tryParse(_gpsLonCtrl.text.trim()) : null,
      gpsAltitudeM: _enableGps ? double.tryParse(_gpsAltCtrl.text.trim()) : null,
      gpsLocationName: _enableGps ? _gpsLocationCtrl.text.trim() : '',
    );

    await ref.read(exifProfileProvider.notifier).saveProfile(profile);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _isEdit ? 'Profil diperbarui!' : 'Profil baru disimpan!',
            style: GoogleFonts.poppins(),
          ),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
        ),
      );
      context.pop(profile);
    }
  }

  Future<void> _exportProfile() async {
    if (widget.existingProfile == null) return;
    final json = widget.existingProfile!.exportJson();
    await Clipboard.setData(ClipboardData(text: json));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('JSON disalin ke clipboard!', style: GoogleFonts.poppins()),
        backgroundColor: AppColors.info,
        behavior: SnackBarBehavior.floating,
      ));
    }
  }

  void _setGpsPreset(String name, double lat, double lon, double alt) {
    setState(() {
      _gpsLocationCtrl.text = name;
      _gpsLatCtrl.text = lat.toString();
      _gpsLonCtrl.text = lon.toString();
      _gpsAltCtrl.text = alt.toString();
    });
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEdit ? 'Edit Profil EXIF' : 'Profil EXIF Baru'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => context.pop(),
        ),
        actions: [
          if (_isEdit)
            IconButton(
              icon: const Icon(Icons.ios_share_rounded),
              tooltip: 'Export JSON',
              onPressed: _exportProfile,
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildModeToggle(context, colorScheme, isDark),
                    const SizedBox(height: 20),
                    _buildProfileNameField(context, colorScheme),
                    const SizedBox(height: 20),
                    _buildCameraSection(context, colorScheme, isDark),
                    const SizedBox(height: 20),
                    if (_mode == _FormMode.advanced) ...[
                      _buildExposureSection(context, colorScheme, isDark),
                      const SizedBox(height: 20),
                      _buildCreatorSection(context, colorScheme, isDark),
                      const SizedBox(height: 20),
                    ],
                    _buildTimestampSection(context, colorScheme, isDark),
                    const SizedBox(height: 20),
                    _buildGpsSection(context, colorScheme, isDark),
                    const SizedBox(height: 28),
                    _buildSaveButton(colorScheme),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModeToggle(
      BuildContext context, ColorScheme cs, bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark2 : AppColors.surfaceLight2,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.borderLight,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: _ModeTab(
              label: 'Basic',
              icon: Icons.tune_rounded,
              isSelected: _mode == _FormMode.basic,
              onTap: () => setState(() => _mode = _FormMode.basic),
            ),
          ),
          Expanded(
            child: _ModeTab(
              label: 'Advanced',
              icon: Icons.settings_applications_rounded,
              isSelected: _mode == _FormMode.advanced,
              onTap: () => setState(() => _mode = _FormMode.advanced),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 300.ms);
  }

  Widget _buildProfileNameField(BuildContext context, ColorScheme cs) {
    return _SectionCard(
      title: 'Nama Profil',
      icon: Icons.badge_outlined,
      child: TextFormField(
        controller: _nameCtrl,
        style: GoogleFonts.poppins(),
        decoration: _inputDeco('Contoh: TikTok Japan Vibes', cs),
        validator: (v) =>
            v == null || v.trim().isEmpty ? 'Nama profil wajib diisi' : null,
      ),
    );
  }

  Widget _buildCameraSection(
      BuildContext context, ColorScheme cs, bool isDark) {
    return _SectionCard(
      title: 'Identitas Kamera',
      icon: Icons.camera_alt_outlined,
      child: Column(
        children: [
          _field('Merek Kamera (Make)', 'Apple, Canon, Sony, NIKON CORPORATION…', _makeCtrl, cs),
          const SizedBox(height: 12),
          _field('Model Kamera', 'iPhone 15 Pro, EOS R6 Mark II…', _modelCtrl, cs),
          if (_mode == _FormMode.advanced) ...[
            const SizedBox(height: 12),
            _field('Model Lensa', 'RF 50mm F1.8 STM…', _lensCtrl, cs),
          ],
          const SizedBox(height: 12),
          _field('Software / Firmware', 'Adobe Photoshop 26.0 (Windows)…', _softwareCtrl, cs),
        ],
      ),
    );
  }

  Widget _buildExposureSection(
      BuildContext context, ColorScheme cs, bool isDark) {
    return _SectionCard(
      title: 'Data Exposure',
      icon: Icons.exposure_outlined,
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _field('ISO', '100, 200, 400…', _isoCtrl, cs,
                    type: TextInputType.number),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _field('F-Number', '1.8, 2.8…', _apertureCtrl, cs,
                    type: const TextInputType.numberWithOptions(decimal: true)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _field('Shutter 1/x detik', '120, 500, 1000…', _shutterCtrl,
                    cs, type: TextInputType.number),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _field('Focal Length (mm)', '6.7, 24, 50…', _focalCtrl, cs,
                    type: const TextInputType.numberWithOptions(decimal: true)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildDropdown(
            label: 'White Balance',
            value: _whiteBalance,
            items: const {0: 'Auto', 1: 'Manual'},
            onChanged: (v) => setState(() => _whiteBalance = v!),
            cs: cs,
          ),
          const SizedBox(height: 12),
          _buildDropdown(
            label: 'Flash',
            value: _flashMode,
            items: const {0: 'No Flash', 1: 'Flash Fired', 16: 'Flash Not Fired'},
            onChanged: (v) => setState(() => _flashMode = v!),
            cs: cs,
          ),
        ],
      ),
    );
  }

  Widget _buildCreatorSection(
      BuildContext context, ColorScheme cs, bool isDark) {
    return _SectionCard(
      title: 'Info Kreator',
      icon: Icons.person_outline_rounded,
      child: Column(
        children: [
          _field('Artist / Fotografer', 'John Doe', _artistCtrl, cs),
          const SizedBox(height: 12),
          _field('Copyright', '© 2025 John Doe', _copyrightCtrl, cs),
        ],
      ),
    );
  }

  Widget _buildTimestampSection(
      BuildContext context, ColorScheme cs, bool isDark) {
    return _SectionCard(
      title: 'Timestamp',
      icon: Icons.schedule_outlined,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Mode Tanggal',
            style: GoogleFonts.poppins(
              fontSize: 13,
              color: cs.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          ...[
            (TimestampMode.current, 'Gunakan waktu sekarang',
                'DateTimeOriginal = waktu proses'),
            (TimestampMode.fixed,
                'Mundur tepat X hari',
                'DateTimeOriginal = hari ini - X hari'),
            (TimestampMode.random,
                'Acak dalam rentang X hari',
                'Random dalam 1–X hari ke belakang'),
          ].map((t) => _TimestampOption(
                mode: t.$1,
                label: t.$2,
                subtitle: t.$3,
                selected: _timestampMode,
                onTap: () => setState(() => _timestampMode = t.$1),
              )),
          if (_timestampMode != TimestampMode.current) ...[
            const SizedBox(height: 12),
            _field(
              _timestampMode == TimestampMode.fixed
                  ? 'Mundur berapa hari?'
                  : 'Batas maksimum hari',
              '7',
              _offsetDaysCtrl,
              cs,
              type: TextInputType.number,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildGpsSection(BuildContext context, ColorScheme cs, bool isDark) {
    // GPS presets populer
    const presets = [
      ('Tokyo, Japan', 35.6762, 139.6503, 40.0),
      ('Bali, Indonesia', -8.4095, 115.1889, 200.0),
      ('Paris, France', 48.8566, 2.3522, 35.0),
      ('New York, USA', 40.7128, -74.0060, 10.0),
      ('Seoul, Korea', 37.5665, 126.9780, 50.0),
      ('Dubai, UAE', 25.2048, 55.2708, 5.0),
    ];

    return _SectionCard(
      title: 'GPS Spoofing',
      icon: Icons.location_on_outlined,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Sisipkan koordinat GPS palsu',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: cs.onSurface,
                      ),
                    ),
                    Text(
                      'Gambar akan terlihat diambil di lokasi tersebut',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Switch(
                value: _enableGps,
                onChanged: (v) => setState(() => _enableGps = v),
              ),
            ],
          ),
          if (_enableGps) ...[
            const SizedBox(height: 14),
            Text(
              'Preset Lokasi',
              style: GoogleFonts.poppins(
                fontSize: 13,
                color: cs.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: presets.map((preset) {
                final isSelected = _gpsLocationCtrl.text == preset.$1;
                return FilterChip(
                  label: Text(
                    preset.$1,
                    style: GoogleFonts.poppins(fontSize: 12),
                  ),
                  selected: isSelected,
                  onSelected: (_) =>
                      _setGpsPreset(preset.$1, preset.$2, preset.$3, preset.$4),
                  selectedColor: cs.primary.withValues(alpha: 0.15),
                  checkmarkColor: cs.primary,
                );
              }).toList(),
            ),
            const SizedBox(height: 14),
            _field('Label Lokasi', 'Tokyo, Japan', _gpsLocationCtrl, cs),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _field('Latitude', '35.6762', _gpsLatCtrl, cs,
                      type: const TextInputType.numberWithOptions(
                          signed: true, decimal: true)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _field('Longitude', '139.6503', _gpsLonCtrl, cs,
                      type: const TextInputType.numberWithOptions(
                          signed: true, decimal: true)),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _field('Altitude (meter)', '40', _gpsAltCtrl, cs,
                type: const TextInputType.numberWithOptions(decimal: true)),
          ],
        ],
      ),
    );
  }

  Widget _buildSaveButton(ColorScheme cs) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: _save,
        icon: const Icon(Icons.save_rounded),
        label: Text(_isEdit ? 'Perbarui Profil' : 'Simpan Profil'),
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
          textStyle:
              GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w600),
        ),
      ),
    ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.1, end: 0);
  }

  // ── Helpers ─────────────────────────────────────────────────────────────────

  Widget _field(
    String label,
    String hint,
    TextEditingController ctrl,
    ColorScheme cs, {
    TextInputType type = TextInputType.text,
  }) {
    return TextFormField(
      controller: ctrl,
      keyboardType: type,
      style: GoogleFonts.poppins(fontSize: 14),
      decoration: _inputDeco(hint, cs).copyWith(labelText: label),
    );
  }

  Widget _buildDropdown({
    required String label,
    required int value,
    required Map<int, String> items,
    required void Function(int?) onChanged,
    required ColorScheme cs,
  }) {
    return DropdownButtonFormField<int>(
      initialValue: value,
      decoration: _inputDeco('', cs).copyWith(labelText: label),
      style: GoogleFonts.poppins(fontSize: 14, color: cs.onSurface),
      items: items.entries
          .map((e) => DropdownMenuItem(
                value: e.key,
                child: Text(e.value, style: GoogleFonts.poppins(fontSize: 14)),
              ))
          .toList(),
      onChanged: onChanged,
    );
  }

  InputDecoration _inputDeco(String hint, ColorScheme cs) {
    return InputDecoration(
      hintText: hint,
      hintStyle: GoogleFonts.poppins(
          fontSize: 13, color: cs.onSurface.withValues(alpha: 0.4)),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: cs.outline.withValues(alpha: 0.5)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: cs.primary, width: 2),
      ),
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
    );
  }
}

// ── Sub-widgets ────────────────────────────────────────────────────────────────

class _SectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget child;

  const _SectionCard({
    required this.title,
    required this.icon,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cs = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : AppColors.cardLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.borderLight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: cs.primary, size: 18),
              const SizedBox(width: 8),
              Text(
                title,
                style: GoogleFonts.poppins(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: cs.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    ).animate().fadeIn(duration: 350.ms).slideY(begin: 0.05, end: 0);
  }
}

class _ModeTab extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _ModeTab({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.all(4),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? cs.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 16,
              color: isSelected ? Colors.white : cs.onSurfaceVariant,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: isSelected ? Colors.white : cs.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TimestampOption extends StatelessWidget {
  final TimestampMode mode;
  final String label;
  final String subtitle;
  final TimestampMode selected;
  final VoidCallback onTap;

  const _TimestampOption({
    required this.mode,
    required this.label,
    required this.subtitle,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isSelected = selected == mode;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? cs.primary : cs.outline,
                  width: isSelected ? 6 : 2,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      fontWeight:
                          isSelected ? FontWeight.w600 : FontWeight.w400,
                      color:
                          isSelected ? cs.primary : cs.onSurface,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      color: cs.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
