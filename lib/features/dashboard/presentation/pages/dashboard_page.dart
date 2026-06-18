import 'dart:ui';
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

class _DashboardPageState extends ConsumerState<DashboardPage> with TickerProviderStateMixin {
  int _todaySteps = 0;
  int _todayDistanceMeters = 0;
  String _dominantActivity = 'idle';
  late AnimationController _syncDotController;

  @override
  void initState() {
    super.initState();
    _syncDotController = AnimationController(vsync: this, duration: const Duration(milliseconds: 800));
    _loadTodayStats();
  }

  @override
  void dispose() { _syncDotController.dispose(); super.dispose(); }

  Future<void> _loadTodayStats() async {
    final today = DateTime.now().toIso8601String().split('T')[0];
    final maps = await LocalDatabase.getActivitiesForDate(today);
    int steps = 0, distance = 0;
    final Map<String, int> counts = {};
    for (final map in maps) {
      steps += (map['steps'] as num).toInt();
      distance += (map['distance_meters'] as num).toInt();
      final type = map['activity_type'] as String;
      counts[type] = (counts[type] ?? 0) + (map['steps'] as num).toInt();
    }
    String dominant = 'idle'; int maxSteps = -1;
    counts.forEach((type, s) { if (s > maxSteps) { maxSteps = s; dominant = type; } });
    if (mounted) setState(() { _todaySteps = steps; _todayDistanceMeters = distance; _dominantActivity = dominant; });
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateProvider);
    final syncState = ref.watch(syncProvider);
    final permState = ref.watch(permissionProvider);
    final trackingState = ref.watch(trackingProvider);
    String userName = 'User';
    if (authState is AuthAuthenticated) userName = authState.user.name;
    final displaySteps = trackingState.isTracking ? _todaySteps + trackingState.steps : _todaySteps;
    final displayDistM = trackingState.isTracking ? _todayDistanceMeters + trackingState.distanceMeters : _todayDistanceMeters;
    final displayDistKm = displayDistM / 1000.0;
    final displayActivity = trackingState.isTracking ? trackingState.activityType : _dominantActivity;

    Color syncDotColor = DSColors.onDarkMuted;
    String syncLabel = 'Belum tersinkron';
    if (syncState.status == SyncStatus.syncing) { syncDotColor = DSColors.accentOrange; syncLabel = 'Menyinkron...'; }
    else if (syncState.status == SyncStatus.success) { syncDotColor = DSColors.primaryDark; syncLabel = 'Tersinkron'; }
    else if (syncState.status == SyncStatus.failed) { syncDotColor = DSColors.errorDark; syncLabel = 'Gagal, akan retry'; }
    else if (syncState.status == SyncStatus.waitingConnection) { syncDotColor = DSColors.accentOrange; syncLabel = 'Menunggu koneksi'; }
    if (syncState.status == SyncStatus.syncing) { if (!_syncDotController.isAnimating) _syncDotController.repeat(reverse: true); }
    else { if (_syncDotController.isAnimating) _syncDotController.stop(); }

