// lib/main.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'pages/app_shell.dart';
import 'services/download_manager.dart';
import 'services/settings_service.dart';
import 'services/history_service.dart';
import 'viewmodels/home_viewmodel.dart';
import 'services/log_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final settingsService = SettingsService();
  await settingsService.loadSettings();
  
  final historyService = HistoryService();
  await historyService.init(); 

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: settingsService),
        ChangeNotifierProvider.value(value: historyService),
        ChangeNotifierProvider(create: (_) => DownloadManager()),
        ChangeNotifierProvider(create: (_) => HomeViewModel()),
        ChangeNotifierProvider(create: (_) => LogService()),
      ],
      child: const MyApp(),
    ),
  );
}

TextTheme _applyFontSize(TextTheme base, double multiplier) {
  return base.copyWith(
    displayLarge: base.displayLarge?.copyWith(fontSize: (base.displayLarge?.fontSize ?? 57) * multiplier),
    displayMedium: base.displayMedium?.copyWith(fontSize: (base.displayMedium?.fontSize ?? 45) * multiplier),
    displaySmall: base.displaySmall?.copyWith(fontSize: (base.displaySmall?.fontSize ?? 36) * multiplier),
    headlineLarge: base.headlineLarge?.copyWith(fontSize: (base.headlineLarge?.fontSize ?? 32) * multiplier),
    headlineMedium: base.headlineMedium?.copyWith(fontSize: (base.headlineMedium?.fontSize ?? 28) * multiplier),
    headlineSmall: base.headlineSmall?.copyWith(fontSize: (base.headlineSmall?.fontSize ?? 24) * multiplier),
    titleLarge: base.titleLarge?.copyWith(fontSize: (base.titleLarge?.fontSize ?? 22) * multiplier),
    titleMedium: base.titleMedium?.copyWith(fontSize: (base.titleMedium?.fontSize ?? 16) * multiplier),
    titleSmall: base.titleSmall?.copyWith(fontSize: (base.titleSmall?.fontSize ?? 14) * multiplier),
    bodyLarge: base.bodyLarge?.copyWith(fontSize: (base.bodyLarge?.fontSize ?? 16) * multiplier),
    bodyMedium: base.bodyMedium?.copyWith(fontSize: (base.bodyMedium?.fontSize ?? 14) * multiplier),
    bodySmall: base.bodySmall?.copyWith(fontSize: (base.bodySmall?.fontSize ?? 12) * multiplier),
    labelLarge: base.labelLarge?.copyWith(fontSize: (base.labelLarge?.fontSize ?? 14) * multiplier),
    labelMedium: base.labelMedium?.copyWith(fontSize: (base.labelMedium?.fontSize ?? 12) * multiplier),
    labelSmall: base.labelSmall?.copyWith(fontSize: (base.labelSmall?.fontSize ?? 11) * multiplier),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<SettingsService>(
      builder: (context, settings, child) {
        
        // 先创建包含 fontFamily 的基础主题
        final baseLightThemeData = ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: settings.seedColor, 
            brightness: Brightness.light,
          ),
          useMaterial3: true,
          fontFamily: 'NotoSansSC',
        );

        final baseDarkThemeData = ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: settings.seedColor, 
            brightness: Brightness.dark,
          ),
          useMaterial3: true,
          fontFamily: 'NotoSansSC',
        );
        
        final scaledLightTextTheme = _applyFontSize(baseLightThemeData.textTheme, settings.fontSizeMultiplier);
        final scaledDarkTextTheme = _applyFontSize(baseDarkThemeData.textTheme, settings.fontSizeMultiplier);

        return MaterialApp(
          title: 'Leuco',
          debugShowCheckedModeBanner: false,
          
          themeMode: settings.themeMode,

          theme: baseLightThemeData.copyWith(
            textTheme: scaledLightTextTheme,
          ),
          darkTheme: baseDarkThemeData.copyWith(
            textTheme: scaledDarkTextTheme,
          ),
          
          home: const AppShell(), 
        );
      },
    );
  }
}