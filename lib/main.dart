import 'package:flutter/material.dart';

import 'app_shell.dart';
import 'core/database/database.dart';
import 'core/theme/wisteria_theme.dart';

void main() {
  final database = WisteriaDatabase();

  runApp(WisteriaApp(database: database));
}

class WisteriaApp extends StatelessWidget {
  final WisteriaDatabase database;

  const WisteriaApp({super.key, required this.database});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: WisteriaThemeController.themeModeNotifier,
      builder: (context, themeMode, _) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'Wisteria — Clinical AI Workstation',
          theme: buildWisteriaTheme(brightness: Brightness.light),
          darkTheme: buildWisteriaTheme(brightness: Brightness.dark),
          themeMode: themeMode,
          home: WisteriaAppShell(database: database),
        );
      },
    );
  }
}
