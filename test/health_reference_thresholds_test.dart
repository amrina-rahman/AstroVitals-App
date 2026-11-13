import 'package:flutter_test/flutter_test.dart';

import 'package:astro_vitals/data/health_reference_thresholds.dart';

void main() {
  const thresholds = HealthReferenceThresholds.prototypeDefaults;

  group('blood pressure reference thresholds', () {
    test('classifies systolic below 90 as critical', () {
      expect(thresholds.bloodPressure.assess(89, 70), HealthStatus.critical);
      expect(thresholds.bloodPressure.labelFor(89, 70), 'Low blood pressure');
    });

    test('classifies diastolic below 60 as critical', () {
      expect(thresholds.bloodPressure.assess(110, 59), HealthStatus.critical);
      expect(thresholds.bloodPressure.labelFor(110, 59), 'Low blood pressure');
    });

    test('does not classify the 90/60 boundary as low', () {
      expect(thresholds.bloodPressure.assess(90, 60), HealthStatus.normal);
      expect(thresholds.bloodPressure.labelFor(90, 60), 'Normal');
    });

    test('classifies systolic and diastolic attention ranges', () {
      expect(thresholds.bloodPressure.assess(130, 75), HealthStatus.attention);
      expect(thresholds.bloodPressure.assess(115, 85), HealthStatus.attention);
      expect(thresholds.bloodPressure.labelFor(130, 75), 'High blood pressure');
      expect(thresholds.bloodPressure.labelFor(115, 85), 'High blood pressure');
      expect(
        thresholds.bloodPressure.labelFor(190, 125),
        'High blood pressure',
      );
      expect(thresholds.bloodPressure.labelFor(115, 75), 'Normal');
    });
  });
}
