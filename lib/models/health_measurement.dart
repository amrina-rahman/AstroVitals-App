enum HealthDataSource {
  manual('manual', 'Manual'),
  simulatedSmartwatch('simulated_smartwatch', 'Simulated smartwatch');

  const HealthDataSource(this.databaseValue, this.label);

  final String databaseValue;
  final String label;

  static HealthDataSource fromDatabase(Object? value) {
    return HealthDataSource.values.firstWhere(
      (source) => source.databaseValue == value,
      orElse: () => throw FormatException('Unknown health data source: $value'),
    );
  }
}

enum HealthMetric {
  heartRate('heart_rate', 'Heart rate', 'BPM', 'Enter heart rate in BPM'),
  spo2('spo2', 'Blood oxygen (SpO₂)', '%', 'Enter SpO₂ percentage'),
  bodyTemperature(
    'body_temperature',
    'Body temperature',
    '°C',
    'Enter body temperature in °C',
  ),
  respiratoryRate(
    'respiratory_rate',
    'Respiratory rate',
    'breaths/min',
    'Enter breaths per minute',
  ),
  bloodPressure(
    'blood_pressure',
    'Blood pressure',
    'mmHg',
    'Enter systolic pressure',
  );

  const HealthMetric(this.databaseValue, this.label, this.unit, this.hint);

  final String databaseValue;
  final String label;
  final String unit;
  final String hint;

  static HealthMetric fromDatabase(Object? value) {
    return HealthMetric.values.firstWhere(
      (metric) => metric.databaseValue == value,
      orElse: () => throw FormatException('Unknown health metric: $value'),
    );
  }
}

class HealthMeasurement {
  const HealthMeasurement({
    required this.id,
    required this.metric,
    required this.value,
    required this.source,
    required this.recordedAt,
    this.secondaryValue,
  });

  final String id;
  final HealthMetric metric;
  final double value;
  final double? secondaryValue;
  final HealthDataSource source;
  final DateTime recordedAt;

  String get formattedValue {
    if (metric == HealthMetric.bloodPressure) {
      return '${_formatNumber(value)}/${_formatNumber(secondaryValue!)}';
    }
    return _formatNumber(value);
  }

  static String _formatNumber(double number) {
    return number == number.roundToDouble()
        ? number.toInt().toString()
        : number.toString();
  }
}

class HealthMeasurementDraft {
  const HealthMeasurementDraft({
    required this.metric,
    required this.value,
    required this.source,
    required this.recordedAt,
    this.secondaryValue,
  });

  final HealthMetric metric;
  final double value;
  final double? secondaryValue;
  final HealthDataSource source;
  final DateTime recordedAt;
}
