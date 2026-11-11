import 'health_measurement.dart';

enum ActivityMetric {
  steps('steps', 'Steps', 'steps'),
  waterIntakeMl('water_intake_ml', 'Water intake', 'ml'),
  sleepDurationHours('sleep_duration_hours', 'Sleep duration', 'hours'),
  exerciseDurationMinutes(
    'exercise_duration_minutes',
    'Exercise duration',
    'minutes',
  ),
  weightKg('weight_kg', 'Current weight', 'kg');

  const ActivityMetric(this.databaseColumn, this.label, this.unit);

  final String databaseColumn;
  final String label;
  final String unit;
}

class ActivityMetricValue {
  const ActivityMetricValue({
    required this.value,
    required this.source,
    required this.recordedAt,
  });

  final double value;
  final HealthDataSource source;
  final DateTime recordedAt;

  String get formattedValue => value == value.roundToDouble()
      ? value.toInt().toString()
      : value.toString();
}

class DailyActivitySnapshot {
  const DailyActivitySnapshot({
    required this.recordedDate,
    required this.values,
  });

  final DateTime recordedDate;
  final Map<ActivityMetric, ActivityMetricValue> values;

  ActivityMetricValue? operator [](ActivityMetric metric) => values[metric];
}

class DailyActivityDraft {
  const DailyActivityDraft({required this.values, required this.recordedAt});

  final Map<ActivityMetric, double> values;
  final DateTime recordedAt;
}
