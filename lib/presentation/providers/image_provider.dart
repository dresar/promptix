import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/datasources/image_processing_datasource.dart';
import '../../data/datasources/local/database_helper.dart';
import '../../data/repositories/image_repository_impl.dart';
import '../../domain/entities/image_info_entity.dart';
import '../../domain/entities/optimization_result_entity.dart';
import '../../domain/usecases/get_image_info_usecase.dart';
import '../../domain/usecases/optimize_image_usecase.dart';
import '../../domain/usecases/history_usecases.dart';

final imageProcessingDatasourceProvider =
    Provider<ImageProcessingDatasource>((ref) {
  return ImageProcessingDatasource();
});

final imageRepositoryProvider = Provider<ImageRepositoryImpl>((ref) {
  return ImageRepositoryImpl(
    processingDatasource: ref.read(imageProcessingDatasourceProvider),
    databaseHelper: DatabaseHelper.instance,
  );
});

final getImageInfoUsecaseProvider = Provider<GetImageInfoUsecase>((ref) {
  return GetImageInfoUsecase(ref.read(imageRepositoryProvider));
});

final optimizeImageUsecaseProvider = Provider<OptimizeImageUsecase>((ref) {
  return OptimizeImageUsecase(ref.read(imageRepositoryProvider));
});

final saveHistoryUsecaseProvider = Provider<SaveHistoryUsecase>((ref) {
  return SaveHistoryUsecase(ref.read(imageRepositoryProvider));
});

final selectedImageProvider = StateProvider<ImageInfoEntity?>((ref) => null);

final optimizationResultProvider =
    StateProvider<OptimizationResultEntity?>((ref) => null);

final optimizationProgressProvider = StateProvider<double>((ref) => 0.0);

final isOptimizingProvider = StateProvider<bool>((ref) => false);

class ImageNotifier extends StateNotifier<AsyncValue<ImageInfoEntity?>> {
  final GetImageInfoUsecase _getImageInfoUsecase;

  ImageNotifier(this._getImageInfoUsecase) : super(const AsyncValue.data(null));

  Future<ImageInfoEntity?> loadImageInfo(String filePath) async {
    state = const AsyncValue.loading();
    try {
      final info = await _getImageInfoUsecase(filePath);
      state = AsyncValue.data(info);
      return info;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return null;
    }
  }

  void reset() {
    state = const AsyncValue.data(null);
  }
}

final imageNotifierProvider =
    StateNotifierProvider<ImageNotifier, AsyncValue<ImageInfoEntity?>>((ref) {
  return ImageNotifier(ref.read(getImageInfoUsecaseProvider));
});
