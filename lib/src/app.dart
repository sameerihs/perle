import 'package:flutter/material.dart';

import 'config/app_config.dart';
import 'data/wallpaper_repository.dart';
import 'features/wallpapers/wallpaper_shell.dart';

class PerleApp extends StatefulWidget {
  const PerleApp({super.key, this.repository});

  final WallpaperRepository? repository;

  @override
  State<PerleApp> createState() => _PerleAppState();
}

class _PerleAppState extends State<PerleApp> {
  late WallpaperRepository _repository;

  @override
  void initState() {
    super.initState();
    _repository = _createRepository();
  }

  @override
  void didUpdateWidget(PerleApp oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.repository, widget.repository)) {
      _repository = _createRepository();
    }
  }

  WallpaperRepository _createRepository() {
    return widget.repository ??
        PexelsWallpaperRepository(apiKey: AppConfig.pexelsApiKey);
  }

  @override
  Widget build(BuildContext context) {
    const backgroundColor = Color(0xFF0D0D0F);
    const foregroundColor = Color(0xFFFAF7ED);

    final colorScheme = ColorScheme.fromSeed(
      seedColor: foregroundColor,
      brightness: Brightness.dark,
      surface: backgroundColor,
    );

    return MaterialApp(
      title: 'Perle',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorScheme: colorScheme,
        scaffoldBackgroundColor: backgroundColor,
        fontFamily: 'Poppins',
        navigationBarTheme: NavigationBarThemeData(
          backgroundColor: Colors.black,
          indicatorColor: foregroundColor,
          iconTheme: WidgetStateProperty.resolveWith((states) {
            return IconThemeData(
              color: states.contains(WidgetState.selected)
                  ? Colors.black
                  : foregroundColor,
            );
          }),
          labelTextStyle: WidgetStateProperty.resolveWith((states) {
            return TextStyle(
              color: foregroundColor,
              fontWeight: states.contains(WidgetState.selected)
                  ? FontWeight.w600
                  : FontWeight.w400,
            );
          }),
        ),
      ),
      home: WallpaperShell(
        key: ObjectKey(_repository),
        repository: _repository,
      ),
    );
  }
}
