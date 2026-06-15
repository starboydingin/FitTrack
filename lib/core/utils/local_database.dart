// Conditional import: Dart hanya mengkompilasi SALAH SATU file di bawah,
// bukan keduanya. Tidak ada konflik nama atau type mismatch.
import 'local_database_mobile.dart'
    // ignore: uri_does_not_exist
    if (dart.library.html) 'local_database_web.dart';

/// Facade publik untuk storage lokal.
///
/// Semua caller (provider, repository) hanya import file ini.
/// Implementasi backend (SQLite vs in-memory) dipilih saat compile-time.
class LocalDatabase {
  // ── User Profile ──────────────────────────────────────────────────────────

  static Future<void> saveUserProfile(Map<String, dynamic> user) =>
      LocalDatabaseImpl.saveUserProfile({
        'id':        user['id'],
        'name':      user['name'],
        'email':     user['email'],
        'weight_kg': user['weightKg'] ?? user['weight_kg'],
        'height_cm': user['heightCm'] ?? user['height_cm'],
      });

  static Future<Map<String, dynamic>?> getUserProfile() =>
      LocalDatabaseImpl.getUserProfile();

  static Future<void> clearUserProfile() =>
      LocalDatabaseImpl.clearUserProfile();

  // ── Activities ─────────────────────────────────────────────────────────────

  static Future<void> insertActivity(Map<String, dynamic> activity) =>
      LocalDatabaseImpl.insertActivity(activity);

  static Future<List<Map<String, dynamic>>> getUnsyncedActivities() =>
      LocalDatabaseImpl.getUnsyncedActivities();

  static Future<void> updateSyncStatus(List<String> localIds, String status) =>
      LocalDatabaseImpl.updateSyncStatus(localIds, status);

  static Future<List<Map<String, dynamic>>> getActivitiesForDate(
          String date) =>
      LocalDatabaseImpl.getActivitiesForDate(date);

  static Future<List<Map<String, dynamic>>> getAllLocalActivities() =>
      LocalDatabaseImpl.getAllLocalActivities();

  static Future<void> clearAllActivities() =>
      LocalDatabaseImpl.clearAllActivities();
}
