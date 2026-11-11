import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:astro_vitals/data/account_repository.dart';
import 'package:astro_vitals/data/health_repository.dart';
import 'package:astro_vitals/main.dart';
import 'package:astro_vitals/models/daily_activity.dart';
import 'package:astro_vitals/models/health_measurement.dart';
import 'package:astro_vitals/models/astro_vitals_user.dart';

void main() {
  testWidgets('app shell switches between responsive destinations', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      AstroVitalsApp(
        accountRepository: _FakeAccountRepository(),
        healthRepository: _FakeHealthRepository(),
        initialUser: AstroVitalsUser(
          astronautId: 'AV-0001',
          fullName: 'Alex Morgan',
          email: 'alex@example.com',
          dateOfBirth: DateTime(1990, 1, 1),
          heightCm: 172,
          weightKg: 68,
        ),
      ),
    );

    expect(find.byType(NavigationBar), findsOneWidget);
    expect(find.text('Welcome, Alex Morgan'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('navigation-Health')));
    await tester.pumpAndSettle();
    expect(find.text('Daily health'), findsOneWidget);
    expect(find.textContaining('No health readings yet.'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('health-threshold-notice')),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const ValueKey('navigation-History')));
    await tester.pumpAndSettle();
    expect(
      find.textContaining('Historical health records and daily or weekly'),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const ValueKey('navigation-Devices')));
    await tester.pumpAndSettle();
    expect(
      find.textContaining('Wearable and medical-device management'),
      findsOneWidget,
    );

    tester.view.physicalSize = const Size(1000, 800);
    await tester.pumpAndSettle();
    expect(find.byType(NavigationRail), findsOneWidget);
    expect(find.byType(NavigationBar), findsNothing);
  });

  testWidgets('saves manual and clearly labeled simulated health readings', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final healthRepository = _FakeHealthRepository();
    await tester.pumpWidget(
      AstroVitalsApp(
        accountRepository: _FakeAccountRepository(),
        healthRepository: healthRepository,
        initialUser: AstroVitalsUser(
          astronautId: 'AV-0002',
          fullName: 'Jordan Lee',
          email: 'jordan@example.com',
          dateOfBirth: DateTime(1991, 2, 3),
          heightCm: 178,
          weightKg: 74,
        ),
      ),
    );

    await tester.tap(find.byKey(const ValueKey('navigation-Health')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('health-simulate-readings')));
    await tester.pumpAndSettle();

    expect(healthRepository.measurements, hasLength(2));
    expect(
      healthRepository.measurements.every(
        (measurement) =>
            measurement.source == HealthDataSource.simulatedSmartwatch,
      ),
      isTrue,
    );
    expect(find.textContaining('Source: Simulated smartwatch'), findsWidgets);
    expect(find.text('72'), findsOneWidget);
    expect(find.text('98'), findsOneWidget);
    expect(find.text('6,200'), findsNothing);
    expect(find.text('6200'), findsOneWidget);
    expect(find.text('7.5'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('health-add-measurement')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('health-entry-metric')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Blood pressure').last);
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('health-entry-value')),
      '128',
    );
    await tester.enterText(
      find.byKey(const ValueKey('health-entry-secondary-value')),
      '82',
    );
    await tester.ensureVisible(find.byKey(const ValueKey('health-entry-save')));
    await tester.tap(find.byKey(const ValueKey('health-entry-save')));
    await tester.pumpAndSettle();

    expect(find.text('128/82'), findsOneWidget);
    expect(find.text('Source: Manual'), findsOneWidget);
    expect(healthRepository.measurements.last.source, HealthDataSource.manual);
    expect(healthRepository.measurements.last.recordedAt, isNotNull);
  });

  testWidgets('saves manual daily activity with its timestamp and source', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final healthRepository = _FakeHealthRepository();
    await tester.pumpWidget(
      AstroVitalsApp(
        accountRepository: _FakeAccountRepository(),
        healthRepository: healthRepository,
        initialUser: AstroVitalsUser(
          astronautId: 'AV-0003',
          fullName: 'Taylor Kim',
          email: 'taylor@example.com',
          dateOfBirth: DateTime(1992, 3, 4),
          heightCm: 170,
          weightKg: 65,
        ),
      ),
    );

    await tester.tap(find.byKey(const ValueKey('navigation-Health')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('health-add-activity')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('activity-entry-water_intake_ml')),
      '750',
    );
    await tester.enterText(
      find.byKey(const ValueKey('activity-entry-exercise_duration_minutes')),
      '30',
    );
    await tester.ensureVisible(
      find.byKey(const ValueKey('activity-entry-save')),
    );
    await tester.tap(find.byKey(const ValueKey('activity-entry-save')));
    await tester.pumpAndSettle();

    expect(healthRepository.savedActivity, isNotNull);
    expect(
      healthRepository.savedActivity!.values[ActivityMetric.waterIntakeMl],
      750,
    );
    expect(
      healthRepository.savedActivity!.values[ActivityMetric
          .exerciseDurationMinutes],
      30,
    );
    expect(find.text('750'), findsOneWidget);
    expect(find.text('Source: Manual'), findsWidgets);
  });

  testWidgets('registration fields validate required profile details', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      AstroVitalsApp(accountRepository: _FakeAccountRepository()),
    );

    await tester.tap(find.text('Sign up'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Create account'));
    await tester.tap(find.text('Create account'));
    await tester.pumpAndSettle();

    expect(find.text('Enter your astronaut ID'), findsNWidgets(2));
    expect(find.text('Enter your full name'), findsOneWidget);
    expect(find.text('Select your date of birth'), findsOneWidget);
    expect(find.text('Enter your height'), findsOneWidget);
    expect(find.text('Enter your weight'), findsOneWidget);
  });

  testWidgets('registers, signs out, and signs back in during the session', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      AstroVitalsApp(accountRepository: _FakeAccountRepository()),
    );

    await tester.tap(find.text('Sign up'));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const ValueKey('astronaut-id')),
      'AV-1001',
    );
    await tester.enterText(
      find.byKey(const ValueKey('full-name')),
      'Alex Morgan',
    );
    await tester.enterText(
      find.byKey(const ValueKey('email')),
      'alex@example.com',
    );
    await tester.enterText(find.byKey(const ValueKey('password')), 'secure123');
    await tester.enterText(
      find.byKey(const ValueKey('confirm-password')),
      'secure123',
    );
    await tester.ensureVisible(find.text('Select date'));
    await tester.tap(find.text('Select date'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const ValueKey('height')), '172.5');
    await tester.enterText(find.byKey(const ValueKey('weight')), '68.5');

    await tester.ensureVisible(find.text('Create account'));
    await tester.tap(find.text('Create account'));
    await tester.pumpAndSettle();

    expect(find.text('Welcome, Alex Morgan'), findsOneWidget);
    expect(find.text('Astronaut ID: AV-1001'), findsOneWidget);

    await tester.tap(find.text('Sign out'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('email')),
      'alex@example.com',
    );
    await tester.enterText(find.byKey(const ValueKey('password')), 'secure123');
    await tester.tap(find.text('Sign in'));
    await tester.pumpAndSettle();

    expect(find.text('Welcome, Alex Morgan'), findsOneWidget);
  });

  testWidgets('rejects incorrect credentials', (WidgetTester tester) async {
    await tester.pumpWidget(
      AstroVitalsApp(accountRepository: _FakeAccountRepository()),
    );

    await tester.enterText(
      find.byKey(const ValueKey('email')),
      'nobody@example.com',
    );
    await tester.enterText(find.byKey(const ValueKey('password')), 'secure123');
    await tester.tap(find.text('Sign in'));
    await tester.pumpAndSettle();

    expect(find.text('Email or password is incorrect.'), findsOneWidget);
  });

  testWidgets('edits, cancels, saves, and signs back in with profile changes', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      AstroVitalsApp(accountRepository: _FakeAccountRepository()),
    );

    await tester.tap(find.text('Sign up'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('astronaut-id')),
      'AV-2002',
    );
    await tester.enterText(
      find.byKey(const ValueKey('full-name')),
      'Jordan Lee',
    );
    await tester.enterText(
      find.byKey(const ValueKey('email')),
      'jordan@example.com',
    );
    await tester.enterText(find.byKey(const ValueKey('password')), 'secure123');
    await tester.enterText(
      find.byKey(const ValueKey('confirm-password')),
      'secure123',
    );
    await tester.ensureVisible(find.text('Select date'));
    await tester.tap(find.text('Select date'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const ValueKey('height')), '180');
    await tester.enterText(find.byKey(const ValueKey('weight')), '75');
    await tester.ensureVisible(find.text('Create account'));
    await tester.tap(find.text('Create account'));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('navigation-Profile')));
    await tester.pumpAndSettle();
    expect(find.text('jordan@example.com'), findsOneWidget);
    expect(find.text('75 kg'), findsOneWidget);

    await tester.ensureVisible(
      find.byKey(const ValueKey('profile-edit-button')),
    );
    await tester.tap(find.byKey(const ValueKey('profile-edit-button')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('profile-full-name')),
      'Discarded Name',
    );
    await tester.ensureVisible(find.byKey(const ValueKey('profile-cancel')));
    await tester.tap(find.byKey(const ValueKey('profile-cancel')));
    await tester.pumpAndSettle();
    expect(find.text('Jordan Lee'), findsAtLeastNWidgets(1));
    expect(find.text('Discarded Name'), findsNothing);

    await tester.ensureVisible(
      find.byKey(const ValueKey('profile-edit-button')),
    );
    await tester.tap(find.byKey(const ValueKey('profile-edit-button')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('profile-full-name')),
      'Jordan Lee Updated',
    );
    await tester.enterText(
      find.byKey(const ValueKey('profile-email')),
      'jordan.updated@example.com',
    );
    await tester.enterText(
      find.byKey(const ValueKey('profile-weight')),
      '77.5',
    );
    await tester.ensureVisible(find.byKey(const ValueKey('profile-save')));
    await tester.tap(find.byKey(const ValueKey('profile-save')));
    await tester.pumpAndSettle();

    expect(
      find.text('Profile updated. Confirm your new email if prompted.'),
      findsOneWidget,
    );
    expect(find.text('Jordan Lee Updated'), findsAtLeastNWidgets(1));
    expect(find.text('jordan.updated@example.com'), findsOneWidget);
    expect(find.text('77.5 kg'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('navigation-Home')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Sign out'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('email')),
      'jordan.updated@example.com',
    );
    await tester.enterText(find.byKey(const ValueKey('password')), 'secure123');
    await tester.tap(find.text('Sign in'));
    await tester.pumpAndSettle();

    expect(find.text('Welcome, Jordan Lee Updated'), findsOneWidget);
  });

  testWidgets('profile editor validates required and invalid values', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      AstroVitalsApp(accountRepository: _FakeAccountRepository()),
    );

    await tester.tap(find.text('Sign up'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('astronaut-id')),
      'AV-3003',
    );
    await tester.enterText(
      find.byKey(const ValueKey('full-name')),
      'Taylor Kim',
    );
    await tester.enterText(
      find.byKey(const ValueKey('email')),
      'taylor@example.com',
    );
    await tester.enterText(find.byKey(const ValueKey('password')), 'secure123');
    await tester.enterText(
      find.byKey(const ValueKey('confirm-password')),
      'secure123',
    );
    await tester.ensureVisible(find.text('Select date'));
    await tester.tap(find.text('Select date'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const ValueKey('height')), '170');
    await tester.enterText(find.byKey(const ValueKey('weight')), '65');
    await tester.ensureVisible(find.text('Create account'));
    await tester.tap(find.text('Create account'));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('navigation-Profile')));
    await tester.pumpAndSettle();
    await tester.ensureVisible(
      find.byKey(const ValueKey('profile-edit-button')),
    );
    await tester.tap(find.byKey(const ValueKey('profile-edit-button')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const ValueKey('profile-email')), 'bad');
    await tester.enterText(find.byKey(const ValueKey('profile-height')), '0');
    await tester.ensureVisible(find.byKey(const ValueKey('profile-save')));
    await tester.tap(find.byKey(const ValueKey('profile-save')));
    await tester.pumpAndSettle();

    expect(find.text('Enter a valid email address'), findsOneWidget);
    expect(find.text('Enter a number greater than 0'), findsOneWidget);
    expect(find.text('Jordan Kim'), findsNothing);
  });
}

