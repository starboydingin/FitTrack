import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/utils/local_database.dart';
import '../../data/models/activity_model.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

class HistoryItem {
  final String date;
  final int totalSteps;
  final int totalDistanceMeters;
  final String dominantActivityType;

  HistoryItem({
    required this.date,
    required this.totalSteps,
    required this.totalDistanceMeters,
    required this.dominantActivityType,
  });

  factory HistoryItem.fromJson(Map<String, dynamic> json) => HistoryItem(
        date:                 json['date'] as String,
        totalSteps:           (json['totalSteps'] ?? 0) as int,
        totalDistanceMeters:   (json['totalDistanceMeters'] ?? 0) as int,
        dominantActivityType: json['dominantActivityType'] ?? 'idle',
      );
}

class HistoryState {
  final bool isLoading;
  final List<HistoryItem> items;
  final String? errorMessage;
  final bool isOffline;

  const HistoryState({
    this.isLoading = false,
    this.items = const [],
    this.errorMessage,
    this.isOffline = false,
  });

  HistoryState copyWith({
    bool? isLoading,
    List<HistoryItem>? items,
    String? errorMessage,
    bool? isOffline,
  }) {
    return HistoryState(
      isLoading:    isLoading ?? this.isLoading,
      items:        items ?? this.items,
      errorMessage: errorMessage ?? this.errorMessage,
      isOffline:    isOffline ?? this.isOffline,
    );
  }
}

class HistoryNotifier extends StateNotifier<HistoryState> {
  final ApiClient _apiClient;

  HistoryNotifier(this._apiClient) : super(const HistoryState()) {
    fetchHistory('weekly');
  }

  Future<void> fetchHistory(String period) async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    // Dummy mode atau offline → baca dari lokal, skip network
    if (kUseDummyMode) {
      await _fetchHistoryOffline();
      return;
    }

    final connectivityResult = await Connectivity().checkConnectivity();
    final isOnline = connectivityResult.any((r) => r != ConnectivityResult.none);
    if (!isOnline) {
      await _fetchHistoryOffline();
      return;
    }

    try {
      final response = await _apiClient.get(
        '/activities/history',
        queryParameters: {'period': period},
      );

      if (response.statusCode == 200 && response.data['success'] == true) {
        final List rawItems = response.data['data']['items'] ?? [];
        final items = rawItems.map((j) => HistoryItem.fromJson(j as Map<String, dynamic>)).toList();
        state = HistoryState(items: items, isOffline: false);
      } else {
        await _fetchHistoryOffline();
        state = state.copyWith(errorMessage: response.data['message']);
      }
    } catch (e) {
      await _fetchHistoryOffline();
      state = state.copyWith(
        errorMessage: 'Terjadi kesalahan jaringan. Menampilkan data lokal.',
      );
    }
  }

  Future<void> _fetchHistoryOffline() async {
    try {
      final localMaps = await LocalDatabase.getAllLocalActivities();

      // Kelompokkan data lokal berdasarkan tanggal
      final Map<String, List<ActivityModel>> grouped = {};
      for (final map in localMaps) {
        final model = ActivityModel.fromDbMap(map);
        grouped.putIfAbsent(model.activityDate, () => []).add(model);
      }

      final List<HistoryItem> items = [];
      grouped.forEach((date, list) {
        int steps = 0;
        int distance = 0;
        final Map<String, int> counts = {};

        for (final act in list) {
          steps += act.steps;
          distance += act.distanceMeters;
          counts[act.activityType] = (counts[act.activityType] ?? 0) + act.steps;
        }

        // Tentukan jenis aktivitas dominan berdasarkan jumlah langkah terbanyak
        String dominant = 'idle';
        int maxSteps = -1;
        counts.forEach((type, s) {
          if (s > maxSteps) {
            maxSteps = s;
            dominant = type;
          }
        });

        items.add(HistoryItem(
          date:                 date,
          totalSteps:           steps,
          totalDistanceMeters:   distance,
          dominantActivityType: dominant,
        ));
      });

      // Urutkan tanggal naik
      items.sort((a, b) => a.date.compareTo(b.date));

      state = HistoryState(items: items, isOffline: true);
    } catch (e) {
      state = HistoryState(
        errorMessage: 'Gagal memuat data riwayat lokal: ${e.toString()}',
        isOffline: true,
      );
    }
  }
}

