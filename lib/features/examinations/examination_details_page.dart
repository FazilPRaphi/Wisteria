import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:uuid/uuid.dart';
import '../../core/database/database.dart';
import '../../core/database/repositories/examination_repository.dart';
import '../../core/database/repositories/medical_image_repository.dart';
import '../../core/storage/medical_image_storage.dart';
import '../../core/theme/wisteria_theme.dart';
import '../shared/wisteria_back_button.dart';

class ExaminationDetailsPage extends StatefulWidget {
  final WisteriaDatabase database;
  final String examinationId;

  const ExaminationDetailsPage({
    super.key,
    required this.database,
    required this.examinationId,
  });

  @override
  State<ExaminationDetailsPage> createState() => _ExaminationDetailsPageState();
}

class _ExaminationDetailsPageState extends State<ExaminationDetailsPage> {
  late final ExaminationRepository _repository;
  late final MedicalImageRepository _imageRepository;
  late final MedicalImageStorage _imageStorage;

  Examination? _examination;
  List<MedicalImage> _medicalImages = [];
  bool _isLoading = true;
  bool _isAddingImage = false;
  @override
  void initState() {
    super.initState();

    _repository = ExaminationRepository(widget.database);
    _imageRepository = MedicalImageRepository(widget.database);
    _imageStorage = MedicalImageStorage();

    _loadExamination();
    _loadMedicalImages();
  }

  Future<void> _loadExamination() async {
    final examination = await _repository.getExaminationById(
      widget.examinationId,
    );

    if (!mounted) return;

    setState(() {
      _examination = examination;
      _isLoading = false;
    });
  }

  Future<void> _loadMedicalImages() async {
    final images = await _imageRepository.getImagesForExamination(
      widget.examinationId,
    );

    if (!mounted) return;

    setState(() {
      _medicalImages = images;
    });
  }

