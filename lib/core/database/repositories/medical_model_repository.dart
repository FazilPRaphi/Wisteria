import 'package:drift/drift.dart';

import '../database.dart';

class MedicalModelRepository {
  final WisteriaDatabase database;

  MedicalModelRepository(this.database);

  Future<List<MedicalModel>> getAllModels() {
    return (database.select(
      database.medicalModels,
    )..orderBy([(model) => OrderingTerm.asc(model.name)])).get();
  }

  Future<void> createModel({
    required String id,
    required String name,
    String? description,
    required String task,
    required String modality,
    required String runtime,
  }) async {
    await database
        .into(database.medicalModels)
        .insert(
          MedicalModelsCompanion.insert(
            id: id,
            name: name,
            description: Value(description),
            task: task,
            modality: modality,
            runtime: runtime,
          ),
        );
  }

  Future<List<ModelVersion>> getVersionsForModel(String modelId) {
    return (database.select(
      database.modelVersions,
    )..where((version) => version.modelId.equals(modelId))).get();
  }
  
  Future<MedicalModel?> getModelById(String id) {
    return (database.select(database.medicalModels)
          ..where((model) => model.id.equals(id)))
        .getSingleOrNull();
  }

  Future<ModelVersion?> getVersionById(String id) {
    return (database.select(database.modelVersions)
          ..where((version) => version.id.equals(id)))
        .getSingleOrNull();
  }

  Future<ModelVersion?> getInstalledVersion(String modelId) {
    return (database.select(database.modelVersions)
          ..where(
            (version) =>
                version.modelId.equals(modelId) &
                version.installationStatus.equals('INSTALLED'),
          ))
        .getSingleOrNull();
  }

  Future<void> registerVersion({
    required String id,
    required String modelId,
    required String version,
    required String filePath,
    required String checksum,
    String? compatibility,
    required String installationStatus,
  }) async {
    await database
        .into(database.modelVersions)
        .insert(
          ModelVersionsCompanion.insert(
            id: id,
            modelId: modelId,
            version: version,
            filePath: filePath,
            checksum: checksum,
            compatibility: Value(compatibility),
            installationStatus: installationStatus,
          ),
        );
  }
}
