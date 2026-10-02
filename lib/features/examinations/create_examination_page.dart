import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import '../../core/database/database.dart';
import '../../core/database/repositories/examination_repository.dart';
import '../../core/database/repositories/medical_image_repository.dart';
import '../../core/database/repositories/medical_model_repository.dart';
import '../../core/database/repositories/model_run_repository.dart';
import '../../core/services/onnx_inference_service.dart';
import '../../core/storage/medical_image_storage.dart';
import '../../core/theme/wisteria_theme.dart';
import '../shared/wisteria_back_button.dart';

/// AI-first New Examination workflow.
///
/// Stages:
///   A — Examination Setup (type, image selection)
///   B — Run AI Analysis
///   C — Review AI Results
///   D — Doctor Notes (revealed after successful inference)
///   E — Save Examination
class CreateExaminationPage extends StatefulWidget {
  final WisteriaDatabase database;
  final String patientId;
  final String patientName;

  const CreateExaminationPage({
    super.key,
    required this.database,
    required this.patientId,
    required this.patientName,
  });

  @override
  State<CreateExaminationPage> createState() => _CreateExaminationPageState();
}

class _CreateExaminationPageState extends State<CreateExaminationPage> {
  static const _uuid = Uuid();

  // Repositories
  late final ExaminationRepository _examRepo;
  late final MedicalImageRepository _imageRepo;
  late final MedicalModelRepository _modelRepo;
  late final ModelRunRepository _runRepo;
  late final MedicalImageStorage _imageStorage;

  // ── State ──

  // Stage tracking
  bool _inferenceCompleted = false;
  bool _examinationSaved = false;

  // Examination metadata
  String _examinationType = 'Chest X-Ray';
  String _previousDataRange = '6 Months';

  // Image
  File? _selectedImageFile;
  String? _selectedImageOriginalName;
  String? _savedImageId;
  String? _savedImagePath;

  // Model
  String? _bundledModelId;
  String? _bundledVersionId;
  bool _modelAvailable = false;
  bool _loadingModel = true;
  String? _modelError;

  // Inference
  bool _runningInference = false;
  String? _inferenceError;
  PneumoniaInferenceResult? _inferenceResult;

  // Doctor notes
  final _notesController = TextEditingController();

  // Save
  bool _saving = false;
  String? _saveError;

  // Draft examination created in DB
  String? _draftExaminationId;

  final List<String> _examinationTypes = [
    'Chest X-Ray',
    'General Examination',
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

  @override
  void initState() {
    super.initState();
    _examRepo = ExaminationRepository(widget.database);
    _imageRepo = MedicalImageRepository(widget.database);
    _modelRepo = MedicalModelRepository(widget.database);
    _runRepo = ModelRunRepository(widget.database);
    _imageStorage = MedicalImageStorage();
    _ensureModel();
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  /// Ensure bundled pneumonia model exists in DB.
  Future<void> _ensureModel() async {
    try {
      final ids = await _modelRepo.ensureBundledPneumoniaModel();
      if (!mounted) return;
      setState(() {
        _bundledModelId = ids.modelId;
        _bundledVersionId = ids.versionId;
        _modelAvailable = true;
        _loadingModel = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _modelError = 'Could not load AI model: $e';
        _loadingModel = false;
      });
    }
  }

  /// Pick an image file from disk.
  Future<void> _pickImage() async {
    final picked = await FilePicker.pickFile(
      type: FileType.custom,
      allowedExtensions: ['jpg', 'jpeg', 'png', 'webp', 'bmp'],
    );

    if (picked == null || picked.path == null) return;
    if (!mounted) return;

    final file = File(picked.path!);
    if (!await file.exists()) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selected file does not exist.')),
      );
      return;
    }

    setState(() {
      _selectedImageFile = file;
      _selectedImageOriginalName = picked.name;
      // Reset inference if image changes
      _inferenceResult = null;
      _inferenceCompleted = false;
      _inferenceError = null;
    });
  }

