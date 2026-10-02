import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import '../../core/database/database.dart';
import '../../core/database/repositories/examination_repository.dart';

class CreateExaminationPage extends StatefulWidget {
  final WisteriaDatabase database;
  final String patientId;

  const CreateExaminationPage({
    super.key,
    required this.database,
    required this.patientId,
  });

  @override
  State<CreateExaminationPage> createState() => _CreateExaminationPageState();
}

class _CreateExaminationPageState extends State<CreateExaminationPage> {
  final _formKey = GlobalKey<FormState>();

  final _doctorNotesController = TextEditingController();

  final _uuid = const Uuid();

  String _examinationType = 'General Examination';
  String _previousDataRange = '6 Months';

  bool _saving = false;

  final List<String> _examinationTypes = [
    'General Examination',
    'Chest X-Ray',
    'Blood Test',
    'MRI',
    'CT Scan',
    'Other',
  ];

  final List<String> _contextWindows = [
    '2 Months',
    '4 Months',
    '6 Months',
    '1 Year',
    '2 Years',
    'All Available',
  ];

  Future<void> _createExamination() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _saving = true;
    });

    try {
      final repository = ExaminationRepository(widget.database);

      await repository.createExamination(
        id: _uuid.v4(),
        patientId: widget.patientId,
        examinationType: _examinationType,
        dateTime: DateTime.now(),
        doctorNotes: _doctorNotesController.text.trim().isEmpty
            ? null
            : _doctorNotesController.text.trim(),
        previousDataRange: _previousDataRange,
      );

      if (!mounted) return;

      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to create examination: $e')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _saving = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _doctorNotesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create Examination')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 700),
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Form(
              key: _formKey,
              child: ListView(
                children: [
                  const Text(
                    'New Examination',
                    style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                  ),

                  const SizedBox(height: 8),

                  Text(
                    'Create a clinical examination for this patient.',
                    style: TextStyle(
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withValues(alpha: 0.65),
                    ),
                  ),

                  const SizedBox(height: 32),

                  DropdownButtonFormField<String>(
                    initialValue: _examinationType,
                    decoration: const InputDecoration(
                      labelText: 'Examination Type',
                      border: OutlineInputBorder(),
                    ),
                    items: _examinationTypes
                        .map(
                          (type) =>
                              DropdownMenuItem(value: type, child: Text(type)),
                        )
                        .toList(),
                    onChanged: (value) {
                      if (value == null) return;

                      setState(() {
                        _examinationType = value;
                      });
                    },
                  ),

                  const SizedBox(height: 20),

                  DropdownButtonFormField<String>(
                    initialValue: _previousDataRange,
                    decoration: const InputDecoration(
                      labelText: 'Previous Data Context',
                      border: OutlineInputBorder(),
                    ),
                    items: _contextWindows
                        .map(
                          (range) => DropdownMenuItem(
                            value: range,
                            child: Text(range),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      if (value == null) return;

                      setState(() {
                        _previousDataRange = value;
                      });
                    },
                  ),

                  const SizedBox(height: 20),

                  TextFormField(
                    controller: _doctorNotesController,
                    maxLines: 5,
                    decoration: const InputDecoration(
                      labelText: 'Doctor Notes',
                      hintText: 'Enter any relevant clinical notes...',
                      border: OutlineInputBorder(),
                    ),
                  ),

                  const SizedBox(height: 32),

                  FilledButton.icon(
                    onPressed: _saving ? null : _createExamination,
                    icon: _saving
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.add),
                    label: Text(_saving ? 'Creating...' : 'Create Examination'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
