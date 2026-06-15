/// Implementasi in-memory — hanya dikompilasi untuk Web.
/// Data hilang saat page refresh (cukup untuk demo/development).
class LocalDatabaseImpl {
  static Map<String, dynamic>? _userProfile;
  static final List<Map<String, dynamic>> _activities = [];

  // ── User Profile ──────────────────────────────────────────────────────────

  static Future<void> saveUserProfile(Map<String, dynamic> record) async {
    _userProfile = Map<String, dynamic>.from(record);
  }

  static Future<Map<String, dynamic>?> getUserProfile() async {
    return _userProfile == null
        ? null
        : Map<String, dynamic>.from(_userProfile!);
  }

  static Future<void> clearUserProfile() async {
    _userProfile = null;
  }

  // ── Activities ─────────────────────────────────────────────────────────────

  static Future<void> insertActivity(Map<String, dynamic> activity) async {
    final idx =
        _activities.indexWhere((m) => m['local_id'] == activity['local_id']);
    if (idx >= 0) {
      _activities[idx] = Map<String, dynamic>.from(activity);
    } else {
      _activities.add(Map<String, dynamic>.from(activity));
    }
  }

  static Future<List<Map<String, dynamic>>> getUnsyncedActivities() async {
    return _activities
        .where((m) =>
            m['sync_status'] == 'pending' || m['sync_status'] == 'failed')
        .map((m) => Map<String, dynamic>.from(m))
        .toList();
  }

  static Future<void> updateSyncStatus(
      List<String> localIds, String status) async {
    for (final m in _activities) {
      if (localIds.contains(m['local_id'])) {
        m['sync_status'] = status;
      }
    }
  }

  static Future<List<Map<String, dynamic>>> getActivitiesForDate(
      String date) async {
    return _activities
        .where((m) => m['activity_date'] == date)
        .map((m) => Map<String, dynamic>.from(m))
        .toList()
      ..sort((a, b) =>
          (a['started_at'] as String).compareTo(b['started_at'] as String));
  }

  static Future<List<Map<String, dynamic>>> getAllLocalActivities() async {
    return _activities
        .map((m) => Map<String, dynamic>.from(m))
        .toList()
      ..sort((a, b) =>
          (b['recorded_at'] as String).compareTo(a['recorded_at'] as String));
  }

  static Future<void> clearAllActivities() async {
    _activities.clear();
  }
}
