import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/utils/local_database.dart';
import '../../data/models/activity_model.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

// ─── Enum Status ─────────────────────────────────────────────────────────────

enum SyncStatus {
  /// Belum pernah dilakukan sinkronisasi sama sekali.
  neverSynced,

  /// Ada data lokal yang belum terkirim, menunggu koneksi tersedia.
  waitingConnection,

  /// Sinkronisasi sedang berjalan.
  syncing,

  /// Sinkronisasi terakhir berhasil.
  success,

  /// Sinkronisasi gagal dan akan dicoba ulang.
  failed,
}

// ─── State ───────────────────────────────────────────────────────────────────

class SyncState {
  final SyncStatus status;
  final String? errorMessage;
  final DateTime? lastSyncedAt;

  /// Jumlah percobaan retry yang sudah dilakukan untuk sesi gagal terakhir.
  final int retryCount;

  const SyncState({
    this.status = SyncStatus.neverSynced,
    this.errorMessage,
    this.lastSyncedAt,
    this.retryCount = 0,
  });

  SyncState copyWith({
    SyncStatus? status,
    String? errorMessage,
    DateTime? lastSyncedAt,
    int? retryCount,
  }) {
    return SyncState(
      status: status ?? this.status,
      errorMessage: errorMessage ?? this.errorMessage,
      lastSyncedAt: lastSyncedAt ?? this.lastSyncedAt,
      retryCount: retryCount ?? this.retryCount,
    );
  }

  /// Apakah masih bisa retry (belum melebihi batas maksimum).
  bool get canRetry => retryCount < kSyncRetryMax;

  /// Label status yang sesuai dengan dokumen ui-design.md.
  String get statusLabel {
    switch (status) {
      case SyncStatus.neverSynced:
        return 'Belum tersinkron';
      case SyncStatus.waitingConnection:
        return 'Menunggu koneksi';
      case SyncStatus.syncing:
        return 'Menyinkron...';
      case SyncStatus.success:
        return 'Tersinkron';
      case SyncStatus.failed:
        return 'Gagal, akan retry';
    }
  }
}

// ─── Notifier ────────────────────────────────────────────────────────────────

class SyncNotifier extends StateNotifier<SyncState> {
  final ApiClient _apiClient;

  /// Subscription untuk mendengarkan perubahan koneksi secara real-time.
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;

  SyncNotifier(this._apiClient) : super(const SyncState()) {
    checkAndSync();

    _connectivitySubscription =
        Connectivity().onConnectivityChanged.listen(_onConnectivityChanged);
  }

  // ── Connectivity Listener ────────────────────────────────────────────────

  void _onConnectivityChanged(List<ConnectivityResult> results) {
    final isOnline = results.any((r) => r != ConnectivityResult.none);

    if (isOnline &&
        (state.status == SyncStatus.waitingConnection ||
            state.status == SyncStatus.failed)) {
      // Koneksi kembali → coba sync ulang
      syncUnsyncedData();
    }
  }

  // ── Helpers ──────────────────────────────────────────────────────────────

  Future<bool> _isOnline() async {
    final results = await Connectivity().checkConnectivity();
    return results.any((r) => r != ConnectivityResult.none);
  }

  // ── Public API ───────────────────────────────────────────────────────────

  /// Cek koneksi lalu jalankan sync jika online.
  Future<void> checkAndSync() async {
    final online = await _isOnline();
    if (!online) {
      state = state.copyWith(status: SyncStatus.waitingConnection);
      return;
    }
    await syncUnsyncedData();
  }

