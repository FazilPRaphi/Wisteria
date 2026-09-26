import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

import 'tables.dart';

part 'database.g.dart';

@DriftDatabase(
  tables: [
    DoctorProfiles,
    Patients,
    PreviousMedicalInformations,
    PreviousMedications,
    PreviousTestResults,
    Examinations,
    MedicalImages,
    MedicalModels,
    ModelVersions,
    ModelRuns,
    ModelRunResults,
    ModelFindings,
    AiAnalyses,
    Evidence,
    DoctorReviews,
    FinalReports,
    SyncItems,
  ],
)
class WisteriaDatabase extends _$WisteriaDatabase {
  WisteriaDatabase([QueryExecutor? executor])
      : super(
         executor ?? driftDatabase(name: 'wisteria_v2'),
        );

  @override
  int get schemaVersion => 1;
}