final historyProvider = StateNotifierProvider<HistoryNotifier, HistoryState>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return HistoryNotifier(apiClient);
});

// ─── Daily Detail Provider ──────────────────────────────────────────────────

class DailyDetailState {
  final bool isLoading;
  final String date;
  final int totalSteps;
  final int totalDistanceMeters;
  final String dominantActivityType;
  final List<ActivityModel> timeline;
  final String? errorMessage;

  const DailyDetailState({
    this.isLoading = false,
    this.date = '',
    this.totalSteps = 0,
    this.totalDistanceMeters = 0,
    this.dominantActivityType = 'idle',
    this.timeline = const [],
    this.errorMessage,
  });

  DailyDetailState copyWith({
    bool? isLoading,
    String? date,
    int? totalSteps,
    int? totalDistanceMeters,
    String? dominantActivityType,
    List<ActivityModel>? timeline,
    String? errorMessage,
  }) {
    return DailyDetailState(
      isLoading:            isLoading ?? this.isLoading,
      date:                 date ?? this.date,
      totalSteps:           totalSteps ?? this.totalSteps,
      totalDistanceMeters:   totalDistanceMeters ?? this.totalDistanceMeters,
      dominantActivityType: dominantActivityType ?? this.dominantActivityType,
      timeline:             timeline ?? this.timeline,
      errorMessage:         errorMessage ?? this.errorMessage,
    );
  }
}

class DailyDetailNotifier extends StateNotifier<DailyDetailState> {
  final ApiClient _apiClient;
  final String _date;

  DailyDetailNotifier(this._apiClient, this._date) : super(const DailyDetailState()) {
    fetchDetail();
  }

  Future<void> fetchDetail() async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    // Dummy mode → baca dari lokal, skip network
    if (kUseDummyMode) {
      await _fetchDetailOffline();
      return;
    }

    final connectivityResult = await Connectivity().checkConnectivity();
    final isOnline = connectivityResult.any((r) => r != ConnectivityResult.none);
    if (!isOnline) {
      await _fetchDetailOffline();
      return;
    }

    try {
      final response = await _apiClient.get('/activities/daily/$_date');

      if (response.statusCode == 200 && response.data['success'] == true) {
        final data = response.data['data'];
        final List rawTimeline = data['timeline'] ?? [];
        final timeline = rawTimeline.map((t) => ActivityModel.fromJson(t as Map<String, dynamic>)).toList();

        state = DailyDetailState(
          date:                 _date,
          totalSteps:           (data['totalSteps'] ?? 0) as int,
          totalDistanceMeters:   (data['totalDistanceMeters'] ?? 0) as int,
          dominantActivityType: data['dominantActivityType'] ?? 'idle',
          timeline:             timeline,
        );
      } else {
        await _fetchDetailOffline();
        state = state.copyWith(errorMessage: response.data['message']);
      }
    } catch (e) {
      await _fetchDetailOffline();
      state = state.copyWith(
        errorMessage: 'Kesalahan jaringan. Menampilkan data detail dari lokal.',
      );
    }
  }

  Future<void> _fetchDetailOffline() async {
    try {
      final maps = await LocalDatabase.getActivitiesForDate(_date);
      final timeline = maps.map((m) => ActivityModel.fromDbMap(m)).toList();

      int steps = 0;
      int distance = 0;
      final Map<String, int> counts = {};

      for (final act in timeline) {
        steps += act.steps;
        distance += act.distanceMeters;
        counts[act.activityType] = (counts[act.activityType] ?? 0) + act.steps;
      }

      String dominant = 'idle';
      int maxSteps = -1;
      counts.forEach((type, s) {
        if (s > maxSteps) {
          maxSteps = s;
          dominant = type;
        }
      });

      state = DailyDetailState(
        date:                 _date,
        totalSteps:           steps,
        totalDistanceMeters:   distance,
        dominantActivityType: dominant,
        timeline:             timeline,
      );
    } catch (e) {
      state = state.copyWith(
        errorMessage: 'Gagal memuat detail aktivitas lokal: ${e.toString()}',
      );
    }
  }
}

final dailyDetailProvider = StateNotifierProvider.family<DailyDetailNotifier, DailyDetailState, String>((ref, date) {
  final apiClient = ref.watch(apiClientProvider);
  return DailyDetailNotifier(apiClient, date);
});
