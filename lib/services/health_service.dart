import 'dart:async';

import 'package:health/health.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Wraps Apple HealthKit (iOS) and Health Connect (Android).
///
/// Health Connect acts as the shared hub other apps (Google Fit, Samsung
/// Health, Fitbit, Strava, etc.) write into, so once the user grants
/// permission here we can read whichever of those apps they actually use —
/// we don't need a separate integration per app.
class HealthService {
  static HealthService? _instance;
  static HealthService get instance => _instance ??= HealthService._();
  HealthService._();

  static const _connectedPrefKey = 'health_connected';

  final Health _health = Health();

  static const List<HealthDataType> _readTypes = [
    HealthDataType.STEPS,
    HealthDataType.ACTIVE_ENERGY_BURNED,
    HealthDataType.DISTANCE_WALKING_RUNNING,
    HealthDataType.HEART_RATE,
    HealthDataType.WORKOUT,
  ];

  bool _configured = false;

  Future<void> _ensureConfigured() async {
    if (_configured) return;
    await _health.configure();
    _configured = true;
  }

  /// Whether the user has previously granted access.
  Future<bool> isConnected() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_connectedPrefKey) ?? false;
  }

  /// Requests permission to read activity data from the platform's health
  /// store (HealthKit on iOS, Health Connect on Android). Returns true if
  /// granted.
  Future<bool> requestPermissions() async {
    await _ensureConfigured();
    final granted = await _health.requestAuthorization(
      _readTypes,
      permissions: List.filled(_readTypes.length, HealthDataAccess.READ),
    );
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_connectedPrefKey, granted);
    return granted;
  }

  Future<void> disconnect() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_connectedPrefKey, false);
  }

  /// Today's headline metrics for the activity screen's step ring.
  Future<DailySummary> fetchTodaySummary() async {
    await _ensureConfigured();
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);

    final steps =
        await _health.getTotalStepsInInterval(startOfDay, now) ?? 0;

    final points = await _health.getHealthDataFromTypes(
      startTime: startOfDay,
      endTime: now,
      types: [
        HealthDataType.ACTIVE_ENERGY_BURNED,
        HealthDataType.DISTANCE_WALKING_RUNNING,
        HealthDataType.HEART_RATE,
        HealthDataType.WORKOUT,
      ],
    );

    double calories = 0;
    double distanceMeters = 0;
    final heartRates = <double>[];
    int activeMinutes = 0;
    int workoutsToday = 0;

    for (final p in points) {
      final value = p.value;
      final numeric = value is NumericHealthValue
          ? value.numericValue.toDouble()
          : 0.0;
      switch (p.type) {
        case HealthDataType.ACTIVE_ENERGY_BURNED:
          calories += numeric;
          break;
        case HealthDataType.DISTANCE_WALKING_RUNNING:
          distanceMeters += numeric;
          break;
        case HealthDataType.HEART_RATE:
          heartRates.add(numeric);
          break;
        case HealthDataType.WORKOUT:
          workoutsToday += 1;
          activeMinutes += p.dateTo.difference(p.dateFrom).inMinutes;
          break;
        default:
          break;
      }
    }

    final avgHeartRate = heartRates.isEmpty
        ? null
        : heartRates.reduce((a, b) => a + b) / heartRates.length;

    return DailySummary(
      steps: steps,
      caloriesKcal: calories,
      distanceKm: distanceMeters / 1000,
      avgHeartRateBpm: avgHeartRate,
      activeMinutes: activeMinutes,
      workoutsToday: workoutsToday,
      asOf: now,
    );
  }

  /// Steps per day for the last [days] days (oldest first), for the bar chart.
  Future<List<double>> fetchDailyStepsSeries({int days = 9}) async {
    await _ensureConfigured();
    final now = DateTime.now();
    final results = <double>[];
    for (int i = days - 1; i >= 0; i--) {
      final dayStart = DateTime(now.year, now.month, now.day - i);
      final dayEnd = i == 0 ? now : dayStart.add(const Duration(days: 1));
      final steps = await _health.getTotalStepsInInterval(dayStart, dayEnd);
      results.add((steps ?? 0).toDouble());
    }
    return results;
  }

  /// Minutes of logged workouts/exercise per day for the last [days] days
  /// (oldest first) — real activity data, not a screen-time proxy.
  Future<List<double>> fetchDailyActiveMinutesSeries({int days = 9}) async {
    await _ensureConfigured();
    final now = DateTime.now();
    final results = <double>[];
    for (int i = days - 1; i >= 0; i--) {
      final dayStart = DateTime(now.year, now.month, now.day - i);
      final dayEnd = i == 0 ? now : dayStart.add(const Duration(days: 1));
      final points = await _health.getHealthDataFromTypes(
        startTime: dayStart,
        endTime: dayEnd,
        types: [HealthDataType.WORKOUT],
      );
      int minutes = 0;
      for (final p in points) {
        minutes += p.dateTo.difference(p.dateFrom).inMinutes;
      }
      results.add(minutes.toDouble());
    }
    return results;
  }
}

class DailySummary {
  final int steps;
  final double caloriesKcal;
  final double distanceKm;
  final double? avgHeartRateBpm;
  final int activeMinutes;
  final int workoutsToday;
  final DateTime asOf;

  const DailySummary({
    required this.steps,
    required this.caloriesKcal,
    required this.distanceKm,
    required this.avgHeartRateBpm,
    required this.activeMinutes,
    required this.workoutsToday,
    required this.asOf,
  });
}
