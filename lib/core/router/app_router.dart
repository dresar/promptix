import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../presentation/screens/splash/splash_screen.dart';
import '../../presentation/screens/pick_image/pick_image_screen.dart';
import '../../presentation/screens/image_info/image_info_screen.dart';
import '../../presentation/screens/optimize/optimize_screen.dart';
import '../../presentation/screens/optimize/optimize_progress_screen.dart';
import '../../presentation/screens/result/result_screen.dart';
import '../../presentation/screens/history/history_detail_screen.dart';
import '../../presentation/screens/about/about_screen.dart';
import '../../domain/entities/image_info_entity.dart';
import '../../domain/entities/optimization_result_entity.dart';
import '../../domain/entities/image_history_entity.dart';
import '../../domain/entities/exif_profile_entity.dart';
import '../../presentation/screens/main/main_layout_screen.dart';
import '../../presentation/screens/exif_profile/exif_profile_screen.dart';
import '../../presentation/screens/editor/video_edit_screen.dart';
import '../../presentation/screens/batch/batch_edit_screen.dart';
import '../../presentation/screens/studio/media_studio_screen.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/splash',
    debugLogDiagnostics: false,
    routes: [
      GoRoute(
        path: '/splash',
        name: 'splash',
        pageBuilder: (context, state) => _fadeTransition(
          state,
          const SplashScreen(),
        ),
      ),
      GoRoute(
        path: '/home',
        name: 'home',
        pageBuilder: (context, state) => _slideTransition(
          state,
          const MainLayoutScreen(),
        ),
      ),
      GoRoute(
        path: '/pick',
        name: 'pick',
        pageBuilder: (context, state) => _slideTransition(
          state,
          const PickImageScreen(),
        ),
      ),
      GoRoute(
        path: '/image-info',
        name: 'image-info',
        pageBuilder: (context, state) {
          final imageInfo = state.extra as ImageInfoEntity;
          return _slideTransition(
            state,
            ImageInfoScreen(imageInfo: imageInfo),
          );
        },
      ),
      GoRoute(
        path: '/optimize',
        name: 'optimize',
        pageBuilder: (context, state) {
          final imageInfo = state.extra as ImageInfoEntity;
          return _slideTransition(
            state,
            OptimizeScreen(imageInfo: imageInfo),
          );
        },
      ),
      GoRoute(
        path: '/optimize-progress',
        name: 'optimize-progress',
        pageBuilder: (context, state) {
          final extra = state.extra as Map<String, dynamic>;
          return _fadeTransition(
            state,
            OptimizeProgressScreen(
              imageInfo: extra['imageInfo'] as ImageInfoEntity,
              format: extra['format'] as String,
              quality: extra['quality'] as int,
              replaceOld: extra['replaceOld'] as bool,
              outputPrefix: extra['outputPrefix'] as String,
              metadataProfile: extra['metadataProfile'] as String,
              customProfile:
                  extra['customProfile'] as ExifProfileEntity?,
              watermarkEnabled: extra['watermarkEnabled'] as bool? ?? false,
              watermarkLogoPath: extra['watermarkLogoPath'] as String?,
              watermarkPosition: extra['watermarkPosition'] as String? ?? 'bottomRight',
              watermarkScale: extra['watermarkScale'] as double? ?? 0.15,
              watermarkOpacity: extra['watermarkOpacity'] as double? ?? 0.8,
            ),
          );
        },
      ),
      GoRoute(
        path: '/result',
        name: 'result',
        pageBuilder: (context, state) {
          final result = state.extra as OptimizationResultEntity;
          return _slideTransition(
            state,
            ResultScreen(result: result),
          );
        },
      ),
      GoRoute(
        path: '/history',
        name: 'history',
        redirect: (context, state) {
          ref.read(currentTabProvider.notifier).state = 2;
          return '/home';
        },
      ),
      GoRoute(
        path: '/history/:id',
        name: 'history-detail',
        pageBuilder: (context, state) {
          final item = state.extra as ImageHistoryEntity;
          return _slideTransition(
            state,
            HistoryDetailScreen(item: item),
          );
        },
      ),
      GoRoute(
        path: '/settings',
        name: 'settings',
        redirect: (context, state) {
          ref.read(currentTabProvider.notifier).state = 3;
          return '/home';
        },
      ),
      GoRoute(
        path: '/about',
        name: 'about',
        pageBuilder: (context, state) => _slideTransition(
          state,
          const AboutScreen(),
        ),
      ),
      GoRoute(
        path: '/exif-profile',
        name: 'exif-profile',
        pageBuilder: (context, state) {
          final existing = state.extra as ExifProfileEntity?;
          return _slideTransition(
            state,
            ExifProfileScreen(existingProfile: existing),
          );
        },
      ),
      GoRoute(
        path: '/video-edit',
        name: 'video-edit',
        pageBuilder: (context, state) {
          final extra = state.extra as Map<String, dynamic>;
          return _slideTransition(
            state,
            VideoEditScreen(
              inputPath: extra['inputPath'] as String,
              isVideo: extra['isVideo'] as bool? ?? false,
            ),
          );
        },
      ),
      GoRoute(
        path: '/batch-edit',
        name: 'batch-edit',
        pageBuilder: (context, state) => _slideTransition(
          state,
          const BatchEditScreen(),
        ),
      ),
      GoRoute(
        path: '/media-studio',
        name: 'media-studio',
        pageBuilder: (context, state) => _slideTransition(
          state,
          const MediaStudioScreen(),
        ),
      ),
    ],
  );
});

CustomTransitionPage<T> _slideTransition<T>(
  GoRouterState state,
  Widget child,
) {
  return CustomTransitionPage<T>(
    key: state.pageKey,
    child: child,
    transitionDuration: const Duration(milliseconds: 300),
    reverseTransitionDuration: const Duration(milliseconds: 250),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      final curved = CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutCubic,
        reverseCurve: Curves.easeInCubic,
      );
      return SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0.04, 0),
          end: Offset.zero,
        ).animate(curved),
        child: FadeTransition(opacity: curved, child: child),
      );
    },
  );
}

CustomTransitionPage<T> _fadeTransition<T>(
  GoRouterState state,
  Widget child,
) {
  return CustomTransitionPage<T>(
    key: state.pageKey,
    child: child,
    transitionDuration: const Duration(milliseconds: 400),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      return FadeTransition(opacity: animation, child: child);
    },
  );
}
