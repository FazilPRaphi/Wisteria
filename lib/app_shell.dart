import 'package:flutter/material.dart';

import 'core/database/database.dart';
import 'core/theme/wisteria_theme.dart';
import 'features/dashboard/dashboard_page.dart';
import 'features/doctor/doctor_profile_page.dart';
import 'features/patients/patient_page.dart';
import 'features/shared/placeholder_page.dart';

class WisteriaAppShell extends StatelessWidget {
  final WisteriaDatabase database;

  const WisteriaAppShell({
    super.key,
    required this.database,
  });

  @override
  Widget build(BuildContext context) {
    return DashboardPage(
      onNavigate: (page) => _navigateTo(context, page),
    );
  }

  void _navigateTo(BuildContext context, String page) {
    final Widget targetPage;

    switch (page) {
      case 'profile':
        targetPage = DoctorProfilePage(database: database);
        break;

      case 'patients':
        targetPage = PatientPage(database: database);
        break;

      case 'history':
        targetPage = const PlaceholderPage(
          title: 'Examination History',
          subtitle: 'Review past examinations, scans, and diagnostic sessions.',
          icon: Icons.history_rounded,
        );
        break;

      case 'models':
        targetPage = const PlaceholderPage(
          title: 'Installed Models',
          subtitle: 'Manage your installed AI models and neural engines.',
          icon: Icons.memory_rounded,
        );
        break;

      case 'sync':
        targetPage = const PlaceholderPage(
          title: 'Data Synchronization',
          subtitle:
              'Synchronize clinical data across your workstations.',
          icon: Icons.sync_rounded,
        );
        break;

      case 'ai':
        targetPage = const PlaceholderPage(
          title: 'AI Workspace',
          subtitle: 'Run AI analyses and review diagnostic results.',
          icon: Icons.auto_awesome_rounded,
          accentColor: WisteriaColors.tertiary,
        );
        break;

      case 'analytics':
        targetPage = const PlaceholderPage(
          title: 'Clinical Analytics',
          subtitle:
              'View clinical analytics, throughput metrics, and insights.',
          icon: Icons.analytics_rounded,
        );
        break;

      case 'more_models':
        targetPage = const PlaceholderPage(
          title: 'Model Registry',
          subtitle: 'Browse and download available AI models.',
          icon: Icons.download_rounded,
        );
        break;

      case 'settings':
        targetPage = const PlaceholderPage(
          title: 'System Configuration',
          subtitle:
              'Configure hardware acceleration, PACS connections, and preferences.',
          icon: Icons.settings_rounded,
        );
        break;

      default:
        return;
    }

    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            targetPage,
        transitionsBuilder:
            (context, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutCubic,
            ),
            child: child,
          );
        },
        transitionDuration: const Duration(milliseconds: 220),
        reverseTransitionDuration: const Duration(milliseconds: 180),
      ),
    );
  }
}