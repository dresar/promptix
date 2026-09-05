import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../../../core/theme/app_colors.dart';
import '../../../services/permission_service.dart';
import '../../../presentation/providers/image_provider.dart';
import '../../../data/datasources/local/web_image_cache.dart';

class PickImageScreen extends ConsumerStatefulWidget {
  const PickImageScreen({super.key});

  @override
  ConsumerState<PickImageScreen> createState() => _PickImageScreenState();
}

class _PickImageScreenState extends ConsumerState<PickImageScreen> {
  bool _isLoading = false;
  String? _errorMessage;

  Future<void> _pickFromGallery() async {
    final permService = PermissionService();
    final hasPermission = await permService.requestStoragePermission();

    if (!hasPermission) {
      _showPermissionError();
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 100,
      );

      if (picked == null) {
        setState(() => _isLoading = false);
        return;
      }

      if (kIsWeb) {
        final bytes = await picked.readAsBytes();
        final fakePath = 'web_image_${DateTime.now().millisecondsSinceEpoch}_${picked.name}';
        WebImageCache.put(fakePath, bytes);
        await _processFile(fakePath);
      } else {
        await _processFile(picked.path);
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Gagal memilih gambar: ${e.toString()}';
      });
    }
  }

  Future<void> _pickFromFiles() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: false,
      );

      if (result == null || result.files.isEmpty) {
        setState(() => _isLoading = false);
        return;
      }

      if (kIsWeb) {
        final bytes = result.files.first.bytes;
        final name = result.files.first.name;
        if (bytes == null) {
          setState(() {
            _isLoading = false;
            _errorMessage = 'Tidak dapat membaca file';
          });
          return;
        }

        final fakePath = 'web_image_${DateTime.now().millisecondsSinceEpoch}_$name';
        WebImageCache.put(fakePath, bytes);
        await _processFile(fakePath);
      } else {
        final filePath = result.files.first.path;
        if (filePath == null) {
          setState(() {
            _isLoading = false;
            _errorMessage = 'Tidak dapat membaca path file';
          });
          return;
        }

        await _processFile(filePath);
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Gagal memilih file: ${e.toString()}';
      });
    }
  }

  Future<void> _processFile(String filePath) async {
    try {
      final imageNotifier = ref.read(imageNotifierProvider.notifier);
      final info = await imageNotifier.loadImageInfo(filePath);

      if (info != null && mounted) {
        setState(() => _isLoading = false);
        context.goNamed('image-info', extra: info);
      } else {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Gagal membaca informasi gambar';
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Format gambar tidak didukung';
      });
    }
  }

  void _showPermissionError() {
    setState(() {
      _errorMessage =
          'Izin akses media diperlukan. Silakan aktifkan di Pengaturan perangkat.';
    });
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pilih Gambar'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => context.pop(),
        ),
      ),
      body: _isLoading
          ? _buildLoadingState(colorScheme)
          : CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildHeader(context, isDark)
                            .animate()
                            .fadeIn(duration: 400.ms)
                            .slideY(begin: 0.1, end: 0),
                        const SizedBox(height: 28),
                        _buildPickerOptions(context, isDark),
                        if (_errorMessage != null) ...[
                          const SizedBox(height: 20),
                          _buildErrorCard(context, _errorMessage!),
                        ],
                        const SizedBox(height: 28),
                        _buildInfoSection(context, isDark),
                        const SizedBox(height: 32),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildLoadingState(ColorScheme colorScheme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            color: colorScheme.primary,
            strokeWidth: 3,
          ),
          const SizedBox(height: 20),
          Text(
            'Membaca gambar...',
            style: GoogleFonts.poppins(
              fontSize: 15,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Dari mana gambar kamu?',
          style: GoogleFonts.poppins(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Pilih sumber gambar yang ingin kamu optimalkan.',
          style: GoogleFonts.poppins(
            fontSize: 14,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget _buildPickerOptions(BuildContext context, bool isDark) {
    return Column(
      children: [
        _PickerOptionCard(
          icon: Icons.photo_library_outlined,
          title: 'Galeri Foto',
          subtitle: 'Pilih dari koleksi foto dan gambar',
          accentColor: AppColors.primary,
          onTap: _pickFromGallery,
          delay: 100,
        ),
        const SizedBox(height: 14),
        _PickerOptionCard(
          icon: Icons.folder_open_outlined,
          title: 'Manajer File',
          subtitle: 'Jelajahi dan pilih file gambar',
          accentColor: const Color(0xFF7C3AED),
          onTap: _pickFromFiles,
          delay: 200,
        ),
      ],
    );
  }

  Widget _buildErrorCard(BuildContext context, String message) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.errorSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.error_outline_rounded,
            color: AppColors.error,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: GoogleFonts.poppins(
                fontSize: 13,
                color: AppColors.error,
              ),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 300.ms);
  }

  Widget _buildInfoSection(BuildContext context, bool isDark) {
    final infos = [
      ('Mendukung format JPG, PNG, dan WebP', Icons.check_circle_outline_rounded),
      ('Metadata dibaca langsung dari file', Icons.info_outline_rounded),
      ('Seluruh proses dilakukan di perangkat', Icons.smartphone_rounded),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Format yang Didukung',
          style: GoogleFonts.poppins(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 12),
        ...infos.mapIndexed((i, info) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(
              children: [
                Icon(
                  info.$2,
                  size: 18,
                  color: AppColors.success,
                ),
                const SizedBox(width: 10),
                Text(
                  info.$1,
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          )
              .animate()
              .fadeIn(delay: (300 + i * 100).ms, duration: 400.ms)
              .slideX(begin: -0.05, end: 0);
        }),
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

class _PickerOptionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color accentColor;
  final VoidCallback onTap;
  final int delay;

  const _PickerOptionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.accentColor,
    required this.onTap,
    required this.delay,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.cardDark : AppColors.cardLight;
    final border = isDark ? AppColors.borderDark : AppColors.borderLight;

    return Material(
      color: bg,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            border: Border.all(color: border),
            borderRadius: BorderRadius.circular(18),
          ),
          child: Row(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(icon, color: accentColor, size: 30),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.arrow_forward_rounded,
                  color: accentColor,
                  size: 18,
                ),
              ),
            ],
          ),
        ),
      ),
    )
        .animate()
        .fadeIn(delay: delay.ms, duration: 400.ms)
        .slideY(begin: 0.1, end: 0, delay: delay.ms, duration: 400.ms);
  }
}
