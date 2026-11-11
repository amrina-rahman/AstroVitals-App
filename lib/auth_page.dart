import 'package:flutter/material.dart';

import 'data/account_repository.dart';
import 'models/astro_vitals_user.dart';

class AuthPage extends StatefulWidget {
  const AuthPage({
    required this.accountRepository,
    required this.onAuthenticated,
    super.key,
  });

  final AccountRepository accountRepository;
  final ValueChanged<AstroVitalsUser> onAuthenticated;

  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  final _formKey = GlobalKey<FormState>();
  final _astronautIdController = TextEditingController();
  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _heightController = TextEditingController();
  final _weightController = TextEditingController();

  bool _isSignIn = true;
  bool _obscurePassword = true;
  bool _isSubmitting = false;
  DateTime? _dateOfBirth;
  String? _gender;

  @override
  void dispose() {
    _astronautIdController.dispose();
    _fullNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _heightController.dispose();
    _weightController.dispose();
    super.dispose();
  }

  void _setSignIn(bool isSignIn) {
    if (_isSignIn == isSignIn) return;
    setState(() {
      _isSignIn = isSignIn;
      _formKey.currentState?.reset();
      _astronautIdController.clear();
      _fullNameController.clear();
      _emailController.clear();
      _passwordController.clear();
      _confirmPasswordController.clear();
      _heightController.clear();
      _weightController.clear();
      _dateOfBirth = null;
      _gender = null;
    });
  }

