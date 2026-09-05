import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/exif_profile_entity.dart';
import '../../domain/usecases/exif_profile_usecases.dart';
import 'image_provider.dart';

// ── Usecase providers ────────────────────────────────────────────────────────

final getCustomExifProfilesUsecaseProvider =
    Provider<GetCustomExifProfilesUsecase>((ref) {
  return GetCustomExifProfilesUsecase(ref.read(imageRepositoryProvider));
});

final saveCustomExifProfileUsecaseProvider =
    Provider<SaveCustomExifProfileUsecase>((ref) {
  return SaveCustomExifProfileUsecase(ref.read(imageRepositoryProvider));
});

final deleteCustomExifProfileUsecaseProvider =
    Provider<DeleteCustomExifProfileUsecase>((ref) {
  return DeleteCustomExifProfileUsecase(ref.read(imageRepositoryProvider));
});

// ── Notifier ─────────────────────────────────────────────────────────────────

class ExifProfileNotifier extends StateNotifier<AsyncValue<List<ExifProfileEntity>>> {
  final GetCustomExifProfilesUsecase _getUsecase;
  final SaveCustomExifProfileUsecase _saveUsecase;
  final DeleteCustomExifProfileUsecase _deleteUsecase;

  ExifProfileNotifier(
    this._getUsecase,
    this._saveUsecase,
    this._deleteUsecase,
  ) : super(const AsyncValue.loading()) {
    loadProfiles();
  }

  /// Semua profil: built-in + custom
  List<ExifProfileEntity> get allProfiles {
    final customList = state.asData?.value ?? [];
    return [...BuiltInProfiles.all, ...customList];
  }

  Future<void> loadProfiles() async {
    state = const AsyncValue.loading();
    try {
      final custom = await _getUsecase();
      state = AsyncValue.data(custom);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> saveProfile(ExifProfileEntity profile) async {
    await _saveUsecase(profile);
    await loadProfiles();
  }

  Future<void> deleteProfile(String id) async {
    await _deleteUsecase(id);
    await loadProfiles();
  }
}

final exifProfileProvider =
    StateNotifierProvider<ExifProfileNotifier, AsyncValue<List<ExifProfileEntity>>>(
  (ref) => ExifProfileNotifier(
    ref.read(getCustomExifProfilesUsecaseProvider),
    ref.read(saveCustomExifProfileUsecaseProvider),
    ref.read(deleteCustomExifProfileUsecaseProvider),
  ),
);

/// Provider untuk mendapatkan SEMUA profil (built-in + custom) sebagai list flat
final allExifProfilesProvider = Provider<List<ExifProfileEntity>>((ref) {
  final notifier = ref.watch(exifProfileProvider.notifier);
  ref.watch(exifProfileProvider); // rebuild saat custom berubah
  return notifier.allProfiles;
});
