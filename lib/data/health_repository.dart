import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/daily_activity.dart';
import '../models/health_measurement.dart';

class HealthDashboardData {
  const HealthDashboardData({
    required this.measurements,
    required this.dailyActivity,
  });

  final List<HealthMeasurement> measurements;
  final DailyActivitySnapshot dailyActivity;
}

class HealthRepositoryException implements Exception {
  const HealthRepositoryException(this.message);

  final String message;

  @override
  String toString() => message;
}

abstract interface class HealthRepository {
  Future<HealthDashboardData> loadDashboard({DateTime? activityDate});

  Future<void> saveMeasurement(HealthMeasurementDraft draft);

  Future<void> saveDailyActivity(DailyActivityDraft draft);

  Future<void> addSimulatedSmartwatchSample(DateTime recordedAt);
}

class SupabaseHealthRepository implements HealthRepository {
  SupabaseHealthRepository(this._client);

  final SupabaseClient _client;
  static const _healthRecordsTable = 'health_records';
  static const _dailyActivityTable = 'daily_activity';
  static const _usersTable = 'users';

  @override
  Future<HealthDashboardData> loadDashboard({DateTime? activityDate}) async {
    final userId = _requireUserId();
    final date = activityDate ?? DateTime.now();

    try {
      final latestRows = await Future.wait(
        HealthMetric.values.map(
          (metric) => _loadLatestMeasurement(userId, metric),
        ),
      );
      final activityRows = await _client
          .from(_dailyActivityTable)
          .select()
          .eq('user_id', userId)
          .eq('recorded_date', _dateToString(date))
          .order('recorded_at', ascending: false);

      return HealthDashboardData(
        measurements: [
          for (final row in latestRows)
            if (row != null) _measurementFromRow(row),
        ],
        dailyActivity: _activityFromRows(activityRows, date),
      );
    } on PostgrestException catch (error) {
      throw HealthRepositoryException(error.message);
    } on FormatException catch (error) {
      throw HealthRepositoryException(error.message);
    }
  }

  Future<Map<String, dynamic>?> _loadLatestMeasurement(
    String userId,
    HealthMetric metric,
  ) async {
    final rows = await _client
        .from(_healthRecordsTable)
        .select('record_id,metric_type,value,unit,source_type,recorded_at')
        .eq('user_id', userId)
        .eq('metric_type', metric.databaseValue)
        .order('recorded_at', ascending: false)
        .limit(1);
    return rows.isEmpty ? null : rows.first;
  }

  @override
  Future<void> saveMeasurement(HealthMeasurementDraft draft) async {
    final userId = _requireUserId();
    final value = draft.metric == HealthMetric.bloodPressure
        ? {'systolic': draft.value, 'diastolic': draft.secondaryValue}
        : draft.value;
    try {
      await _client.from(_healthRecordsTable).insert({
        'user_id': userId,
        'metric_type': draft.metric.databaseValue,
        'value': value,
        'unit': draft.metric.unit,
        'source_type': draft.source.databaseValue,
        'recorded_at': draft.recordedAt.toUtc().toIso8601String(),
      });
    } on PostgrestException catch (error) {
      throw HealthRepositoryException(error.message);
    }
  }

  @override
  Future<void> saveDailyActivity(DailyActivityDraft draft) async {
    if (draft.values.isEmpty) {
      throw const HealthRepositoryException(
        'Enter at least one daily activity value.',
      );
    }
    final userId = _requireUserId();
    final weight = draft.values[ActivityMetric.weightKg];
    final row = <String, Object?>{
      'user_id': userId,
      'recorded_date': _dateToString(draft.recordedAt),
      'recorded_at': draft.recordedAt.toUtc().toIso8601String(),
      'source_type': HealthDataSource.manual.databaseValue,
      for (final entry in draft.values.entries)
        entry.key.databaseColumn: entry.value,
    };

    try {
      await _client
          .from(_dailyActivityTable)
          .upsert(row, onConflict: 'user_id,recorded_date,source_type');
      if (weight != null) {
        await _client
            .from(_usersTable)
            .update({'current_weight_kg': weight})
            .eq('user_id', userId);
      }
    } on PostgrestException catch (error) {
      throw HealthRepositoryException(
        weight != null
            ? 'Activity data was saved, but the profile weight update failed: '
                  '${error.message}'
            : error.message,
      );
    }
  }

