import 'package:flutter/material.dart';
import 'patient_details_page.dart';
import '../../core/database/database.dart';
import '../../core/database/repositories/patient_repository.dart';
import '../../core/theme/wisteria_theme.dart';
import '../shared/wisteria_back_button.dart';

class PatientPage extends StatefulWidget {
  final WisteriaDatabase database;

  const PatientPage({super.key, required this.database});

  @override
  State<PatientPage> createState() => _PatientPageState();
}

class _PatientPageState extends State<PatientPage> {
  late final PatientRepository _patientRepository;

  List<Patient> _patients = [];
  bool _isLoading = true;

  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();

    _patientRepository = PatientRepository(widget.database);

    _searchController.addListener(_onSearchChanged);

    _loadPatients();
  }

  void _onSearchChanged() {
    final query = _searchController.text.trim();

    if (query.isEmpty) {
      _loadPatients();
    } else {
      _searchPatients(query);
    }
  }

  Future<void> _searchPatients(String query) async {
    final patients = await _patientRepository.searchPatients(query);

    if (!mounted) return;

    setState(() {
      _patients = patients;
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadPatients() async {
    setState(() {
      _isLoading = true;
    });

    final patients = await _patientRepository.getAllPatients();

    if (!mounted) return;

    setState(() {
      _patients = patients;
      _isLoading = false;
    });
  }

  Future<void> _showAddPatientDialog() async {
    final nameController = TextEditingController();
    final phoneController = TextEditingController();
    final ageController = TextEditingController();
    final bloodGroupController = TextEditingController();
    final otherContactController = TextEditingController();
    final addressController = TextEditingController();

    final formKey = GlobalKey<FormState>();

    final result = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Add Patient'),
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

                final patientId =
                    'patient-${DateTime.now().microsecondsSinceEpoch}';

                await _patientRepository.createPatient(
                  id: patientId,
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
              child: const Text('Save Patient'),
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
      await _loadPatients();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: WisteriaColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // ── Top bar ──
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Row(
                children: [
                  const WisteriaBackButton(),
                  const Spacer(),
                  Text(
                    '${_patients.length} patient${_patients.length == 1 ? '' : 's'}',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: WisteriaColors.textMuted,
                    ),
                  ),
                ],
              ),
            ),

            // ── Header + Search ──
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: WisteriaColors.primary.withValues(alpha: 0.10),
                          borderRadius: BorderRadius.circular(
                            WisteriaRadius.md,
                          ),
                          border: Border.all(
                            color: WisteriaColors.primary.withValues(
                              alpha: 0.15,
                            ),
                          ),
                        ),
                        child: const Icon(
                          Icons.people_rounded,
                          color: WisteriaColors.primary,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 16),
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Patients',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w700,
                              color: WisteriaColors.textPrimary,
                              letterSpacing: -0.2,
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'Manage patient records',
                            style: TextStyle(
                              fontSize: 13,
                              color: WisteriaColors.textMuted,
                            ),
                          ),
                        ],
                      ),
                      const Spacer(),
                      // Add button
                      _AddPatientButton(onTap: _showAddPatientDialog),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // Search bar
                  TextField(
                    controller: _searchController,
                    style: const TextStyle(
                      color: WisteriaColors.textPrimary,
                      fontSize: 14,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Search patients by name or phone...',
                      prefixIcon: const Icon(
                        Icons.search_rounded,
                        color: WisteriaColors.textMuted,
                        size: 20,
                      ),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              onPressed: () {
                                _searchController.clear();
                              },
                              icon: const Icon(
                                Icons.clear_rounded,
                                size: 18,
                                color: WisteriaColors.textMuted,
                              ),
                            )
                          : null,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // ── Patient list ──
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: WisteriaColors.primary,
                      ),
                    )
                  : _patients.isEmpty
                  ? _buildEmptyState(
                      message: _searchController.text.isEmpty
                          ? 'No patients yet'
                          : 'No patients found',
                    )
                  : _buildPatientList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState({required String message}) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: WisteriaColors.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(WisteriaRadius.xl),
              border: Border.all(
                color: WisteriaColors.primary.withValues(alpha: 0.12),
              ),
            ),
            child: Icon(
              Icons.people_outline_rounded,
              size: 32,
              color: WisteriaColors.primary.withValues(alpha: 0.5),
            ),
          ),

          const SizedBox(height: 20),

          Text(
            message,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: WisteriaColors.textSecondary,
            ),
          ),

          const SizedBox(height: 8),

          const Text(
            'Add your first patient to get started.',
            style: TextStyle(fontSize: 13, color: WisteriaColors.textMuted),
          ),

          const SizedBox(height: 24),

          FilledButton.icon(
            onPressed: _showAddPatientDialog,
            icon: const Icon(Icons.person_add_rounded, size: 18),
            label: const Text('Add Patient'),
          ),
        ],
      ),
    );
  }

  Widget _buildPatientList() {
    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      itemCount: _patients.length,
      separatorBuilder: (_, _) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final patient = _patients[index];

        return _PatientListItem(
          patient: patient,
          onTap: () async {
            final deleted = await Navigator.push<bool>(
              context,
              PageRouteBuilder(
                pageBuilder: (context, animation, secondaryAnimation) =>
                    PatientDetailsPage(
                      database: widget.database,
                      patientId: patient.id,
                    ),
                transitionsBuilder:
                    (context, animation, secondaryAnimation, child) {
                      return FadeTransition(opacity: animation, child: child);
                    },
                transitionDuration: const Duration(milliseconds: 200),
              ),
            );

            if (deleted == true) {
              await _loadPatients();
            }
          },
        );
      },
    );
  }
}

