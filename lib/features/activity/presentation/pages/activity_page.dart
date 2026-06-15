import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/constants/app_theme.dart';
import '../providers/tracking_provider.dart';
import '../providers/permission_provider.dart';
import '../providers/sync_provider.dart';

class ActivityPage extends ConsumerStatefulWidget {
  const ActivityPage({super.key});

  @override
  ConsumerState<ActivityPage> createState() => _ActivityPageState();
}

class _ActivityPageState extends ConsumerState<ActivityPage> with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  bool _isPaused = false;
  int _pausedStepsOffset = 0;
  int _pausedDistanceOffset = 0;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final trackingState = ref.watch(trackingProvider);
    final permState = ref.watch(permissionProvider);
    final syncState = ref.watch(syncProvider);

    if (trackingState.isTracking && !_isPaused) {
      if (!_pulseController.isAnimating) {
        _pulseController.repeat(reverse: true);
      }
    } else {
      _pulseController.stop();
    }

    final displaySteps = _isPaused
        ? _pausedStepsOffset
        : trackingState.steps;
    final displayDistanceMeters = _isPaused
        ? _pausedDistanceOffset
        : trackingState.distanceMeters;

    final displayDistanceKm = displayDistanceMeters / 1000.0;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Aktivitas Real-time'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Hero Steps Card
              Container(
                padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 24),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withOpacity(0.15),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // Pulse Ring Animation wrapper
                    AnimatedBuilder(
                      animation: _pulseController,
                      builder: (context, child) {
                        return Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: AppColors.secondary.withOpacity(
                                  trackingState.isTracking && !_isPaused
                                      ? 0.5 * (1.0 - _pulseController.value)
                                      : 0.1
                              ),
                              width: 8 * _pulseController.value + 1,
                            ),
                          ),
                          child: child,
                        );
                      },
                      child: Container(
                        width: 72,
                        height: 72,
                        decoration: const BoxDecoration(
                          color: AppColors.secondary,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.directions_run_rounded,
                          color: Colors.white,
                          size: 36,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'LANGKAH REAL-TIME',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Colors.white.withOpacity(0.6),
                        letterSpacing: 0.08 * 11,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      displaySteps.toString(),
                      style: GoogleFonts.inter(
                        fontSize: 52,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: -0.04 * 52,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Aktivitas: ${trackingState.isTracking && !_isPaused ? trackingState.activityType.toUpperCase() : "NONAKTIF"}',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: AppColors.secondaryPale,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Jarak, Durasi, GPS 2-Column Cards
              Row(
                children: [
                  Expanded(
                    child: _buildMetricCard(
                      title: 'ESTIMASI JARAK',
                      value: '${displayDistanceKm.toStringAsFixed(2)} km',
                      subtitle: '$displayDistanceMeters meter',
                      icon: Icons.map_outlined,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildMetricCard(
                      title: 'KUALITAS GPS',
                      value: trackingState.latitude != null
                          ? '${trackingState.gpsAccuracy?.toStringAsFixed(1) ?? 'ok'} m'
                          : 'Tidak Aktif',
                      subtitle: trackingState.latitude != null
                          ? 'Akurasi GPS saat ini'
                          : 'Lokasi belum tersedia',
                      icon: Icons.gps_fixed_rounded,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // GPS Status / Coordinates
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: trackingState.latitude != null ? AppColors.secondary : AppColors.danger,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'KOORDINAT TERAKHIR',
                              style: GoogleFonts.inter(
                                fontSize: 9,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textSecondary,
                                letterSpacing: 0.08 * 9,
                              ),
                            ),
                            Text(
                              trackingState.latitude != null
                                  ? '${trackingState.latitude!.toStringAsFixed(5)}° S, ${trackingState.longitude!.toStringAsFixed(5)}° E'
                                  : 'Lokasi belum tersedia',
                              style: GoogleFonts.inter(
                                fontSize: 13,
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
              const SizedBox(height: 16),

              // Accelerometer Raw Bars (X / Y / Z)
              _buildAccelerometerCard(trackingState),
              const SizedBox(height: 32),

              // Action buttons row
              if (!trackingState.isTracking) ...[
                ElevatedButton(
                  onPressed: permState.isMinimumGranted
                      ? () {
                          setState(() {
                            _isPaused = false;
                          });
                          ref.read(trackingProvider.notifier).startTracking();
                        }
                      : null,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 18),
                  ),
                  child: const Text('Mulai Pelacakan'),
                ),
              ] else ...[
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          setState(() {
                            if (_isPaused) {
                              _isPaused = false;
                            } else {
                              _isPaused = true;
                              _pausedStepsOffset = trackingState.steps;
                              _pausedDistanceOffset = trackingState.distanceMeters;
                            }
                          });
                        },
                        child: Text(_isPaused ? 'Lanjutkan' : 'Jeda'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () async {
                          setState(() => _isPaused = false);
                          await ref.read(trackingProvider.notifier).stopTracking();
                          if (context.mounted) {
                            Navigator.of(context).pop();
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.danger,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: const Text('Selesai'),
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 12),

              // ── Sync Status + Tombol Sync Manual ──────────────────────────
              _buildSyncSection(syncState),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSyncSection(SyncState syncState) {
    // Warna dan label sesuai dokumen ui-design.md
    Color dotColor;
    String label;
    switch (syncState.status) {
      case SyncStatus.neverSynced:
        dotColor = AppColors.textMuted;
        label = 'Belum tersinkron';
        break;
      case SyncStatus.waitingConnection:
        dotColor = AppColors.warning;
        label = 'Menunggu koneksi';
        break;
      case SyncStatus.syncing:
        dotColor = AppColors.warning;
        label = 'Menyinkron...';
        break;
      case SyncStatus.success:
        dotColor = AppColors.secondary;
        label = syncState.lastSyncedAt != null
            ? 'Tersinkron ${_formatTime(syncState.lastSyncedAt!)}'
            : 'Tersinkron';
        break;
      case SyncStatus.failed:
        dotColor = AppColors.danger;
        label = 'Gagal, akan retry';
        break;
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: dotColor,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          TextButton.icon(
            onPressed: syncState.status == SyncStatus.syncing
                ? null
                : () => ref.read(syncProvider.notifier).syncUnsyncedData(),
            icon: syncState.status == SyncStatus.syncing
                ? const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.cloud_upload_outlined, size: 16),
            label: Text(
              syncState.status == SyncStatus.syncing ? 'Mengirim...' : 'Sync',
              style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600),
            ),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.primary,
              padding: const EdgeInsets.symmetric(horizontal: 8),
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime dt) {
    final local = dt.toLocal();
    return '${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}';
  }

  Widget _buildMetricCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
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
          Icon(icon, color: AppColors.primary, size: 24),
          const SizedBox(height: 12),
          Text(
            title,
            style: GoogleFonts.inter(
              fontSize: 9,
              fontWeight: FontWeight.w700,
              color: AppColors.textSecondary,
              letterSpacing: 0.05 * 9,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: GoogleFonts.inter(
              fontSize: 12,
              color: AppColors.textMuted,
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAccelerometerCard(TrackingState state) {
    // Accelerometer X/Y/Z progress bars
    // Normal acceleration values ranges usually around -15 to +15.
    // We can map these to a 0.0 to 1.0 range: (val + 15) / 30.
    final xValNormalized = ((state.accelX + 15) / 30).clamp(0.0, 1.0);
    final yValNormalized = ((state.accelY + 15) / 30).clamp(0.0, 1.0);
    final zValNormalized = ((state.accelZ + 15) / 30).clamp(0.0, 1.0);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'AKSELEROMETER REAL-TIME',
              style: GoogleFonts.inter(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: AppColors.textSecondary,
                letterSpacing: 0.08 * 10,
              ),
            ),
            const SizedBox(height: 16),
            _buildSensorBar('Axis X', state.accelX, xValNormalized, Colors.blue),
            const SizedBox(height: 12),
            _buildSensorBar('Axis Y', state.accelY, yValNormalized, Colors.green),
            const SizedBox(height: 12),
            _buildSensorBar('Axis Z', state.accelZ, zValNormalized, Colors.orange),
          ],
        ),
      ),
    );
  }

  Widget _buildSensorBar(String label, double val, double progress, Color barColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
            ),
            Text(
              '${val.toStringAsFixed(2)} m/s²',
              style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(3),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 6,
            backgroundColor: AppColors.surface2,
            valueColor: AlwaysStoppedAnimation<Color>(barColor),
          ),
        ),
      ],
    );
  }
}
