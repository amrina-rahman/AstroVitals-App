import 'package:flutter/material.dart';

import 'data/health_reference_thresholds.dart';
import 'data/health_repository.dart';
import 'health_entry_forms.dart';
import 'models/daily_activity.dart';
import 'models/health_measurement.dart';

class HealthPage extends StatefulWidget {
  const HealthPage({
    required this.repository,
    required this.thresholds,
    required this.initialWeightKg,
    required this.onWeightSaved,
    super.key,
  });

  final HealthRepository repository;
  final HealthReferenceThresholds thresholds;
  final double initialWeightKg;
  final ValueChanged<double> onWeightSaved;

  @override
  State<HealthPage> createState() => _HealthPageState();
}

class _HealthPageState extends State<HealthPage> {
  HealthDashboardData? _data;
  bool _isLoading = true;
  bool _isSaving = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadDashboard();
  }

  Future<void> _loadDashboard() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final data = await widget.repository.loadDashboard();
      if (!mounted) return;
      setState(() {
        _data = data;
        _isLoading = false;
      });
    } on HealthRepositoryException catch (error) {
      if (!mounted) return;
      setState(() {
        _errorMessage = error.message;
        _isLoading = false;
      });
    }
  }

  Future<void> _addMeasurement() async {
    final draft = await showHealthMeasurementForm(context);
    if (draft == null || !mounted) return;
    setState(() => _isSaving = true);
    try {
      await widget.repository.saveMeasurement(draft);
      await _loadDashboard();
      if (!mounted) return;
      _showMessage('Health measurement saved.');
    } on HealthRepositoryException catch (error) {
      if (!mounted) return;
      _showMessage(error.message);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _addActivity() async {
    final existingValues = <ActivityMetric, double>{
      for (final entry
          in _data?.dailyActivity.values.entries ??
              const <MapEntry<ActivityMetric, ActivityMetricValue>>[])
        entry.key: entry.value.value,
    };
    final draft = await showDailyActivityForm(
      context,
      existingValues: existingValues,
    );
    if (draft == null || !mounted) return;
    setState(() => _isSaving = true);
    try {
      await widget.repository.saveDailyActivity(draft);
      final weight = draft.values[ActivityMetric.weightKg];
      if (weight != null) widget.onWeightSaved(weight);
      await _loadDashboard();
      if (!mounted) return;
      _showMessage('Daily activity saved.');
    } on HealthRepositoryException catch (error) {
      if (!mounted) return;
      _showMessage(error.message);
      await _loadDashboard();
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _addSimulatedSample() async {
    setState(() => _isSaving = true);
    try {
      await widget.repository.addSimulatedSmartwatchSample(DateTime.now());
      await _loadDashboard();
      if (!mounted) return;
      _showMessage('Labeled simulated readings saved.');
    } on HealthRepositoryException catch (error) {
      if (!mounted) return;
      _showMessage(error.message);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Map<HealthMetric, HealthMeasurement> _latestMeasurements() {
    final latest = <HealthMetric, HealthMeasurement>{};
    for (final measurement
        in _data?.measurements ?? const <HealthMeasurement>[]) {
      final previous = latest[measurement.metric];
      if (previous == null ||
          measurement.recordedAt.isAfter(previous.recordedAt)) {
        latest[measurement.metric] = measurement;
      }
    }
    return latest;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return RefreshIndicator(
      onRefresh: _loadDashboard,
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
            sliver: SliverToBoxAdapter(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1000),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Daily health',
                                  key: const ValueKey('health-page-title'),
                                  style: theme.textTheme.headlineSmall
                                      ?.copyWith(fontWeight: FontWeight.w700),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Your latest measurements and activity',
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: const Color(0xFF657370),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            tooltip: 'Refresh health data',
                            onPressed: _isLoading || _isSaving
                                ? null
                                : _loadDashboard,
                            icon: const Icon(Icons.refresh_rounded),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _buildReferenceNotice(context),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 10,
                        runSpacing: 8,
                        children: [
                          OutlinedButton.icon(
                            key: const ValueKey('health-add-measurement'),
                            onPressed: _isSaving ? null : _addMeasurement,
                            icon: const Icon(Icons.add_rounded),
                            label: const Text('Add reading'),
                          ),
                          OutlinedButton.icon(
                            key: const ValueKey('health-add-activity'),
                            onPressed: _isLoading || _isSaving
                                ? null
                                : _addActivity,
                            icon: const Icon(Icons.edit_outlined),
                            label: const Text('Log activity'),
                          ),
                          OutlinedButton.icon(
                            key: const ValueKey('health-simulate-readings'),
                            onPressed: _isSaving ? null : _addSimulatedSample,
                            icon: const Icon(Icons.watch_rounded),
                            label: const Text('Add simulated sample'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Simulation uses fixed demo data for heart rate, SpO₂, '
                        'steps and sleep; it is not a real wearable.',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: const Color(0xFF657370),
                        ),
                      ),
                      const SizedBox(height: 24),
                      _buildSectionHeader(
                        context,
                        title: 'Latest measurements',
                      ),
                      const SizedBox(height: 12),
                      if (_isLoading)
                        const Padding(
                          padding: EdgeInsets.all(32),
                          child: Center(child: CircularProgressIndicator()),
                        )
                      else if (_errorMessage != null)
                        _buildErrorCard(context)
                      else
                        _buildMeasurements(context),
                      const SizedBox(height: 28),
                      _buildSectionHeader(context, title: 'Daily activity'),
                      const SizedBox(height: 12),
                      if (_isLoading)
                        const Center(child: CircularProgressIndicator())
                      else if (_errorMessage != null)
                        _buildErrorCard(context)
                      else
                        _buildActivity(context),
                      if (_isSaving) ...[
                        const SizedBox(height: 16),
                        const LinearProgressIndicator(),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReferenceNotice(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      key: const ValueKey('health-threshold-notice'),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colorScheme.secondaryContainer.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline_rounded, color: colorScheme.primary),
          const SizedBox(width: 10),
          const Expanded(
            child: Text(
              'Status ranges are configurable prototype references, not '
              'validated for astronaut-specific medical use and not a diagnosis.',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, {required String title}) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleLarge
          ?.copyWith(fontWeight: FontWeight.w700),
    );
  }

  Widget _buildErrorCard(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      color: Theme.of(context).colorScheme.errorContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(_errorMessage ?? 'Unable to load health data.'),
            const SizedBox(height: 8),
            TextButton.icon(
              onPressed: _loadDashboard,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Try again'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMeasurements(BuildContext context) {
    final latest = _latestMeasurements();
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 740
            ? 3
            : constraints.maxWidth >= 480
            ? 2
            : 1;
        final cardWidth = (constraints.maxWidth - (columns - 1) * 12) / columns;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (latest.isEmpty) ...[
              const _EmptySection(
                icon: Icons.favorite_border_rounded,
                message: 'No health readings yet.',
              ),
              const SizedBox(height: 12),
            ],
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                for (final metric in HealthMetric.values)
                  SizedBox(
                    width: cardWidth,
                    child: _MeasurementCard(
                      metric: metric,
                      measurement: latest[metric],
                      status: latest[metric] == null
                          ? null
                          : _statusFor(latest[metric]!),
                      statusLabel: latest[metric] == null
                          ? null
                          : metric == HealthMetric.bloodPressure
                          ? widget.thresholds.bloodPressure.labelFor(
                              latest[metric]!.value,
                              latest[metric]!.secondaryValue!,
                            )
                          : _statusFor(latest[metric]!).label,
                    ),
                  ),
              ],
            ),
          ],
        );
      },
    );
  }

  HealthStatus _statusFor(HealthMeasurement measurement) {
    return switch (measurement.metric) {
      HealthMetric.heartRate => widget.thresholds.heartRate.assess(
        measurement.value,
      ),
      HealthMetric.spo2 => widget.thresholds.spo2.assess(measurement.value),
      HealthMetric.bodyTemperature => widget.thresholds.bodyTemperature.assess(
        measurement.value,
      ),
      HealthMetric.respiratoryRate => widget.thresholds.respiratoryRate.assess(
        measurement.value,
      ),
      HealthMetric.bloodPressure => widget.thresholds.bloodPressure.assess(
        measurement.value,
        measurement.secondaryValue!,
      ),
    };
  }

  Widget _buildActivity(BuildContext context) {
    final snapshot = _data!.dailyActivity;
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 740
            ? 3
            : constraints.maxWidth >= 480
            ? 2
            : 1;
        final cardWidth = (constraints.maxWidth - (columns - 1) * 12) / columns;
        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            for (final metric in ActivityMetric.values)
              SizedBox(
                width: cardWidth,
                child: _ActivityCard(
                  metric: metric,
                  value: snapshot[metric],
                  profileWeightKg: widget.initialWeightKg,
                ),
              ),
          ],
        );
      },
    );
  }
}