class _FakeAccountRepository implements AccountRepository {
  final Map<String, AstroVitalsUser> _usersByEmail = {};
  final Map<String, String> _passwordsByEmail = {};

  @override
  Future<AstroVitalsUser?> currentUser() async => null;

  @override
  Future<AstroVitalsUser?> register({
    required AstroVitalsUser user,
    required String password,
  }) async {
    final email = user.email.toLowerCase();
    if (_usersByEmail.containsKey(email)) {
      throw const AccountAlreadyExistsException('Email');
    }

    if (_usersByEmail.values.any(
      (existingUser) =>
          existingUser.astronautId.toLowerCase() ==
          user.astronautId.toLowerCase(),
    )) {
      throw const AccountAlreadyExistsException('Astronaut ID');
    }
    _usersByEmail[email] = user;
    _passwordsByEmail[email] = password;
    return user;
  }

  @override
  Future<AstroVitalsUser?> signIn({
    required String email,
    required String password,
  }) async {
    final normalizedEmail = email.toLowerCase();
    if (_passwordsByEmail[normalizedEmail] != password) return null;
    return _usersByEmail[normalizedEmail];
  }

  @override
  Future<void> signOut() async {}

  @override
  Future<void> updateProfile({
    required AstroVitalsUser currentUser,
    required AstroVitalsUser updatedUser,
  }) async {
    final currentEmail = currentUser.email.toLowerCase();
    if (!_usersByEmail.containsKey(currentEmail)) {
      throw const AccountNotFoundException();
    }
    final updatedEmail = updatedUser.email.toLowerCase();
    if (updatedEmail != currentEmail &&
        _usersByEmail.containsKey(updatedEmail)) {
      throw const AccountAlreadyExistsException('Email');
    }
    final password = _passwordsByEmail.remove(currentEmail)!;
    _usersByEmail.remove(currentEmail);
    _usersByEmail[updatedEmail] = updatedUser;
    _passwordsByEmail[updatedEmail] = password;
  }
}

