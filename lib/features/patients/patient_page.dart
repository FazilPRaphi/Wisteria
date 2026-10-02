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

  // null => show landing; false => show registry
  bool _showRegistry = false;

  List<Patient> _patients = [];
  bool _isLoading = true;
  String? _error;

  final TextEditingController _searchController = TextEditingController();
  String? _bloodGroupFilter;

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
    try {
      final patients = await _patientRepository.searchPatients(query);
      if (!mounted) return;
      setState(() {
        _patients = _applyFilter(patients);
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = 'Search failed: $e');
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadPatients() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final patients = await _patientRepository.getAllPatients();
      if (!mounted) return;
      setState(() {
        _patients = _applyFilter(patients);
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Failed to load patients: $e';
        _isLoading = false;
      });
    }
  }

  List<Patient> _applyFilter(List<Patient> patients) {
    if (_bloodGroupFilter == null || _bloodGroupFilter!.isEmpty) {
      return patients;
    }
    return patients
        .where(
          (p) =>
              p.bloodGroup != null &&
              p.bloodGroup!.toLowerCase() == _bloodGroupFilter!.toLowerCase(),
        )
        .toList();
  }

  void _setBloodGroupFilter(String? filter) {
    setState(() {
      _bloodGroupFilter = filter;
    });
    if (_searchController.text.trim().isEmpty) {
      _loadPatients();
    } else {
      _searchPatients(_searchController.text.trim());
    }
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
          title: const Text('New Patient Registration'),
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
                      decoration: const InputDecoration(
                        labelText: 'Patient Name',
                      ),
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
                        labelText: 'Contact Address',
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
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () async {
                if (!formKey.currentState!.validate()) return;

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
              child: const Text('Register Patient'),
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

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Patient registered successfully')),
        );
      }
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
                  WisteriaBackButton(
                    label: _showRegistry ? 'Patients' : 'Workspace',
                    onTap: () {
                      if (_showRegistry) {
                        setState(() => _showRegistry = false);
                      } else {
                        Navigator.of(context).pop();
                      }
                    },
                  ),
                  const Spacer(),
                  if (_showRegistry)
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

            // ── Content ──
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                child: _showRegistry
                    ? _buildRegistryView()
                    : _buildLandingView(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Two-card landing: New Patient + Registered Patients
  Widget _buildLandingView() {
    return Padding(
      key: const ValueKey('landing'),
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 900),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Title ──
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: WisteriaColors.primary.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(WisteriaRadius.md),
                      border: Border.all(
                        color: WisteriaColors.primary.withValues(alpha: 0.15),
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
                        'Patient registration and records',
                        style: TextStyle(
                          fontSize: 13,
                          color: WisteriaColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 40),

              // ── Two cards ──
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final isNarrow = constraints.maxWidth < 560;
                    if (isNarrow) {
                      return Column(
                        children: [
                          Expanded(
                            child: _LandingCard(
                              title: 'New Patient',
                              subtitle: 'Register a new patient record',
                              icon: Icons.person_add_rounded,
                              accentColor: WisteriaColors.primary,
                              onTap: _showAddPatientDialog,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Expanded(
                            child: _LandingCard(
                              title: 'Registered Patients',
                              subtitle: 'Browse and search patient directory',
                              icon: Icons.folder_shared_rounded,
                              accentColor: WisteriaColors.tertiary,
                              onTap: () => setState(() => _showRegistry = true),
                            ),
                          ),
                        ],
                      );
                    }
                    return Row(
                      children: [
                        Expanded(
                          child: _LandingCard(
                            title: 'New Patient',
                            subtitle: 'Register a new patient record',
                            icon: Icons.person_add_rounded,
                            accentColor: WisteriaColors.primary,
                            onTap: _showAddPatientDialog,
                          ),
                        ),
                        const SizedBox(width: 24),
                        Expanded(
                          child: _LandingCard(
                            title: 'Registered Patients',
                            subtitle: 'Browse and search patient directory',
                            icon: Icons.folder_shared_rounded,
                            accentColor: WisteriaColors.tertiary,
                            onTap: () => setState(() => _showRegistry = true),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  /// Full patient registry with card grid, search, and filters.
  Widget _buildRegistryView() {
    return Padding(
      key: const ValueKey('registry'),
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          // ── Header + Search ──
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1200),
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
                        borderRadius: BorderRadius.circular(WisteriaRadius.md),
                        border: Border.all(
                          color: WisteriaColors.primary.withValues(alpha: 0.15),
                        ),
                      ),
                      child: const Icon(
                        Icons.folder_shared_rounded,
                        color: WisteriaColors.primary,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 16),
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Registered Patients',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                            color: WisteriaColors.textPrimary,
                            letterSpacing: -0.2,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Search and manage patient records',
                          style: TextStyle(
                            fontSize: 13,
                            color: WisteriaColors.textMuted,
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    _AddPatientButton(onTap: _showAddPatientDialog),
                  ],
                ),

                const SizedBox(height: 20),

                // ── Search bar and filter ──
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        style: const TextStyle(
                          color: WisteriaColors.textPrimary,
                          fontSize: 14,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Search by name, ID, or phone number...',
                          prefixIcon: const Icon(
                            Icons.search_rounded,
                            color: WisteriaColors.textMuted,
                            size: 20,
                          ),
                          suffixIcon: _searchController.text.isNotEmpty
                              ? IconButton(
                                  onPressed: () => _searchController.clear(),
                                  icon: const Icon(
                                    Icons.clear_rounded,
                                    size: 18,
                                    color: WisteriaColors.textMuted,
                                  ),
                                )
                              : null,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Blood group filter
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      decoration: BoxDecoration(
                        color: WisteriaColors.surfaceLowest,
                        borderRadius: BorderRadius.circular(WisteriaRadius.md),
                        border: Border.all(color: WisteriaColors.border),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _bloodGroupFilter,
                          hint: const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 8),
                            child: Text(
                              'Blood Group',
                              style: TextStyle(
                                fontSize: 13,
                                color: WisteriaColors.textMuted,
                              ),
                            ),
                          ),
                          icon: const Icon(
                            Icons.arrow_drop_down,
                            color: WisteriaColors.textMuted,
                          ),
                          dropdownColor: WisteriaColors.surfaceContainer,
                          items: [
                            const DropdownMenuItem(
                              value: '',
                              child: Text('All'),
                            ),
                            ...[
                              'A+',
                              'A-',
                              'B+',
                              'B-',
                              'AB+',
                              'AB-',
                              'O+',
                              'O-',
                            ].map(
                              (bg) =>
                                  DropdownMenuItem(value: bg, child: Text(bg)),
                            ),
                          ],
                          onChanged: (value) {
                            _setBloodGroupFilter(value == '' ? null : value);
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // ── Patient grid ──
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                      color: WisteriaColors.primary,
                    ),
                  )
                : _error != null
                ? _buildErrorState()
                : _patients.isEmpty
                ? _buildEmptyState(
                    message: _searchController.text.isEmpty
                        ? 'No patients yet'
                        : 'No patients found',
                  )
                : _buildPatientGrid(),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.error_outline_rounded,
            size: 48,
            color: WisteriaColors.error,
          ),
          const SizedBox(height: 16),
          Text(
            _error ?? 'An error occurred',
            style: const TextStyle(
              fontSize: 14,
              color: WisteriaColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          FilledButton.icon(
            onPressed: _loadPatients,
            icon: const Icon(Icons.refresh_rounded, size: 18),
            label: const Text('Retry'),
          ),
        ],
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

  Widget _buildPatientGrid() {
    return LayoutBuilder(
      builder: (context, constraints) {
        int crossAxisCount;
        if (constraints.maxWidth >= 1100) {
          crossAxisCount = 4;
        } else if (constraints.maxWidth >= 800) {
          crossAxisCount = 3;
        } else if (constraints.maxWidth >= 500) {
          crossAxisCount = 2;
        } else {
          crossAxisCount = 1;
        }

        return GridView.builder(
          padding: const EdgeInsets.only(bottom: 32),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 1.1,
          ),
          itemCount: _patients.length,
          itemBuilder: (context, index) {
            final patient = _patients[index];
            return _PatientCard(
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
                          return SlideTransition(
                            position:
                                Tween<Offset>(
                                  begin: const Offset(0.03, 0),
                                  end: Offset.zero,
                                ).animate(
                                  CurvedAnimation(
                                    parent: animation,
                                    curve: Curves.easeOutCubic,
                                  ),
                                ),
                            child: FadeTransition(
                              opacity: animation,
                              child: child,
                            ),
                          );
                        },
                    transitionDuration: const Duration(milliseconds: 250),
                    reverseTransitionDuration: const Duration(
                      milliseconds: 200,
                    ),
                  ),
                );

                if (deleted == true) {
                  await _loadPatients();
                }
              },
            );
          },
        );
      },
    );
  }
}

/// Patient card for the 4-column grid.
class _PatientCard extends StatefulWidget {
  final Patient patient;
  final VoidCallback onTap;

  const _PatientCard({required this.patient, required this.onTap});

  @override
  State<_PatientCard> createState() => _PatientCardState();
}

class _PatientCardState extends State<_PatientCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final patient = widget.patient;
    final initials = patient.name.isNotEmpty
        ? patient.name
              .split(' ')
              .map((w) => w.isNotEmpty ? w[0] : '')
              .take(2)
              .join()
              .toUpperCase()
        : '?';

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: WisteriaColors.cardGradient,
            borderRadius: BorderRadius.circular(WisteriaRadius.lg),
            border: Border.all(
              color: _isHovered
                  ? WisteriaColors.primary.withValues(alpha: 0.4)
                  : WisteriaColors.border,
            ),
            boxShadow: _isHovered ? WisteriaElevation.low : [],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Avatar ──
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: WisteriaColors.primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(WisteriaRadius.md),
                    ),
                    child: Center(
                      child: Text(
                        initials,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: WisteriaColors.primary,
                        ),
                      ),
                    ),
                  ),
                  const Spacer(),
                  Icon(
                    Icons.chevron_right_rounded,
                    size: 20,
                    color: _isHovered
                        ? WisteriaColors.primary
                        : WisteriaColors.textMuted,
                  ),
                ],
              ),

              const Spacer(),

              // ── Name ──
              Text(
                patient.name,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: WisteriaColors.textPrimary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),

              const SizedBox(height: 4),

              // ── ID ──
              Text(
                patient.id,
                style: const TextStyle(
                  fontSize: 11,
                  color: WisteriaColors.textMuted,
                  fontFamily: 'monospace',
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),

              const SizedBox(height: 8),

              // ── Details ──
              Text(
                [
                  if (patient.age != null) 'Age ${patient.age}',
                  if (patient.bloodGroup != null) patient.bloodGroup!,
                ].join(' · '),
                style: const TextStyle(
                  fontSize: 12,
                  color: WisteriaColors.textSecondary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Landing card for patient workspace.
class _LandingCard extends StatefulWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color accentColor;
  final VoidCallback onTap;

  const _LandingCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.accentColor,
    required this.onTap,
  });

  @override
  State<_LandingCard> createState() => _LandingCardState();
}