  Future<void> _addMedicalImage() async {
    setState(() {
      _isAddingImage = true;
    });

    try {
      final selectedFile = await FilePicker.pickFile(
        type: FileType.custom,
        allowedExtensions: ['jpg', 'jpeg', 'png', 'webp', 'bmp'],
      );

      if (selectedFile == null || selectedFile.path == null) {
        return;
      }

      final examination = _examination;

      if (examination == null) {
        return;
      }

      final modality = await _showModalityDialog();

      if (modality == null) {
        return;
      }

      final clinicalDate = await _showClinicalDateDialog(
        examination.examinationDate,
      );

      if (clinicalDate == null) {
        return;
      }

      final savedPath = await _imageStorage.saveImage(
        patientId: examination.patientId,
        examinationId: examination.id,
        originalFilePath: selectedFile.path!,
      );

      final extension = selectedFile.extension?.toLowerCase() ?? 'unknown';

      await _imageRepository.createMedicalImage(
        id: const Uuid().v4(),
        examinationId: examination.id,
        filePath: savedPath,
        originalFileName: selectedFile.name,
        fileFormat: extension,
        modality: modality,
        clinicalDate: clinicalDate,
      );

      await _loadMedicalImages();
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to add medical image: $e')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isAddingImage = false;
        });
      }
    }
  }

  Future<void> _deleteMedicalImage(MedicalImage image) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete Medical Image'),
          content: Text(
            'Delete "${image.originalFileName}" from this examination?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) {
      return;
    }

    await _imageStorage.deleteImage(image.filePath);
    await _imageRepository.deleteMedicalImage(image.id);

    await _loadMedicalImages();
  }

  Future<String?> _showModalityDialog() async {
    const modalities = [
      'X-Ray',
      'CT',
      'MRI',
      'Ultrasound',
      'Mammography',
      'Other',
    ];

    return showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Select Modality'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: modalities.map((modality) {
              return ListTile(
                title: Text(modality),
                onTap: () {
                  Navigator.pop(context, modality);
                },
              );
            }).toList(),
          ),
        );
      },
    );
  }

  Future<DateTime?> _showClinicalDateDialog(DateTime initialDate) async {
    return showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: WisteriaColors.background,
        body: Center(
          child: CircularProgressIndicator(color: WisteriaColors.primary),
        ),
      );
    }

    final examination = _examination;

    if (examination == null) {
      return Scaffold(
        backgroundColor: WisteriaColors.background,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                WisteriaBackButton(
                  label: 'Patient',
                  onTap: () => Navigator.pop(context),
                ),
                const Expanded(
                  child: Center(
                    child: Text(
                      'Examination not found',
                      style: TextStyle(color: WisteriaColors.textSecondary),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: WisteriaColors.background,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Row(
                children: [
                  WisteriaBackButton(
                    label: 'Patient',
                    onTap: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(32),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 900),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          examination.examinationType,
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w700,
                            color: WisteriaColors.textPrimary,
                          ),
                        ),

                        const SizedBox(height: 8),

                        Text(
                          _formatDateTime(examination.examinationDate),
                          style: const TextStyle(
                            fontSize: 13,
                            color: WisteriaColors.textMuted,
                          ),
                        ),

                        const SizedBox(height: 32),

                        _buildSection(
                          title: 'Examination Information',
                          icon: Icons.medical_information_outlined,
                          children: [
                            _buildInfoRow('Type', examination.examinationType),
                            _buildInfoRow('Status', examination.status),
                            _buildInfoRow(
                              'Context',
                              examination.previousDataRange,
                            ),
                            _buildInfoRow(
                              'Date',
                              _formatDateTime(examination.examinationDate),
                            ),
                          ],
                        ),

                        const SizedBox(height: 20),

                        _buildSection(
                          title: 'Doctor Notes',
                          icon: Icons.notes_outlined,
                          children: [
                            Text(
                              examination.doctorNotes?.trim().isNotEmpty == true
                                  ? examination.doctorNotes!
                                  : 'No doctor notes added.',
                              style: const TextStyle(
                                fontSize: 14,
                                color: WisteriaColors.textSecondary,
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 20),

                        _buildSection(
                          title: 'Medical Images',
                          icon: Icons.image_outlined,
                          children: [
                            Row(
                              children: [
                                const Expanded(
                                  child: Text(
                                    'Images attached to this examination.',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: WisteriaColors.textMuted,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                FilledButton.icon(
                                  onPressed: _isAddingImage
                                      ? null
                                      : _addMedicalImage,
                                  icon: _isAddingImage
                                      ? const SizedBox(
                                          width: 16,
                                          height: 16,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                          ),
                                        )
                                      : const Icon(
                                          Icons.add_photo_alternate_outlined,
                                        ),
                                  label: Text(
                                    _isAddingImage ? 'Adding...' : 'Add Image',
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 20),

                            if (_medicalImages.isEmpty)
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(24),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(
                                    WisteriaRadius.md,
                                  ),
                                  border: Border.all(
                                    color: WisteriaColors.border,
                                  ),
                                ),
                                child: const Column(
                                  children: [
                                    Icon(
                                      Icons.image_not_supported_outlined,
                                      size: 36,
                                      color: WisteriaColors.textMuted,
                                    ),
                                    SizedBox(height: 12),
                                    Text(
                                      'No medical images added yet.',
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: WisteriaColors.textMuted,
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            else
                              ..._medicalImages.map(_buildMedicalImageCard),
                          ],
                        ),

                        const SizedBox(height: 20),

                        _buildSection(
                          title: 'AI Analysis',
                          icon: Icons.auto_awesome_outlined,
                          children: const [
                            Text(
                              'AI inference will be added in a later stage.',
                              style: TextStyle(
                                fontSize: 13,
                                color: WisteriaColors.textMuted,
                              ),
                            ),
                          ],
                        ),

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
    );
  }

  Widget _buildSection({
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
              Icon(
                icon,
                size: 20,
                color: WisteriaColors.primary.withValues(alpha: 0.7),
              ),
              const SizedBox(width: 12),
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
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 150,
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

  Widget _buildMedicalImageCard(MedicalImage image) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(WisteriaRadius.md),
        border: Border.all(color: WisteriaColors.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 120,
            height: 90,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(WisteriaRadius.md),
              color: WisteriaColors.surfaceHigh,
            ),
            clipBehavior: Clip.antiAlias,
            child: Image.file(
              File(image.filePath),
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) {
                return const Icon(
                  Icons.broken_image_outlined,
                  color: WisteriaColors.textMuted,
                  size: 32,
                );
              },
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  image.originalFileName,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: WisteriaColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                _buildInfoRow('Modality', image.modality),
                _buildInfoRow(
                  'Clinical Date',
                  _formatDateTime(image.clinicalDate),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Delete image',
            icon: const Icon(
              Icons.delete_outline,
              color: WisteriaColors.textMuted,
            ),
            onPressed: () => _deleteMedicalImage(image),
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

    return '$day/$month/$year • $hour:$minute $period';
  }
}
