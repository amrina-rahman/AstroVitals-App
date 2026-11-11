enum HealthStatus {
  normal('Normal'),
  attention('Attention'),
  critical('Critical');

  const HealthStatus(this.label);

  final String label;
}

class MetricReferenceThreshold {
  const MetricReferenceThreshold({
    this.normalMinimum,
    this.normalMaximum,
    this.criticalMinimum,
    this.criticalMaximum,
  });

  final double? normalMinimum;
  final double? normalMaximum;
  final double? criticalMinimum;
  final double? criticalMaximum;

  HealthStatus assess(double value) {
    if ((criticalMinimum != null && value < criticalMinimum!) ||
        (criticalMaximum != null && value > criticalMaximum!)) {
      return HealthStatus.critical;
    }
    if ((normalMinimum != null && value < normalMinimum!) ||
        (normalMaximum != null && value > normalMaximum!)) {
      return HealthStatus.attention;
    }
    return HealthStatus.normal;
  }
}

class BloodPressureReferenceThreshold {
  const BloodPressureReferenceThreshold({
    required this.systolic,
    required this.diastolic,
  });

  final MetricReferenceThreshold systolic;
  final MetricReferenceThreshold diastolic;

  HealthStatus assess(double systolicValue, double diastolicValue) {
    final systolicStatus = systolic.assess(systolicValue);
    final diastolicStatus = diastolic.assess(diastolicValue);
    if (systolicStatus == HealthStatus.critical ||
        diastolicStatus == HealthStatus.critical) {
      return HealthStatus.critical;
    }
    if (systolicStatus == HealthStatus.attention ||
        diastolicStatus == HealthStatus.attention) {
      return HealthStatus.attention;
    }
    return HealthStatus.normal;
  }
}

class HealthReferenceThresholds {
  const HealthReferenceThresholds({
    required this.heartRate,
    required this.spo2,
    required this.bodyTemperature,
    required this.respiratoryRate,
    required this.bloodPressure,
  });

  final MetricReferenceThreshold heartRate;
  final MetricReferenceThreshold spo2;
  final MetricReferenceThreshold bodyTemperature;
  final MetricReferenceThreshold respiratoryRate;
  final BloodPressureReferenceThreshold bloodPressure;

  static const prototypeDefaults = HealthReferenceThresholds(
    heartRate: MetricReferenceThreshold(
      normalMinimum: 60,
      normalMaximum: 100,
      criticalMinimum: 40,
      criticalMaximum: 140,
    ),
    spo2: MetricReferenceThreshold(normalMinimum: 95, criticalMinimum: 90),
    bodyTemperature: MetricReferenceThreshold(
      normalMinimum: 36.1,
      normalMaximum: 37.5,
      criticalMinimum: 35,
      criticalMaximum: 39,
    ),
    respiratoryRate: MetricReferenceThreshold(
      normalMinimum: 12,
      normalMaximum: 20,
      criticalMinimum: 8,
      criticalMaximum: 30,
    ),
    bloodPressure: BloodPressureReferenceThreshold(
      systolic: MetricReferenceThreshold(
        normalMaximum: 120,
        criticalMaximum: 180,
      ),
      diastolic: MetricReferenceThreshold(
        normalMaximum: 80,
        criticalMaximum: 120,
      ),
    ),
  );

  HealthStatus assess({
    required double value,
    required MetricReferenceThreshold threshold,
  }) => threshold.assess(value);
}
