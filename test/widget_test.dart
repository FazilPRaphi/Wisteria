import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:drift/native.dart';
import 'package:wisteria/core/database/database.dart';
import 'package:wisteria/core/theme/wisteria_theme.dart';
import 'package:wisteria/features/workspace/main_workspace_panel.dart';
import 'package:wisteria/features/workspace/system_workspace_panel.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('Verify all local image assets can be loaded from rootBundle', () async {
    const assets = [
      'assets/images/new_patients.jpg',
      'assets/images/registered_patients.jpg',
      'assets/images/doctor.png',
      'assets/images/model.jpg',
      'assets/images/data sync.jpg',
      'assets/images/settings.jpg',
    ];

    for (final asset in assets) {
      final byteData = await rootBundle.load(asset);
      expect(byteData.lengthInBytes, greaterThan(0),
          reason: 'Asset $asset failed to load or is empty');
    }
  });

  testWidgets('MainWorkspacePanel renders cards in both Dark and Light mode',
      (tester) async {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    final db = WisteriaDatabase(NativeDatabase.memory());

    // Dark Mode test
    await tester.pumpWidget(
      MaterialApp(
        theme: buildWisteriaTheme(brightness: Brightness.dark),
        home: Scaffold(
          body: MainWorkspacePanel(database: db),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('New Patient'), findsOneWidget);
    expect(find.text('Registered Patients'), findsOneWidget);
    expect(find.byType(Image), findsNWidgets(2));

    // Light Mode test
    await tester.pumpWidget(
      MaterialApp(
        theme: buildWisteriaTheme(brightness: Brightness.light),
        home: Scaffold(
          body: MainWorkspacePanel(database: db),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('New Patient'), findsOneWidget);
    expect(find.text('Registered Patients'), findsOneWidget);
    expect(find.byType(Image), findsNWidgets(2));

    await db.close();
  });

  testWidgets('SystemWorkspacePanel renders cards in both Dark and Light mode',
      (tester) async {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    final db = WisteriaDatabase(NativeDatabase.memory());

    // Dark Mode test
    await tester.pumpWidget(
      MaterialApp(
        theme: buildWisteriaTheme(brightness: Brightness.dark),
        home: Scaffold(
          body: SystemWorkspacePanel(database: db),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Doctor Profile'), findsOneWidget);
    expect(find.text('Settings'), findsOneWidget);
    expect(find.text('Models'), findsOneWidget);
    expect(find.text('Sync'), findsOneWidget);
    expect(find.byType(Image), findsNWidgets(4));

    // Light Mode test
    await tester.pumpWidget(
      MaterialApp(
        theme: buildWisteriaTheme(brightness: Brightness.light),
        home: Scaffold(
          body: SystemWorkspacePanel(database: db),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Doctor Profile'), findsOneWidget);
    expect(find.text('Settings'), findsOneWidget);
    expect(find.text('Models'), findsOneWidget);
    expect(find.text('Sync'), findsOneWidget);
    expect(find.byType(Image), findsNWidgets(4));

    await db.close();
  });

  test('Verify teal color scheme constants and palettes', () {
    expect(WisteriaColors.primary, const Color(0xFF098FA6));
    expect(WisteriaColors.pink, const Color(0xFFC998A2));
    expect(WisteriaColors.burgundy, const Color(0xFF96162C));
    expect(WisteriaColors.mutedRose, const Color(0xFFAF6A6A));
    expect(WisteriaColors.darkPalette.primary, const Color(0xFF098FA6));
    expect(WisteriaColors.lightPalette.primary, const Color(0xFF098FA6));

    expect(WisteriaColors.darkPalette.background, const Color(0xFF111923));
    expect(WisteriaColors.darkPalette.surface, const Color(0xFF1A2632));
    expect(WisteriaColors.darkPalette.textPrimary, const Color(0xFFF1F5F7));
    expect(WisteriaColors.darkPalette.textSecondary, const Color(0xFFA6B5C0));
    expect(WisteriaColors.darkPalette.border, const Color(0xFF2B3B48));

    expect(WisteriaColors.lightPalette.background, const Color(0xFFF0F5F6));
    expect(WisteriaColors.lightPalette.surface, const Color(0xFFF7F4EF));
    expect(WisteriaColors.lightPalette.textPrimary, const Color(0xFF202B35));
    expect(WisteriaColors.lightPalette.textSecondary, const Color(0xFF667783));
    expect(WisteriaColors.lightPalette.border, const Color(0xFFD9E4E8));
  });
}
