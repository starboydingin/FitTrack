import 'dart:async';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/utils/local_database.dart';
import '../../data/models/activity_model.dart';

// Native sensor imports — hanya digunakan saat bukan Web
import 'package:geolocator/geolocator.dart'
    if (dart.library.html) '../../../../core/stubs/geolocator_stub.dart';
import 'package:pedometer/pedometer.dart'
    if (dart.library.html) '../../../../core/stubs/pedometer_stub.dart';
import 'package:sensors_plus/sensors_plus.dart'
    if (dart.library.html) '../../../../core/stubs/sensors_stub.dart';

// ─── State ───────────────────────────────────────────────────────────────────

class TrackingState {
  final bool isTracking;
  final int steps;
  final int distanceMeters;
  final String activityType; // 'idle', 'walking', 'running'
  final double? latitude;
  final double? longitude;
  final double? gpsAccuracy;
  final double accelX;
  final double accelY;
  final double accelZ;
  final DateTime? startTime;
  final String? localId;

  const TrackingState({
    this.isTracking = false,
    this.steps = 0,
    this.distanceMeters = 0,
    this.activityType = 'idle',
    this.latitude,
    this.longitude,
    this.gpsAccuracy,
    this.accelX = 0.0,
    this.accelY = 0.0,
    this.accelZ = 0.0,
    this.startTime,
    this.localId,
  });

  TrackingState copyWith({
    bool? isTracking,
    int? steps,
    int? distanceMeters,
    String? activityType,
    double? latitude,
    double? longitude,
    double? gpsAccuracy,
    double? accelX,
    double? accelY,
    double? accelZ,
    DateTime? startTime,
    String? localId,
  }) {
    return TrackingState(
      isTracking: isTracking ?? this.isTracking,
      steps: steps ?? this.steps,
      distanceMeters: distanceMeters ?? this.distanceMeters,
      activityType: activityType ?? this.activityType,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      gpsAccuracy: gpsAccuracy ?? this.gpsAccuracy,
      accelX: accelX ?? this.accelX,
      accelY: accelY ?? this.accelY,
      accelZ: accelZ ?? this.accelZ,
      startTime: startTime ?? this.startTime,
      localId: localId ?? this.localId,
    );
  }
}

// ─── Notifier ────────────────────────────────────────────────────────────────

class TrackingNotifier extends StateNotifier<TrackingState> {
  TrackingNotifier() : super(const TrackingState());

  // Native sensor subscriptions
  StreamSubscription<Position>? _gpsSubscription;
  StreamSubscription<StepCount>? _pedometerSubscription;
  StreamSubscription<UserAccelerometerEvent>? _accelSubscription;

  // Web fallback timer because native sensor plugins are unavailable in browser.
  Timer? _webFallbackTimer;

  int? _initialSteps;
  Position? _lastPosition;

  final _uuid = const Uuid();

  // ── Flag helper ────────────────────────────────────────────────────────────

  // ── Public API ─────────────────────────────────────────────────────────────

  /// Pause sensor subscriptions when the app goes to background.
  /// Sensor streams become stale when the OS suspends the process,
  /// so we cancel them and re-subscribe on resume.
  void pauseSensors() {
    if (!state.isTracking) return;
    _webFallbackTimer?.cancel();
    _webFallbackTimer = null;
    _pedometerSubscription?.cancel();
    _pedometerSubscription = null;
    _gpsSubscription?.cancel();
    _gpsSubscription = null;
    _accelSubscription?.cancel();
    _accelSubscription = null;
  }

  /// Re-subscribe to sensors after returning from background.
  /// Resets _initialSteps so the pedometer baseline is recalibrated.
  Future<void> resumeSensors() async {
    if (!state.isTracking) return;
    // Ensure clean slate
    _webFallbackTimer?.cancel();
    _webFallbackTimer = null;
    _pedometerSubscription?.cancel();
    _pedometerSubscription = null;
    _gpsSubscription?.cancel();
    _gpsSubscription = null;
    _accelSubscription?.cancel();
    _accelSubscription = null;
    // Reset baseline so next pedometer event recalibrates
    _initialSteps = null;

    if (kIsWeb) {
      _startWebFallback();
    } else {
      await _startNativeSensors();
    }
  }

  Future<void> startTracking() async {
    if (state.isTracking) return;

    final localId = _uuid.v4();
    final startTime = DateTime.now();
    _initialSteps = null;
    _lastPosition = null;

    state = TrackingState(
      isTracking: true,
      localId: localId,
      startTime: startTime,
      steps: 0,
      distanceMeters: 0,
      activityType: 'idle',
    );

    if (kIsWeb) {
      _startWebFallback();
    } else {
      await _startNativeSensors();
    }
  }

