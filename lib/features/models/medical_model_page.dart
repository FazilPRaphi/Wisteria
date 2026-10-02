import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import '../../core/database/database.dart';
import '../../core/database/repositories/medical_model_repository.dart';
import '../../core/theme/wisteria_theme.dart';

class MedicalModelPage extends StatefulWidget {
  final WisteriaDatabase database;

  const MedicalModelPage({super.key, required this.database});

  @override
  State<MedicalModelPage> createState() => _MedicalModelPageState();
}

class _MedicalModelPageState extends State<MedicalModelPage> {
  late final MedicalModelRepository _repository;
  late Future<List<MedicalModel>> _modelsFuture;

  @override
  void initState() {
    super.initState();
    _repository = MedicalModelRepository(widget.database);
    _loadModels();
  }

  void _loadModels() {
    _modelsFuture = _repository.getAllModels();
  }

  Future<void> _refresh() async {
    setState(_loadModels);
    await _modelsFuture;
  }

  Future<void> _addModel() async {
    final name = TextEditingController();
    final description = TextEditingController();
    final task = TextEditingController();
    final modality = TextEditingController(text: 'X-Ray');
    final runtime = TextEditingController(text: 'ONNX Runtime');

    final formKey = GlobalKey<FormState>();

    final values = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Register Medical Model'),
        content: SizedBox(
          width: 440,
          child: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _field(name, 'Model name'),
                  _field(description, 'Description', required: false),
                  _field(task, 'Medical task'),
                  _field(modality, 'Supported modality'),
                  _field(runtime, 'Runtime'),
                ],
              ),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                Navigator.pop(dialogContext, true);
              }
            },
            child: const Text('Register'),
          ),
        ],
      ),
    );

    if (values != true || !mounted) {
      name.dispose();
      description.dispose();
      task.dispose();
      modality.dispose();
      runtime.dispose();
      return;
    }

    try {
      await _repository.createModel(
        id: const Uuid().v4(),
        name: name.text.trim(),
        description: description.text.trim().isEmpty
            ? null
            : description.text.trim(),
        task: task.text.trim(),
        modality: modality.text.trim(),
        runtime: runtime.text.trim(),
      );

      if (!mounted) return;
      await _refresh();
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Model registered successfully.')),
      );
    } catch (error) {
      if (!mounted) return;
      _showError('Could not register model: $error');
    } finally {
      name.dispose();
      description.dispose();
      task.dispose();
      modality.dispose();
      runtime.dispose();
    }
  }

  Future<void> _addVersion(MedicalModel model) async {
    final version = TextEditingController();
    final compatibility = TextEditingController();

    final formKey = GlobalKey<FormState>();

    final values = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('Add version — ${model.name}'),
        content: SizedBox(
          width: 400,
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _field(version, 'Version (e.g. 1.0.0)'),
                _field(compatibility, 'Compatibility notes', required: false),
                const SizedBox(height: 8),
                const Text(
                  'This registers the version only. '
                  'The model file must be installed and validated separately.',
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                Navigator.pop(dialogContext, true);
              }
            },
            child: const Text('Add version'),
          ),
        ],
      ),
    );

    if (values != true || !mounted) {
      version.dispose();
      compatibility.dispose();
      return;
    }

    try {
      await _repository.registerVersion(
        id: const Uuid().v4(),
        modelId: model.id,
        version: version.text.trim(),
        filePath: '',
        checksum: '',
        compatibility: compatibility.text.trim().isEmpty
            ? null
            : compatibility.text.trim(),
        installationStatus: 'NOT_INSTALLED',
      );

      if (!mounted) return;
      await _refresh();
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Model version registered.')),
      );
    } catch (error) {
      if (!mounted) return;
      _showError('Could not register version: $error');
    } finally {
      version.dispose();
      compatibility.dispose();
    }
  }

  Widget _field(
    TextEditingController controller,
    String label, {
    bool required = true,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
        validator: (value) {
          if (required && (value == null || value.trim().isEmpty)) {
            return 'Please enter $label.';
          }
          return null;
        },
      ),
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: WisteriaColors.background,
      appBar: AppBar(
        title: const Text('Medical Model Management'),
        backgroundColor: WisteriaColors.background,
        actions: [
          IconButton(
            tooltip: 'Refresh models',
            onPressed: _refresh,
            icon: const Icon(Icons.refresh_rounded),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1100),
          child: FutureBuilder<List<MedicalModel>>(
            future: _modelsFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError) {
                return Center(
                  child: Text('Could not load models: ${snapshot.error}'),
                );
              }

              final models = snapshot.data ?? [];

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
                    child: Row(
                      children: [
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Local AI models',
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(height: 6),
                              Text(
                                'Register models and manage their versions.',
                              ),
                            ],
                          ),
                        ),
                        FilledButton.icon(
                          onPressed: _addModel,
                          icon: const Icon(Icons.add),
                          label: const Text('Register model'),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Text('${models.length} registered model(s)'),
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: models.isEmpty
                        ? const Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.memory_rounded, size: 56),
                                SizedBox(height: 12),
                                Text(
                                  'No models registered yet.',
                                  style: TextStyle(fontSize: 18),
                                ),
                                SizedBox(height: 6),
                                Text(
                                  'Register a model to begin managing versions.',
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                            itemCount: models.length,
                            itemBuilder: (context, index) {
                              return _ModelCard(
                                model: models[index],
                                repository: _repository,
                                onAddVersion: () => _addVersion(models[index]),
                              );
                            },
                          ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _ModelCard extends StatelessWidget {
  final MedicalModel model;
  final MedicalModelRepository repository;
  final VoidCallback onAddVersion;

  const _ModelCard({
    required this.model,
    required this.repository,
    required this.onAddVersion,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      child: ExpansionTile(
        leading: const CircleAvatar(child: Icon(Icons.memory_rounded)),
        title: Text(
          model.name,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text('${model.task} • ${model.modality} • ${model.runtime}'),
        childrenPadding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
        children: [
          if (model.description?.isNotEmpty == true)
            Align(
              alignment: Alignment.centerLeft,
              child: Text(model.description!),
            ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Registered versions',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              TextButton.icon(
                onPressed: onAddVersion,
                icon: const Icon(Icons.add),
                label: const Text('Add version'),
              ),
            ],
          ),
          FutureBuilder(
            future: repository.getVersionsForModel(model.id),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const LinearProgressIndicator();
              }

              if (snapshot.hasError) {
                return Text('Could not load versions: ${snapshot.error}');
              }

              final versions = snapshot.data ?? [];

              if (versions.isEmpty) {
                return const Align(
                  alignment: Alignment.centerLeft,
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: Text('No versions registered.'),
                  ),
                );
              }

              return Column(
                children: versions.map((version) {
                  final installed = version.installationStatus == 'INSTALLED';

                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(
                      installed
                          ? Icons.check_circle_outline
                          : Icons.download_for_offline_outlined,
                      color: installed ? Colors.green : Colors.orange,
                    ),
                    title: Text('Version ${version.version}'),
                    subtitle: Text(
                      '${version.installationStatus}'
                      '${version.compatibility == null ? '' : ' • ${version.compatibility}'}',
                    ),
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }
}
