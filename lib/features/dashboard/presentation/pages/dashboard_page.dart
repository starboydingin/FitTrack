import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/constants/app_theme.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../activity/presentation/providers/tracking_provider.dart';
import '../../../activity/presentation/providers/sync_provider.dart';
import '../../../activity/presentation/providers/permission_provider.dart';
import '../../../activity/presentation/providers/history_provider.dart';
import '../../../../features/activity/presentation/pages/activity_page.dart';
import '../../../../core/utils/local_database.dart';

class DashboardPage extends ConsumerStatefulWidget {
  const DashboardPage({super.key});

  @override
  ConsumerState<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends ConsumerState<DashboardPage>
    with TickerProviderStateMixin {
  int _todaySteps = 0;
  int _todayDistanceMeters = 0;
  String _dominantActivity = 'idle';
  late AnimationController _syncDotController;

  @override
  void initState() {
    super.initState();
    _syncDotController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _loadTodayStats();
  }

  @override
  void dispose() {
    _syncDotController.dispose();
    super.dispose();
  }

  Future<void> _loadTodayStats() async {
    final today = DateTime.now().toIso8601String().split('T')[0];
    final maps = await LocalDatabase.getActivitiesForDate(today);

    int steps = 0;
    int distance = 0;
    final Map<String, int> counts = {};

    for (final map in maps) {
      steps += (map['steps'] as num).toInt();
      distance += (map['distance_meters'] as num).toInt();
      final type = map['activity_type'] as String;
      counts[type] = (counts[type] ?? 0) + (map['steps'] as num).toInt();
    }

    String dominant = 'idle';
    int maxSteps = -1;
    counts.forEach((type, s) {
      if (s > maxSteps) {
        maxSteps = s;
        dominant = type;
      }
    });

    if (mounted) {
      setState(() {
        _todaySteps = steps;
        _todayDistanceMeters = distance;
        _dominantActivity = dominant;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateProvider);
    final syncState = ref.watch(syncProvider);
    final permState = ref.watch(permissionProvider);
    final trackingState = ref.watch(trackingProvider);

    String userName = 'User';
    if (authState is AuthAuthenticated) {
      userName = authState.user.name;
    }

    // Hitung langkah real-time jika tracking sedang aktif
    final displaySteps = trackingState.isTracking
        ? _todaySteps + trackingState.steps
        : _todaySteps;
    final displayDistanceMeters = trackingState.isTracking
        ? _todayDistanceMeters + trackingState.distanceMeters
        : _todayDistanceMeters;
    final displayDistanceKm = displayDistanceMeters / 1000.0;

    final displayActivity = trackingState.isTracking
        ? trackingState.activityType
        : _dominantActivity;

    // Mapping Status Sync
    Color syncDotColor = AppColors.textMuted;
    String syncLabel = 'Belum tersinkron';
    if (syncState.status == SyncStatus.syncing) {
      syncDotColor = AppColors.warning;
      syncLabel = 'Menyinkron...';
    } else if (syncState.status == SyncStatus.success) {
      syncDotColor = AppColors.secondary;
      syncLabel = 'Tersinkron';
    } else if (syncState.status == SyncStatus.failed) {
      syncDotColor = AppColors.danger;
      syncLabel = 'Gagal, akan retry';
    } else if (syncState.status == SyncStatus.waitingConnection) {
      syncDotColor = AppColors.warning;
      syncLabel = 'Menunggu koneksi';
    }
    // neverSynced: tetap pakai default abu + "Belum tersinkron"

    // Kontrol animasi dot berdasarkan status sync
    if (syncState.status == SyncStatus.syncing) {
      if (!_syncDotController.isAnimating) {
        _syncDotController.repeat(reverse: true);
      }
    } else {
      if (_syncDotController.isAnimating) _syncDotController.stop();
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            await ref.read(syncProvider.notifier).checkAndSync();
            await _loadTodayStats();
            ref.read(historyProvider.notifier).fetchHistory('weekly');
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header Row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Halo, 👋',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        Text(
                          userName,
                          style: GoogleFonts.inter(
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                            letterSpacing: -0.03 * 22,
                          ),
                        ),
                      ],
                    ),
                    // Sync Status Badge (animasi saat syncing)
                    GestureDetector(
                      onTap: () => ref.read(syncProvider.notifier).checkAndSync(),
                      child: AnimatedBuilder(
                        animation: _syncDotController,
                        builder: (context, child) {
                          final dotColor = syncState.status == SyncStatus.syncing
                              ? Color.lerp(AppColors.warning,
                                    AppColors.warning.withOpacity(0.3),
                                    _syncDotController.value)!
                              : syncDotColor;
                          return Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                  color: AppColors.border, width: 1),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 8,
                                  height: 8,
                                  decoration: BoxDecoration(
                                    color: dotColor,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  syncLabel,
                                  style: GoogleFonts.inter(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // ── BENTO GRID ───────────────────────────────────────────────

                // Bento 1: Hero Full-width (Langkah Hari Ini)
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withOpacity(0.2),
                        blurRadius: 12,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'LANGKAH HARI INI',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Colors.white.withOpacity(0.7),
                          letterSpacing: 0.08 * 11,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Text(
                            displaySteps.toString(),
                            style: GoogleFonts.inter(
                              fontSize: 48,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                              letterSpacing: -0.04 * 48,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'langkah',
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: Colors.white.withOpacity(0.7),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      // Progress Bar
                      ClipRRect(
                        borderRadius: BorderRadius.circular(3),
                        child: LinearProgressIndicator(
                          value: (displaySteps / 10000.0).clamp(0.0, 1.0),
                          backgroundColor: Colors.white.withOpacity(0.15),
                          valueColor: const AlwaysStoppedAnimation<Color>(AppColors.secondary),
                          minHeight: 6,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Target 10.000 langkah • ${((displaySteps / 10000.0) * 100).toInt()}%',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: Colors.white.withOpacity(0.7),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // Bento 2: 2 Column (Jarak & Aktivitas)
                Row(
                  children: [
                    // Jarak Card (Secondary Pale)
                    Expanded(
                      child: Container(
                        height: 120,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.secondaryPale,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: AppColors.border, width: 1),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'JARAK TEMPUH',
                              style: GoogleFonts.inter(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textSecondary,
                                letterSpacing: 0.05 * 10,
                              ),
                            ),
                            Text(
                              '${displayDistanceKm.toStringAsFixed(1)} km',
                              style: GoogleFonts.inter(
                                fontSize: 26,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primary,
                              ),
                            ),
                            Text(
                              '${displayDistanceMeters.toString()} m',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Aktivitas Card (White Card)
                    Expanded(
                      child: Container(
                        height: 120,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: AppColors.border, width: 1),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'AKTIVITAS UTAMA',
                              style: GoogleFonts.inter(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textSecondary,
                                letterSpacing: 0.05 * 10,
                              ),
                            ),
                            Text(
                              displayActivity == 'walking'
                                  ? 'Berjalan'
                                  : displayActivity == 'running'
                                      ? 'Berlari'
                                      : 'Diam',
                              style: GoogleFonts.inter(
                                fontSize: 26,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            Text(
                              displayActivity.toUpperCase(),
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Bento 3: 7 Hari Terakhir (Mini Bar Chart)
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.border, width: 1),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        '7 HARI TERAKHIR',
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textSecondary,
                          letterSpacing: 0.08 * 10,
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Mini Chart Bars Row
                      ref.watch(historyProvider).isLoading
                          ? const SizedBox(
                              height: 60,
                              child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
                            )
                          : _buildMiniBarChart(),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Bento 4: Sensor & Control status
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.surface2,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        trackingState.isTracking ? Icons.sensors : Icons.sensors_off,
                        color: trackingState.isTracking ? AppColors.secondary : AppColors.textMuted,
                        size: 24,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'STATUS TRACKING',
                              style: GoogleFonts.inter(
                                fontSize: 9,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textSecondary,
                                letterSpacing: 0.08 * 9,
                              ),
                            ),
                            Text(
                              trackingState.isTracking
                                  ? 'Pelacakan sedang aktif'
                                  : permState.isMinimumGranted
                                      ? 'Pelacakan siap digunakan'
                                      : 'Izin lokasi belum lengkap',
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      ElevatedButton(
                        onPressed: () {
                          if (trackingState.isTracking) {
                            ref.read(trackingProvider.notifier).stopTracking();
                          } else {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const ActivityPage()),
                            ).then((_) => _loadTodayStats());
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: trackingState.isTracking ? AppColors.danger : AppColors.primary,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        child: Text(
                          trackingState.isTracking ? 'Hentikan' : 'Mulai',
                          style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // Bento 5: Tombol Sync Manual + error message jika gagal
                if (syncState.status == SyncStatus.failed &&
                    syncState.errorMessage != null) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.danger.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: AppColors.danger.withOpacity(0.3)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.error_outline_rounded,
                            color: AppColors.danger, size: 18),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            syncState.errorMessage!,
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: AppColors.danger,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: syncState.status == SyncStatus.syncing
                        ? null
                        : () => ref
                            .read(syncProvider.notifier)
                            .syncUnsyncedData(),
                    icon: syncState.status == SyncStatus.syncing
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                  AppColors.primary),
                            ),
                          )
                        : const Icon(Icons.cloud_upload_outlined, size: 18),
                    label: Text(
                      syncState.status == SyncStatus.syncing
                          ? 'Menyinkron...'
                          : 'Sinkronisasi Manual',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMiniBarChart() {
    final historyState = ref.watch(historyProvider);
    final items = historyState.items;

    // Default 7 hari kosong jika tidak ada data
    final Map<String, int> dailySteps = {};

    for (var i = 0; i < 7; i++) {
      final date = DateTime.now().subtract(Duration(days: 6 - i));
      final dateString = date.toIso8601String().split('T')[0];
      final label = _getDayLabel(date.weekday);

      // Cari di history items
      final match = items.firstWhere(
        (it) => it.date == dateString,
        orElse: () => HistoryItem(date: dateString, totalSteps: 0, totalDistanceMeters: 0, dominantActivityType: 'idle'),
      );
      dailySteps[label] = match.totalSteps;
    }

    // Cari langkah maksimal untuk scaling
    int maxSteps = 1000;
    dailySteps.forEach((k, v) {
      if (v > maxSteps) maxSteps = v;
    });

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: dailySteps.entries.map((entry) {
        final double barHeight = (entry.value / maxSteps * 60).clamp(4.0, 60.0);
        final isToday = entry.key == _getDayLabel(DateTime.now().weekday);

        return Column(
          children: [
            Container(
              width: 20,
              height: barHeight,
              decoration: BoxDecoration(
                color: isToday ? AppColors.secondary : AppColors.border.withOpacity(0.5),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(4),
                  topRight: Radius.circular(4),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              entry.key,
              style: GoogleFonts.inter(
                fontSize: 10,
                fontWeight: isToday ? FontWeight.bold : FontWeight.w500,
                color: isToday ? AppColors.primary : AppColors.textSecondary,
              ),
            ),
          ],
        );
      }).toList(),
    );
  }

  String _getDayLabel(int weekday) {
    switch (weekday) {
      case 1: return 'Sen';
      case 2: return 'Sel';
      case 3: return 'Rab';
      case 4: return 'Kam';
      case 5: return 'Jum';
      case 6: return 'Sab';
      case 7: return 'Min';
      default: return '';
    }
  }
}
