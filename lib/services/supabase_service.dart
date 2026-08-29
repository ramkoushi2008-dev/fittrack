import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseService {
  static SupabaseService? _instance;
  static SupabaseService get instance => _instance ??= SupabaseService._();

  SupabaseService._();

  static const String supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: '',
  );
  static const String supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: '',
  );

  // Initialize Supabase - call this in main()
  static Future<void> initialize() async {
    if (supabaseUrl.isEmpty || supabaseAnonKey.isEmpty) {
      throw Exception(
        'SUPABASE_URL and SUPABASE_ANON_KEY must be defined using --dart-define.',
      );
    }
    await Supabase.initialize(url: supabaseUrl, anonKey: supabaseAnonKey);
  }

  // Get Supabase client
  SupabaseClient get client => Supabase.instance.client;

  // Current authenticated user id
  String? get currentUserId => client.auth.currentUser?.id;

  // ─────────────────────────────────────────────────────────────────────────
  // Ensure user_profile row exists (called after login/signup)
  // ─────────────────────────────────────────────────────────────────────────
  Future<void> ensureUserProfile() async {
    final user = client.auth.currentUser;
    if (user == null) return;
    try {
      await client.from('user_profiles').upsert({
        'id': user.id,
        'email': user.email ?? '',
        'full_name': user.userMetadata?['full_name'] ?? '',
      }, onConflict: 'id');
    } catch (_) {}
  }

  /// Whether this user has already completed the personalization
  /// questionnaire — used right after login to decide whether to route to
  /// Home or back through onboarding.
  Future<bool> hasCompletedOnboarding() async {
    final uid = currentUserId;
    if (uid == null) return false;
    try {
      final row = await client
          .from('user_profiles')
          .select('onboarding_completed')
          .eq('id', uid)
          .maybeSingle();
      return (row?['onboarding_completed'] as bool?) ?? false;
    } catch (_) {
      // If we can't tell, send them through onboarding rather than risk
      // dropping a new user straight onto an empty Home screen.
      return false;
    }
  }

  /// Marks onboarding as complete so future logins go straight to Home.
  Future<void> markOnboardingComplete() async {
    final uid = currentUserId;
    if (uid == null) return;
    try {
      await client
          .from('user_profiles')
          .update({'onboarding_completed': true})
          .eq('id', uid);
    } catch (_) {}
  }

  // ─────────────────────────────────────────────────────────────────────────
  // WORKOUT LOGS
  // ─────────────────────────────────────────────────────────────────────────

  /// Save a completed workout session to the cloud
  Future<void> saveWorkoutLog({
    required String workoutLabel,
    required int durationSeconds,
    required double caloriesBurned,
    required int totalSets,
    List<Map<String, dynamic>> exercises = const [],
  }) async {
    final uid = currentUserId;
    if (uid == null) return;
    try {
      await client.from('workout_logs').insert({
        'user_id': uid,
        'workout_label': workoutLabel,
        'duration_seconds': durationSeconds,
        'calories_burned': caloriesBurned,
        'total_sets': totalSets,
        'exercises': exercises,
        'logged_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      // Silent fail — local state still works
    }
  }

  /// Fetch all workout logs for the current user (newest first)
  Future<List<Map<String, dynamic>>> fetchWorkoutLogs({int limit = 50}) async {
    final uid = currentUserId;
    if (uid == null) return [];
    try {
      final response = await client
          .from('workout_logs')
          .select()
          .eq('user_id', uid)
          .order('logged_at', ascending: false)
          .limit(limit);
      return List<Map<String, dynamic>>.from(response);
    } catch (_) {
      return [];
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // NUTRITION LOGS
  // ─────────────────────────────────────────────────────────────────────────

  /// Save a single food entry to the cloud
  Future<void> saveNutritionLog({
    required int mealIndex,
    required String foodName,
    required int calories,
    required int protein,
    required int carbs,
    required int fat,
    required String portion,
  }) async {
    final uid = currentUserId;
    if (uid == null) return;
    try {
      await client.from('nutrition_logs').insert({
        'user_id': uid,
        'meal_index': mealIndex,
        'food_name': foodName,
        'calories': calories,
        'protein': protein,
        'carbs': carbs,
        'fat': fat,
        'portion': portion,
        'logged_at': DateTime.now().toIso8601String(),
      });
    } catch (_) {}
  }

  /// Delete a nutrition log entry by id
  Future<void> deleteNutritionLog(String id) async {
    final uid = currentUserId;
    if (uid == null) return;
    try {
      await client
          .from('nutrition_logs')
          .delete()
          .eq('id', id)
          .eq('user_id', uid);
    } catch (_) {}
  }

  /// Fetch today's nutrition logs for the current user
  Future<List<Map<String, dynamic>>> fetchTodayNutritionLogs() async {
    final uid = currentUserId;
    if (uid == null) return [];
    try {
      final today = DateTime.now();
      final startOfDay = DateTime(
        today.year,
        today.month,
        today.day,
      ).toIso8601String();
      final endOfDay = DateTime(
        today.year,
        today.month,
        today.day,
        23,
        59,
        59,
      ).toIso8601String();
      final response = await client
          .from('nutrition_logs')
          .select()
          .eq('user_id', uid)
          .gte('logged_at', startOfDay)
          .lte('logged_at', endOfDay)
          .order('logged_at', ascending: true);
      return List<Map<String, dynamic>>.from(response);
    } catch (_) {
      return [];
    }
  }

  /// Total calories logged per day for the last [days] days (oldest first),
  /// summed from real meals the user has logged — used to drive the
  /// Activity screen's Calories chart tab.
  Future<List<double>> fetchDailyCaloriesSeries({int days = 9}) async {
    final totals = List<double>.filled(days, 0.0);
    final uid = currentUserId;
    if (uid == null) return totals;
    final now = DateTime.now();
    final startDay = DateTime(now.year, now.month, now.day - (days - 1));
    try {
      final response = await client
          .from('nutrition_logs')
          .select()
          .eq('user_id', uid)
          .gte('logged_at', startDay.toIso8601String())
          .order('logged_at', ascending: true);
      final rows = List<Map<String, dynamic>>.from(response);
      for (final row in rows) {
        final loggedAt = DateTime.tryParse(row['logged_at']?.toString() ?? '');
        if (loggedAt == null) continue;
        final rowDay = DateTime(loggedAt.year, loggedAt.month, loggedAt.day);
        final index = rowDay.difference(startDay).inDays;
        if (index < 0 || index >= days) continue;
        totals[index] += (row['calories'] as num?)?.toDouble() ?? 0.0;
      }
      return totals;
    } catch (_) {
      return totals;
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // SLEEP LOGS
  // ─────────────────────────────────────────────────────────────────────────

  /// Save a sleep entry to the cloud
  Future<void> saveSleepLog({required double hoursSlept}) async {
    final uid = currentUserId;
    if (uid == null) return;
    try {
      await client.from('sleep_logs').insert({
        'user_id': uid,
        'hours_slept': hoursSlept,
        'logged_at': DateTime.now().toIso8601String(),
      });
    } catch (_) {}
  }

  /// Fetch the most recent sleep log for the current user
  Future<Map<String, dynamic>?> fetchLatestSleepLog() async {
    final uid = currentUserId;
    if (uid == null) return null;
    try {
      final response = await client
          .from('sleep_logs')
          .select()
          .eq('user_id', uid)
          .order('logged_at', ascending: false)
          .limit(1)
          .maybeSingle();
      return response;
    } catch (_) {
      return null;
    }
  }

  /// Fetch last 7 sleep logs for the current user
  Future<List<Map<String, dynamic>>> fetchWeeklySleepLogs() async {
    final uid = currentUserId;
    if (uid == null) return [];
    try {
      final response = await client
          .from('sleep_logs')
          .select()
          .eq('user_id', uid)
          .order('logged_at', ascending: false)
          .limit(7);
      return List<Map<String, dynamic>>.from(response);
    } catch (_) {
      return [];
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // USER PROFILE (Account Screen)
  // ─────────────────────────────────────────────────────────────────────────

  /// Fetch the current user's full profile
  Future<Map<String, dynamic>?> fetchUserProfile() async {
    final uid = currentUserId;
    if (uid == null) return null;
    try {
      final response = await client
          .from('user_profiles')
          .select()
          .eq('id', uid)
          .maybeSingle();
      return response;
    } catch (_) {
      return null;
    }
  }

  /// Update the current user's profile fields
  Future<bool> updateUserProfile(Map<String, dynamic> fields) async {
    final uid = currentUserId;
    if (uid == null) return false;
    try {
      await client
          .from('user_profiles')
          .update({...fields, 'updated_at': DateTime.now().toIso8601String()})
          .eq('id', uid);
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Update password via Supabase Auth
  Future<String?> updatePassword(String newPassword) async {
    try {
      await client.auth.updateUser(UserAttributes(password: newPassword));
      return null; // null = success
    } catch (e) {
      return e.toString();
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // LINKED DEVICES
  // ─────────────────────────────────────────────────────────────────────────

  Future<List<Map<String, dynamic>>> fetchLinkedDevices() async {
    final uid = currentUserId;
    if (uid == null) return [];
    try {
      final response = await client
          .from('linked_devices')
          .select()
          .eq('user_id', uid)
          .order('created_at', ascending: true);
      return List<Map<String, dynamic>>.from(response);
    } catch (_) {
      return [];
    }
  }

  Future<void> addLinkedDevice({
    required String deviceName,
    required String deviceType,
  }) async {
    final uid = currentUserId;
    if (uid == null) return;
    try {
      await client.from('linked_devices').insert({
        'user_id': uid,
        'device_name': deviceName,
        'device_type': deviceType,
        'is_connected': true,
        'last_synced_at': DateTime.now().toIso8601String(),
      });
    } catch (_) {}
  }

  Future<void> removeLinkedDevice(String deviceId) async {
    final uid = currentUserId;
    if (uid == null) return;
    try {
      await client
          .from('linked_devices')
          .delete()
          .eq('id', deviceId)
          .eq('user_id', uid);
    } catch (_) {}
  }

  Future<void> toggleDeviceConnection(String deviceId, bool isConnected) async {
    final uid = currentUserId;
    if (uid == null) return;
    try {
      await client
          .from('linked_devices')
          .update({
            'is_connected': isConnected,
            'last_synced_at': isConnected
                ? DateTime.now().toIso8601String()
                : null,
          })
          .eq('id', deviceId)
          .eq('user_id', uid);
    } catch (_) {}
  }

  // ─────────────────────────────────────────────────────────────────────────
  // CONNECTED HEALTH APPS
  // ─────────────────────────────────────────────────────────────────────────

  Future<List<Map<String, dynamic>>> fetchConnectedHealthApps() async {
    final uid = currentUserId;
    if (uid == null) return [];
    try {
      final response = await client
          .from('connected_health_apps')
          .select()
          .eq('user_id', uid)
          .order('app_name', ascending: true);
      return List<Map<String, dynamic>>.from(response);
    } catch (_) {
      return [];
    }
  }

  Future<void> upsertHealthApp({
    required String appName,
    required bool isConnected,
  }) async {
    final uid = currentUserId;
    if (uid == null) return;
    try {
      // Check if exists
      final existing = await client
          .from('connected_health_apps')
          .select('id')
          .eq('user_id', uid)
          .eq('app_name', appName)
          .maybeSingle();

      if (existing != null) {
        await client
            .from('connected_health_apps')
            .update({
              'is_connected': isConnected,
              'connected_at': isConnected
                  ? DateTime.now().toIso8601String()
                  : null,
            })
            .eq('id', existing['id']);
      } else {
        await client.from('connected_health_apps').insert({
          'user_id': uid,
          'app_name': appName,
          'is_connected': isConnected,
          'connected_at': isConnected ? DateTime.now().toIso8601String() : null,
        });
      }
    } catch (_) {}
  }

  // ─────────────────────────────────────────────────────────────────────────
  // DELETE ACCOUNT
  // ─────────────────────────────────────────────────────────────────────────

  /// Deletes all user data from all tables, then deletes the underlying
  /// auth identity itself (email/password or linked Google account) via the
  /// `delete-account` Edge Function, and signs out.
  Future<DeleteAccountResult> deleteAccount() async {
    final uid = currentUserId;
    if (uid == null) {
      return DeleteAccountResult(
        signedOut: false,
        warning: 'No authenticated user found.',
      );
    }
    try {
      // Delete all user data from all tables
      await client.from('workout_logs').delete().eq('user_id', uid);
      await client.from('nutrition_logs').delete().eq('user_id', uid);
      await client.from('sleep_logs').delete().eq('user_id', uid);
      await client.from('linked_devices').delete().eq('user_id', uid);
      await client.from('connected_health_apps').delete().eq('user_id', uid);
      await client.from('user_profiles').delete().eq('id', uid);
      // personal_records / user_achievements cascade-delete automatically
      // via their FK to user_profiles(id) ON DELETE CASCADE.
    } catch (e) {
      // Data deletion itself failed — nothing was signed out, safe to retry.
      return DeleteAccountResult(signedOut: false, warning: e.toString());
    }

    // Delete the auth identity itself. This requires the service_role key,
    // which can only run server-side — hence the Edge Function rather than
    // an admin call from here.
    String? authDeleteWarning;
    try {
      final res = await client.functions.invoke('delete-account');
      if (res.status != 200) {
        authDeleteWarning =
            'Your data was deleted, but removing the sign-in credential '
            'failed (status ${res.status}). Deploy the delete-account '
            'Edge Function to fully complete deletion.';
      }
    } catch (e) {
      // The function may not be deployed yet — data is still gone, but the
      // auth identity survives, so surface that clearly.
      authDeleteWarning =
          'Your data was deleted, but removing the sign-in credential '
          'failed: $e. Deploy the delete-account Edge Function to fully '
          'complete deletion.';
    }

    await client.auth.signOut();
    return DeleteAccountResult(signedOut: true, warning: authDeleteWarning);
  }
}

/// Result of [SupabaseService.deleteAccount].
/// [signedOut] indicates whether the session actually ended — if false,
/// nothing was deleted and it's safe to retry. If true but [warning] is
/// non-null, the user's data was deleted but the underlying sign-in
/// credential may still exist (e.g. the delete-account Edge Function isn't
/// deployed yet).
class DeleteAccountResult {
  final bool signedOut;
  final String? warning;
  const DeleteAccountResult({required this.signedOut, this.warning});
}
