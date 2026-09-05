import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/image_history_entity.dart';
import '../../domain/usecases/history_usecases.dart';
import 'image_provider.dart';

final getHistoryUsecaseProvider = Provider<GetHistoryUsecase>((ref) {
  return GetHistoryUsecase(ref.read(imageRepositoryProvider));
});

final deleteHistoryUsecaseProvider = Provider<DeleteHistoryUsecase>((ref) {
  return DeleteHistoryUsecase(ref.read(imageRepositoryProvider));
});

final clearAllHistoryUsecaseProvider = Provider<ClearAllHistoryUsecase>((ref) {
  return ClearAllHistoryUsecase(ref.read(imageRepositoryProvider));
});

class HistoryNotifier
    extends StateNotifier<AsyncValue<List<ImageHistoryEntity>>> {
  final GetHistoryUsecase _getHistory;
  final DeleteHistoryUsecase _deleteHistory;
  final ClearAllHistoryUsecase _clearAll;

  HistoryNotifier(
    this._getHistory,
    this._deleteHistory,
    this._clearAll,
  ) : super(const AsyncValue.loading()) {
    loadHistory();
  }

  Future<void> loadHistory() async {
    state = const AsyncValue.loading();
    try {
      final history = await _getHistory();
      state = AsyncValue.data(history);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> deleteItem(int id) async {
    try {
      await _deleteHistory(id);
      final current = state.valueOrNull ?? [];
      state = AsyncValue.data(
        current.where((item) => item.id != id).toList(),
      );
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> clearAll() async {
    try {
      await _clearAll();
      state = const AsyncValue.data([]);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

final historyProvider =
    StateNotifierProvider<HistoryNotifier, AsyncValue<List<ImageHistoryEntity>>>(
  (ref) {
    return HistoryNotifier(
      ref.read(getHistoryUsecaseProvider),
      ref.read(deleteHistoryUsecaseProvider),
      ref.read(clearAllHistoryUsecaseProvider),
    );
  },
);
