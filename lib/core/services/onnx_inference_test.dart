import 'dart:io';

import 'onnx_inference_service.dart';

Future<void> testPneumoniaModel(String imagePath) async {
  final service = OnnxInferenceService.instance;

  try {
    print('Loading pneumonia model...');

    await service.initialize();

    print('Model loaded successfully!');
    print('Input image: $imagePath');

    final result = await service.analyzeImage(File(imagePath));

    print('Prediction: ${result.prediction}');
    print('Confidence: ${(result.confidence * 100).toStringAsFixed(2)}%');
    print(
      'NORMAL probability: '
      '${(result.normalProbability * 100).toStringAsFixed(2)}%',
    );
    print(
      'PNEUMONIA probability: '
      '${(result.pneumoniaProbability * 100).toStringAsFixed(2)}%',
    );
    print('Execution time: ${result.executedAt}');
  } catch (error, stackTrace) {
    print('Inference test failed: $error');
    print(stackTrace);
  } finally {
    await service.dispose();
  }
}
