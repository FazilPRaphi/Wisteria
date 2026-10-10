import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:drift/native.dart';
import 'package:wisteria/core/database/database.dart';
import 'package:wisteria/core/database/repositories/medical_model_repository.dart';
import 'package:wisteria/core/services/model_registry_service.dart';
import 'package:wisteria/core/theme/wisteria_theme.dart';
import 'package:wisteria/features/doctor/doctor_profile_page.dart';
import 'package:wisteria/features/models/medical_model_page.dart';
import 'package:wisteria/features/workspace/main_workspace_panel.dart';
import 'package:wisteria/features/workspace/system_workspace_panel.dart';
import 'package:wisteria/features/patients/new_patient_registration_page.dart';
import 'package:wisteria/features/patients/patient_page.dart';
import 'package:wisteria/features/patients/widgets/patient_age_avatar.dart';

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
      expect(
        byteData.lengthInBytes,
        greaterThan(0),
        reason: 'Asset $asset failed to load or is empty',
      );
    }
  });

  test('Verify patient age category mapping', () {
    expect(getPatientAgeCategory(null), PatientAgeCategory.adult);
    expect(getPatientAgeCategory(5), PatientAgeCategory.child);
    expect(getPatientAgeCategory(12), PatientAgeCategory.child);
    expect(getPatientAgeCategory(13), PatientAgeCategory.teenager);
    expect(getPatientAgeCategory(19), PatientAgeCategory.teenager);
    expect(getPatientAgeCategory(20), PatientAgeCategory.adult);
    expect(getPatientAgeCategory(59), PatientAgeCategory.adult);
    expect(getPatientAgeCategory(60), PatientAgeCategory.senior);
    expect(getPatientAgeCategory(85), PatientAgeCategory.senior);
  });

  testWidgets('MainWorkspacePanel renders cards in both Dark and Light mode', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    final db = WisteriaDatabase(NativeDatabase.memory());

    // Dark Mode test
    await tester.pumpWidget(
      MaterialApp(
        theme: buildWisteriaTheme(brightness: Brightness.dark),
        home: Scaffold(body: MainWorkspacePanel(database: db)),
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
        home: Scaffold(body: MainWorkspacePanel(database: db)),
      ),
    );
    await tester.pump();

    expect(find.text('New Patient'), findsOneWidget);
    expect(find.text('Registered Patients'), findsOneWidget);
    expect(find.byType(Image), findsNWidgets(2));

    await db.close();
  });

  testWidgets(
    'NewPatientRegistrationPage renders standalone registration screen with mandatory indicators',
    (tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final db = WisteriaDatabase(NativeDatabase.memory());

      await tester.pumpWidget(
        MaterialApp(
          theme: buildWisteriaTheme(brightness: Brightness.dark),
          home: NewPatientRegistrationPage(database: db),
        ),
      );
      await tester.pump();

      expect(find.text('New Patient Registration'), findsOneWidget);
      expect(find.text('Patient Name'), findsOneWidget);
      expect(find.text('Phone Number'), findsOneWidget);
      expect(find.text('Age'), findsOneWidget);
      expect(find.text('Blood Group'), findsOneWidget);
      expect(find.text('Other Contact'), findsOneWidget);
      expect(find.text('Contact Address'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);
      expect(find.text('Register Patient'), findsOneWidget);

      // Verify 6 red asterisk indicators exist
      expect(find.text('*'), findsNWidgets(6));

      await db.close();
    },
  );

  testWidgets(
    'NewPatientRegistrationPage validates mandatory empty fields on submit',
    (tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final db = WisteriaDatabase(NativeDatabase.memory());

      await tester.pumpWidget(
        MaterialApp(
          theme: buildWisteriaTheme(brightness: Brightness.light),
          home: NewPatientRegistrationPage(database: db),
        ),
      );
      await tester.pump();

      // Tap Register Patient without entering anything
      await tester.tap(find.text('Register Patient'));
      await tester.pumpAndSettle();

      // Verify error messages appear for all 6 fields
      expect(find.text('Patient name is required.'), findsOneWidget);
      expect(find.text('Phone number is required.'), findsOneWidget);
      expect(find.text('Age is required.'), findsOneWidget);
      expect(find.text('Please select a blood group.'), findsOneWidget);
      expect(find.text('Other contact is required.'), findsOneWidget);
      expect(find.text('Contact address is required.'), findsOneWidget);

      await db.close();
    },
  );

  testWidgets(
    'NewPatientRegistrationPage validates invalid formats for phone, age, contact',
    (tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final db = WisteriaDatabase(NativeDatabase.memory());

      await tester.pumpWidget(
        MaterialApp(
          theme: buildWisteriaTheme(brightness: Brightness.light),
          home: NewPatientRegistrationPage(database: db),
        ),
      );
      await tester.pump();

      // Fill in invalid values
      await tester.enterText(find.byKey(const Key('name_field')), 'John Doe');
      await tester.enterText(
        find.byKey(const Key('phone_field')),
        'abc',
      ); // Invalid phone
      await tester.enterText(
        find.byKey(const Key('age_field')),
        '200',
      ); // Invalid age out of range
      await tester.enterText(
        find.byKey(const Key('other_contact_field')),
        'invalid-contact',
      ); // Invalid contact format
      await tester.enterText(
        find.byKey(const Key('address_field')),
        '123 Main St',
      );

      await tester.tap(find.text('Register Patient'));
      await tester.pumpAndSettle();

      expect(find.text('Enter a valid phone number.'), findsOneWidget);
      expect(find.text('Enter a valid age between 0 and 150.'), findsOneWidget);
      expect(find.text('Please select a blood group.'), findsOneWidget);
      expect(
        find.text('Enter a valid email or emergency contact.'),
        findsOneWidget,
      );

      await db.close();
    },
  );

  testWidgets(
    'NewPatientRegistrationPage registers successfully with complete valid data',
    (tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final db = WisteriaDatabase(NativeDatabase.memory());

      await tester.pumpWidget(
        MaterialApp(
          theme: buildWisteriaTheme(brightness: Brightness.dark),
          home: NewPatientRegistrationPage(database: db),
        ),
      );
      await tester.pump();

      // Fill in valid values for all 6 fields
      await tester.enterText(
        find.byKey(const Key('name_field')),
        '   Sarah Connor   ',
      );
      await tester.enterText(
        find.byKey(const Key('phone_field')),
        '+1-555-019-2834',
      );
      await tester.enterText(find.byKey(const Key('age_field')), '29');

      // Select Blood Group
      await tester.tap(find.byKey(const Key('blood_group_field')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('O+').last);
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byKey(const Key('other_contact_field')),
        'sarah@example.com',
      );
      await tester.enterText(
        find.byKey(const Key('address_field')),
        '742 Evergreen Terrace',
      );

      await tester.tap(find.text('Register Patient'));
      await tester.pumpAndSettle();

      // Check DB insertion
      final patients = await db.select(db.patients).get();
      expect(patients.length, equals(1));
      expect(patients.first.name, equals('Sarah Connor'));
      expect(patients.first.phoneNumber, equals('+1-555-019-2834'));
      expect(patients.first.age, equals(29));
      expect(patients.first.bloodGroup, equals('O+'));
      expect(patients.first.otherContact, equals('sarah@example.com'));
      expect(patients.first.address, equals('742 Evergreen Terrace'));

      await db.close();
    },
  );

  testWidgets('PatientPage renders directory without New Patient button', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    final db = WisteriaDatabase(NativeDatabase.memory());

    await tester.pumpWidget(
      MaterialApp(
        theme: buildWisteriaTheme(brightness: Brightness.light),
        home: PatientPage(database: db),
      ),
    );
    await tester.pump();
    await tester.pumpAndSettle();

    expect(find.text('Registered Patients'), findsOneWidget);
    expect(find.text('Search by name, ID, or phone number...'), findsOneWidget);
    expect(find.text('Blood Group'), findsOneWidget);
    expect(find.widgetWithText(FilledButton, 'New Patient'), findsNothing);
    expect(find.widgetWithText(FilledButton, 'Add Patient'), findsNothing);

    await db.close();
  });

  testWidgets(
    'DoctorProfilePage renders 2-column layout and compact document panel',
    (tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final db = WisteriaDatabase(NativeDatabase.memory());

      await tester.pumpWidget(
        MaterialApp(
          theme: buildWisteriaTheme(brightness: Brightness.dark),
          home: DoctorProfilePage(database: db),
        ),
      );
      await tester.pump();
      await tester.pumpAndSettle();

      expect(find.text('Doctor Profile'), findsWidgets);
      expect(find.text('DOCTOR INFORMATION'), findsOneWidget);
      expect(find.text('CLINIC & PROFESSIONAL DETAILS'), findsOneWidget);
      expect(find.text('DOCTOR DOCUMENT'), findsOneWidget);
      expect(find.text('Edit Profile'), findsOneWidget);
      expect(find.text('No Doctor Document Uploaded'), findsOneWidget);

      await db.close();
    },
  );

  test('Verify theme mode controller persistence switching', () {
    WisteriaThemeController.setThemeMode(ThemeMode.light);
    expect(WisteriaThemeController.currentThemeMode, ThemeMode.light);
    expect(WisteriaThemeController.isDark, isFalse);

    WisteriaThemeController.setThemeMode(ThemeMode.dark);
    expect(WisteriaThemeController.currentThemeMode, ThemeMode.dark);
    expect(WisteriaThemeController.isDark, isTrue);
  });

  testWidgets(
    'SystemWorkspacePanel renders cards in both Dark and Light mode',
    (tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final db = WisteriaDatabase(NativeDatabase.memory());

      // Dark Mode test
      await tester.pumpWidget(
        MaterialApp(
          theme: buildWisteriaTheme(brightness: Brightness.dark),
          home: Scaffold(body: SystemWorkspacePanel(database: db)),
        ),
      );
      await tester.pump();

      expect(find.text('Doctor Profile'), findsOneWidget);
      expect(find.text('Settings'), findsOneWidget);
      expect(find.text('Models'), findsOneWidget);
      expect(find.text('Sync'), findsOneWidget);
      expect(find.byType(Image), findsNWidgets(4));

      await db.close();
    },
  );

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
  });

  test(
    'ModelRegistryService auto-registers catalog models and safely purges john entry idempotently',
    () async {
      final db = WisteriaDatabase(NativeDatabase.memory());
      final repo = MedicalModelRepository(db);

      // Manually insert an unwanted 'john' test model record to simulate obsolete data
      await repo.createModel(
        id: 'john',
        name: 'john',
        description: 'Obsolete test model',
        task: 'Testing',
        modality: 'X-Ray',
        runtime: 'ONNX',
      );

      var models = await repo.getAllModels();
      expect(models.any((m) => m.name.toLowerCase() == 'john'), isTrue);

      // Perform catalog synchronization
      final service = ModelRegistryService(db);
      await service.synchronizeCatalog();

      models = await repo.getAllModels();
      expect(models.any((m) => m.name.toLowerCase() == 'john'), isFalse);
      expect(models.any((m) => m.name == 'Pneumonia ResNet18'), isTrue);

      // Repeat sync to verify idempotency (no duplicates created)
      await service.synchronizeCatalog();
      models = await repo.getAllModels();
      expect(
        models.where((m) => m.id == 'wisteria-pneumonia-resnet18').length,
        equals(1),
      );

      await db.close();
    },
  );

  testWidgets(
    'MedicalModelPage renders auto-registered models without Register model button',
    (tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final db = WisteriaDatabase(NativeDatabase.memory());
      final service = ModelRegistryService(db);
      await service.synchronizeCatalog();

      await tester.pumpWidget(
        MaterialApp(
          theme: buildWisteriaTheme(brightness: Brightness.dark),
          home: MedicalModelPage(database: db),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Medical Model Management'), findsWidgets);
      expect(
        find.text(
          'Manage available medical AI models and their installed versions.',
        ),
        findsOneWidget,
      );
      expect(find.text('1 recognized model'), findsOneWidget);
      expect(find.text('Pneumonia ResNet18'), findsOneWidget);
      expect(find.widgetWithText(FilledButton, 'Register model'), findsNothing);

      await db.close();
    },
  );
}
