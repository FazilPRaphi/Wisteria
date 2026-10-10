import 'package:flutter/material.dart';
import '../examinations/create_examination_page.dart';
import '../../core/database/database.dart';
import '../../core/database/repositories/patient_repository.dart';
import '../../core/theme/wisteria_theme.dart';
import '../shared/wisteria_back_button.dart';
import '../../core/database/repositories/examination_repository.dart';

import '../examinations/examination_details_page.dart';

class PatientDetailsPage extends StatefulWidget {
  final WisteriaDatabase database;
  final String patientId;

  const PatientDetailsPage({
    super.key,
    required this.database,
    required this.patientId,
  });

  @override
  State<PatientDetailsPage> createState() => _PatientDetailsPageState();
}

class _PatientDetailsPageState extends State<PatientDetailsPage> {
  late final PatientRepository _patientRepository;
  late final ExaminationRepository _examinationRepository;

  Patient? _patient;
  List<Examination> _examinations = [];

  bool _isLoading = true;
  @override
  void initState() {
    super.initState();

    _patientRepository = PatientRepository(widget.database);
    _examinationRepository = ExaminationRepository(widget.database);

    _loadPatient();
    _loadExaminations();
  }

  Future<void> _loadPatient() async {
    final patient = await _patientRepository.getPatientById(widget.patientId);

    if (!mounted) return;

    setState(() {
      _patient = patient;
      _isLoading = false;
    });
  }

  Future<void> _loadExaminations() async {
    final examinations = await _examinationRepository.getExaminationsForPatient(
      widget.patientId,
    );

    if (!mounted) return;

    setState(() {
      _examinations = examinations;
    });
  }

  String _formatDateTime(DateTime dateTime) {
    final day = dateTime.day.toString().padLeft(2, '0');
    final month = dateTime.month.toString().padLeft(2, '0');
    final year = dateTime.year.toString();

    final hour = dateTime.hour == 0
        ? 12
        : dateTime.hour > 12
        ? dateTime.hour - 12
        : dateTime.hour;

    final minute = dateTime.minute.toString().padLeft(2, '0');

    final period = dateTime.hour >= 12 ? 'PM' : 'AM';

    return '$day/$month/$year • $hour:$minute $period';
  }

  Future<void> _editPatient() async {
    final patient = _patient;

    if (patient == null) return;

    final nameController = TextEditingController(text: patient.name);

    final phoneController = TextEditingController(
      text: patient.phoneNumber ?? '',
    );

    final ageController = TextEditingController(
      text: patient.age?.toString() ?? '',
    );

    final bloodGroupController = TextEditingController(
      text: patient.bloodGroup ?? '',
    );

    final otherContactController = TextEditingController(
      text: patient.otherContact ?? '',
    );

    final addressController = TextEditingController(
      text: patient.address ?? '',
    );

    final formKey = GlobalKey<FormState>();

    final result = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Edit Patient'),
          content: SizedBox(
            width: 500,
            child: Form(
              key: formKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: nameController,
                      style: const TextStyle(color: WisteriaColors.textPrimary),
                      decoration: const InputDecoration(labelText: 'Name'),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Name is required';
                        }

                        return null;
                      },
                    ),

                    const SizedBox(height: 16),

                    TextFormField(
                      controller: phoneController,
                      style: const TextStyle(color: WisteriaColors.textPrimary),
                      decoration: const InputDecoration(
                        labelText: 'Phone Number',
                      ),
                    ),

                    const SizedBox(height: 16),

                    TextFormField(
                      controller: ageController,
                      keyboardType: TextInputType.number,
                      style: const TextStyle(color: WisteriaColors.textPrimary),
                      decoration: const InputDecoration(labelText: 'Age'),
                    ),

                    const SizedBox(height: 16),

                    TextFormField(
                      controller: bloodGroupController,
                      style: const TextStyle(color: WisteriaColors.textPrimary),
                      decoration: const InputDecoration(
                        labelText: 'Blood Group',
                      ),
                    ),

                    const SizedBox(height: 16),

                    TextFormField(
                      controller: otherContactController,
                      style: const TextStyle(color: WisteriaColors.textPrimary),
                      decoration: const InputDecoration(
                        labelText: 'Other Contact',
                      ),
                    ),

                    const SizedBox(height: 16),