  /// Create draft examination + save image to DB, then run ONNX inference.
  Future<void> _runAIAnalysis() async {
    final imageFile = _selectedImageFile;
    if (imageFile == null) return;
    if (!_modelAvailable || _bundledModelId == null) return;

    setState(() {
      _runningInference = true;
      _inferenceError = null;
      _inferenceResult = null;
    });

    try {
      // Step 1: Create draft examination if not already created.
      if (_draftExaminationId == null) {
        final examId = _uuid.v4();
        await _examRepo.createExamination(
          id: examId,
          patientId: widget.patientId,
          examinationType: _examinationType,
          dateTime: DateTime.now(),
          doctorNotes: null,
          previousDataRange: _previousDataRange,
        );
        _draftExaminationId = examId;
      }

      // Step 2: Save image to local storage + DB if not already saved.
      if (_savedImageId == null) {
        final extension =
            _selectedImageOriginalName?.split('.').last.toLowerCase() ??
                'unknown';

        final savedPath = await _imageStorage.saveImage(
          patientId: widget.patientId,
          examinationId: _draftExaminationId!,
          originalFilePath: imageFile.path,
        );

        final imageId = _uuid.v4();

        await _imageRepo.createMedicalImage(
          id: imageId,
          examinationId: _draftExaminationId!,
          filePath: savedPath,
          originalFileName: _selectedImageOriginalName ?? 'unknown',
          fileFormat: extension,
          modality: 'X-Ray',
          clinicalDate: DateTime.now(),
        );

        _savedImageId = imageId;
        _savedImagePath = savedPath;
      }

      // Step 3: Run ONNX inference.
      final service = OnnxInferenceService.instance;
      await service.initialize();

      // Use the saved copy for inference (canonical path).
      final inferenceFile = File(_savedImagePath ?? imageFile.path);
      final result = await service.analyzeImage(inferenceFile);

      if (!mounted) return;

      setState(() {
        _inferenceResult = result;
        _inferenceCompleted = true;
        _runningInference = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _inferenceError = 'AI analysis failed: $e';
        _runningInference = false;
      });
    }
  }

