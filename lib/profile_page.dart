import 'package:flutter/material.dart';

import 'data/account_repository.dart';
import 'models/astro_vitals_user.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({
    required this.user,
    required this.onSave,
    this.embedded = false,
    super.key,
  });

  final AstroVitalsUser user;
  final bool embedded;
  final Future<void> Function(
    AstroVitalsUser currentUser,
    AstroVitalsUser updatedUser,
  )
  onSave;

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _astronautIdController;
  late final TextEditingController _fullNameController;
  late final TextEditingController _emailController;
  late final TextEditingController _dateOfBirthController;
  late final TextEditingController _heightController;
  late final TextEditingController _weightController;

  late AstroVitalsUser _user;
  DateTime? _dateOfBirth;
  String? _gender;
  bool _isEditing = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _user = widget.user;
    _astronautIdController = TextEditingController();
    _fullNameController = TextEditingController();
    _emailController = TextEditingController();
    _dateOfBirthController = TextEditingController();
    _heightController = TextEditingController();
    _weightController = TextEditingController();
    _loadUserIntoForm();
  }

  @override
  void dispose() {
    _astronautIdController.dispose();
    _fullNameController.dispose();
    _emailController.dispose();
    _dateOfBirthController.dispose();
    _heightController.dispose();
    _weightController.dispose();
    super.dispose();
  }

  void _loadUserIntoForm() {
    _astronautIdController.text = _user.astronautId;
    _fullNameController.text = _user.fullName;
    _emailController.text = _user.email;
    _dateOfBirth = _user.dateOfBirth;
    _dateOfBirthController.text = _formatDate(_user.dateOfBirth);
    _heightController.text = _formatMeasurement(_user.heightCm);
    _weightController.text = _formatMeasurement(_user.weightKg);
    _gender = _user.gender;
  }

  void _beginEditing() {
    setState(() {
      _loadUserIntoForm();
      _isEditing = true;
    });
  }

  void _cancelEditing() {
    setState(() {
      _loadUserIntoForm();
      _formKey.currentState?.reset();
      _isEditing = false;
    });
  }

  Future<void> _selectDateOfBirth() async {
    final today = DateUtils.dateOnly(DateTime.now());
    final selectedDate = await showDatePicker(
      context: context,
      initialDate: _dateOfBirth ?? DateTime(today.year - 25),
      firstDate: DateTime(1900),
      lastDate: today,
      helpText: 'Select date of birth',
    );
    if (selectedDate != null) {
      setState(() {
        _dateOfBirth = selectedDate;
        _dateOfBirthController.text = _formatDate(selectedDate);
      });
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final updatedUser = _user.copyWith(
      astronautId: _astronautIdController.text.trim(),
      fullName: _fullNameController.text.trim(),
      email: _emailController.text.trim(),
      dateOfBirth: _dateOfBirth,
      heightCm: double.parse(_heightController.text.trim()),
      weightKg: double.parse(_weightController.text.trim()),
      gender: _gender,
      clearGender: _gender == null,
    );

    setState(() => _isSaving = true);
    try {
      await widget.onSave(_user, updatedUser);
      if (!mounted) return;
      final emailChanged =
          updatedUser.email.trim().toLowerCase() !=
          _user.email.trim().toLowerCase();
      setState(() {
        _user = updatedUser;
        _isEditing = false;
      });
      _showMessage(
        emailChanged
            ? 'Profile updated. Confirm your new email if prompted.'
            : 'Profile updated successfully.',
      );
    } on AccountAlreadyExistsException catch (error) {
      if (mounted) _showMessage('${error.field} is already registered.');
    } on AccountNotFoundException {
      if (mounted) {
        _showMessage('This account is no longer available. Sign in again.');
      }
    } on AccountOperationException catch (error) {
      if (mounted) _showMessage(error.message);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  String? _validateRequired(String? value, String label) {
    if (value == null || value.trim().isEmpty) return 'Enter $label';
    return null;
  }

  String? _validateEmail(String? value) {
    final email = value?.trim() ?? '';
    if (email.isEmpty) return 'Enter your email address';
    if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email)) {
      return 'Enter a valid email address';
    }
    return null;
  }

  String? _validateMeasurement(String? value, String label) {
    final measurement = double.tryParse(value?.trim() ?? '');
    if (measurement == null) return 'Enter $label';
    if (!measurement.isFinite || measurement <= 0) {
      return 'Enter a number greater than 0';
    }
    return null;
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final pageContent = SafeArea(
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 680),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _ProfileHeader(user: _user),
                const SizedBox(height: 20),
                if (_isEditing)
                  Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _ProfileSection(
                          title: 'Identity',
                          children: [
                            _ProfileTextField(
                              key: const ValueKey('profile-astronaut-id'),
                              controller: _astronautIdController,
                              label: 'Astronaut ID',
                              textCapitalization: TextCapitalization.characters,
                              validator: (value) =>
                                  _validateRequired(value, 'your astronaut ID'),
                            ),
                            _ProfileTextField(
                              key: const ValueKey('profile-full-name'),
                              controller: _fullNameController,
                              label: 'Full name',
                              textCapitalization: TextCapitalization.words,
                              validator: (value) =>
                                  _validateRequired(value, 'your full name'),
                            ),
                            _ProfileTextField(
                              key: const ValueKey('profile-email'),
                              controller: _emailController,
                              label: 'Email',
                              keyboardType: TextInputType.emailAddress,
                              validator: _validateEmail,
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        _ProfileSection(
                          title: 'Personal and physical details',
                          children: [
                            TextFormField(
                              key: const ValueKey('profile-date-of-birth'),
                              controller: _dateOfBirthController,
                              readOnly: true,
                              onTap: _selectDateOfBirth,
                              validator: (_) => _dateOfBirth == null
                                  ? 'Select your date of birth'
                                  : null,
                              decoration: const InputDecoration(
                                labelText: 'Date of birth',
                                suffixIcon: Icon(Icons.calendar_today_outlined),
                              ),
                            ),
                            _ProfileTextField(
                              key: const ValueKey('profile-height'),
                              controller: _heightController,
                              label: 'Height (cm)',
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                    decimal: true,
                                  ),
                              validator: (value) =>
                                  _validateMeasurement(value, 'your height'),
                            ),
                            _ProfileTextField(
                              key: const ValueKey('profile-weight'),
                              controller: _weightController,
                              label: 'Current weight (kg)',
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                    decimal: true,
                                  ),
                              validator: (value) =>
                                  _validateMeasurement(value, 'your weight'),
                            ),
                            DropdownButtonFormField<String>(
                              key: const ValueKey('profile-gender'),
                              initialValue: _gender ?? '',
                              decoration: const InputDecoration(
                                labelText: 'Gender (optional)',
                              ),
                              items: const [
                                DropdownMenuItem(
                                  value: '',
                                  child: Text('Not provided'),
                                ),
                                DropdownMenuItem(
                                  value: 'Female',
                                  child: Text('Female'),
                                ),
                                DropdownMenuItem(
                                  value: 'Male',
                                  child: Text('Male'),
                                ),
                                DropdownMenuItem(
                                  value: 'Non-binary',
                                  child: Text('Non-binary'),
                                ),
                                DropdownMenuItem(
                                  value: 'Prefer not to say',
                                  child: Text('Prefer not to say'),
                                ),
                                DropdownMenuItem(
                                  value: 'Other',
                                  child: Text('Other'),
                                ),
                              ],
                              onChanged: (value) {
                                setState(() {
                                  _gender = value == null || value.isEmpty
                                      ? null
                                      : value;
                                });
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        FilledButton(
                          key: const ValueKey('profile-save'),
                          onPressed: _isSaving ? null : _save,
                          style: FilledButton.styleFrom(
                            minimumSize: const Size.fromHeight(52),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: _isSaving
                              ? const SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Text('Save changes'),
                        ),
                        if (widget.embedded) ...[
                          const SizedBox(height: 8),
                          TextButton(
                            key: const ValueKey('profile-cancel'),
                            onPressed: _isSaving ? null : _cancelEditing,
                            child: const Text('Cancel'),
                          ),
                        ],
                      ],
                    ),
                  )
                else ...[
                  _ProfileSection(
                    title: 'Identity',
                    children: [
                      _ProfileDetail(
                        label: 'Astronaut ID',
                        value: _user.astronautId,
                      ),
                      _ProfileDetail(label: 'Full name', value: _user.fullName),
                      _ProfileDetail(label: 'Email', value: _user.email),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _ProfileSection(
                    title: 'Personal and physical details',
                    children: [
                      _ProfileDetail(
                        label: 'Date of birth',
                        value: _formatDate(_user.dateOfBirth),
                      ),
                      _ProfileDetail(
                        label: 'Height',
                        value: '${_formatMeasurement(_user.heightCm)} cm',
                      ),
                      _ProfileDetail(
                        label: 'Current weight',
                        value: '${_formatMeasurement(_user.weightKg)} kg',
                      ),
                      _ProfileDetail(
                        label: 'Gender',
                        value: _user.gender ?? 'Not provided',
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  OutlinedButton.icon(
                    key: const ValueKey('profile-edit-button'),
                    onPressed: _beginEditing,
                    icon: const Icon(Icons.edit_outlined),
                    label: const Text('Edit profile'),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(50),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );

    if (widget.embedded) return pageContent;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Astronaut profile'),
        actions: [
          if (_isEditing)
            TextButton(
              key: const ValueKey('profile-cancel'),
              onPressed: _isSaving ? null : _cancelEditing,
              child: const Text('Cancel'),
            )
          else
            IconButton(
              key: const ValueKey('profile-edit'),
              tooltip: 'Edit profile',
              onPressed: _beginEditing,
              icon: const Icon(Icons.edit_outlined),
            ),
        ],
      ),
      body: pageContent,
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({required this.user});

  final AstroVitalsUser user;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final initials = user.fullName
        .trim()
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .take(2)
        .map((part) => part[0].toUpperCase())
        .join();

    return Card(
      margin: EdgeInsets.zero,
      color: colorScheme.primaryContainer.withValues(alpha: 0.45),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: colorScheme.primary.withValues(alpha: 0.12)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            CircleAvatar(
              radius: 34,
              backgroundColor: colorScheme.primary,
              child: initials.isEmpty
                  ? const Icon(Icons.person_outline, color: Colors.white)
                  : Text(
                      initials,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user.fullName,
                    style: Theme.of(context).textTheme.titleLarge
                        ?.copyWith(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Astronaut ID  ${user.astronautId}',
                    style: Theme.of(context).textTheme.bodyMedium
                        ?.copyWith(color: colorScheme.onSurfaceVariant),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileSection extends StatelessWidget {
  const _ProfileSection({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      color: Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: Color(0xFFDCE5E2)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 16),
            for (var index = 0; index < children.length; index++) ...[
              if (index > 0) const SizedBox(height: 14),
              children[index],
            ],
          ],
        ),
      ),
    );
  }
}

class _ProfileDetail extends StatelessWidget {
  const _ProfileDetail({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 150,
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium
                ?.copyWith(color: const Color(0xFF657370)),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium
                ?.copyWith(fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }
}

class _ProfileTextField extends StatelessWidget {
  const _ProfileTextField({
    super.key,
    required this.controller,
    required this.label,
    required this.validator,
    this.keyboardType,
    this.textCapitalization = TextCapitalization.none,
  });

  final TextEditingController controller;
  final String label;
  final FormFieldValidator<String> validator;
  final TextInputType? keyboardType;
  final TextCapitalization textCapitalization;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      textCapitalization: textCapitalization,
      validator: validator,
      decoration: InputDecoration(labelText: label),
    );
  }
}

String _formatDate(DateTime date) {
  const months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  return '${date.day.toString().padLeft(2, '0')} '
      '${months[date.month - 1]} ${date.year}';
}

String _formatMeasurement(double value) {
  return value == value.roundToDouble()
      ? value.toInt().toString()
      : value.toString();
}