    return Scaffold(
      backgroundColor: DSColors.brandTealDeep,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            await ref.read(syncProvider.notifier).checkAndSync();
            await _loadTodayStats();
            ref.read(historyProvider.notifier).fetchHistory('weekly');
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(DSSpacing.page),
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              // Header
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Halo,', style: DSText.caption(color: DSColors.onDarkMuted)),
                  const SizedBox(height: 2),
                  Text(userName, style: DSText.userName()),
                ]),
                GestureDetector(
                  onTap: () => ref.read(syncProvider.notifier).checkAndSync(),
                  child: AnimatedBuilder(animation: _syncDotController, builder: (context, child) {
                    final dc = syncState.status == SyncStatus.syncing
                        ? Color.lerp(DSColors.accentOrange, DSColors.accentOrange.withOpacity(0.3), _syncDotController.value)!
                        : syncDotColor;
                    return ClipRRect(borderRadius: BorderRadius.circular(DSRadius.pill), child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                      child: Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(color: Colors.white.withOpacity(0.06),
                          borderRadius: BorderRadius.circular(DSRadius.pill),
                          border: Border.all(color: Colors.white.withOpacity(0.10), width: 0.5)),
                        child: Row(mainAxisSize: MainAxisSize.min, children: [
                          Container(width: 8, height: 8, decoration: BoxDecoration(color: dc, shape: BoxShape.circle)),
                          const SizedBox(width: 8),
                          Text(syncLabel, style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: DSColors.onDark)),
                        ]),
                      ),
                    ));
                  }),
                ),
              ]),
              const SizedBox(height: 24),

              // Hero: Steps
              GlassHeroCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('LANGKAH HARI INI', style: DSText.sectionLabel(color: DSColors.onDarkMuted)),
                const SizedBox(height: 8),
                Row(crossAxisAlignment: CrossAxisAlignment.baseline, textBaseline: TextBaseline.alphabetic, children: [
                  Text(displaySteps.toString(), style: DSText.stepCountHero()),
                  const SizedBox(width: 8),
                  Text('langkah', style: DSText.body(color: DSColors.onDarkMuted)),
                ]),
                const SizedBox(height: 12),
                ClipRRect(borderRadius: BorderRadius.circular(DSRadius.progressBar), child: LinearProgressIndicator(
                  value: (displaySteps / 10000.0).clamp(0.0, 1.0),
                  backgroundColor: Colors.white.withOpacity(0.10),
                  valueColor: const AlwaysStoppedAnimation<Color>(DSColors.primaryDark), minHeight: 6,
                )),
                const SizedBox(height: 8),
                Row(children: [
                  Text('Target 10.000 langkah', style: DSText.caption(color: DSColors.onDarkMuted)),
                  const Spacer(),
                  Text('${((displaySteps / 10000.0) * 100).toInt()}%', style: DSText.progressPct()),
                ]),
              ])),
              const SizedBox(height: 12),

              // Jarak + Aktivitas
              Row(children: [
                Expanded(child: GlassCard(child: SizedBox(height: 100, child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                    Text('JARAK', style: DSText.sectionLabel(color: DSColors.onDarkMuted)),
                    Text('${displayDistKm.toStringAsFixed(1)} km', style: DSText.metricLarge(size: 26)),
                    Text('${displayDistM.toString()} m', style: DSText.caption(color: DSColors.onDarkMuted)),
                  ],
                )))),
                const SizedBox(width: 12),
                Expanded(child: GlassCard(child: SizedBox(height: 100, child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                    Text('AKTIVITAS', style: DSText.sectionLabel(color: DSColors.onDarkMuted)),
                    Text(displayActivity == 'walking' ? 'Berjalan' : displayActivity == 'running' ? 'Berlari' : 'Diam',
                        style: DSText.heroCardTitle()),
                    Text(displayActivity.toUpperCase(), style: DSText.chipLabel(color: DSColors.onDarkMuted)),
                  ],
                )))),
              ]),
              const SizedBox(height: 12),

              // 7 Hari Chart
              GlassCard(child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                Text('7 HARI TERAKHIR', style: DSText.sectionLabel(color: DSColors.onDarkMuted)),
                const SizedBox(height: 16),
                ref.watch(historyProvider).isLoading
                    ? const SizedBox(height: 60, child: Center(child: CircularProgressIndicator(strokeWidth: 2, color: DSColors.primaryDark)))
                    : _buildMiniBarChart(),
              ])),
              const SizedBox(height: 16),

              // Sensor Status
              GlassCard(radius: DSRadius.control, child: Row(children: [
                Container(padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: (trackingState.isTracking ? DSColors.primaryDark : DSColors.onDarkMuted).withOpacity(0.15),
                    borderRadius: BorderRadius.circular(DSRadius.permIcon)),
                  child: Icon(trackingState.isTracking ? Icons.sensors : Icons.sensors_off,
                      color: trackingState.isTracking ? DSColors.primaryDark : DSColors.onDarkMuted, size: 24)),
                const SizedBox(width: 12),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('STATUS SENSOR', style: DSText.sectionLabel(color: DSColors.onDarkMuted)),
                  const SizedBox(height: 2),
                  Text(trackingState.isTracking ? 'Pelacakan sedang aktif'
                      : permState.isMinimumGranted ? 'Pelacakan siap digunakan' : 'Izin lokasi belum lengkap',
                      style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: DSColors.onDark)),
                ])),
                ElevatedButton(
                  onPressed: () {
                    if (trackingState.isTracking) ref.read(trackingProvider.notifier).stopTracking();
                    else Navigator.push(context, MaterialPageRoute(builder: (_) => const ActivityPage())).then((_) => _loadTodayStats());
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: trackingState.isTracking ? DSColors.errorDark : DSColors.primaryDark,
                    foregroundColor: trackingState.isTracking ? DSColors.onDark : DSColors.onPrimaryDark,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(DSRadius.button))),
                  child: Text(trackingState.isTracking ? 'Hentikan' : 'Mulai',
                      style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600)),
                ),
              ])),
              const SizedBox(height: 12),

              // Sync Error
              if (syncState.status == SyncStatus.failed && syncState.errorMessage != null) ...[
                Container(padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: DSColors.errorDark.withOpacity(0.10),
                      borderRadius: BorderRadius.circular(DSRadius.control),
                      border: Border.all(color: DSColors.errorDark.withOpacity(0.3))),
                  child: Row(children: [
                    const Icon(Icons.error_outline_rounded, color: DSColors.errorDark, size: 18),
                    const SizedBox(width: 8),
                    Expanded(child: Text(syncState.errorMessage!,
                        style: GoogleFonts.inter(fontSize: 12, color: DSColors.errorDark, fontWeight: FontWeight.w500))),
                  ]),
                ),
                const SizedBox(height: 8),
              ],
              SizedBox(width: double.infinity, child: OutlinedButton.icon(
                onPressed: syncState.status == SyncStatus.syncing ? null : () => ref.read(syncProvider.notifier).syncUnsyncedData(),
                icon: syncState.status == SyncStatus.syncing
                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(DSColors.primaryDark)))
                    : const Icon(Icons.cloud_upload_outlined, size: 18),
                label: Text(syncState.status == SyncStatus.syncing ? 'Menyinkron...' : 'Sinkronisasi Manual',
                    style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600)),
                style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(DSRadius.button))),
              )),
            ]),
          ),
        ),
      ),
    );
  }

  Widget _buildMiniBarChart() {
    final items = ref.watch(historyProvider).items;
    final Map<String, int> dailySteps = {};
    for (var i = 0; i < 7; i++) {
      final date = DateTime.now().subtract(Duration(days: 6 - i));
      final ds = date.toIso8601String().split('T')[0];
      final label = _getDayLabel(date.weekday);
      final match = items.firstWhere((it) => it.date == ds,
          orElse: () => HistoryItem(date: ds, totalSteps: 0, totalDistanceMeters: 0, dominantActivityType: 'idle'));
      dailySteps[label] = match.totalSteps;
    }
    int maxSteps = 1000;
    dailySteps.forEach((k, v) { if (v > maxSteps) maxSteps = v; });
    return Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, crossAxisAlignment: CrossAxisAlignment.end,
      children: dailySteps.entries.map((e) {
        final h = (e.value / maxSteps * 60).clamp(4.0, 60.0);
        final isToday = e.key == _getDayLabel(DateTime.now().weekday);
        return Column(children: [
          Container(width: 20, height: h, decoration: BoxDecoration(
              color: isToday ? DSColors.primaryDark : Colors.white.withOpacity(0.10),
              borderRadius: const BorderRadius.only(topLeft: Radius.circular(4), topRight: Radius.circular(4)))),
          const SizedBox(height: 8),
          Text(e.key, style: GoogleFonts.inter(fontSize: 10, fontWeight: isToday ? FontWeight.w600 : FontWeight.w500,
              color: isToday ? DSColors.primaryDark : DSColors.onDarkMuted)),
        ]);
      }).toList(),
    );
  }

  String _getDayLabel(int w) {
    switch (w) {
      case 1: return 'Sen'; case 2: return 'Sel'; case 3: return 'Rab';
      case 4: return 'Kam'; case 5: return 'Jum'; case 6: return 'Sab'; case 7: return 'Min'; default: return '';
    }
  }
}