/// Styled patient list item with hover effects.
class _PatientListItem extends StatefulWidget {
  final Patient patient;
  final VoidCallback onTap;

  const _PatientListItem({required this.patient, required this.onTap});

  @override
  State<_PatientListItem> createState() => _PatientListItemState();
}

class _PatientListItemState extends State<_PatientListItem> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final patient = widget.patient;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          decoration: BoxDecoration(
            color: _isHovered
                ? WisteriaColors.surfaceContainer
                : WisteriaColors.surfaceLow,
            borderRadius: BorderRadius.circular(WisteriaRadius.md),
            border: Border.all(
              color: _isHovered
                  ? WisteriaColors.primary.withValues(alpha: 0.25)
                  : WisteriaColors.border,
            ),
          ),
          child: Row(
            children: [
              // Avatar
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: WisteriaColors.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(WisteriaRadius.md),
                ),
                child: Center(
                  child: Text(
                    patient.name.isNotEmpty
                        ? patient.name[0].toUpperCase()
                        : '?',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: WisteriaColors.primary,
                    ),
                  ),
                ),
              ),

              const SizedBox(width: 14),

              // Name + info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      patient.name,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: WisteriaColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      [
                        if (patient.age != null) 'Age: ${patient.age}',
                        if (patient.bloodGroup != null)
                          'Blood: ${patient.bloodGroup}',
                        if (patient.phoneNumber != null) patient.phoneNumber!,
                      ].join(' • '),
                      style: const TextStyle(
                        fontSize: 12,
                        color: WisteriaColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),

              // Arrow
              Icon(
                Icons.chevron_right_rounded,
                size: 20,
                color: _isHovered
                    ? WisteriaColors.primary
                    : WisteriaColors.textMuted,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Styled Add Patient button.
class _AddPatientButton extends StatefulWidget {
  final VoidCallback onTap;

  const _AddPatientButton({required this.onTap});

  @override
  State<_AddPatientButton> createState() => _AddPatientButtonState();
}

class _AddPatientButtonState extends State<_AddPatientButton> {
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
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
          decoration: BoxDecoration(
            color: _isHovered
                ? WisteriaColors.primaryMuted
                : WisteriaColors.primaryMuted.withValues(alpha: 0.9),
            borderRadius: BorderRadius.circular(WisteriaRadius.md),
            boxShadow: _isHovered
                ? WisteriaElevation.accentGlow(WisteriaColors.primary)
                : [],
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.person_add_rounded,
                size: 16,
                color: WisteriaColors.textOnPrimary,
              ),
              SizedBox(width: 8),
              Text(
                'Add Patient',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: WisteriaColors.textOnPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
