import 'dart:io';

import 'package:usage_stats/usage_stats.dart';

/// Android-only. Uses the system "Usage Access" permission to look at
/// screen on/off history and suggest last night's sleep window, as a
/// stand-in for a dedicated sleep tracker.
///
/// This is a heuristic, not a real sleep measurement — it just finds the
/// longest stretch the screen was off overnight. It's always presented to
/// the user as a suggestion they confirm or adjust, never logged silently.
class ScreenTimeService {
  static ScreenTimeService? _instance;
  static ScreenTimeService get instance => _instance ??= ScreenTimeService._();
  ScreenTimeService._();

  // Matches Android's UsageEvents.Event constants.
  static const int _screenInteractive = 15;
  static const int _screenNonInteractive = 16;

  static const _minPlausibleSleep = Duration(hours: 2);

  bool get isSupported => Platform.isAndroid;

  Future<bool> hasPermission() async {
    if (!isSupported) return false;
    try {
      final granted = await UsageStats.checkUsagePermission();
      return granted ?? false;
    } catch (_) {
      return false;
    }
  }

  /// Opens Android's system "Usage Access" settings so the user can grant
  /// permission manually. Android doesn't allow this to be requested as a
  /// normal in-app dialog. Returns to the app; check [hasPermission] again
  /// on resume.
  void openPermissionSettings() {
    if (!isSupported) return;
    UsageStats.grantUsagePermission();
  }

  /// Finds the longest continuous screen-off window between 6pm yesterday
  /// and noon today, as a candidate for last night's sleep. Returns null if
  /// unsupported, unauthorized, or nothing plausible (< 2h) was found.
  Future<SleepSuggestion?> detectLastNightSleep() async {
    if (!await hasPermission()) return null;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final windowStart = today.subtract(const Duration(hours: 6)); // 6pm yesterday
    final windowEnd = today.add(const Duration(hours: 12)); // noon today
    final effectiveEnd = windowEnd.isBefore(now) ? windowEnd : now;

    try {
      final events = await UsageStats.queryEvents(windowStart, effectiveEnd);

      final screenEvents =
          events
              .map((e) {
                final type = int.tryParse(e.eventType ?? '');
                final ts = int.tryParse(e.timeStamp ?? '');
                if (type == null || ts == null) return null;
                if (type != _screenInteractive &&
                    type != _screenNonInteractive) {
                  return null;
                }
                return _ScreenEvent(
                  isOn: type == _screenInteractive,
                  time: DateTime.fromMillisecondsSinceEpoch(ts),
                );
              })
              .whereType<_ScreenEvent>()
              .toList()
            ..sort((a, b) => a.time.compareTo(b.time));

      if (screenEvents.isEmpty) return null;

      DateTime? offStart;
      DateTime bestStart = windowStart;
      DateTime bestEnd = windowStart;

      void considerCandidate(DateTime start, DateTime end) {
        if (end.difference(start) > bestEnd.difference(bestStart)) {
          bestStart = start;
          bestEnd = end;
        }
      }

      for (final e in screenEvents) {
        if (!e.isOn) {
          offStart ??= e.time;
        } else if (offStart != null) {
          considerCandidate(offStart!, e.time);
          offStart = null;
        }
      }
      // Screen was still off when the query window ended.
      if (offStart != null) {
        considerCandidate(offStart!, effectiveEnd);
      }

      final duration = bestEnd.difference(bestStart);
      if (duration < _minPlausibleSleep) return null;

      return SleepSuggestion(bedtime: bestStart, wakeTime: bestEnd);
    } catch (_) {
      return null;
    }
  }
}

class SleepSuggestion {
  final DateTime bedtime;
  final DateTime wakeTime;

  const SleepSuggestion({required this.bedtime, required this.wakeTime});

  Duration get duration => wakeTime.difference(bedtime);
  double get hours => duration.inMinutes / 60.0;
}

class _ScreenEvent {
  final bool isOn;
  final DateTime time;
  const _ScreenEvent({required this.isOn, required this.time});
}
