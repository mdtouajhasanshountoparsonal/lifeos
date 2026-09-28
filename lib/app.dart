import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:lifeos/services/app_nav.dart';
import 'package:lifeos/theme/app_theme.dart';
import 'package:lifeos/screens/main_screen.dart';

class LifeOSApp extends StatefulWidget {
  const LifeOSApp({super.key});

  @override
  State<LifeOSApp> createState() => _LifeOSAppState();
}

class _LifeOSAppState extends State<LifeOSApp> {
  late final ValueNotifier<int> _themeIndex;

  @override
  void initState() {
    super.initState();
    final saved = Hive.box('settings').get('theme_index', defaultValue: 0);
    _themeIndex = ValueNotifier(saved is int ? saved : 0);
    _themeIndex.addListener(_persistTheme);
  }

  void _persistTheme() {
    if (Hive.isBoxOpen('settings')) {
      Hive.box('settings').put('theme_index', _themeIndex.value);
    }
  }

  @override
  void dispose() {
    _themeIndex.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: _themeIndex,
      builder: (context, index, _) {
        final colors = AppColors.themes[index];
        return MaterialApp(
          title: 'LifeOS',
          debugShowCheckedModeBanner: false,
          navigatorKey: AppNav.key,
          theme: AppTheme.build(colors),
          themeAnimationDuration: const Duration(milliseconds: 700),
          themeAnimationCurve: Curves.easeInOut,
          home: MainScreen(themeIndex: _themeIndex),
        );
      },
    );
  }
}