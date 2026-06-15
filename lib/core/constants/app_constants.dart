const String kBaseUrl = 'http://10.0.2.2:3000/api/v1'; // 10.0.2.2 = localhost di Android Emulator

// SQLite database name
const String kDbName = 'fitness_tracker.db';
const int kDbVersion = 1;

// Sync settings
const Duration kSyncInterval = Duration(minutes: 15);
const int kSyncRetryMax = 3;

// Geolocator distance filter (meter) — hemat baterai
const double kGpsDistanceFilter = 10.0;

// ── Dummy / Mock Mode ────────────────────────────────────────────────────────
// Set ke `true` agar aplikasi berjalan tanpa backend dan sensor nyata.
// Set ke `false` untuk menggunakan backend dan sensor asli.
const bool kUseDummyMode = true;