class _FakeHealthRepository implements HealthRepository {
  final List<HealthMeasurement> measurements = [];
  final Map<HealthDataSource, Map<ActivityMetric, ActivityMetricValue>>
  _activityBySource = {};
  DailyActivityDraft? savedActivity;
  var _nextId = 0;

  @override
  Future<HealthDashboardData> loadDashboard({DateTime? activityDate}) async {
    final activity = <ActivityMetric, ActivityMetricValue>{};
    for (final sourceValues in _activityBySource.values) {
      for (final entry in sourceValues.entries) {
        final previous = activity[entry.key];
        if (previous == null ||
            entry.value.recordedAt.isAfter(previous.recordedAt)) {
          activity[entry.key] = entry.value;
        }
      }
    }
    return HealthDashboardData(
      measurements: List.unmodifiable(measurements),
      dailyActivity: DailyActivitySnapshot(
        recordedDate: activityDate ?? DateTime.now(),
        values: activity,
      ),
    );
  }

  @override
  Future<void> saveMeasurement(HealthMeasurementDraft draft) async {
    measurements.add(
      HealthMeasurement(
        id: 'measurement-${_nextId++}',
        metric: draft.metric,
        value: draft.value,
        secondaryValue: draft.secondaryValue,
        source: draft.source,
        recordedAt: draft.recordedAt,
      ),
    );
  }

