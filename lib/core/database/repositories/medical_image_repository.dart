import 'package:drift/drift.dart';

import '../database.dart';

class MedicalImageRepository {
  final WisteriaDatabase database;

  MedicalImageRepository(this.database);

  Future<List<MedicalImage>> getImagesForExamination(
    String examinationId,
  ) {
    return (database.select(database.medicalImages)
          ..where(
            (image) => image.examinationId.equals(examinationId),
          )
          ..orderBy([
            (image) => OrderingTerm.asc(image.clinicalDate),
          ]))
        .get();
  }

  Future<MedicalImage?> getImageById(String imageId) {
    return (database.select(database.medicalImages)
          ..where((image) => image.id.equals(imageId)))
        .getSingleOrNull();
  }

  Future<void> createMedicalImage({
    required String id,
    required String examinationId,
    required String filePath,
    required String originalFileName,
    required String fileFormat,
    required String modality,
    required DateTime clinicalDate,
  }) async {
    await database.into(database.medicalImages).insert(
      MedicalImagesCompanion.insert(
        id: id,
        examinationId: examinationId,
        filePath: filePath,
        originalFileName: originalFileName,
        fileFormat: fileFormat,
        modality: modality,
        clinicalDate: clinicalDate,
      ),
    );
  }

  Future<bool> deleteMedicalImage(String imageId) async {
    final deletedRows =
        await (database.delete(database.medicalImages)
              ..where((image) => image.id.equals(imageId)))
            .go();

    return deletedRows > 0;
  }
}