  /// Upload semua data lokal yang belum tersinkron ke backend.
  Future<void> syncUnsyncedData() async {
    final unsynced = await LocalDatabase.getUnsyncedActivities();
    if (unsynced.isEmpty) {
      // Tidak ada yang perlu dikirim
      state = state.copyWith(
        status: SyncStatus.success,
        lastSyncedAt: state.lastSyncedAt ?? DateTime.now(),
        retryCount: 0,
        errorMessage: null,
      );
      return;
    }

    state = state.copyWith(status: SyncStatus.syncing, errorMessage: null);

    final localIds = unsynced.map((m) => m['local_id'] as String).toList();

    try {
      // Tandai sebagai "syncing" di database lokal
      await LocalDatabase.updateSyncStatus(localIds, 'syncing');

      final activitiesList =
          unsynced.map((m) => ActivityModel.fromDbMap(m).toJson()).toList();

      // deviceId statis untuk sesi ini; bisa diganti ID perangkat sebenarnya
      const deviceId = 'flutter-app-device';

      final response = await _apiClient.post(
        '/activities/sync',
        data: {
          'deviceId': deviceId,
          'lastSyncedAt': state.lastSyncedAt?.toIso8601String() ??
              DateTime.now().toIso8601String(),
          'activities': activitiesList,
        },
      );

      if (response.statusCode == 200 && response.data['success'] == true) {
        final acceptedIds = List<String>.from(
          response.data['data']['acceptedLocalIds'] ?? [],
        );
        await LocalDatabase.updateSyncStatus(acceptedIds, 'synced');

        // Kembalikan yang tidak diterima ke 'failed'
        final rejected =
            localIds.where((id) => !acceptedIds.contains(id)).toList();
        if (rejected.isNotEmpty) {
          await LocalDatabase.updateSyncStatus(rejected, 'failed');
        }

        state = state.copyWith(
          status: SyncStatus.success,
          lastSyncedAt: DateTime.now(),
          retryCount: 0,
          errorMessage: null,
        );
      } else {
        await LocalDatabase.updateSyncStatus(localIds, 'failed');
        _handleSyncFailure(
          localIds,
          response.data['message'] ?? 'Sinkronisasi gagal.',
        );
      }
    } catch (e) {
      await LocalDatabase.updateSyncStatus(localIds, 'failed');
      _handleSyncFailure(
        localIds,
        e.toString().replaceAll('Exception: ', ''),
      );
    }
  }

  void _handleSyncFailure(List<String> localIds, String message) {
    final newRetryCount = state.retryCount + 1;
    state = state.copyWith(
      status: SyncStatus.failed,
      errorMessage: message,
      retryCount: newRetryCount,
    );

    if (newRetryCount < kSyncRetryMax) {
      final delay = Duration(seconds: 5 * newRetryCount);
      Future.delayed(delay, () {
        if (mounted && state.status == SyncStatus.failed) {
          checkAndSync();
        }
      });
    }
  }

  /// Ambil semua data aktivitas dari cloud dan simpan ke lokal.
  Future<void> restoreCloudData() async {
    if (!(await _isOnline())) {
      state = state.copyWith(
        status: SyncStatus.waitingConnection,
        errorMessage: 'Tidak ada koneksi internet.',
      );
      return;
    }

    state = state.copyWith(status: SyncStatus.syncing, errorMessage: null);
    try {
      final response = await _apiClient.get('/activities/restore');
      if (response.statusCode == 200 && response.data['success'] == true) {
        final List activitiesRaw = response.data['data']['activities'] ?? [];

        await LocalDatabase.clearAllActivities();

        for (final actRaw in activitiesRaw) {
          final model = ActivityModel.fromJson(actRaw as Map<String, dynamic>);
          final dbMap = model.toDbMap();
          dbMap['sync_status'] = 'synced';
          await LocalDatabase.insertActivity(dbMap);
        }

        state = state.copyWith(
          status: SyncStatus.success,
          lastSyncedAt: DateTime.now(),
          retryCount: 0,
          errorMessage: null,
        );
      } else {
        state = state.copyWith(
          status: SyncStatus.failed,
          errorMessage: response.data['message'] ?? 'Gagal memulihkan data.',
        );
      }
    } catch (e) {
      state = state.copyWith(
        status: SyncStatus.failed,
        errorMessage: e.toString().replaceAll('Exception: ', ''),
      );
    }
  }

  @override
  void dispose() {
    _connectivitySubscription?.cancel();
    super.dispose();
  }
}

// ─── Provider ────────────────────────────────────────────────────────────────

final syncProvider = StateNotifierProvider<SyncNotifier, SyncState>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return SyncNotifier(apiClient);
});