  Future<void> stopTracking() async {
    if (!state.isTracking) return;

    // Hentikan semua sensor / fallback
    _webFallbackTimer?.cancel();
    _webFallbackTimer = null;
    await _pedometerSubscription?.cancel();
    await _gpsSubscription?.cancel();
    await _accelSubscription?.cancel();
    _pedometerSubscription = null;
    _gpsSubscription = null;
    _accelSubscription = null;

    final endTime = DateTime.now();

    // Simpan ke lokal (SQLite di mobile, in-memory di Web)
    // Wrap DB write in try-catch so a failed write never prevents state reset
    try {
      if (state.localId != null && state.startTime != null) {
        final activity = ActivityModel(
          localId: state.localId!,
          activityDate: state.startTime!.toIso8601String().split('T')[0],
          startedAt: state.startTime!,
          endedAt: endTime,
          steps: state.steps,
          distanceMeters: state.distanceMeters,
          activityType: state.activityType,
          latitude: state.latitude,
          longitude: state.longitude,
          recordedAt: endTime,
          syncStatus: 'pending',
        );
        await LocalDatabase.insertActivity(activity.toDbMap());
      }
    } catch (_) {
      // Silently continue — the activity data may be lost but the UI
      // must recover gracefully instead of being stuck in tracking state.
    }

    state = const TrackingState(isTracking: false);
  }

  // ── Web Fallback ──────────────────────────────────────────────────────────

  int _webFallbackTick = 0;

  void _startWebFallback() {
    _webFallbackTick = 0;
    _webFallbackTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!state.isTracking) return;
      _webFallbackTick++;

      // Simulasi langkah: ~1.5 langkah/detik saat walking
      final newSteps = state.steps + 2;

      // Simulasi jarak: ~1.2 m/detik
      final newDist = state.distanceMeters + 1;

      // Simulasi akselerasi & activity type bervariasi tiap ~5 detik
      final cycle = _webFallbackTick % 15;
      String activityType;
      double ax, ay, az;
      if (cycle < 5) {
        activityType = 'idle';
        ax = 0.1;
        ay = 0.1;
        az = 0.2;
      } else if (cycle < 11) {
        activityType = 'walking';
        ax = 1.2;
        ay = 0.8;
        az = 1.5;
      } else {
        activityType = 'running';
        ax = 3.5;
        ay = 2.8;
        az = 4.1;
      }

      // Simulasi GPS koordinat (bergerak sedikit tiap tick)
      final lat = (state.latitude ?? -6.20000) - (0.000005 * _webFallbackTick);
      final lng =
          (state.longitude ?? 106.81660) + (0.000004 * _webFallbackTick);

      state = state.copyWith(
        steps: newSteps,
        distanceMeters: newDist,
        activityType: activityType,
        accelX: ax,
        accelY: ay,
        accelZ: az,
        latitude: lat,
        longitude: lng,
        gpsAccuracy: 5.0,
      );
    });
  }

  // ── Native Sensors ─────────────────────────────────────────────────────────

  Future<void> _startNativeSensors() async {
    // 1. Pedometer
    try {
      _pedometerSubscription = Pedometer.stepCountStream.listen(
        _onStepCount,
        onError: (_) {},
      );
    } catch (_) {}

    // 2. Geolocator
    try {
      final isLocEnabled = await Geolocator.isLocationServiceEnabled();
      if (isLocEnabled) {
        _gpsSubscription = Geolocator.getPositionStream(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.high,
            distanceFilter: 5,
          ),
        ).listen(_onLocationUpdate, onError: (_) {});
      }
    } catch (_) {}

    // 3. Accelerometer
    try {
      _accelSubscription = userAccelerometerEventStream().listen(
        _onAccelerometerUpdate,
        onError: (_) {},
      );
    } catch (_) {}
  }

  // ── Sensor Callbacks ───────────────────────────────────────────────────────

  void _onStepCount(StepCount event) {
    if (!state.isTracking) return;
    if (_initialSteps == null) {
      _initialSteps = event.steps;
      return;
    }
    state = state.copyWith(steps: event.steps - _initialSteps!);
  }

  void _onLocationUpdate(Position position) {
    if (!state.isTracking) return;

    int newDistance = state.distanceMeters;
    if (_lastPosition != null) {
      newDistance += Geolocator.distanceBetween(
        _lastPosition!.latitude,
        _lastPosition!.longitude,
        position.latitude,
        position.longitude,
      ).round();
    }
    _lastPosition = position;

    state = state.copyWith(
      latitude: position.latitude,
      longitude: position.longitude,
      gpsAccuracy: position.accuracy,
      distanceMeters: newDistance,
    );
  }

  void _onAccelerometerUpdate(UserAccelerometerEvent event) {
    if (!state.isTracking) return;

    final double ax = event.x;
    final double ay = event.y;
    final double az = event.z;
    final double mag = ax * ax + ay * ay + az * az;

    String type = 'idle';
    if (mag >= 20.0) {
      type = 'running';
    } else if (mag >= 2.0) {
      type = 'walking';
    }

    state = state.copyWith(
      accelX: ax,
      accelY: ay,
      accelZ: az,
      activityType: type,
    );
  }

  @override
  void dispose() {
    _webFallbackTimer?.cancel();
    _pedometerSubscription?.cancel();
    _gpsSubscription?.cancel();
    _accelSubscription?.cancel();
    super.dispose();
  }
}

// ─── Provider ────────────────────────────────────────────────────────────────

final trackingProvider =
    StateNotifierProvider<TrackingNotifier, TrackingState>((ref) {
  return TrackingNotifier();
});
