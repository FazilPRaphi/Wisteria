import 'package:flutter/material.dart';

import 'app_shell.dart';
import 'core/database/database.dart';
import 'core/services/model_registry_service.dart';
import 'core/theme/wisteria_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await WisteriaThemeController.init();
  final database = WisteriaDatabase();
  await ModelRegistryService(database).synchronizeCatalog();

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
