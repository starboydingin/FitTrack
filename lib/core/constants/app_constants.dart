const String _apiBaseUrlOverride = String.fromEnvironment('API_BASE_URL');
const String _externalApiBaseUrl = 'http://202.10.48.45/fit-track/api/v1';

String get kBaseUrl {
  if (_apiBaseUrlOverride.isNotEmpty) {
    return _apiBaseUrlOverride;
  }
  return _externalApiBaseUrl;
}

// SQLite database name
const String kDbName = 'fitness_tracker.db';
const int kDbVersion = 1;

// Sync settings
const Duration kSyncInterval = Duration(minutes: 15);
const int kSyncRetryMax = 3;

// Geolocator distance filter (meter)
const double kGpsDistanceFilter = 10.0;
