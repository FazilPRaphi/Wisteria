import 'package:flutter/material.dart';

import '../../core/database/database.dart';
import '../../core/database/repositories/doctor_repository.dart';
import '../../core/theme/wisteria_theme.dart';
import '../shared/wisteria_back_button.dart';

class DoctorProfilePage extends StatefulWidget {
  final WisteriaDatabase database;

  const DoctorProfilePage({
    super.key,
    required this.database,
  });

  @override
  State<DoctorProfilePage> createState() =>
      _DoctorProfilePageState();
}

class _DoctorProfilePageState
    extends State<DoctorProfilePage> {
  late final DoctorRepository _doctorRepository;

  final _formKey = GlobalKey<FormState>();

  final _doctorNameController = TextEditingController();
  final _specializationController = TextEditingController();
  final _clinicNameController = TextEditingController();
  final _clinicAddressController = TextEditingController();
  final _clinicPhoneController = TextEditingController();
  final _signatureController = TextEditingController();

  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();

    _doctorRepository = DoctorRepository(widget.database);

    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final profile = await _doctorRepository.getProfile();

    if (!mounted) return;

    if (profile != null) {
      _doctorNameController.text = profile.doctorName;
      _specializationController.text =
          profile.specialization ?? '';
      _clinicNameController.text =
          profile.clinicName ?? '';
      _clinicAddressController.text =
          profile.clinicAddress ?? '';
      _clinicPhoneController.text =
          profile.clinicPhoneNumber ?? '';
      _signatureController.text =
          profile.signature ?? '';
    }

    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      await _doctorRepository.saveProfile(
        id: 'local-doctor',
        doctorName: _doctorNameController.text.trim(),
        specialization:
            _optionalValue(_specializationController),
        clinicName:
            _optionalValue(_clinicNameController),
        clinicAddress:
            _optionalValue(_clinicAddressController),
        clinicPhoneNumber:
            _optionalValue(_clinicPhoneController),
        signature:
            _optionalValue(_signatureController),
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Doctor profile saved'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  String? _optionalValue(
    TextEditingController controller,
  ) {
    final value = controller.text.trim();

    return value.isEmpty ? null : value;
  }

  @override
  void dispose() {
    _doctorNameController.dispose();
    _specializationController.dispose();
    _clinicNameController.dispose();
    _clinicAddressController.dispose();
    _clinicPhoneController.dispose();
    _signatureController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: WisteriaColors.background,
        body: Center(
          child: CircularProgressIndicator(
            color: WisteriaColors.primary,
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: WisteriaColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // ── Top bar with back button ──
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 24,
                vertical: 16,
              ),
              child: Row(
                children: [
                  const WisteriaBackButton(),
                  const Spacer(),
                  Text(
                    'Doctor Profile',
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
                    constraints: const BoxConstraints(
                      maxWidth: 700,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // ── Header ──
                        Row(
                          children: [
                            Container(
                              width: 52,
                              height: 52,
                              decoration: BoxDecoration(
                                color: WisteriaColors.tertiary
                                    .withValues(alpha: 0.10),
                                borderRadius: BorderRadius.circular(
                                  WisteriaRadius.lg,
                                ),
                                border: Border.all(
                                  color: WisteriaColors.tertiary
                                      .withValues(alpha: 0.15),
                                ),
                              ),
                              child: const Icon(
                                Icons.person_rounded,
                                color: WisteriaColors.tertiary,
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 18),
                            const Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Doctor Information',
                                  style: TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.w700,
                                    color: WisteriaColors.textPrimary,
                                    letterSpacing: -0.2,
                                  ),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  'This information will be used in patient reports.',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: WisteriaColors.textMuted,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),

                        const SizedBox(height: 32),

                        // ── Form card ──
                        Container(
                          padding: const EdgeInsets.all(28),
                          decoration: BoxDecoration(
                            color: WisteriaColors.surfaceLow,
                            borderRadius: BorderRadius.circular(
                              WisteriaRadius.lg,
                            ),
                            border: Border.all(
                              color: WisteriaColors.border,
                            ),
                          ),
                          child: Form(
                            key: _formKey,
                            child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [
                                _buildSectionLabel('Personal'),

                                const SizedBox(height: 16),

                                TextFormField(
                                  controller: _doctorNameController,
                                  style: const TextStyle(
                                    color: WisteriaColors.textPrimary,
                                  ),
                                  decoration: const InputDecoration(
                                    labelText: 'Doctor Name',
                                  ),
                                  validator: (value) {
                                    if (value == null ||
                                        value.trim().isEmpty) {
                                      return 'Doctor name is required';
                                    }

                                    return null;
                                  },
                                ),

                                const SizedBox(height: 20),

                                TextFormField(
                                  controller:
                                      _specializationController,
                                  style: const TextStyle(
                                    color: WisteriaColors.textPrimary,
                                  ),
                                  decoration: const InputDecoration(
                                    labelText: 'Specialization',
                                  ),
                                ),

                                const SizedBox(height: 32),

                                _buildSectionLabel('Clinic Details'),

                                const SizedBox(height: 16),

                                TextFormField(
                                  controller: _clinicNameController,
                                  style: const TextStyle(
                                    color: WisteriaColors.textPrimary,
                                  ),
                                  decoration: const InputDecoration(
                                    labelText: 'Clinic Name',
                                  ),
                                ),

                                const SizedBox(height: 20),

                                TextFormField(
                                  controller:
                                      _clinicAddressController,
                                  maxLines: 3,
                                  style: const TextStyle(
                                    color: WisteriaColors.textPrimary,
                                  ),
                                  decoration: const InputDecoration(
                                    labelText: 'Clinic Address',
                                    alignLabelWithHint: true,
                                  ),
                                ),

                                const SizedBox(height: 20),

                                TextFormField(
                                  controller:
                                      _clinicPhoneController,
                                  keyboardType: TextInputType.phone,
                                  style: const TextStyle(
                                    color: WisteriaColors.textPrimary,
                                  ),
                                  decoration: const InputDecoration(
                                    labelText: 'Clinic Phone Number',
                                  ),
                                ),

                                const SizedBox(height: 32),

                                _buildSectionLabel('Signature'),

                                const SizedBox(height: 16),

                                TextFormField(
                                  controller: _signatureController,
                                  maxLines: 2,
                                  style: const TextStyle(
                                    color: WisteriaColors.textPrimary,
                                  ),
                                  decoration: const InputDecoration(
                                    labelText: 'Signature',
                                    hintText:
                                        'Signature information / reference',
                                    alignLabelWithHint: true,
                                  ),
                                ),

                                const SizedBox(height: 32),

                                SizedBox(
                                  width: double.infinity,
                                  child: FilledButton.icon(
                                    onPressed:
                                        _isSaving ? null : _saveProfile,
                                    icon: _isSaving
                                        ? const SizedBox(
                                            width: 18,
                                            height: 18,
                                            child:
                                                CircularProgressIndicator(
                                              strokeWidth: 2,
                                              color: WisteriaColors
                                                  .textOnPrimary,
                                            ),
                                          )
                                        : const Icon(Icons.save_rounded),
                                    label: Text(
                                      _isSaving
                                          ? 'Saving...'
                                          : 'Save Doctor Profile',
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
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

  Widget _buildSectionLabel(String label) {
    return Row(
      children: [
        Container(
          width: 3,
          height: 14,
          decoration: BoxDecoration(
            color: WisteriaColors.primary.withValues(alpha: 0.6),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 10),
        Text(
          label.toUpperCase(),
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: WisteriaColors.textMuted,
            letterSpacing: 1.2,
          ),
        ),
      ],
    );
  }
}