class _LandingCardState extends State<_LandingCard>
    with SingleTickerProviderStateMixin {
  bool _isHovered = false;
  late final AnimationController _controller;
  late final Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 220),
      vsync: this,
    );
    _animation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) {
        setState(() => _isHovered = true);
        _controller.forward();
      },
      onExit: (_) {
        setState(() => _isHovered = false);
        _controller.reverse();
      },
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedBuilder(
          animation: _animation,
          builder: (context, child) {
            final t = _animation.value;
            return Transform.translate(
              offset: Offset(0, -2 * t),
              child: Container(
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      widget.accentColor.withValues(alpha: 0.08 + (0.04 * t)),
                      WisteriaColors.surfaceLow,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(WisteriaRadius.xl),
                  border: Border.all(
                    color: _isHovered
                        ? widget.accentColor.withValues(alpha: 0.45)
                        : widget.accentColor.withValues(alpha: 0.15),
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      blurRadius: 10 + (16 * t),
                      spreadRadius: -3,
                      offset: Offset(0, 3 + (6 * t)),
                      color: Colors.black.withValues(alpha: 0.18 + (0.08 * t)),
                    ),
                    if (_isHovered)
                      BoxShadow(
                        blurRadius: 24,
                        spreadRadius: -6,
                        offset: const Offset(0, 8),
                        color: widget.accentColor.withValues(alpha: 0.10),
                      ),
                  ],
                ),
                child: child,
              ),
            );
          },
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: _isHovered
                      ? widget.accentColor.withValues(alpha: 0.16)
                      : widget.accentColor.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(WisteriaRadius.md),
                  border: Border.all(
                    color: _isHovered
                        ? widget.accentColor.withValues(alpha: 0.3)
                        : Colors.transparent,
                  ),
                ),
                child: Icon(
                  widget.icon,
                  size: 26,
                  color: _isHovered
                      ? widget.accentColor
                      : widget.accentColor.withValues(alpha: 0.8),
                ),
              ),
              const Spacer(),
              Text(
                widget.title,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: WisteriaColors.textPrimary,
                  letterSpacing: -0.1,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                widget.subtitle,
                style: const TextStyle(
                  fontSize: 13,
                  color: WisteriaColors.textSecondary,
                  height: 1.4,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Text(
                    'Open',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: widget.accentColor,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Icon(
                    Icons.arrow_forward_rounded,
                    size: 16,
                    color: widget.accentColor,
                  ),
                ],
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
                'New Patient',
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