  /// Save the full examination with inference result and doctor notes.
  Future<void> _saveExamination() async {
    if (_examinationSaved) return; // Idempotent guard
    if (_draftExaminationId == null || _inferenceResult == null) return;

    setState(() {
      _saving = true;
      _saveError = null;
    });

    try {
      final result = _inferenceResult!;

      // Save model run + result + finding.
      await _runRepo.saveSuccessfulRun(
        runId: _uuid.v4(),
        resultId: _uuid.v4(),
        findingId: _uuid.v4(),
        examinationId: _draftExaminationId!,
        modelId: _bundledModelId!,
        modelVersionId: _bundledVersionId!,
        inputImageId: _savedImageId!,
        inputImageDate: DateTime.now(),
        executionTimestamp: result.executedAt,
        prediction: result.prediction,
        confidence: result.confidence,
        normalProbability: result.normalProbability,
        pneumoniaProbability: result.pneumoniaProbability,
      );

      // Update examination with notes and status.
      final notes = _notesController.text.trim();
      await _examRepo.updateExamination(
        examinationId: _draftExaminationId!,
        doctorNotes: notes.isEmpty ? null : notes,
        status: 'COMPLETED',
      );

      if (!mounted) return;

      setState(() {
        _saving = false;
        _examinationSaved = true;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Examination saved successfully')),
      );

      // Navigate back, signaling success.
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _saveError = 'Failed to save examination: $e';
      });
    }
  }

  /// Warn about unsaved work before navigating away.
  Future<bool> _confirmDiscard() async {
    // Only warn if meaningful work has been done.
    if (_selectedImageFile == null && !_inferenceCompleted) {
      return true;
    }

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Discard Examination?'),
        content: const Text(
          'You have unsaved work. If you leave, the AI analysis result '
          'and any notes will be lost.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Stay'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: WisteriaColors.error,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Discard'),
          ),
        ],
      ),
    );

    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        if (_examinationSaved) {
          Navigator.of(context).pop(true);
          return;
        }
        final shouldDiscard = await _confirmDiscard();
        if (shouldDiscard && context.mounted) {
          Navigator.of(context).pop(false);
        }
      },
      child: Scaffold(
        backgroundColor: WisteriaColors.background,
        body: SafeArea(
          child: Column(
            children: [
              // ── Top bar ──
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 16,
                ),
                child: Row(
                  children: [
                    WisteriaBackButton(
                      label: 'Patient',
                      onTap: () async {
                        if (_examinationSaved) {
                          Navigator.of(context).pop(true);
                          return;
                        }
                        final shouldDiscard = await _confirmDiscard();
                        if (shouldDiscard && context.mounted) {
                          Navigator.of(context).pop(false);
                        }
                      },
                    ),
                    const Spacer(),
                    const Text(
                      'New Examination',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: WisteriaColors.textMuted,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ],
                ),
              ),

              // ── Content ──
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 8,
                  ),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 820),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Page header
                          _buildPageHeader(),
                          const SizedBox(height: 36),

                          // Stage A: Examination Setup
                          _buildStageA(),
                          const SizedBox(height: 20),

                          // Stage B: AI Analysis
                          _buildStageB(),

                          // Stage C: AI Results (only if completed)
                          if (_inferenceCompleted && _inferenceResult != null)
                            ...[
                              const SizedBox(height: 20),
                              _buildStageC(),
                            ],

                          // Stage D: Doctor Notes (only after inference)
                          if (_inferenceCompleted) ...[
                            const SizedBox(height: 20),
                            _buildStageD(),
                          ],

                          // Stage E: Save (only after inference)
                          if (_inferenceCompleted) ...[
                            const SizedBox(height: 20),
                            _buildStageE(),
                          ],

                          const SizedBox(height: 48),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPageHeader() {
    return Row(
      children: [
        Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            color: WisteriaColors.primary.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(WisteriaRadius.lg),
            border: Border.all(
              color: WisteriaColors.primary.withValues(alpha: 0.15),
            ),
          ),
          child: const Icon(
            Icons.biotech_rounded,
            color: WisteriaColors.primary,
            size: 24,
          ),
        ),
        const SizedBox(width: 18),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'New Examination',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: WisteriaColors.textPrimary,
                  letterSpacing: -0.2,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${widget.patientName} · ${widget.patientId}',
                style: const TextStyle(
                  fontSize: 12,
                  color: WisteriaColors.textMuted,
                  fontFamily: 'monospace',
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ── Stage A: Examination Setup ──

  Widget _buildStageA() {
    return _buildSection(
      number: '1',
      title: 'Examination Setup',
      icon: Icons.assignment_outlined,
      children: [
        // Patient info
        _buildInfoRow('Patient', widget.patientName),
        _buildInfoRow('Patient ID', widget.patientId),
        const SizedBox(height: 16),

        // Examination type dropdown
        InputDecorator(
          decoration: const InputDecoration(
            labelText: 'Examination Type',
            border: OutlineInputBorder(),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _examinationType,
              isExpanded: true,
              isDense: true,
              dropdownColor: WisteriaColors.surfaceContainer,
              items: _examinationTypes
                  .map((type) => DropdownMenuItem(
                        value: type,
                        child: Text(type),
                      ))
                  .toList(),
              onChanged: _inferenceCompleted
                  ? null
                  : (value) {
                      if (value == null) return;
                      setState(() => _examinationType = value);
                    },
            ),
          ),
        ),

        const SizedBox(height: 16),

        // Context window dropdown
        InputDecorator(
          decoration: const InputDecoration(
            labelText: 'Previous Data Context',
            border: OutlineInputBorder(),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _previousDataRange,
              isExpanded: true,
              isDense: true,
              dropdownColor: WisteriaColors.surfaceContainer,
              items: _contextWindows
                  .map((range) => DropdownMenuItem(
                        value: range,
                        child: Text(range),
                      ))
                  .toList(),
              onChanged: _inferenceCompleted
                  ? null
                  : (value) {
                      if (value == null) return;
                      setState(() => _previousDataRange = value);
                    },
            ),
          ),
        ),

        const SizedBox(height: 20),

        // Image selection
        const Text(
          'Medical Image',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: WisteriaColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),

        if (_selectedImageFile != null)
          _buildSelectedImagePreview()
        else
          _buildImagePicker(),
      ],
    );
  }

  Widget _buildImagePicker() {
    return InkWell(
      borderRadius: BorderRadius.circular(WisteriaRadius.md),
      onTap: _runningInference ? null : _pickImage,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: WisteriaColors.surfaceContainer,
          borderRadius: BorderRadius.circular(WisteriaRadius.md),
          border: Border.all(
            color: WisteriaColors.border,
            style: BorderStyle.solid,
          ),
        ),
        child: const Column(
          children: [
            Icon(
              Icons.add_photo_alternate_outlined,
              size: 36,
              color: WisteriaColors.textMuted,
            ),
            SizedBox(height: 12),
            Text(
              'Click to select a medical image',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: WisteriaColors.textSecondary,
              ),
            ),
            SizedBox(height: 4),
            Text(
              'JPG, PNG, WebP, BMP',
              style: TextStyle(
                fontSize: 12,
                color: WisteriaColors.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSelectedImagePreview() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: WisteriaColors.surfaceContainer,
        borderRadius: BorderRadius.circular(WisteriaRadius.md),
        border: Border.all(
          color: WisteriaColors.primary.withValues(alpha: 0.25),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Thumbnail
          Container(
            width: 100,
            height: 80,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(WisteriaRadius.sm),
              color: WisteriaColors.surfaceHigh,
            ),
            clipBehavior: Clip.antiAlias,
            child: Image.file(
              _selectedImageFile!,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => const Icon(
                Icons.broken_image_outlined,
                color: WisteriaColors.textMuted,
              ),
            ),
          ),

          const SizedBox(width: 16),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _selectedImageOriginalName ?? 'Selected image',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: WisteriaColors.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  _selectedImageFile!.path,
                  style: const TextStyle(
                    fontSize: 11,
                    color: WisteriaColors.textMuted,
                    fontFamily: 'monospace',
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                if (!_inferenceCompleted)
                  InkWell(
                    borderRadius: BorderRadius.circular(WisteriaRadius.sm),
                    onTap: _runningInference ? null : _pickImage,
                    child: const Padding(
                      padding: EdgeInsets.symmetric(vertical: 4),
                      child: Text(
                        'Change image',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: WisteriaColors.primary,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Stage B: AI Analysis ──

  Widget _buildStageB() {
    return _buildSection(
      number: '2',
      title: 'AI Analysis',
      icon: Icons.auto_awesome_outlined,
      children: [
        // Model info
        if (_loadingModel)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(20),
              child: CircularProgressIndicator(
                color: WisteriaColors.primary,
              ),
            ),
          )
        else if (_modelError != null)
          _buildErrorCard(_modelError!)
        else ...[
          // Model card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: WisteriaColors.surfaceContainer,
              borderRadius: BorderRadius.circular(WisteriaRadius.sm),
              border: Border.all(color: WisteriaColors.border),
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: WisteriaColors.primary.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(WisteriaRadius.sm),
                  ),
                  child: const Icon(
                    Icons.memory_rounded,
                    size: 20,
                    color: WisteriaColors.primary,
                  ),
                ),
                const SizedBox(width: 14),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Pneumonia ResNet18',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: WisteriaColors.textPrimary,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Pneumonia Classification · X-Ray · ONNX Runtime · v1.0.0',
                        style: TextStyle(
                          fontSize: 11,
                          color: WisteriaColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: WisteriaColors.success.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'LOCAL',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: WisteriaColors.success,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Clinical disclaimer
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: WisteriaColors.warning.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(WisteriaRadius.sm),
              border: Border.all(
                color: WisteriaColors.warning.withValues(alpha: 0.15),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.info_outline_rounded,
                  size: 18,
                  color: WisteriaColors.warning.withValues(alpha: 0.7),
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text(
                    'AI-generated classification only. Model output is not a definitive medical diagnosis and must be reviewed by a qualified clinician.',
                    style: TextStyle(
                      fontSize: 12,
                      color: WisteriaColors.textSecondary,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Run button
          if (!_inferenceCompleted)
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _runningInference ||
                        _selectedImageFile == null ||
                        !_modelAvailable
                    ? null
                    : _runAIAnalysis,
                icon: _runningInference
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: WisteriaColors.textOnPrimary,
                        ),
                      )
                    : const Icon(Icons.play_arrow_rounded, size: 20),
                label: Text(
                  _runningInference
                      ? 'Running AI analysis...'
                      : _selectedImageFile == null
                          ? 'Select an image first'
                          : 'Run AI Analysis',
                ),
              ),
            ),

          if (_runningInference) ...[
            const SizedBox(height: 12),
            const LinearProgressIndicator(
              color: WisteriaColors.primary,
              backgroundColor: WisteriaColors.surfaceHigh,
            ),
          ],

          if (_inferenceError != null) ...[
            const SizedBox(height: 12),
            _buildErrorCard(_inferenceError!),
            const SizedBox(height: 12),
            // Retry button
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _runningInference ? null : _runAIAnalysis,
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: const Text('Retry AI Analysis'),
              ),
            ),
          ],

          if (_inferenceCompleted)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: WisteriaColors.success.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(WisteriaRadius.sm),
                border: Border.all(
                  color: WisteriaColors.success.withValues(alpha: 0.2),
                ),
              ),
              child: const Row(
                children: [
                  Icon(
                    Icons.check_circle_rounded,
                    size: 18,
                    color: WisteriaColors.success,
                  ),
                  SizedBox(width: 10),
                  Text(
                    'AI analysis completed successfully',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: WisteriaColors.success,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ],
    );
  }

  // ── Stage C: AI Results ──

  Widget _buildStageC() {
    final result = _inferenceResult!;
    final isPneumonia = result.prediction == 'PNEUMONIA';

    return _buildSection(
      number: '3',
      title: 'AI Classification Result',
      icon: Icons.analytics_outlined,
      children: [
        // Prediction header
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: isPneumonia
                ? WisteriaColors.warning.withValues(alpha: 0.08)
                : WisteriaColors.success.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(WisteriaRadius.md),
            border: Border.all(
              color: isPneumonia
                  ? WisteriaColors.warning.withValues(alpha: 0.2)
                  : WisteriaColors.success.withValues(alpha: 0.2),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: isPneumonia
                      ? WisteriaColors.warning.withValues(alpha: 0.12)
                      : WisteriaColors.success.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(WisteriaRadius.md),
                ),
                child: Icon(
                  isPneumonia
                      ? Icons.warning_amber_rounded
                      : Icons.check_circle_outline_rounded,
                  color: isPneumonia
                      ? WisteriaColors.warning
                      : WisteriaColors.success,
                  size: 28,
                ),
              ),
              const SizedBox(width: 18),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      result.prediction,
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: isPneumonia
                            ? WisteriaColors.warning
                            : WisteriaColors.success,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Confidence: ${(result.confidence * 100).toStringAsFixed(2)}%',
                      style: const TextStyle(
                        fontSize: 13,
                        color: WisteriaColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // Detailed results
        _buildResultRow(
          'Predicted Class',
          result.prediction,
        ),
        _buildResultRow(
          'Model Confidence',
          '${(result.confidence * 100).toStringAsFixed(2)}%',
        ),
        _buildResultRow(
          'NORMAL Probability',
          '${(result.normalProbability * 100).toStringAsFixed(2)}%',
        ),
        _buildResultRow(
          'PNEUMONIA Probability',
          '${(result.pneumoniaProbability * 100).toStringAsFixed(2)}%',
        ),
        _buildResultRow(
          'Model',
          'Pneumonia ResNet18 v1.0.0',
        ),
        _buildResultRow(
          'Execution Time',
          _formatDateTime(result.executedAt),
        ),

        const SizedBox(height: 12),

        // AI label
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: WisteriaColors.surfaceContainer,
            borderRadius: BorderRadius.circular(WisteriaRadius.full),
            border: Border.all(color: WisteriaColors.border),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.auto_awesome_outlined,
                size: 14,
                color: WisteriaColors.primary,
              ),
              SizedBox(width: 6),
              Text(
                'AI-generated classification result',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: WisteriaColors.textMuted,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ── Stage D: Doctor Notes ──

  Widget _buildStageD() {
    return _buildSection(
      number: '4',
      title: 'Doctor Notes',
      icon: Icons.notes_outlined,
      children: [
        const Text(
          'Enter your clinical observations and notes. This field is optional.',
          style: TextStyle(
            fontSize: 13,
            color: WisteriaColors.textMuted,
            height: 1.4,
          ),
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _notesController,
          maxLines: 6,
          style: const TextStyle(color: WisteriaColors.textPrimary),
          decoration: const InputDecoration(
            hintText:
                'Clinical observations, assessment, and plan...',
            border: OutlineInputBorder(),
            alignLabelWithHint: true,
          ),
        ),
      ],
    );
  }

  // ── Stage E: Save ──

  Widget _buildStageE() {
    return _buildSection(
      number: '5',
      title: 'Save Examination',
      icon: Icons.save_outlined,
      children: [
        if (_saveError != null) ...[
          _buildErrorCard(_saveError!),
          const SizedBox(height: 16),
        ],

        const Text(
          'Review the AI result and your notes above, then save the completed examination.',
          style: TextStyle(
            fontSize: 13,
            color: WisteriaColors.textMuted,
            height: 1.4,
          ),
        ),
        const SizedBox(height: 20),

        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: _saving || _examinationSaved ? null : _saveExamination,
            icon: _saving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: WisteriaColors.textOnPrimary,
                    ),
                  )
                : _examinationSaved
                    ? const Icon(Icons.check_rounded, size: 20)
                    : const Icon(Icons.save_rounded, size: 20),
            label: Text(
              _saving
                  ? 'Saving...'
                  : _examinationSaved
                      ? 'Examination Saved'
                      : 'Save Examination',
            ),
          ),
        ),
      ],
    );
  }

  // ── Shared Widgets ──

  Widget _buildSection({
    required String number,
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: WisteriaColors.surfaceLow,
        borderRadius: BorderRadius.circular(WisteriaRadius.lg),
        border: Border.all(color: WisteriaColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: WisteriaColors.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(WisteriaRadius.sm),
                ),
                child: Center(
                  child: Text(
                    number,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: WisteriaColors.primary,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Icon(
                icon,
                size: 20,
                color: WisteriaColors.primary.withValues(alpha: 0.7),
              ),
              const SizedBox(width: 10),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: WisteriaColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          ...children,
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                color: WisteriaColors.textMuted,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                color: WisteriaColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: WisteriaColors.textMuted,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: WisteriaColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorCard(String message) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: WisteriaColors.error.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(WisteriaRadius.sm),
        border: Border.all(
          color: WisteriaColors.error.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.error_outline_rounded,
            size: 18,
            color: WisteriaColors.error,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                fontSize: 12,
                color: WisteriaColors.error,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    final day = dateTime.day.toString().padLeft(2, '0');
    final month = dateTime.month.toString().padLeft(2, '0');
    final year = dateTime.year;
    final hour = dateTime.hour == 0
        ? 12
        : dateTime.hour > 12
            ? dateTime.hour - 12
            : dateTime.hour;
    final minute = dateTime.minute.toString().padLeft(2, '0');
    final period = dateTime.hour >= 12 ? 'PM' : 'AM';
    return '$day/$month/$year · $hour:$minute $period';
  }
}