  Future<void> _submit() async {
    final form = _formKey.currentState;
    if (form == null || !form.validate()) return;

    form.save();
    setState(() => _isSubmitting = true);
    try {
      if (_isSignIn) {
        final user = await widget.accountRepository.signIn(
          email: _emailController.text,
          password: _passwordController.text,
        );
        if (!mounted) return;
        if (user == null) {
          _showMessage('Email or password is incorrect.');
          return;
        }
        widget.onAuthenticated(user);
      } else {
        final user = AstroVitalsUser(
          astronautId: _astronautIdController.text.trim(),
          fullName: _fullNameController.text.trim(),
          email: _emailController.text.trim(),
          dateOfBirth: _dateOfBirth!,
          heightCm: double.parse(_heightController.text.trim()),
          weightKg: double.parse(_weightController.text.trim()),
          gender: _gender,
        );
        final registeredUser = await widget.accountRepository.register(
          user: user,
          password: _passwordController.text,
        );
        if (!mounted) return;
        if (registeredUser == null) {
          _showMessage(
            'Check your email to confirm your account, then sign in.',
          );
          return;
        }
        widget.onAuthenticated(registeredUser);
      }
    } on AccountAlreadyExistsException catch (error) {
      if (mounted) _showMessage('${error.field} is already registered.');
    } on AccountOperationException catch (error) {
      if (mounted) _showMessage(error.message);
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _selectDateOfBirth(FormFieldState<DateTime> field) async {
    final today = DateUtils.dateOnly(DateTime.now());
    final initialDate = field.value ?? DateTime(today.year - 25);
    final selectedDate = await showDatePicker(
      context: context,
      initialDate: initialDate.isAfter(today) ? today : initialDate,
      firstDate: DateTime(1900),
      lastDate: today,
      helpText: 'Select date of birth',
    );
    if (selectedDate != null) {
      field.didChange(selectedDate);
      _dateOfBirth = selectedDate;
    }
  }

  String? _validateMeasurement(String? value, String label) {
    final measurement = double.tryParse(value?.trim() ?? '');
    if (measurement == null) return 'Enter $label';
    if (!measurement.isFinite || measurement <= 0) {
      return 'Enter a number greater than 0';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final title = _isSignIn ? 'Welcome back' : 'Create your account';
    final subtitle = _isSignIn
        ? 'Sign in to continue your health journey.'
        : 'Enter your details to get started.';

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const _BrandHeader(),
                    const SizedBox(height: 36),
                    Text(
                      title,
                      style: Theme.of(context).textTheme.headlineMedium
                          ?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodyLarge
                          ?.copyWith(color: const Color(0xFF657370)),
                    ),
                    const SizedBox(height: 28),
                    _AuthModeSelector(
                      isSignIn: _isSignIn,
                      onChanged: _setSignIn,
                    ),
                    const SizedBox(height: 24),
                    if (!_isSignIn) ...[
                      _AuthTextField(
                        key: const ValueKey('astronaut-id'),
                        label: 'Astronaut ID',
                        hint: 'Enter your astronaut ID',
                        controller: _astronautIdController,
                        textCapitalization: TextCapitalization.characters,
                        validator: _requiredValidator(
                          'Enter your astronaut ID',
                        ),
                      ),
                      const SizedBox(height: 16),
                      _AuthTextField(
                        key: const ValueKey('full-name'),
                        label: 'Full name',
                        hint: 'Your name',
                        controller: _fullNameController,
                        textCapitalization: TextCapitalization.words,
                        validator: _requiredValidator('Enter your full name'),
                      ),
                      const SizedBox(height: 16),
                    ],
                    _AuthTextField(
                      key: const ValueKey('email'),
                      label: 'Email',
                      hint: 'you@example.com',
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      textCapitalization: TextCapitalization.none,
                      validator: _validateEmail,
                    ),
                    const SizedBox(height: 16),
                    _AuthTextField(
                      key: const ValueKey('password'),
                      label: 'Password',
                      hint: 'At least 8 characters',
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      textCapitalization: TextCapitalization.none,
                      suffixIcon: IconButton(
                        tooltip: _obscurePassword
                            ? 'Show password'
                            : 'Hide password',
                        onPressed: () {
                          setState(() {
                            _obscurePassword = !_obscurePassword;
                          });
                        },
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Enter your password';
                        }
                        if (value.length < 8) {
                          return 'Use at least 8 characters';
                        }
                        return null;
                      },
                    ),
                    if (!_isSignIn) ...[
                      const SizedBox(height: 16),
                      _AuthTextField(
                        key: const ValueKey('confirm-password'),
                        label: 'Confirm password',
                        hint: 'Re-enter your password',
                        controller: _confirmPasswordController,
                        obscureText: true,
                        textCapitalization: TextCapitalization.none,
                        validator: (value) => value != _passwordController.text
                            ? 'Passwords do not match'
                            : null,
                      ),
                      const SizedBox(height: 16),
                      _DateOfBirthField(
                        onSelect: _selectDateOfBirth,
                        onSaved: (value) => _dateOfBirth = value,
                      ),
                      const SizedBox(height: 16),
                      _AuthTextField(
                        key: const ValueKey('height'),
                        label: 'Height (cm)',
                        hint: 'e.g. 172.5',
                        controller: _heightController,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        textCapitalization: TextCapitalization.none,
                        validator: (value) =>
                            _validateMeasurement(value, 'your height'),
                      ),
                      const SizedBox(height: 16),
                      _AuthTextField(
                        key: const ValueKey('weight'),
                        label: 'Weight (kg)',
                        hint: 'e.g. 68.5',
                        controller: _weightController,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        textCapitalization: TextCapitalization.none,
                        validator: (value) =>
                            _validateMeasurement(value, 'your weight'),
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        key: const ValueKey('gender'),
                        initialValue: _gender,
                        decoration: const InputDecoration(
                          labelText: 'Gender (optional)',
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: 'Female',
                            child: Text('Female'),
                          ),
                          DropdownMenuItem(value: 'Male', child: Text('Male')),
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
                        onChanged: (value) => setState(() => _gender = value),
                        onSaved: (value) => _gender = value,
                      ),
                    ],
                    if (_isSignIn)
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: () => _showMessage(
                            'Password reset is not available yet.',
                          ),
                          child: const Text('Forgot password?'),
                        ),
                      )
                    else
                      const SizedBox(height: 24),
                    const SizedBox(height: 8),
                    FilledButton(
                      onPressed: _isSubmitting ? null : _submit,
                      style: FilledButton.styleFrom(
                        minimumSize: const Size.fromHeight(52),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: _isSubmitting
                          ? const SizedBox(
                              height: 22,
                              width: 22,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Text(_isSignIn ? 'Sign in' : 'Create account'),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Accounts are temporary and will be cleared when the app closes.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Color(0xFF657370)),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  FormFieldValidator<String> _requiredValidator(String message) {
    return (value) => value == null || value.trim().isEmpty ? message : null;
  }

  String? _validateEmail(String? value) {
    final email = value?.trim() ?? '';
    if (email.isEmpty) return 'Enter your email address';
    if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email)) {
      return 'Enter a valid email address';
    }
    return null;
  }
}

class _DateOfBirthField extends StatelessWidget {
  const _DateOfBirthField({required this.onSelect, required this.onSaved});

