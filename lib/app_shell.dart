import 'package:flutter/material.dart';
import 'core/database/database.dart';
import 'features/workspace/workspace_shell.dart';

class WisteriaAppShell extends StatelessWidget {
  final WisteriaDatabase database;

  const WisteriaAppShell({super.key, required this.database});

  @override
  Widget build(BuildContext context) {
    return WorkspaceShell(database: database);
  }
}
