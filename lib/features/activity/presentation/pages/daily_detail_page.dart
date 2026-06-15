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

    // Format Tanggal Header (e.g. "Senin, 15 Juni 2026")
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
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Detail Aktivitas'),
        actions: [
          IconButton(
            icon: const Icon(Icons.sync_rounded),
            onPressed: () {
              ref.read(syncProvider.notifier).checkAndSync().then((_) {
                ref.read(dailyDetailProvider(date).notifier).fetchDetail();
              });
            },
          ),
        ],
      ),
      body: SafeArea(
        child: detailState.isLoading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Date header
                    Text(
                      formattedDate,
                      style: GoogleFonts.inter(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                        letterSpacing: -0.03 * 20,
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Stats row cards
                    Row(
                      children: [
                        Expanded(
                          child: _buildStatWidget(
                            context: context,
                            label: 'TOTAL LANGKAH',
                            value: detailState.totalSteps.toString(),
                            subtitle: 'langkah',
                            color: AppColors.primary,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildStatWidget(
                            context: context,
                            label: 'TOTAL JARAK',
                            value: '${displayDistanceKm.toStringAsFixed(1)} km',
                            subtitle: '${detailState.totalDistanceMeters} m',
                            color: AppColors.secondary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Dominant Activity row
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: AppColors.secondaryPale,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(Icons.star_rounded, color: AppColors.primary, size: 24),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'AKTIVITAS DOMINAN',
                                    style: GoogleFonts.inter(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.textSecondary,
                                      letterSpacing: 0.05 * 10,
                                    ),
                                  ),
                                  Text(
                                    detailState.dominantActivityType == 'walking'
                                        ? 'Berjalan kaki'
                                        : detailState.dominantActivityType == 'running'
                                            ? 'Berlari'
                                            : 'Berdiam diri',
                                    style: GoogleFonts.inter(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Sync Status Card (sesuai ui-design.md 3.9)
                    _buildSyncStatusCard(context, ref, syncState),
                    const SizedBox(height: 24),

                    // Timeline Title
                    Text(
                      'TIMELINE AKTIVITAS',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textSecondary,
                        letterSpacing: 0.08 * 11,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Timeline List
                    detailState.timeline.isEmpty
                        ? _buildEmptyTimeline()
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

  Widget _buildSyncStatusCard(
      BuildContext context, WidgetRef ref, SyncState syncState) {
    Color dotColor;
    String label;
    switch (syncState.status) {
      case SyncStatus.neverSynced:
        dotColor = AppColors.textMuted;
        label = 'Data belum pernah disinkronkan';
        break;
      case SyncStatus.waitingConnection:
        dotColor = AppColors.warning;
        label = 'Menunggu koneksi untuk sinkronisasi';
        break;
      case SyncStatus.syncing:
        dotColor = AppColors.warning;
        label = 'Sedang menyinkronkan data...';
        break;
      case SyncStatus.success:
        dotColor = AppColors.secondary;
        label = syncState.lastSyncedAt != null
            ? 'Tersinkron pada ${_formatDateTime(syncState.lastSyncedAt!)}'
            : 'Data sudah tersinkron';
        break;
      case SyncStatus.failed:
        dotColor = AppColors.danger;
        label = syncState.errorMessage ?? 'Sinkronisasi gagal';
        break;
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: dotColor.withOpacity(0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              syncState.status == SyncStatus.success
                  ? Icons.cloud_done_outlined
                  : syncState.status == SyncStatus.syncing
                      ? Icons.cloud_sync_outlined
                      : syncState.status == SyncStatus.failed
                          ? Icons.cloud_off_outlined
                          : Icons.cloud_outlined,
              color: dotColor,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'STATUS SINKRONISASI',
                  style: GoogleFonts.inter(
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textSecondary,
                    letterSpacing: 0.08 * 9,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  label,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: syncState.status == SyncStatus.failed
                        ? AppColors.danger
                        : AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
          if (syncState.status == SyncStatus.failed ||
              syncState.status == SyncStatus.neverSynced ||
              syncState.status == SyncStatus.waitingConnection) ...[
            TextButton(
              onPressed: syncState.status == SyncStatus.syncing
                  ? null
                  : () {
                      ref.read(syncProvider.notifier).syncUnsyncedData().then(
                        (_) {
                          ref
                              .read(dailyDetailProvider(date).notifier)
                              .fetchDetail();
                        },
                      );
                    },
              style: TextButton.styleFrom(
                foregroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(horizontal: 8),
              ),
              child: const Text('Sync Ulang',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatWidget({
    required BuildContext context,
    required String label,
    required String value,
    required String subtitle,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.inter(fontSize: 9, fontWeight: FontWeight.bold, color: AppColors.textMuted),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: GoogleFonts.inter(fontSize: 24, fontWeight: FontWeight.bold, color: color),
          ),
          Text(
            subtitle,
            style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  String _formatDateTime(DateTime dt) {
    final local = dt.toLocal();
    return '${local.day}/${local.month} ${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}';
  }

  Widget _buildEmptyTimeline() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 32),
      alignment: Alignment.center,
      child: Text(
        'Tidak ada log aktivitas terperinci untuk tanggal ini.',
        style: GoogleFonts.inter(fontSize: 13, color: AppColors.textSecondary),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildTimelineItem(dynamic item, bool isLast) {
    // Format Waktu (e.g. "07:00 - 07:30")
    String timeRange = '';
    try {
      final start = DateFormat('HH:mm').format(item.startedAt.toLocal());
      final end = DateFormat('HH:mm').format(item.endedAt.toLocal());
      timeRange = '$start - $end';
    } catch (_) {
      timeRange = '${item.startedAt} - ${item.endedAt}';
    }

    Color typeColor = AppColors.textMuted;
    String typeLabel = 'Idle';
    IconData typeIcon = Icons.accessibility_rounded;

    if (item.activityType == 'walking') {
      typeColor = AppColors.secondary;
      typeLabel = 'Berjalan';
      typeIcon = Icons.directions_walk_rounded;
    } else if (item.activityType == 'running') {
      typeColor = AppColors.warning;
      typeLabel = 'Berlari';
      typeIcon = Icons.directions_run_rounded;
    }

    final double displayDistanceKm = item.distanceMeters / 1000.0;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Left Column: Dot and Line
        Column(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: typeColor.withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(typeIcon, color: typeColor, size: 20),
            ),
            if (!isLast)
              Container(
                width: 2,
                height: 56,
                color: AppColors.border,
              ),
          ],
        ),
        const SizedBox(width: 16),

        // Right Column: Card Detail
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 2.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      typeLabel,
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      timeRange,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '${item.steps} langkah • ${displayDistanceKm.toStringAsFixed(2)} km (${item.distanceMeters} m)',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w400,
                  ),
                ),
                if (item.latitude != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    'GPS: ${item.latitude!.toStringAsFixed(4)}, ${item.longitude!.toStringAsFixed(4)}',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      color: AppColors.textMuted,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
