import 'package:drift/drift.dart';
import 'package:flutter/services.dart' show rootBundle;

import '../database/database.dart';
import '../models/system_model_catalog.dart';

class ModelRegistryService {
  final WisteriaDatabase database;

  ModelRegistryService(this.database);

  /// Synchronizes the local database registry with the authoritative [SystemModelCatalog].
  ///
  /// This method is idempotent:
  /// 1. Safely removes obsolete/unwanted test model entries (such as 'john').
  /// 2. Upserts predefined catalog models in [database.medicalModels].
  /// 3. Checks actual asset file availability to assign correct [installationStatus].
  /// 4. Upserts model versions in [database.modelVersions].
  Future<void> synchronizeCatalog() async {
    // Step 1: Remove unwanted test models (e.g. 'john')
    await _removeObsoleteTestModels();

    // Step 2: Synchronize predefined catalog models
    for (final catalogModel in SystemModelCatalog.allModels) {
      final status = await _checkInstallationStatus(catalogModel);

      // Check if MedicalModel record exists
      final existingModel = await (database.select(
        database.medicalModels,
      )..where((m) => m.id.equals(catalogModel.id))).getSingleOrNull();

      if (existingModel == null) {
        await database
            .into(database.medicalModels)
            .insert(
              MedicalModelsCompanion.insert(
                id: catalogModel.id,
                name: catalogModel.displayName,
                description: Value(catalogModel.description),
                task: catalogModel.task,
                modality: catalogModel.modality,
                runtime: catalogModel.runtime,
              ),
            );
      } else {
        await (database.update(
          database.medicalModels,
        )..where((m) => m.id.equals(catalogModel.id))).write(
          MedicalModelsCompanion(
            name: Value(catalogModel.displayName),
            description: Value(catalogModel.description),
            task: Value(catalogModel.task),
            modality: Value(catalogModel.modality),
            runtime: Value(catalogModel.runtime),
          ),
        );
      }

      // Check if ModelVersion record exists
      final versionId = '${catalogModel.id}-v1';
      final existingVersion =
          await (database.select(database.modelVersions)..where(
                (v) =>
                    v.modelId.equals(catalogModel.id) &
                    v.version.equals(catalogModel.version),
              ))
              .getSingleOrNull();

      if (existingVersion == null) {
        await database
            .into(database.modelVersions)
            .insert(
              ModelVersionsCompanion.insert(
                id: versionId,
                modelId: catalogModel.id,
                version: catalogModel.version,
                filePath: catalogModel.assetPath,
                checksum: 'bundled',
                compatibility: Value(catalogModel.compatibility),
                installationStatus: status,
              ),
            );
      } else {
        await (database.update(
          database.modelVersions,
        )..where((v) => v.id.equals(existingVersion.id))).write(
          ModelVersionsCompanion(
            filePath: Value(catalogModel.assetPath),
            compatibility: Value(catalogModel.compatibility),
            installationStatus: Value(status),
          ),
        );
      }
    }
  }

  Future<String> _checkInstallationStatus(CatalogModel catalogModel) async {
    if (!catalogModel.isSupported) {
      return 'UNAVAILABLE';
    }

    try {
      final byteData = await rootBundle.load(catalogModel.assetPath);
      if (byteData.lengthInBytes > 0) {
        return 'INSTALLED';
      } else {
        return 'NOT_INSTALLED';
      }
    } catch (_) {
      return 'NOT_INSTALLED';
    }
  }

  Future<void> _removeObsoleteTestModels() async {
    // Delete any test models named or IDed as 'john' (case-insensitive)
    final allModels = await database.select(database.medicalModels).get();

    for (final model in allModels) {
      final idLower = model.id.toLowerCase();
      final nameLower = model.name.toLowerCase();

      if (idLower == 'john' || nameLower == 'john') {
        // Delete child versions first if present
        await (database.delete(
          database.modelVersions,
        )..where((v) => v.modelId.equals(model.id))).go();

        // Delete model entry
        await (database.delete(
          database.medicalModels,
        )..where((m) => m.id.equals(model.id))).go();
      }
    }
  }
}
