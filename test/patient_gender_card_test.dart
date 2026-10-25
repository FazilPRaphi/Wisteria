import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:drift/native.dart';
import 'package:wisteria/core/database/database.dart';
import 'package:wisteria/core/database/repositories/patient_repository.dart';
import 'package:wisteria/core/theme/wisteria_theme.dart';
import 'package:wisteria/features/patients/patient_details_page.dart';
import 'package:wisteria/features/patients/patient_page.dart';
import 'package:wisteria/features/patients/widgets/patient_age_avatar.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Patient Gender Icons & Modern Card Verification', () {
    late WisteriaDatabase db;
    late PatientRepository repo;

    setUp(() async {
      db = WisteriaDatabase(NativeDatabase.memory());
      repo = PatientRepository(db);

      // Create male patient
      await repo.createPatient(
        id: 'patient-male-01',
        name: 'Arthur Pendelton',
        phoneNumber: '+1-555-010-0001',
        age: 42,
        bloodGroup: 'A+',
        gender: 'Male',
      );

      // Create female patient
      await repo.createPatient(
        id: 'patient-female-01',
        name: 'Beatrice Webb',
        phoneNumber: '+1-555-010-0002',
        age: 35,
        bloodGroup: 'B-',
        gender: 'Female',
      );

      // Create neutral / unspecified gender patient
      await repo.createPatient(
        id: 'patient-neutral-01',
        name: 'Rowan Riley',
        phoneNumber: '+1-555-010-0003',
        age: 28,
        bloodGroup: 'O+',
        gender: null,
      );

      // Create other / custom gender patient
      await repo.createPatient(
        id: 'patient-other-01',
        name: 'Morgan Reese',
        phoneNumber: '+1-555-010-0004',
        age: 56,
        bloodGroup: 'AB+',
        gender: 'Other',
      );
    });

    tearDown(() async {
      await db.close();
    });

    test('getPatientGenderIcon correctly resolves icons and fallbacks', () {
      expect(getPatientGenderIcon('Male'), equals(Icons.male));
      expect(getPatientGenderIcon('male'), equals(Icons.male));
      expect(getPatientGenderIcon('M'), equals(Icons.male));
      expect(getPatientGenderIcon('m'), equals(Icons.male));

      expect(getPatientGenderIcon('Female'), equals(Icons.female));
      expect(getPatientGenderIcon('female'), equals(Icons.female));
      expect(getPatientGenderIcon('F'), equals(Icons.female));
      expect(getPatientGenderIcon('f'), equals(Icons.female));

      expect(getPatientGenderIcon(null), equals(Icons.person));
      expect(getPatientGenderIcon(''), equals(Icons.person));
      expect(getPatientGenderIcon('Other'), equals(Icons.person));
      expect(getPatientGenderIcon('Non-binary'), equals(Icons.person));
      expect(getPatientGenderIcon('Unknown'), equals(Icons.person));
    });

    testWidgets('Registered Patients cards display modern oversized gender icons in Light mode', (tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        MaterialApp(
          theme: buildWisteriaTheme(brightness: Brightness.light),
          home: PatientPage(database: db),
        ),
      );
      await tester.pumpAndSettle();

      // Verify all 4 patients render
      expect(find.text('Arthur Pendelton'), findsOneWidget);
      expect(find.text('Beatrice Webb'), findsOneWidget);
      expect(find.text('Rowan Riley'), findsOneWidget);
      expect(find.text('Morgan Reese'), findsOneWidget);

      // Verify patient IDs
      expect(find.text('patient-male-01'), findsOneWidget);
      expect(find.text('patient-female-01'), findsOneWidget);

      // Verify age badges
      expect(find.text('42 yrs'), findsOneWidget);
      expect(find.text('35 yrs'), findsOneWidget);

      // Verify male and female icons are present in cards
      expect(find.byIcon(Icons.male), findsOneWidget);
      expect(find.byIcon(Icons.female), findsOneWidget);
      // Rowan Riley (null) and Morgan Reese (Other) both use Icons.person fallback
      expect(find.byIcon(Icons.person), findsNWidgets(2));

      // Verify navigation affordance chevron
      expect(find.byIcon(Icons.chevron_right_rounded), findsNWidgets(4));

      // Verify Transform.rotate is applied for the fashionable tilt
      final transforms = tester.widgetList<Transform>(find.byType(Transform));
      final rotatedTransforms = transforms.where((t) {
        final transform = t.transform;
        // Check for non-zero rotation (e.g. angle around -14 deg)
        return transform.storage[1] != 0.0 || transform.storage[4] != 0.0;
      }).toList();
      expect(rotatedTransforms.isNotEmpty, isTrue);

      // Verify Light mode contrast:
      // Silhouette icon color has dark contrast on light muted surface
      final maleIcon = tester.widget<Icon>(find.byIcon(Icons.male));
      expect(maleIcon.size, greaterThan(150.0)); // Oversized
      final maleIconColor = maleIcon.color!;
      expect(maleIconColor.toARGB32() & 0x00FFFFFF, equals(const Color(0xFF1E293B).toARGB32() & 0x00FFFFFF));
    });

    testWidgets('Registered Patients cards adapt automatically to Dark mode', (tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        MaterialApp(
          theme: buildWisteriaTheme(brightness: Brightness.dark),
          home: PatientPage(database: db),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Arthur Pendelton'), findsOneWidget);
      expect(find.text('Beatrice Webb'), findsOneWidget);

      // Verify icons in Dark mode
      expect(find.byIcon(Icons.male), findsOneWidget);
      expect(find.byIcon(Icons.female), findsOneWidget);

      // In Dark mode, silhouette icon color is light for sufficient contrast
      final femaleIcon = tester.widget<Icon>(find.byIcon(Icons.female));
      expect(femaleIcon.size, greaterThan(150.0)); // Oversized
      final femaleIconColor = femaleIcon.color!;
      // Checks that dark mode silhouette uses white with alpha
      expect(femaleIconColor.toARGB32() & 0x00FFFFFF, equals(Colors.white.toARGB32() & 0x00FFFFFF));
    });

    testWidgets('Theme switching automatically updates card silhouette colors without restart', (tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      Brightness brightness = Brightness.light;

      await tester.pumpWidget(
        StatefulBuilder(
          builder: (context, setState) {
            return MaterialApp(
              theme: buildWisteriaTheme(brightness: brightness),
              home: Scaffold(
                body: PatientPage(database: db),
                floatingActionButton: FloatingActionButton(
                  onPressed: () {
                    setState(() {
                      brightness = Brightness.dark;
                    });
                  },
                  child: const Icon(Icons.palette),
                ),
              ),
            );
          },
        ),
      );
      await tester.pumpAndSettle();

      // Initially Light mode -> dark silhouette
      var icon = tester.widget<Icon>(find.byIcon(Icons.male));
      expect(icon.color!.toARGB32() & 0x00FFFFFF, equals(const Color(0xFF1E293B).toARGB32() & 0x00FFFFFF));

      // Switch to Dark mode
      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();

      // Now Dark mode -> light silhouette
      icon = tester.widget<Icon>(find.byIcon(Icons.male));
      expect(icon.color!.toARGB32() & 0x00FFFFFF, equals(Colors.white.toARGB32() & 0x00FFFFFF));
    });

    testWidgets('Responsive resizing adjusts silhouette icon scale without overflow', (tester) async {
      tester.view.physicalSize = const Size(600, 700); // Narrower viewport
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        MaterialApp(
          theme: buildWisteriaTheme(brightness: Brightness.light),
          home: PatientPage(database: db),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.byIcon(Icons.male), findsOneWidget);

      // Resize to large desktop
      tester.view.physicalSize = const Size(1920, 1080);
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.byIcon(Icons.male), findsOneWidget);
    });

    testWidgets('Search and blood-group filtering remain fully functional', (tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        MaterialApp(
          theme: buildWisteriaTheme(brightness: Brightness.light),
          home: PatientPage(database: db),
        ),
      );
      await tester.pumpAndSettle();

      // Search by name
      await tester.enterText(find.byType(TextField), 'Arthur');
      await tester.pumpAndSettle();

      expect(find.text('Arthur Pendelton'), findsOneWidget);
      expect(find.text('Beatrice Webb'), findsNothing);

      // Clear search
      await tester.enterText(find.byType(TextField), '');
      await tester.pumpAndSettle();

      expect(find.text('Arthur Pendelton'), findsOneWidget);
      expect(find.text('Beatrice Webb'), findsOneWidget);

      // Filter by blood group
      await tester.tap(find.byType(DropdownButton<String>));
      await tester.pumpAndSettle();

      await tester.tap(find.text('B-').last);
      await tester.pumpAndSettle();

      expect(find.text('Beatrice Webb'), findsOneWidget);
      expect(find.text('Arthur Pendelton'), findsNothing);
    });

    testWidgets('Card navigation interaction opens PatientDetailsPage', (tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        MaterialApp(
          theme: buildWisteriaTheme(brightness: Brightness.light),
          home: PatientPage(database: db),
        ),
      );
      await tester.pumpAndSettle();

      // Tap on Beatrice Webb card
      await tester.tap(find.text('Beatrice Webb'));
      await tester.pumpAndSettle();

      // Verify PatientDetailsPage is opened
      expect(find.byType(PatientDetailsPage), findsOneWidget);
      expect(find.text('Patient Record Overview'), findsOneWidget);
    });
  });
}