class _MeasurementCard extends StatelessWidget {
  const _MeasurementCard({
    required this.metric,
    required this.measurement,
    required this.status,
    required this.statusLabel,
  });

  final HealthMetric metric;
  final HealthMeasurement? measurement;
  final HealthStatus? status;
  final String? statusLabel;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final statusColor = switch (status) {
      HealthStatus.normal => colors.primary,
      HealthStatus.attention => Colors.orange.shade800,
      HealthStatus.critical => colors.error,
      null => colors.outline,
    };

    return Card(
      margin: EdgeInsets.zero,
      color: Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: const BorderSide(color: Color(0xFFDCE5E2)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              metric.label,
              style: Theme.of(context).textTheme.titleSmall
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 10),
            if (measurement == null)
              Text(
                'No reading',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: colors.outline,
                  fontWeight: FontWeight.w700,
                ),
              )
            else
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Flexible(
                    child: Text(
                      measurement!.formattedValue,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(fontWeight: FontWeight.w700),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    metric.unit,
                    style: Theme.of(context).textTheme.bodySmall
                        ?.copyWith(color: colors.onSurfaceVariant),
                  ),
                ],
              ),
            const SizedBox(height: 10),
            if (status != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  statusLabel!,
                  key: ValueKey('health-status-${metric.databaseValue}'),
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: statusColor,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            const SizedBox(height: 10),
            Text(
              measurement == null
                  ? 'Recorded time unavailable'
                  : 'Recorded ${_formatTimestamp(measurement!.recordedAt)}',
              style: Theme.of(context).textTheme.bodySmall
                  ?.copyWith(color: colors.onSurfaceVariant),
            ),
            const SizedBox(height: 4),
            Text(
              'Source: ${measurement?.source.label ?? 'Not recorded'}',
              style: Theme.of(context).textTheme.bodySmall
                  ?.copyWith(color: colors.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActivityCard extends StatelessWidget {
  const _ActivityCard({
    required this.metric,
    required this.value,
    required this.profileWeightKg,
  });

  final ActivityMetric metric;
  final ActivityMetricValue? value;
  final double profileWeightKg;

  @override
  Widget build(BuildContext context) {
    final isProfileWeight = value == null && metric == ActivityMetric.weightKg;
    final displayValue =
        value?.formattedValue ??
        (isProfileWeight ? _formatNumber(profileWeightKg) : 'Not entered');
    final source =
        value?.source.label ??
        (isProfileWeight ? 'Profile baseline' : 'Not recorded');
    final timestamp = value == null
        ? (isProfileWeight ? 'No daily reading recorded' : 'No time recorded')
        : 'Recorded ${_formatTimestamp(value!.recordedAt)}';

    return Card(
      margin: EdgeInsets.zero,
      color: Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: const BorderSide(color: Color(0xFFDCE5E2)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              metric.label,
              style: Theme.of(context).textTheme.titleSmall
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 10),
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Flexible(
                  child: Text(
                    displayValue,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.headlineSmall
                        ?.copyWith(fontWeight: FontWeight.w700),
                  ),
                ),
                if (value != null || isProfileWeight) ...[
                  const SizedBox(width: 6),
                  Text(metric.unit),
                ],
              ],
            ),
            const SizedBox(height: 10),
            Text(
              timestamp,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Source: $source',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptySection extends StatelessWidget {
  const _EmptySection({required this.icon, required this.message});

  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
      ),
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
