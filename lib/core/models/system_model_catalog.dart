class CatalogModel {
  final String id;
  final String displayName;
  final String description;
  final String task;
  final String modality;
  final String architecture;
  final String runtime;
  final String inputRequirements;
  final List<String> outputClasses;
  final String assetPath;
  final String version;
  final String compatibility;
  final bool isSupported;

  const CatalogModel({
    required this.id,
    required this.displayName,
    required this.description,
    required this.task,
    required this.modality,
    required this.architecture,
    required this.runtime,
    required this.inputRequirements,
    required this.outputClasses,
    required this.assetPath,
    required this.version,
    required this.compatibility,
    this.isSupported = true,
  });
}

class SystemModelCatalog {
  SystemModelCatalog._();

  static const CatalogModel pneumoniaResNet18 = CatalogModel(
    id: 'wisteria-pneumonia-resnet18',
    displayName: 'Pneumonia ResNet18',
    description:
        'Binary classification of chest X-ray images for pneumonia detection. Locally bundled ONNX model.',
    task: 'Pneumonia Classification',
    modality: 'X-Ray',
    architecture: 'ResNet-18',
    runtime: 'ONNX Runtime',
    inputRequirements: '224x224 RGB / Grayscale Image Tensor (NCHW)',
    outputClasses: ['NORMAL', 'PNEUMONIA'],
    assetPath: 'assets/models/pneumonia_resnet18.onnx',
    version: '1.0.0',
    compatibility: 'Wisteria 1.0',
    isSupported: true,
  );

  /// Predefined catalog of authoritative medical AI models supported by Wisteria.
  static List<CatalogModel> get allModels => [
        pneumoniaResNet18,
      ];

  static CatalogModel? getById(String id) {
    for (final model in allModels) {
      if (model.id == id) return model;
    }
    return null;
  }
}