                    TextFormField(
                      controller: addressController,
                      maxLines: 3,
                      style: const TextStyle(color: WisteriaColors.textPrimary),
                      decoration: const InputDecoration(
                        labelText: 'Address',
                        alignLabelWithHint: true,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context, false);
              },
              child: const Text('Cancel'),
            ),

            FilledButton(
              onPressed: () async {
                if (!formKey.currentState!.validate()) {
                  return;
                }

                await _patientRepository.updatePatient(
                  id: patient.id,
                  name: nameController.text.trim(),
                  phoneNumber: phoneController.text.trim().isEmpty
                      ? null
                      : phoneController.text.trim(),
                  age: int.tryParse(ageController.text.trim()),
                  bloodGroup: bloodGroupController.text.trim().isEmpty
                      ? null
                      : bloodGroupController.text.trim(),
                  otherContact: otherContactController.text.trim().isEmpty
                      ? null
                      : otherContactController.text.trim(),
                  address: addressController.text.trim().isEmpty
                      ? null
                      : addressController.text.trim(),
                );

                if (!context.mounted) return;

                Navigator.pop(context, true);
              },
              child: const Text('Save Changes'),
            ),
          ],
        );
      },
    );

    nameController.dispose();
    phoneController.dispose();
    ageController.dispose();
    bloodGroupController.dispose();
    otherContactController.dispose();
    addressController.dispose();

    if (result == true) {
      await _loadPatient();
    }
  }

  Future<void> _deletePatient() async {
    final patient = _patient;

    if (patient == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete Patient?'),
          content: Text(
            'Are you sure you want to delete ${patient.name}? '
            'This action cannot be undone.',
            style: const TextStyle(color: WisteriaColors.textSecondary),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context, false);
              },
              child: const Text('Cancel'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: WisteriaColors.error,
              ),
              onPressed: () {
                Navigator.pop(context, true);
              },
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    await _patientRepository.deletePatient(patient.id);

    if (!mounted) return;

    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    final colors = WisteriaColors.of(context);

    if (_isLoading) {
      return Scaffold(
        backgroundColor: colors.background,
        body: const Center(
          child: CircularProgressIndicator(color: WisteriaColors.primary),
        ),
      );
    }

    if (_patient == null) {
      return Scaffold(
        backgroundColor: colors.background,
        body: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 16,
                ),
                child: Row(
                  children: [
                    WisteriaBackButton(
                      label: 'Patients',
                      onTap: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
              ),
              const Expanded(
                child: Center(
                  child: Text(
                    'Patient not found',
                    style: TextStyle(color: WisteriaColors.textSecondary),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    final patient = _patient!;

    return Scaffold(
      backgroundColor: colors.background,
      body: SafeArea(
        child: Column(
          children: [
            // ── Top bar ──
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Row(
                children: [
                  WisteriaBackButton(
                    label: 'Patients',
                    onTap: () => Navigator.of(context).pop(),
                  ),
                  const Spacer(),
                  // Edit button
                  _ActionButton(
                    icon: Icons.edit_rounded,
                    tooltip: 'Edit patient',
                    onTap: _editPatient,
                  ),
                  const SizedBox(width: 8),
                  // Delete button
                  _ActionButton(
                    icon: Icons.delete_outline_rounded,
                    tooltip: 'Delete patient',
                    onTap: _deletePatient,
                    isDestructive: true,
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
                    constraints: const BoxConstraints(maxWidth: 960),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // ── Patient header ──
                        _buildPatientHeader(patient),

                        const SizedBox(height: 32),

                        // ── Cards in a responsive layout ──
                        LayoutBuilder(
                          builder: (context, constraints) {
                            final isWide = constraints.maxWidth >= 700;

                            if (isWide) {
                              return Column(
                                children: [
                                  // Row 1: Biodata + New Examination
                                  Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Expanded(
                                        flex: 3,
                                        child: _buildBiodataCard(patient),
                                      ),
                                      const SizedBox(width: 20),
                                      Expanded(
                                        flex: 2,
                                        child: Column(
                                          children: [
                                            _buildNewExaminationCard(patient),
                                            const SizedBox(height: 20),
                                            _buildAnalyticsPlaceholder(),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),

                                  const SizedBox(height: 20),

                                  // Row 2: Medical history placeholder
                                  _buildMedicalHistoryPlaceholder(),

                                  const SizedBox(height: 20),

                                  // Row 3: Examinations
                                  _buildExaminationsSection(patient),
                                ],
                              );
                            }

                            return Column(
                              children: [
                                _buildBiodataCard(patient),
                                const SizedBox(height: 20),
                                _buildNewExaminationCard(patient),
                                const SizedBox(height: 20),
                                _buildAnalyticsPlaceholder(),
                                const SizedBox(height: 20),
                                _buildMedicalHistoryPlaceholder(),
                                const SizedBox(height: 20),
                                _buildExaminationsSection(patient),
                              ],
                            );
                          },
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

  Widget _buildPatientHeader(Patient patient) {
    final initials = patient.name.isNotEmpty
        ? patient.name
              .split(' ')
              .map((w) => w.isNotEmpty ? w[0] : '')
              .take(2)
              .join()
              .toUpperCase()
        : '?';

    return Row(
      children: [
        Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            color: WisteriaColors.primary.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(WisteriaRadius.lg),
            border: Border.all(
              color: WisteriaColors.primary.withValues(alpha: 0.2),
            ),
          ),
          child: Center(
            child: Text(
              initials,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: WisteriaColors.primary,
              ),
            ),
          ),
        ),

        const SizedBox(width: 20),

        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                patient.name,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: WisteriaColors.textPrimary,
                  letterSpacing: -0.2,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'ID: ${patient.id}',
                style: const TextStyle(
                  fontSize: 12,
                  color: WisteriaColors.textMuted,
                  fontFamily: 'monospace',
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ── A. Patient Biodata Card ──

  Widget _buildBiodataCard(Patient patient) {
    return _buildSection(
      title: 'Patient Information',
      icon: Icons.person_outline_rounded,
      children: [
        _buildInfoRow('Name', patient.name),
        _buildInfoRow('Age', patient.age?.toString() ?? 'Not provided'),
        _buildInfoRow('Blood Group', patient.bloodGroup ?? 'Not provided'),
        _buildInfoRow('Phone', patient.phoneNumber ?? 'Not provided'),
        _buildInfoRow('Other Contact', patient.otherContact ?? 'Not provided'),
        _buildInfoRow('Address', patient.address ?? 'Not provided'),
      ],
    );
  }

  // ── B. Analytics Placeholder Card ──

  Widget _buildAnalyticsPlaceholder() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: WisteriaColors.surfaceLow,
        borderRadius: BorderRadius.circular(WisteriaRadius.lg),
        border: Border.all(color: WisteriaColors.border),
      ),
      child: Column(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: WisteriaColors.info.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(WisteriaRadius.md),
            ),
            child: Icon(
              Icons.analytics_outlined,
              size: 26,
              color: WisteriaColors.info.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Patient Analytics',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: WisteriaColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Analytics and insights for this patient will be available in a future update.',
            style: TextStyle(
              fontSize: 13,
              color: WisteriaColors.textMuted,
              height: 1.4,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: WisteriaColors.surfaceContainer,
              borderRadius: BorderRadius.circular(WisteriaRadius.full),
              border: Border.all(color: WisteriaColors.border),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.construction_rounded,
                  size: 14,
                  color: WisteriaColors.warning.withValues(alpha: 0.7),
                ),
                const SizedBox(width: 6),
                const Text(
                  'Coming soon',
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
      ),
    );
  }

  // ── C. Medical History Placeholder Card ──

  Widget _buildMedicalHistoryPlaceholder() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: WisteriaColors.surfaceLow,
        borderRadius: BorderRadius.circular(WisteriaRadius.lg),
        border: Border.all(color: WisteriaColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: WisteriaColors.tertiary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(WisteriaRadius.md),
            ),
            child: Icon(
              Icons.timeline_rounded,
              size: 24,
              color: WisteriaColors.tertiary.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(width: 20),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Medical History & Trends',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: WisteriaColors.textPrimary,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Longitudinal medical history and health trends will be available in a future iteration.',
                  style: TextStyle(
                    fontSize: 13,
                    color: WisteriaColors.textMuted,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
            decoration: BoxDecoration(
              color: WisteriaColors.surfaceContainer,
              borderRadius: BorderRadius.circular(WisteriaRadius.full),
              border: Border.all(color: WisteriaColors.border),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.construction_rounded,
                  size: 13,
                  color: WisteriaColors.warning.withValues(alpha: 0.7),
                ),
                const SizedBox(width: 5),
                const Text(
                  'Coming soon',
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
      ),
    );
  }

  // ── D. New Examination Card ──

  Widget _buildNewExaminationCard(Patient patient) {
    return _NewExaminationCard(
      onTap: () async {
        final created = await Navigator.push<bool>(
          context,
          MaterialPageRoute(
            builder: (_) => CreateExaminationPage(
              database: widget.database,
              patientId: patient.id,
              patientName: patient.name,
            ),
          ),
        );

        if (created == true && mounted) {
          await _loadExaminations();
        }
      },
    );
  }

  Widget _buildExaminationsSection(Patient patient) {
    return _buildSection(
      title: 'Examinations',
      icon: Icons.medical_information_outlined,
      children: [
        if (_examinations.isEmpty)
          const _EmptySectionContent(message: 'No examinations yet.')
        else
          ..._examinations.map(
            (examination) => _buildExaminationItem(examination),
          ),
      ],
    );
  }

  Widget _buildExaminationItem(Examination examination) {
    return InkWell(
      borderRadius: BorderRadius.circular(WisteriaRadius.md),
      onTap: () async {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ExaminationDetailsPage(
              database: widget.database,
              examinationId: examination.id,
            ),
          ),
        );

        if (mounted) {
          await _loadExaminations();
        }
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: WisteriaColors.background,
          borderRadius: BorderRadius.circular(WisteriaRadius.md),
          border: Border.all(color: WisteriaColors.border),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: WisteriaColors.primary.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(WisteriaRadius.sm),
              ),
              child: const Icon(
                Icons.medical_information_outlined,
                color: WisteriaColors.primary,
              ),
            ),

            const SizedBox(width: 16),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    examination.examinationType,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: WisteriaColors.textPrimary,
                    ),
                  ),

                  const SizedBox(height: 5),

                  Text(
                    _formatDateTime(examination.examinationDate),
                    style: const TextStyle(
                      fontSize: 12,
                      color: WisteriaColors.textMuted,
                    ),
                  ),
                ],
              ),
            ),

            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: WisteriaColors.primary.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                examination.status,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: WisteriaColors.primary,
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
      decoration: BoxDecoration(
        color: WisteriaColors.surfaceLow,
        borderRadius: BorderRadius.circular(WisteriaRadius.lg),
        border: Border.all(color: WisteriaColors.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
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
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    final isProvided = value != 'Not provided';

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
                fontWeight: FontWeight.w500,
                fontSize: 13,
                color: WisteriaColors.textMuted,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 14,
                fontWeight: isProvided ? FontWeight.w400 : FontWeight.w400,
                color: isProvided
                    ? WisteriaColors.textPrimary
                    : WisteriaColors.textMuted.withValues(alpha: 0.6),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptySectionContent extends StatelessWidget {
  final String message;

  const _EmptySectionContent({required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Text(
          message,
          style: const TextStyle(fontSize: 13, color: WisteriaColors.textMuted),
        ),
      ),
    );
  }
}

/// Prominent New Examination card.
class _NewExaminationCard extends StatefulWidget {
  final VoidCallback onTap;

  const _NewExaminationCard({required this.onTap});

  @override
  State<_NewExaminationCard> createState() => _NewExaminationCardState();
}

class _NewExaminationCardState extends State<_NewExaminationCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                WisteriaColors.primary.withValues(
                  alpha: _isHovered ? 0.14 : 0.08,
                ),
                WisteriaColors.surfaceLow,
              ],
            ),
            borderRadius: BorderRadius.circular(WisteriaRadius.lg),
            border: Border.all(
              color: _isHovered
                  ? WisteriaColors.primary.withValues(alpha: 0.5)
                  : WisteriaColors.primary.withValues(alpha: 0.2),
            ),
            boxShadow: _isHovered
                ? WisteriaElevation.accentGlow(WisteriaColors.primary)
                : [],
          ),
          child: Column(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: WisteriaColors.primary.withValues(
                    alpha: _isHovered ? 0.18 : 0.12,
                  ),
                  borderRadius: BorderRadius.circular(WisteriaRadius.md),
                ),
                child: Icon(
                  Icons.add_circle_outline_rounded,
                  size: 28,
                  color: _isHovered
                      ? WisteriaColors.primary
                      : WisteriaColors.primary.withValues(alpha: 0.8),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'New Examination',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: WisteriaColors.textPrimary,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Create a clinical examination with AI-assisted diagnostics',
                style: TextStyle(
                  fontSize: 12,
                  color: WisteriaColors.textMuted,
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Action icon button with hover effects.
class _ActionButton extends StatefulWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;
  final bool isDestructive;

  const _ActionButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
    this.isDestructive = false,
  });

  @override
  State<_ActionButton> createState() => _ActionButtonState();
}

class _ActionButtonState extends State<_ActionButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final hoverColor = widget.isDestructive
        ? WisteriaColors.error
        : WisteriaColors.primary;

    return Tooltip(
      message: widget.tooltip,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        child: GestureDetector(
          onTap: widget.onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: _isHovered
                  ? hoverColor.withValues(alpha: 0.12)
                  : WisteriaColors.surfaceLow,
              borderRadius: BorderRadius.circular(WisteriaRadius.sm),
              border: Border.all(
                color: _isHovered
                    ? hoverColor.withValues(alpha: 0.3)
                    : WisteriaColors.border,
              ),
            ),
            child: Icon(
              widget.icon,
              size: 18,
              color: _isHovered ? hoverColor : WisteriaColors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}
