import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../../core/services/onnx_inference_service.dart';

class ModelInferenceTestPage extends StatefulWidget {
  const ModelInferenceTestPage({super.key});

  @override
  State<ModelInferenceTestPage> createState() => _ModelInferenceTestPageState();
}

class _ModelInferenceTestPageState extends State<ModelInferenceTestPage> {
  File? _selectedImage;
  PneumoniaInferenceResult? _result;

  bool _loadingModel = false;
  bool _runningInference = false;
  String? _error;

  Future<void> _pickImage() async {
    final picked = await FilePicker.pickFile(type: FileType.image);

    if (!mounted || picked == null) {
      return;
    }

    final imagePath = picked.path;
    if (imagePath == null) return;

    setState(() {
      _selectedImage = File(imagePath);
      _result = null;
      _error = null;
    });
  }

  Future<void> _runInference() async {
    final image = _selectedImage;
    if (image == null) return;

    setState(() {
      _runningInference = true;
      _loadingModel = true;
      _error = null;
      _result = null;
    });

    try {
      final service = OnnxInferenceService.instance;

      await service.initialize();

      if (!mounted) return;

      setState(() => _loadingModel = false);

      final result = await service.analyzeImage(image);

      if (!mounted) return;

      setState(() => _result = result);
    } catch (e) {
      if (!mounted) return;

      setState(() => _error = e.toString());
    } finally {
      if (mounted) {
        setState(() {
          _loadingModel = false;
          _runningInference = false;
        });
      }
    }
  }

  @override
  void dispose() {
    // Keep the shared inference session alive while the app runs.
    // The service can be disposed centrally when the app shuts down.
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('ONNX Model Test')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 760),
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              const Text(
                'Pneumonia ResNet18',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text('Test the locally bundled ONNX model with one image.'),
              const SizedBox(height: 24),
              OutlinedButton.icon(
                onPressed: _runningInference ? null : _pickImage,
                icon: const Icon(Icons.image_outlined),
                label: const Text('Choose X-ray image'),
              ),
              if (_selectedImage != null) ...[
                const SizedBox(height: 16),
                Text(
                  _selectedImage!.path,
                  style: const TextStyle(fontSize: 12),
                ),
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.file(
                    _selectedImage!,
                    height: 280,
                    fit: BoxFit.contain,
                    errorBuilder: (_, _, _) =>
                        const Text('Image preview unavailable.'),
                  ),
                ),
              ],
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: _selectedImage == null || _runningInference
                    ? null
                    : _runInference,
                icon: const Icon(Icons.play_arrow_rounded),
                label: Text(
                  _loadingModel
                      ? 'Loading model...'
                      : _runningInference
                      ? 'Running inference...'
                      : 'Run inference',
                ),
              ),
              if (_runningInference) ...[
                const SizedBox(height: 16),
                const LinearProgressIndicator(),
              ],
              if (_error != null) ...[
                const SizedBox(height: 20),
                SelectableText(
                  'Inference failed:\n$_error',
                  style: const TextStyle(color: Colors.red),
                ),
              ],
              if (_result != null) ...[
                const SizedBox(height: 24),
                const Divider(),
                const Text(
                  'Model output',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                _resultRow('Predicted class', _result!.prediction),
                _resultRow(
                  'Model confidence',
                  '${(_result!.confidence * 100).toStringAsFixed(2)}%',
                ),
                _resultRow(
                  'NORMAL probability',
                  '${(_result!.normalProbability * 100).toStringAsFixed(2)}%',
                ),
                _resultRow(
                  'PNEUMONIA probability',
                  '${(_result!.pneumoniaProbability * 100).toStringAsFixed(2)}%',
                ),
                _resultRow(
                  'Executed at',
                  _result!.executedAt.toLocal().toString(),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Development test only. This output is not a '
                  'validated diagnosis and must not be used to '
                  'make clinical decisions.',
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _resultRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(child: SelectableText(value)),
        ],
      ),
    );
  }
}
