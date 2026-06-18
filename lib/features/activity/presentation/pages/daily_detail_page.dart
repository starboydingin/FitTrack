import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_theme.dart';
import '../providers/history_provider.dart';
import '../providers/sync_provider.dart';

class DailyDetailPage extends ConsumerWidget {
  final String date;

  const DailyDetailPage({super.key, required this.date});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detailState = ref.watch(dailyDetailProvider(date));
    final syncState = ref.watch(syncProvider);

    String formattedDate = date;
    try {
      final parsed = DateTime.parse(date);
      formattedDate = DateFormat('EEEE, d MMMM yyyy', 'id_ID').format(parsed);
    } catch (_) {
      try {
        final parsed = DateTime.parse(date);
        formattedDate = DateFormat('EEEE, d MMMM yyyy').format(parsed);
      } catch (_) {}
    }

    final displayDistanceKm = detailState.totalDistanceMeters / 1000.0;

    return Scaffold(
      backgroundColor: DSColors.brandTealDeep,
      body: SafeArea(
        child: detailState.isLoading
            ? const Center(child: CircularProgressIndicator(color: DSColors.primaryDark))
            : SingleChildScrollView(
                padding: const EdgeInsets.all(DSSpacing.page),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        IconButton(icon: const Icon(Icons.arrow_back_rounded, color: DSColors.onDark),
                            onPressed: () => Navigator.pop(context)),
                        const SizedBox(width: 8),
                        Expanded(child: Text('Detail Aktivitas', style: DSText.screenTitle())),
                        IconButton(icon: const Icon(Icons.sync_rounded, color: DSColors.onDarkMuted),
                          onPressed: () {
                            ref.read(syncProvider.notifier).checkAndSync().then((_) {
                              ref.read(dailyDetailProvider(date).notifier).fetchDetail();
                            });
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(formattedDate,
                        style: GoogleFonts.sora(fontSize: 20, fontWeight: FontWeight.w600, color: DSColors.onDark)),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(child: _buildStatWidget(label: 'TOTAL LANGKAH',
                            value: detailState.totalSteps.toString(), subtitle: 'langkah')),
                        const SizedBox(width: 12),
                        Expanded(child: _buildStatWidget(label: 'TOTAL JARAK',
                            value: '${displayDistanceKm.toStringAsFixed(1)} km',
                            subtitle: '${detailState.totalDistanceMeters} m')),
                      ],
                    ),
                    const SizedBox(height: 16),
                    GlassCard(
                      child: Row(children: [
                        Container(padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(color: DSColors.primaryDark.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(DSRadius.permIcon)),
                          child: const Icon(Icons.star_rounded, color: DSColors.primaryDark, size: 24),
                        ),
                        const SizedBox(width: 16),
                        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text('AKTIVITAS DOMINAN', style: DSText.sectionLabel(color: DSColors.onDarkMuted)),
                          const SizedBox(height: 4),
                          Text(
                            detailState.dominantActivityType == 'walking' ? 'Berjalan kaki'
                                : detailState.dominantActivityType == 'running' ? 'Berlari' : 'Berdiam diri',
                            style: GoogleFonts.sora(fontSize: 16, fontWeight: FontWeight.w600, color: DSColors.onDark),
                          ),
                        ])),
                      ]),
                    ),
                    const SizedBox(height: 16),
                    _buildSyncStatusCard(ref, syncState),
                    const SizedBox(height: 24),
                    Text('TIMELINE AKTIVITAS', style: DSText.sectionLabel(color: DSColors.onDarkMuted)),
                    const SizedBox(height: 16),
                    detailState.timeline.isEmpty
                        ? Container(padding: const EdgeInsets.symmetric(vertical: 32), alignment: Alignment.center,
                            child: Text('Tidak ada log aktivitas terperinci untuk tanggal ini.',
                                style: DSText.body(color: DSColors.onDarkMuted), textAlign: TextAlign.center))
                        : ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: detailState.timeline.length,
                            itemBuilder: (context, index) {
                              final item = detailState.timeline[index];
                              final isLast = index == detailState.timeline.length - 1;
                              return _buildTimelineItem(item, isLast);
                            },
                          ),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildSyncStatusCard(WidgetRef ref, SyncState syncState) {
    Color dotColor;
    String label;
    switch (syncState.status) {
      case SyncStatus.neverSynced:
        dotColor = DSColors.onDarkMuted; label = 'Data belum pernah disinkronkan'; break;
      case SyncStatus.waitingConnection:
        dotColor = DSColors.accentOrange; label = 'Menunggu koneksi untuk sinkronisasi'; break;
      case SyncStatus.syncing:
        dotColor = DSColors.accentOrange; label = 'Sedang menyinkronkan data...'; break;
      case SyncStatus.success:
        dotColor = DSColors.primaryDark;
        label = syncState.lastSyncedAt != null
            ? 'Tersinkron pada ${_formatDateTime(syncState.lastSyncedAt!)}' : 'Data sudah tersinkron';
        break;
      case SyncStatus.failed:
        dotColor = DSColors.errorDark; label = syncState.errorMessage ?? 'Sinkronisasi gagal'; break;
    }
    return GlassCard(
      radius: DSRadius.control,
      padding: const EdgeInsets.all(14),
      child: Row(children: [
        Container(padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: dotColor.withOpacity(0.12),
              borderRadius: BorderRadius.circular(DSRadius.sensorChip)),
          child: Icon(
            syncState.status == SyncStatus.success ? Icons.cloud_done_outlined
                : syncState.status == SyncStatus.syncing ? Icons.cloud_sync_outlined
                : syncState.status == SyncStatus.failed ? Icons.cloud_off_outlined : Icons.cloud_outlined,
            color: dotColor, size: 20,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('STATUS SINKRONISASI', style: DSText.sectionLabel(color: DSColors.onDarkMuted)),
          const SizedBox(height: 2),
          Text(label, style: DSText.body(
              color: syncState.status == SyncStatus.failed ? DSColors.errorDark : DSColors.onDark)),
        ])),
        if (syncState.status == SyncStatus.failed ||
            syncState.status == SyncStatus.neverSynced ||
            syncState.status == SyncStatus.waitingConnection)
          TextButton(
            onPressed: syncState.status == SyncStatus.syncing ? null : () {
              ref.read(syncProvider.notifier).syncUnsyncedData().then((_) {
                ref.read(dailyDetailProvider(date).notifier).fetchDetail();
              });
            },
            style: TextButton.styleFrom(foregroundColor: DSColors.primaryDark,
                padding: const EdgeInsets.symmetric(horizontal: 8)),
            child: Text('Sync Ulang', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600)),
          ),
      ]),
    );
  }

  Widget _buildStatWidget({required String label, required String value, required String subtitle}) {
    return GlassCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: DSText.sectionLabel(color: DSColors.onDarkMuted)),
        const SizedBox(height: 8),
        Text(value,
            style: GoogleFonts.jetBrainsMono(fontSize: 24, fontWeight: FontWeight.w600, color: DSColors.onDark)),
        Text(subtitle, style: DSText.caption(color: DSColors.onDarkMuted)),
      ]),
    );
  }

  String _formatDateTime(DateTime dt) {
    final local = dt.toLocal();
    return '${local.day}/${local.month} ${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}';
  }

  Widget _buildTimelineItem(dynamic item, bool isLast) {
    String timeRange = '';
    try {
      final start = DateFormat('HH:mm').format(item.startedAt.toLocal());
      final end = DateFormat('HH:mm').format(item.endedAt.toLocal());
      timeRange = '$start - $end';
    } catch (_) {
      timeRange = '${item.startedAt} - ${item.endedAt}';
    }

    Color typeColor = DSColors.onDarkMuted;
    String typeLabel = 'Idle';
    IconData typeIcon = Icons.accessibility_rounded;
    if (item.activityType == 'walking') {
      typeColor = DSColors.primaryDark; typeLabel = 'Berjalan'; typeIcon = Icons.directions_walk_rounded;
    } else if (item.activityType == 'running') {
      typeColor = DSColors.accentOrange; typeLabel = 'Berlari'; typeIcon = Icons.directions_run_rounded;
    }
    final double displayDistanceKm = item.distanceMeters / 1000.0;

    return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Column(children: [
        Container(width: 36, height: 36,
          decoration: BoxDecoration(color: typeColor.withOpacity(0.15), shape: BoxShape.circle),
          child: Icon(typeIcon, color: typeColor, size: 20),
        ),
        if (!isLast) Container(width: 2, height: 56, color: Colors.white.withOpacity(0.06)),
      ]),
      const SizedBox(width: 16),
      Expanded(child: Padding(padding: const EdgeInsets.only(top: 2.0),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text(typeLabel, style: GoogleFonts.sora(fontSize: 15, fontWeight: FontWeight.w600, color: DSColors.onDark)),
            Text(timeRange, style: DSText.caption(color: DSColors.onDarkMuted)),
          ]),
          const SizedBox(height: 4),
          Text('${item.steps} langkah \u2022 ${displayDistanceKm.toStringAsFixed(2)} km (${item.distanceMeters} m)',
              style: DSText.body(color: DSColors.onDarkMuted)),
          if (item.latitude != null) ...[
            const SizedBox(height: 2),
            Text('GPS: ${item.latitude!.toStringAsFixed(4)}, ${item.longitude!.toStringAsFixed(4)}',
                style: DSText.coordinate()),
          ],
          const SizedBox(height: 16),
        ]),
      )),
    ]);
  }
}