  final Future<void> Function(FormFieldState<DateTime>) onSelect;
  final FormFieldSetter<DateTime> onSaved;

  @override
  Widget build(BuildContext context) {
    return FormField<DateTime>(
      validator: (value) => value == null ? 'Select your date of birth' : null,
      onSaved: onSaved,
      builder: (field) {
        final value = field.value;
        return InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () => onSelect(field),
          child: InputDecorator(
            decoration: InputDecoration(
              labelText: 'Date of birth',
              errorText: field.errorText,
              suffixIcon: const Icon(Icons.calendar_today_outlined),
            ),
            child: Text(
              value == null
                  ? 'Select date'
                  : '${value.day.toString().padLeft(2, '0')}/'
                        '${value.month.toString().padLeft(2, '0')}/'
                        '${value.year}',
              style: TextStyle(
                color: value == null
                    ? Theme.of(context).hintColor
                    : Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ),
        );
      },
    );
  }
}

class _BrandHeader extends StatelessWidget {
  const _BrandHeader();

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.primary;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(14),
          ),
          child: const Icon(
            Icons.favorite_rounded,
            color: Colors.white,
            size: 25,
          ),
        ),
        const SizedBox(width: 12),
        Text(
          'AstroVitals',
          style: Theme.of(context).textTheme.titleLarge
              ?.copyWith(fontWeight: FontWeight.w700, letterSpacing: 0.2),
        ),
      ],
    );
  }
}

class _AuthModeSelector extends StatelessWidget {
  const _AuthModeSelector({required this.isSignIn, required this.onChanged});

  final bool isSignIn;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.primary;
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFFEAF0EE),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          _AuthModeButton(
            label: 'Log in',
            selected: isSignIn,
            color: color,
            onPressed: () => onChanged(true),
          ),
          _AuthModeButton(
            label: 'Sign up',
            selected: !isSignIn,
            color: color,
            onPressed: () => onChanged(false),
          ),
        ],
      ),
    );
  }
}

class _AuthModeButton extends StatelessWidget {
  const _AuthModeButton({
    required this.label,
    required this.selected,
    required this.color,
    required this.onPressed,
  });

  final String label;
  final bool selected;
  final Color color;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: TextButton(
        onPressed: onPressed,
        style: TextButton.styleFrom(
          backgroundColor: selected ? Colors.white : Colors.transparent,
          foregroundColor: selected ? color : const Color(0xFF657370),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        child: Text(label),
      ),
    );
  }
}

class _AuthTextField extends StatelessWidget {
  const _AuthTextField({
    super.key,
    required this.label,
    required this.hint,
    required this.textCapitalization,
    required this.validator,
    this.controller,
    this.keyboardType,
    this.obscureText = false,
    this.suffixIcon,
  });

  final String label;
  final String hint;
  final TextCapitalization textCapitalization;
  final FormFieldValidator<String> validator;
  final TextEditingController? controller;
  final TextInputType? keyboardType;
  final bool obscureText;
  final Widget? suffixIcon;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      textCapitalization: textCapitalization,
      obscureText: obscureText,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        suffixIcon: suffixIcon,
      ),
    );
  }
}
