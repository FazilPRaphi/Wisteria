import 'dart:convert';
import 'dart:math' as math;

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wisteria/core/database/database.dart';
import 'package:wisteria/core/database/repositories/medical_model_repository.dart';
import 'package:wisteria/core/database/repositories/model_run_repository.dart';
import 'package:wisteria/core/models/system_model_catalog.dart';
import 'package:wisteria/core/services/model_registry_service.dart';
import 'package:wisteria/core/services/onnx_inference_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Diabetic Retinopathy ResNet18 Catalog & Metadata Tests', () {
    test('DR model is properly registered in SystemModelCatalog', () {
      final model = SystemModelCatalog.diabeticRetinopathyResNet18;

      expect(model.id, equals('wisteria-diabetic-retinopathy-resnet18'));
      expect(model.displayName, equals('Diabetic Retinopathy — ResNet18'));
      expect(model.task, equals('DR Classification'));
      expect(model.modality, equals('Retinal Fundus'));
      expect(model.architecture, equals('ResNet-18'));
      expect(model.runtime, equals('ONNX Runtime'));
      expect(model.assetPath, equals('assets/models/dr_resnet18.onnx'));
      expect(model.version, equals('1.0.0'));
      expect(model.isSupported, isTrue);

      // Verify exact 5 output classes in training order (alphabetical)
      expect(model.outputClasses, equals(['Mild', 'Moderate', 'No_DR', 'Proliferate_DR', 'Severe']));

      // Verify presence in allModels and getById
      expect(SystemModelCatalog.allModels.map((m) => m.id), contains(model.id));
      expect(SystemModelCatalog.getById(model.id), isNotNull);
      expect(SystemModelCatalog.getById(model.id)!.id, equals(model.id));
    });

    test('MedicalModelRepository constants match catalog', () {
      expect(MedicalModelRepository.diabeticRetinopathyModelId,
          equals(SystemModelCatalog.diabeticRetinopathyResNet18.id));
      expect(MedicalModelRepository.diabeticRetinopathyVersionId,
          equals('wisteria-diabetic-retinopathy-resnet18-v1'));
    });
  });

  group('Diabetic Retinopathy Database Registry & Persistence Tests', () {
    late WisteriaDatabase db;
    late MedicalModelRepository modelRepo;
    late ModelRunRepository runRepo;

    setUp(() {
      db = WisteriaDatabase(NativeDatabase.memory());
      modelRepo = MedicalModelRepository(db);
      runRepo = ModelRunRepository(db);
    });

    tearDown(() async {
      await db.close();
    });

    test('ModelRegistryService synchronizes DR model and version into DB', () async {
      final registryService = ModelRegistryService(db);
      await registryService.synchronizeCatalog();

      // Verify medical model row
      final drModel = await modelRepo.getModelById(MedicalModelRepository.diabeticRetinopathyModelId);
      expect(drModel, isNotNull);
      expect(drModel!.name, equals('Diabetic Retinopathy — ResNet18'));
      expect(drModel.task, equals('DR Classification'));
      expect(drModel.modality, equals('Retinal Fundus'));
      expect(drModel.runtime, equals('ONNX Runtime'));

      // Verify model version row
      final versions = await modelRepo.getVersionsForModel(MedicalModelRepository.diabeticRetinopathyModelId);
      expect(versions, isNotEmpty);
      final version = versions.first;
      expect(version.version, equals('1.0.0'));
      expect(version.filePath, equals('assets/models/dr_resnet18.onnx'));
    });

    test('ModelRunRepository saves and retrieves DR run results and findings', () async {
      // First ensure model records exist
      final registryService = ModelRegistryService(db);
      await registryService.synchronizeCatalog();

      // Create a test patient and examination
      await db.into(db.patients).insert(
        PatientsCompanion.insert(
          id: 'test-patient-dr',
          name: 'Jane Fundus',
        ),
      );

      await db.into(db.examinations).insert(
        ExaminationsCompanion.insert(
          id: 'test-exam-dr',
          patientId: 'test-patient-dr',
          examinationType: 'Retinal Fundus',
          examinationDate: DateTime.now(),
          previousDataRange: '6 Months',
          status: 'COMPLETED',
        ),
      );

      await db.into(db.medicalImages).insert(
        MedicalImagesCompanion.insert(
          id: 'test-image-dr',
          examinationId: 'test-exam-dr',
          filePath: 'path/to/fundus.png',
          originalFileName: 'fundus.png',
          fileFormat: 'png',
          modality: 'Retinal Fundus',
          clinicalDate: DateTime.now(),
        ),
      );

      final scores = {
        'Mild': 0.05,
        'Moderate': 0.15,
        'No_DR': 0.72,
        'Proliferate_DR': 0.03,
        'Severe': 0.05,
      };

      await runRepo.saveSuccessfulDiabeticRetinopathyRun(
        runId: 'run-dr-01',
        resultId: 'result-dr-01',
        findingId: 'finding-dr-01',
        examinationId: 'test-exam-dr',
        modelId: MedicalModelRepository.diabeticRetinopathyModelId,
        modelVersionId: MedicalModelRepository.diabeticRetinopathyVersionId,
        inputImageId: 'test-image-dr',
        inputImageDate: DateTime.now(),
        executionTimestamp: DateTime.now(),
        prediction: 'No_DR',
        confidence: 0.72,
        scores: scores,
      );

      // Verify model run retrieved
      final runs = await runRepo.getRunsForExamination('test-exam-dr');
      expect(runs.length, equals(1));
      expect(runs.first.modelId, equals(MedicalModelRepository.diabeticRetinopathyModelId));

      // Verify model run result
      final result = await runRepo.getResultForRun('run-dr-01');
      expect(result, isNotNull);
      expect(result!.status, equals('SUCCESS'));
      expect(result.confidence, equals('0.72'));

      final parsedRaw = jsonDecode(result.rawModelOutput!) as Map<String, dynamic>;
      expect(parsedRaw['modelType'], equals('diabetic_retinopathy'));
      expect(parsedRaw['prediction'], equals('No_DR'));
      expect(parsedRaw['No_DR'], equals(0.72));
      expect(parsedRaw['Mild'], equals(0.05));
      expect(parsedRaw['Moderate'], equals(0.15));

      // Verify findings
      final findings = await runRepo.getFindingsForResult('result-dr-01');
      expect(findings.length, equals(1));
      expect(findings.first.label, equals('classification'));
      expect(findings.first.value, equals('No_DR'));
      expect(findings.first.confidence, equals('0.72'));
    });
  });

  group('Diabetic Retinopathy Preprocessing & Output Contract Verification', () {
    test('ImageNet mean and std match verified training parameters', () {
      expect(DiabeticRetinopathyInferenceService.mean, equals([0.485, 0.456, 0.406]));
      expect(DiabeticRetinopathyInferenceService.std, equals([0.229, 0.224, 0.225]));
      expect(DiabeticRetinopathyInferenceService.inputSize, equals(224));
    });

    test('Class labels and order match training notebook exactly', () {
      const expected = ['Mild', 'Moderate', 'No_DR', 'Proliferate_DR', 'Severe'];
      expect(DiabeticRetinopathyInferenceService.classLabels, equals(expected));

      expect(DiabeticRetinopathyInferenceService.classDisplayNames,
          equals(['Mild', 'Moderate', 'No DR', 'Proliferative DR', 'Severe']));
    });

    test('DiabeticRetinopathyInferenceResult formats scores map correctly', () {
      final now = DateTime.now();
      final result = DiabeticRetinopathyInferenceResult(
        prediction: 'Moderate',
        confidence: 0.80,
        mildScore: 0.05,
        moderateScore: 0.80,
        noDrScore: 0.05,
        proliferateDrScore: 0.05,
        severeScore: 0.05,
        executedAt: now,
      );

      expect(result.prediction, equals('Moderate'));
      expect(result.confidence, equals(0.80));
      expect(result.scores['Mild'], equals(0.05));
      expect(result.scores['Moderate'], equals(0.80));
      expect(result.scores['No_DR'], equals(0.05));
      expect(result.scores['Proliferate_DR'], equals(0.05));
      expect(result.scores['Severe'], equals(0.05));
    });

    test('Softmax normalization preserves relative ranking and sums to 1.0', () {
      // Sample logits: [Mild, Moderate, No_DR, Proliferate_DR, Severe]
      final logits = [-1.5, 3.2, 0.1, -0.8, -2.0];
      final maxLogit = logits.reduce(math.max);
      final exponentials = logits.map((v) => math.exp(v - maxLogit)).toList();
      final sum = exponentials.reduce((a, b) => a + b);
      final probs = exponentials.map((v) => v / sum).toList();

      // Check sum to ~1.0
      final totalProb = probs.reduce((a, b) => a + b);
      expect((totalProb - 1.0).abs(), lessThan(1e-6));

      // Largest logit is index 1 (Moderate, 3.2)
      var maxIdx = 0;
      var maxP = probs[0];
      for (var i = 1; i < probs.length; i++) {
        if (probs[i] > maxP) {
          maxP = probs[i];
          maxIdx = i;
        }
      }
      expect(maxIdx, equals(1));
      expect(DiabeticRetinopathyInferenceService.classLabels[maxIdx], equals('Moderate'));
    });
  });
}