  @override
  Future<void> saveDailyActivity(DailyActivityDraft draft) async {
    savedActivity = draft;
    final values = _activityBySource.putIfAbsent(
      HealthDataSource.manual,
      () => {},
    );
    for (final entry in draft.values.entries) {
      values[entry.key] = ActivityMetricValue(
        value: entry.value,
        source: HealthDataSource.manual,
        recordedAt: draft.recordedAt,
      );
    }
  }

  @override
  Future<void> addSimulatedSmartwatchSample(DateTime recordedAt) async {
    for (final sample in [
      (HealthMetric.heartRate, 72.0),
      (HealthMetric.spo2, 98.0),
    ]) {
      measurements.add(
        HealthMeasurement(
          id: 'measurement-${_nextId++}',
          metric: sample.$1,
          value: sample.$2,
          source: HealthDataSource.simulatedSmartwatch,
          recordedAt: recordedAt,
        ),
      );
    }
    _activityBySource[HealthDataSource.simulatedSmartwatch] = {
      ActivityMetric.steps: ActivityMetricValue(
        value: 6200,
        source: HealthDataSource.simulatedSmartwatch,
        recordedAt: recordedAt,
      ),
      ActivityMetric.sleepDurationHours: ActivityMetricValue(
        value: 7.5,
        source: HealthDataSource.simulatedSmartwatch,
        recordedAt: recordedAt,
      ),
    };
  }
}
