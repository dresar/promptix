import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../services/watermark_service.dart';

final watermarkServiceProvider = Provider<WatermarkService>((ref) => WatermarkService());

class WatermarkListNotifier extends StateNotifier<AsyncValue<List<File>>> {
  final WatermarkService _service;

  WatermarkListNotifier(this._service) : super(const AsyncValue.loading()) {
    loadWatermarks();
  }

  Future<void> loadWatermarks() async {
    try {
      final list = await _service.getWatermarks();
      state = AsyncValue.data(list);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> addWatermark(String sourcePath) async {
    state = const AsyncValue.loading();
    try {
      final file = File(sourcePath);
      await _service.saveWatermark(file);
      await loadWatermarks();
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> deleteWatermark(File file) async {
    state = const AsyncValue.loading();
    try {
      await _service.deleteWatermark(file);
      await loadWatermarks();
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

final watermarkListProvider =
    StateNotifierProvider<WatermarkListNotifier, AsyncValue<List<File>>>((ref) {
  return WatermarkListNotifier(ref.watch(watermarkServiceProvider));
});