  @override
  Future<void> addSimulatedSmartwatchSample(DateTime recordedAt) async {
    final userId = _requireUserId();
    final timestamp = recordedAt.toUtc().toIso8601String();

    try {
      await _client.from(_healthRecordsTable).insert([
        {
          'user_id': userId,
          'metric_type': HealthMetric.heartRate.databaseValue,
          'value': 72,
          'unit': HealthMetric.heartRate.unit,
          'source_type': HealthDataSource.simulatedSmartwatch.databaseValue,
          'recorded_at': timestamp,
        },
        {
          'user_id': userId,
          'metric_type': HealthMetric.spo2.databaseValue,
          'value': 98,
          'unit': HealthMetric.spo2.unit,
          'source_type': HealthDataSource.simulatedSmartwatch.databaseValue,
          'recorded_at': timestamp,
        },
      ]);
      await _client.from(_dailyActivityTable).upsert({
        'user_id': userId,
        'recorded_date': _dateToString(recordedAt),
        'recorded_at': timestamp,
        'source_type': HealthDataSource.simulatedSmartwatch.databaseValue,
        ActivityMetric.steps.databaseColumn: 6200,
        ActivityMetric.sleepDurationHours.databaseColumn: 7.5,
      }, onConflict: 'user_id,recorded_date,source_type');
    } on PostgrestException catch (error) {
      throw HealthRepositoryException(error.message);
    }
  }

  String _requireUserId() {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) {
      throw const HealthRepositoryException(
        'Your session has expired. Sign in again to view health data.',
      );
    }
    return userId;
  }

  HealthMeasurement _measurementFromRow(Map<String, dynamic> row) {
    final metric = HealthMetric.fromDatabase(row['metric_type']);
    final storedValue = row['value'];
    double? value;
    double? secondaryValue;

    if (metric == HealthMetric.bloodPressure) {
      if (storedValue is Map) {
        value = _asDouble(storedValue['systolic']);
        secondaryValue = _asDouble(storedValue['diastolic']);
      }
      if (value == null || secondaryValue == null) {
        throw const FormatException('Blood pressure record is incomplete.');
      }
    } else {
      value = _asDouble(storedValue);
      if (value == null) {
        throw FormatException('Invalid value for ${metric.label}.');
      }
    }

    final id = row['record_id'] as String?;
    final recordedAt = DateTime.tryParse(row['recorded_at'] as String? ?? '');
    if (id == null || recordedAt == null) {
      throw const FormatException('Health record is missing its ID or time.');
    }

    return HealthMeasurement(
      id: id,
      metric: metric,
      value: value,
      secondaryValue: secondaryValue,
      source: HealthDataSource.fromDatabase(row['source_type']),
      recordedAt: recordedAt,
    );
  }

  DailyActivitySnapshot _activityFromRows(
    List<Map<String, dynamic>> rows,
    DateTime date,
  ) {
    final values = <ActivityMetric, ActivityMetricValue>{};
    for (final row in rows) {
      final recordedAt = DateTime.tryParse(row['recorded_at'] as String? ?? '');
      if (recordedAt == null) {
        throw const FormatException('Activity record is missing its time.');
      }
      final source = HealthDataSource.fromDatabase(row['source_type']);
      for (final metric in ActivityMetric.values) {
        final value = _asDouble(row[metric.databaseColumn]);
        if (value == null || values.containsKey(metric)) continue;
        values[metric] = ActivityMetricValue(
          value: value,
          source: source,
          recordedAt: recordedAt,
        );
      }
    }
    return DailyActivitySnapshot(recordedDate: date, values: values);
  }

  double? _asDouble(Object? value) {
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }

  String _dateToString(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-'
      '${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';
}
