import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'data/datasources/local/preferences_datasource.dart';
import 'data/repositories/settings_repository_impl.dart';
import 'domain/usecases/settings_usecases.dart';
import 'presentation/providers/settings_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
  ));

  final prefsDatasource = PreferencesDatasource();
  final settingsRepo = SettingsRepositoryImpl(prefsDatasource);
  final initialSettings = await GetSettingsUsecase(settingsRepo)();

  runApp(
    ProviderScope(
      overrides: [
        settingsNotifierProvider.overrideWith(
          (ref) => SettingsNotifier(
            initialSettings,
            SaveSettingsUsecase(ref.read(settingsRepositoryProvider)),
          ),
        ),
      ],
      child: const PromptixApp(),
    ),
  );
}

class PromptixApp extends ConsumerWidget {
  const PromptixApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsNotifierProvider);
    final router = ref.watch(appRouterProvider);

    return MaterialApp.router(
      title: 'Promptix',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: settings.isDarkMode ? ThemeMode.dark : ThemeMode.light,
      routerConfig: router,
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: const TextScaler.linear(1.0),
          ),
          child: child!,
        );
      },
    );
  }
}
