import 'package:flutter/material.dart';

import 'models/daily_activity.dart';
import 'models/health_measurement.dart';

Future<HealthMeasurementDraft?> showHealthMeasurementForm(
  BuildContext context,
) {
  return showModalBottomSheet<HealthMeasurementDraft>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) => const _HealthMeasurementForm(),
  );
}

Future<DailyActivityDraft?> showDailyActivityForm(
  BuildContext context, {
  required Map<ActivityMetric, double> existingValues,
}) {
  return showModalBottomSheet<DailyActivityDraft>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) => _DailyActivityForm(existingValues: existingValues),
  );
}

class _HealthMeasurementForm extends StatefulWidget {
  const _HealthMeasurementForm();

  @override
  State<_HealthMeasurementForm> createState() => _HealthMeasurementFormState();
}

class _HealthMeasurementFormState extends State<_HealthMeasurementForm> {
  final _formKey = GlobalKey<FormState>();
  final _valueController = TextEditingController();
  final _secondaryValueController = TextEditingController();
  HealthMetric _metric = HealthMetric.heartRate;
  DateTime _recordedAt = DateTime.now();

  @override
  void dispose() {
    _valueController.dispose();
    _secondaryValueController.dispose();
    super.dispose();
  }

  Future<void> _selectTimestamp() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _recordedAt,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (!mounted || date == null) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_recordedAt),
    );
    if (time == null) return;
    setState(() {
      _recordedAt = DateTime(
        date.year,
        date.month,
        date.day,
        time.hour,
        time.minute,
      );
    });
  }

  String? _validateValue(String? text, {required bool isDiastolic}) {
    final value = double.tryParse(text?.trim() ?? '');
    if (value == null || !value.isFinite || value <= 0) {
      return 'Enter a number greater than 0';
    }
    if (_metric == HealthMetric.spo2 && value > 100) {
      return 'SpO₂ cannot be greater than 100%';
    }
    if (_metric == HealthMetric.bloodPressure && value > 300) {
      return 'Enter a value no greater than 300 mmHg';
    }
    if (_metric == HealthMetric.heartRate && value > 300) {
      return 'Enter a value no greater than 300 BPM';
    }
    if (_metric == HealthMetric.bodyTemperature && (value < 20 || value > 50)) {
      return 'Enter a temperature between 20°C and 50°C';
    }
    if (_metric == HealthMetric.respiratoryRate && value > 100) {
      return 'Enter a value no greater than 100 breaths/min';
    }
    if (_metric == HealthMetric.bloodPressure &&
        !isDiastolic &&
        _secondaryValueController.text.isNotEmpty) {
      final diastolic = double.tryParse(_secondaryValueController.text.trim());
      if (diastolic != null && value <= diastolic) {
        return 'Systolic pressure must be greater than diastolic pressure';
      }
    }
    if (_metric == HealthMetric.bloodPressure &&
        isDiastolic &&
        _valueController.text.isNotEmpty) {
      final systolic = double.tryParse(_valueController.text.trim());
      if (systolic != null && value >= systolic) {
        return 'Diastolic pressure must be less than systolic pressure';
      }
    }
    return null;
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    final value = double.parse(_valueController.text.trim());
    final secondaryValue = _metric == HealthMetric.bloodPressure
        ? double.parse(_secondaryValueController.text.trim())
        : null;
    Navigator.of(context).pop(
      HealthMeasurementDraft(
        metric: _metric,
        value: value,
        secondaryValue: secondaryValue,
        source: HealthDataSource.manual,
        recordedAt: _recordedAt,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isBloodPressure = _metric == HealthMetric.bloodPressure;

    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 16,
        bottom: MediaQuery.viewInsetsOf(context).bottom + 20,
      ),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Add health measurement',
                style: Theme.of(context).textTheme.titleLarge
                    ?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 18),
              DropdownButtonFormField<HealthMetric>(
                key: const ValueKey('health-entry-metric'),
                initialValue: _metric,
                isExpanded: true,
                decoration: const InputDecoration(labelText: 'Measurement'),
                items: [
                  for (final metric in HealthMetric.values)
                    DropdownMenuItem(value: metric, child: Text(metric.label)),
                ],
                onChanged: (metric) {
                  if (metric == null) return;
                  setState(() {
                    _metric = metric;
                    _valueController.clear();
                    _secondaryValueController.clear();
                  });
                },
              ),
              const SizedBox(height: 14),
              TextFormField(
                key: const ValueKey('health-entry-value'),
                controller: _valueController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: InputDecoration(
                  labelText: isBloodPressure ? 'Systolic (mmHg)' : _metric.unit,
                  hintText: isBloodPressure ? 'e.g. 120' : _metric.hint,
                ),
                validator: (value) => _validateValue(value, isDiastolic: false),
              ),
              if (isBloodPressure) ...[
                const SizedBox(height: 14),
                TextFormField(
                  key: const ValueKey('health-entry-secondary-value'),
                  controller: _secondaryValueController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: const InputDecoration(
                    labelText: 'Diastolic (mmHg)',
                    hintText: 'e.g. 80',
                  ),
                  validator: (value) =>
                      _validateValue(value, isDiastolic: true),
                ),
              ],
              const SizedBox(height: 14),
              _TimestampButton(
                key: const ValueKey('health-entry-timestamp'),
                value: _recordedAt,
                onPressed: _selectTimestamp,
              ),
              const SizedBox(height: 10),
              const _SourceHint(source: HealthDataSource.manual),
              const SizedBox(height: 18),
              FilledButton(
                key: const ValueKey('health-entry-save'),
                onPressed: _save,
                child: const Text('Save measurement'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DailyActivityForm extends StatefulWidget {
  const _DailyActivityForm({required this.existingValues});

  final Map<ActivityMetric, double> existingValues;

  @override
  State<_DailyActivityForm> createState() => _DailyActivityFormState();
}

class _DailyActivityFormState extends State<_DailyActivityForm> {
  final _formKey = GlobalKey<FormState>();
  final Map<ActivityMetric, TextEditingController> _controllers = {
    for (final metric in ActivityMetric.values) metric: TextEditingController(),
  };
  DateTime _recordedAt = DateTime.now();

  @override
  void initState() {
    super.initState();
    for (final entry in widget.existingValues.entries) {
      _controllers[entry.key]!.text = _formatNumber(entry.value);
    }
  }

  @override
  void dispose() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _selectTimestamp() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _recordedAt,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (!mounted || date == null) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_recordedAt),
    );
    if (time == null) return;
    setState(() {
      _recordedAt = DateTime(
        date.year,
        date.month,
        date.day,
        time.hour,
        time.minute,
      );
    });
  }

  String? _validate(ActivityMetric metric, String? text) {
    if (text == null || text.trim().isEmpty) return null;
    final value = double.tryParse(text.trim());
    if (value == null || !value.isFinite || value < 0) {
      return 'Enter a valid non-negative number';
    }
    if (metric == ActivityMetric.weightKg && value == 0) {
      return 'Enter a weight greater than 0';
    }
    if (metric == ActivityMetric.sleepDurationHours && value > 24) {
      return 'Sleep duration cannot exceed 24 hours';
    }
    if ((metric == ActivityMetric.steps ||
            metric == ActivityMetric.waterIntakeMl ||
            metric == ActivityMetric.exerciseDurationMinutes) &&
        value != value.roundToDouble()) {
      return 'Enter a whole number';
    }
    return null;
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    final values = <ActivityMetric, double>{};
    for (final entry in _controllers.entries) {
      final text = entry.value.text.trim();
      if (text.isNotEmpty) values[entry.key] = double.parse(text);
    }
    if (values.isEmpty) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(content: Text('Enter at least one activity value.')),
        );
      return;
    }
    Navigator.of(context)
        .pop(DailyActivityDraft(values: values, recordedAt: _recordedAt));
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 16,
        bottom: MediaQuery.viewInsetsOf(context).bottom + 20,
      ),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Add daily activity',
                style: Theme.of(context).textTheme.titleLarge
                    ?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 18),
              for (final metric in ActivityMetric.values) ...[
                TextFormField(
                  key: ValueKey('activity-entry-${metric.databaseColumn}'),
                  controller: _controllers[metric],
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: InputDecoration(
                    labelText: '${metric.label} (${metric.unit})',
                  ),
                  validator: (value) => _validate(metric, value),
                ),
                const SizedBox(height: 14),
              ],
              _TimestampButton(
                key: const ValueKey('activity-entry-timestamp'),
                value: _recordedAt,
                onPressed: _selectTimestamp,
              ),
              const SizedBox(height: 10),
              const _SourceHint(source: HealthDataSource.manual),
              const SizedBox(height: 18),
              FilledButton(
                key: const ValueKey('activity-entry-save'),
                onPressed: _save,
                child: const Text('Save activity'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TimestampButton extends StatelessWidget {
  const _TimestampButton({
    required this.value,
    required this.onPressed,
    super.key,
  });

  final DateTime value;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: const Icon(Icons.schedule_rounded),
      label: Text('Recorded ${_formatTimestamp(value)}'),
      style: OutlinedButton.styleFrom(
        alignment: Alignment.centerLeft,
        minimumSize: const Size.fromHeight(48),
      ),
    );
  }
}

class _SourceHint extends StatelessWidget {
  const _SourceHint({required this.source});

  final HealthDataSource source;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Icon(Icons.info_outline_rounded, size: 18),
        const SizedBox(width: 8),
        Text('Source: ${source.label}'),
      ],
    );
  }
}

String _formatTimestamp(DateTime dateTime) {
  final local = dateTime.toLocal();
  final date =
      '${local.day.toString().padLeft(2, '0')}/'
      '${local.month.toString().padLeft(2, '0')}/'
      '${local.year}';
  final time =
      '${local.hour.toString().padLeft(2, '0')}:'
      '${local.minute.toString().padLeft(2, '0')}';
  return '$date at $time';
}

String _formatNumber(double value) => value == value.roundToDouble()
    ? value.toInt().toString()
    : value.toString();
