import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../../core/database/database.dart';
import '../../core/database/repositories/doctor_repository.dart';
import '../../core/storage/doctor_document_storage.dart';
import '../../core/theme/wisteria_theme.dart';
import '../shared/wisteria_back_button.dart';

class DoctorProfilePage extends StatefulWidget {
  final WisteriaDatabase database;

  const DoctorProfilePage({super.key, required this.database});

  @override
  State<DoctorProfilePage> createState() => _DoctorProfilePageState();
}

class _DoctorProfilePageState extends State<DoctorProfilePage> {
  late final DoctorRepository _doctorRepository;
  late final DoctorDocumentStorage _documentStorage;

  final _formKey = GlobalKey<FormState>();

  final _doctorNameController = TextEditingController();
  final _specializationController = TextEditingController();
  final _clinicNameController = TextEditingController();
  final _clinicAddressController = TextEditingController();
  final _clinicPhoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _signatureController = TextEditingController();

  String? _documentPath;
  String? _documentFileName;

  bool _isLoading = true;
  bool _isSaving = false;
  bool _isEditing = false;
  bool _isPickingDocument = false;

  @override
  void initState() {
    super.initState();

    _doctorRepository = DoctorRepository(widget.database);
    _documentStorage = DoctorDocumentStorage();

    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final profile = await _doctorRepository.getProfile();

    if (!mounted) return;

    if (profile != null) {
      _doctorNameController.text = profile.doctorName;

      _specializationController.text = profile.specialization ?? '';

      _clinicNameController.text = profile.clinicName ?? '';

      _clinicAddressController.text = profile.clinicAddress ?? '';

      _clinicPhoneController.text = profile.clinicPhoneNumber ?? '';

      _emailController.text = profile.email ?? '';

      _signatureController.text = profile.signature ?? '';

      _documentPath = profile.documentPath;

      _documentFileName = profile.documentFileName;
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
        specialization: _optionalValue(_specializationController),
        clinicName: _optionalValue(_clinicNameController),
        clinicAddress: _optionalValue(_clinicAddressController),
        clinicPhoneNumber: _optionalValue(_clinicPhoneController),
        email: _optionalValue(_emailController),
        signature: _optionalValue(_signatureController),
        documentPath: _documentPath,
        documentFileName: _documentFileName,
      );

      if (!mounted) return;

      setState(() {
        _isEditing = false;
        _isSaving = false;
      });

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Doctor profile saved')));
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isSaving = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save doctor profile: $e')),
      );
    }
  }

  Future<void> _pickDoctorDocument() async {
    setState(() {
      _isPickingDocument = true;
    });

    try {
      final selectedFile = await FilePicker.pickFile(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
      );

      if (selectedFile == null || selectedFile.path == null) {
        return;
      }

      final savedPath = await _documentStorage.saveDocument(selectedFile.path!);

      if (!mounted) return;

      setState(() {
        _documentPath = savedPath;
        _documentFileName = selectedFile.name;
      });
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to add document: $e')));
    } finally {
      if (mounted) {
        setState(() {
          _isPickingDocument = false;
        });
      }
    }
  }

  String? _optionalValue(TextEditingController controller) {
    final value = controller.text.trim();

    return value.isEmpty ? null : value;
  }

  void _cancelEditing() {
    _loadProfile();

    setState(() {
      _isEditing = false;
    });
  }

  @override
  void dispose() {
    _doctorNameController.dispose();
    _specializationController.dispose();
    _clinicNameController.dispose();
    _clinicAddressController.dispose();
    _clinicPhoneController.dispose();
    _emailController.dispose();
    _signatureController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: const Center(
          child: CircularProgressIndicator(color: WisteriaColors.primary),
        ),
      );
    }

    final colors = WisteriaColors.of(context);

    return Scaffold(
      backgroundColor: colors.background,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Row(
                children: [
                  const WisteriaBackButton(),
                  const Spacer(),
                  const Text(
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

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 8,
                ),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 700),
                    child: _isEditing
                        ? _buildEditProfile()
                        : _buildProfileView(),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileView() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHeader(),

        const SizedBox(height: 32),

        _buildProfileCard(),

        const SizedBox(height: 20),

        _buildDocumentCard(),

        const SizedBox(height: 32),

        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: () {
              setState(() {
                _isEditing = true;
              });
            },
            icon: const Icon(Icons.edit_outlined),
            label: const Text('Edit Profile'),
          ),
        ),

        const SizedBox(height: 48),
      ],
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            color: WisteriaColors.tertiary.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(WisteriaRadius.lg),
            border: Border.all(
              color: WisteriaColors.tertiary.withValues(alpha: 0.15),
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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Doctor Profile',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: WisteriaColors.textPrimary,
                letterSpacing: -0.2,
              ),
            ),
            SizedBox(height: 4),
            Text(
              'Doctor information and documents',
              style: TextStyle(fontSize: 13, color: WisteriaColors.textMuted),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildProfileCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: WisteriaColors.surfaceLow,
        borderRadius: BorderRadius.circular(WisteriaRadius.lg),
        border: Border.all(color: WisteriaColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionLabel('Doctor Information'),

          const SizedBox(height: 20),

          _buildProfileField('Doctor Name', _doctorNameController.text),

          _buildProfileField('Specialization', _specializationController.text),

          _buildProfileField('Email', _emailController.text),

          const SizedBox(height: 12),

          _buildSectionLabel('Clinic Details'),

          const SizedBox(height: 20),

          _buildProfileField('Clinic Name', _clinicNameController.text),

          _buildProfileField('Clinic Address', _clinicAddressController.text),

          _buildProfileField(
            'Clinic Phone Number',
            _clinicPhoneController.text,
          ),

          const SizedBox(height: 12),

          _buildSectionLabel('Signature'),

          const SizedBox(height: 20),

          _buildProfileField('Signature', _signatureController.text),
        ],
      ),
    );
  }

  Widget _buildDocumentCard() {
    final hasDocument = _documentPath != null && _documentPath!.isNotEmpty;

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
          _buildSectionLabel('Doctor Document'),

          const SizedBox(height: 20),

          if (hasDocument)
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: WisteriaColors.primary.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(WisteriaRadius.md),
                  ),
                  child: const Icon(
                    Icons.picture_as_pdf_outlined,
                    color: WisteriaColors.primary,
                  ),
                ),

                const SizedBox(width: 14),

                Expanded(
                  child: Text(
                    _documentFileName ?? 'Doctor document',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: WisteriaColors.textPrimary,
                    ),
                  ),
                ),
              ],
            )
          else
            const Text(
              'No doctor document added.',
              style: TextStyle(fontSize: 13, color: WisteriaColors.textMuted),
            ),
        ],
      ),
    );
  }

  Widget _buildEditProfile() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHeader(),

        const SizedBox(height: 32),

        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            color: WisteriaColors.surfaceLow,
            borderRadius: BorderRadius.circular(WisteriaRadius.lg),
            border: Border.all(color: WisteriaColors.border),
          ),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSectionLabel('Doctor Information'),

                const SizedBox(height: 16),

                TextFormField(
                  controller: _doctorNameController,
                  style: const TextStyle(color: WisteriaColors.textPrimary),
                  decoration: const InputDecoration(labelText: 'Doctor Name'),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Doctor name is required';
                    }

                    return null;
                  },
                ),

                const SizedBox(height: 20),

                TextFormField(
                  controller: _specializationController,
                  style: const TextStyle(color: WisteriaColors.textPrimary),
                  decoration: const InputDecoration(
                    labelText: 'Specialization',
                  ),
                ),

                const SizedBox(height: 20),

                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  style: const TextStyle(color: WisteriaColors.textPrimary),
                  decoration: const InputDecoration(labelText: 'Email'),
                ),

                const SizedBox(height: 32),

                _buildSectionLabel('Clinic Details'),

                const SizedBox(height: 16),

                TextFormField(
                  controller: _clinicNameController,
                  style: const TextStyle(color: WisteriaColors.textPrimary),
                  decoration: const InputDecoration(labelText: 'Clinic Name'),
                ),

                const SizedBox(height: 20),

                TextFormField(
                  controller: _clinicAddressController,
                  maxLines: 3,
                  style: const TextStyle(color: WisteriaColors.textPrimary),
                  decoration: const InputDecoration(
                    labelText: 'Clinic Address',
                    alignLabelWithHint: true,
                  ),
                ),

                const SizedBox(height: 20),

                TextFormField(
                  controller: _clinicPhoneController,
                  keyboardType: TextInputType.phone,
                  style: const TextStyle(color: WisteriaColors.textPrimary),
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
                  style: const TextStyle(color: WisteriaColors.textPrimary),
                  decoration: const InputDecoration(
                    labelText: 'Signature',
                    hintText: 'Signature information / reference',
                    alignLabelWithHint: true,
                  ),
                ),

                const SizedBox(height: 32),

                _buildSectionLabel('Doctor Document'),

                const SizedBox(height: 16),

                if (_documentFileName != null)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(WisteriaRadius.md),
                      border: Border.all(color: WisteriaColors.border),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.picture_as_pdf_outlined,
                          color: WisteriaColors.primary,
                        ),

                        const SizedBox(width: 12),

                        Expanded(
                          child: Text(
                            _documentFileName!,
                            style: const TextStyle(
                              fontSize: 13,
                              color: WisteriaColors.textPrimary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  const Text(
                    'No PDF selected.',
                    style: TextStyle(
                      fontSize: 13,
                      color: WisteriaColors.textMuted,
                    ),
                  ),

                const SizedBox(height: 14),

                OutlinedButton.icon(
                  onPressed: _isPickingDocument ? null : _pickDoctorDocument,
                  icon: _isPickingDocument
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.upload_file_outlined),
                  label: Text(
                    _isPickingDocument
                        ? 'Selecting...'
                        : _documentFileName == null
                        ? 'Add PDF'
                        : 'Replace PDF',
                  ),
                ),

                const SizedBox(height: 36),

                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _isSaving ? null : _cancelEditing,
                        child: const Text('Cancel'),
                      ),
                    ),

                    const SizedBox(width: 12),

                    Expanded(
                      child: FilledButton.icon(
                        onPressed: _isSaving ? null : _saveProfile,
                        icon: _isSaving
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: WisteriaColors.textOnPrimary,
                                ),
                              )
                            : const Icon(Icons.save_rounded),
                        label: Text(_isSaving ? 'Saving...' : 'Save Changes'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 48),
      ],
    );
  }

  Widget _buildProfileField(String label, String value) {
    final displayValue = value.trim().isEmpty ? 'Not provided' : value.trim();

    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: WisteriaColors.textMuted,
            ),
          ),

          const SizedBox(height: 6),

          Text(
            displayValue,
            style: const TextStyle(
              fontSize: 15,
              color: WisteriaColors.textPrimary,
            ),
          ),
        ],
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
