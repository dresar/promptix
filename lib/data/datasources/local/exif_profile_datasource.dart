import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../domain/entities/exif_profile_entity.dart';

/// Menyimpan dan membaca custom EXIF profiles dari SharedPreferences
class ExifProfileDatasource {
  static const String _key = 'custom_exif_profiles';

  const ExifProfileDatasource();

  /// Ambil semua custom profiles (bukan built-in)
  Future<List<ExifProfileEntity>> getCustomProfiles() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = prefs.getStringList(_key) ?? [];
    return jsonList.map((s) {
      try {
        return ExifProfileEntity.fromJson(
          jsonDecode(s) as Map<String, dynamic>,
        );
      } catch (_) {
        return null;
      }
    }).whereType<ExifProfileEntity>().toList();
  }

  /// Simpan satu custom profile (insert atau update by id)
  Future<void> saveProfile(ExifProfileEntity profile) async {
    final prefs = await SharedPreferences.getInstance();
    final profiles = await getCustomProfiles();

    final idx = profiles.indexWhere((p) => p.id == profile.id);
    if (idx >= 0) {
      profiles[idx] = profile;
    } else {
      profiles.add(profile);
    }

    await prefs.setStringList(
      _key,
      profiles.map((p) => jsonEncode(p.toJson())).toList(),
    );
  }

  /// Hapus custom profile by id
  Future<void> deleteProfile(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final profiles = await getCustomProfiles();
    profiles.removeWhere((p) => p.id == id);
    await prefs.setStringList(
      _key,
      profiles.map((p) => jsonEncode(p.toJson())).toList(),
    );
  }

  /// Import profile dari JSON string (untuk fitur import file)
  Future<ExifProfileEntity> importProfileFromJson(String jsonStr) async {
    final profile = ExifProfileEntity.importJson(jsonStr);
    // Pastikan tidak override built-in
    final imported = profile.copyWith(isBuiltIn: false);
    await saveProfile(imported);
    return imported;
  }

  /// Export semua custom profiles ke satu JSON string
  Future<String> exportAllProfiles() async {
    final profiles = await getCustomProfiles();
    return jsonEncode(profiles.map((p) => p.toJson()).toList());
  }
}
