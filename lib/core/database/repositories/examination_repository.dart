import 'package:drift/drift.dart';

import '../database.dart';

class ExaminationRepository {
  final WisteriaDatabase database;

  ExaminationRepository(this.database);

  Future<List<Examination>> getExaminationsForPatient(String patientId) {
    return (database.select(database.examinations)
          ..where((examination) => examination.patientId.equals(patientId))
          ..orderBy([
            (examination) => OrderingTerm.desc(examination.examinationDate),
          ]))
        .get();
  }

  Future<Examination?> getExaminationById(String examinationId) {
    return (database.select(database.examinations)
          ..where((examination) => examination.id.equals(examinationId)))
        .getSingleOrNull();
  }

  Future<void> createExamination({
    required String id,
    required String patientId,
    required String examinationType,
    required DateTime dateTime,
    String? doctorNotes,
    required String previousDataRange,
  }) async {
    await database
        .into(database.examinations)
        .insert(
          ExaminationsCompanion.insert(
            id: id,
            patientId: patientId,
            examinationType: examinationType,
            examinationDate: dateTime,
            doctorNotes: Value(doctorNotes),
            previousDataRange: previousDataRange,
            status: 'DRAFT',
          ),
        );
  }

  Future<bool> updateDoctorNotes({
    required String examinationId,
    required String doctorNotes,
  }) async {
    final updatedRows =
        await (database.update(database.examinations)
              ..where((examination) => examination.id.equals(examinationId)))
            .write(ExaminationsCompanion(doctorNotes: Value(doctorNotes)));

    return updatedRows > 0;
  }

  Future<bool> updateExamination({
    required String examinationId,
    String? doctorNotes,
    String? status,
  }) async {
    final companion = ExaminationsCompanion(
      doctorNotes: doctorNotes != null ? Value(doctorNotes) : const Value.absent(),
      status: status != null ? Value(status) : const Value.absent(),
    );

    final updatedRows =
        await (database.update(database.examinations)
              ..where((examination) => examination.id.equals(examinationId)))
            .write(companion);

    return updatedRows > 0;
  }
}
