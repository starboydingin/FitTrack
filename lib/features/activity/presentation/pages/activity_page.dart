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

class _ActivityPageState extends ConsumerState<ActivityPage> with SingleTickerProviderStateMixin, WidgetsBindingObserver {
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
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _pulseController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!mounted) return;
    final tracking = ref.read(trackingProvider);
    if (!tracking.isTracking) return;

    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      // Pause sensor subscriptions to avoid stale/dead streams
      ref.read(trackingProvider.notifier).pauseSensors();
    } else if (state == AppLifecycleState.resumed) {
      // Re-subscribe sensors with fresh baseline
      ref.read(trackingProvider.notifier).resumeSensors();
    }
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

    final displaySteps = _isPaused ? _pausedStepsOffset : trackingState.steps;
    final displayDistanceMeters = _isPaused ? _pausedDistanceOffset : trackingState.distanceMeters;
    final displayDistanceKm = displayDistanceMeters / 1000.0;

    return Scaffold(
      backgroundColor: DSColors.brandTealDeep,
      body: Stack(
        children: [
          Positioned.fill(
            child: CustomPaint(
              painter: _GridPainter(
                color: Colors.white.withOpacity(0.03),
                spacing: 40,
              ),
            ),
          ),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(DSSpacing.page),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text('Aktivitas Real-time', style: DSText.screenTitle()),
                  const SizedBox(height: 24),
                  GlassHeroCard(
                    child: Column(
                      children: [
                        AnimatedBuilder(
                          animation: _pulseController,
                          builder: (context, child) {
                            return Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: DSColors.primaryDark.withOpacity(
                                      trackingState.isTracking && !_isPaused
                                          ? 0.5 * (1.0 - _pulseController.value)
                                          : 0.1),
                                  width: 8 * _pulseController.value + 1,
                                ),
                              ),
                              child: child,
                            );
                          },
                          child: Container(
                            width: 64,
                            height: 64,
                            decoration: BoxDecoration(
                              color: DSColors.primaryDark.withOpacity(0.15),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.directions_run_rounded, color: DSColors.primaryDark, size: 32),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text('LANGKAH SAAT INI', style: DSText.sectionLabel(color: DSColors.onDarkMuted)),
                        const SizedBox(height: 8),
                        Text(displaySteps.toString(), style: DSText.stepCountRealtime()),
                        const SizedBox(height: 8),
                        Text(
                          'Aktivitas: ${trackingState.isTracking && !_isPaused ? trackingState.activityType.toUpperCase() : "NONAKTIF"}',
                          style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: DSColors.onDarkMuted),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: GlassCard(
                          child: _buildMetricContent(
                            title: 'GPS STATUS',
                            value: trackingState.latitude != null
                                ? '${trackingState.gpsAccuracy?.toStringAsFixed(1) ?? 'ok'} m'
                                : 'Tidak Aktif',
                            subtitle: trackingState.latitude != null ? 'Akurasi GPS saat ini' : 'Lokasi belum tersedia',
                            icon: Icons.gps_fixed_rounded,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: GlassCard(
                          child: _buildMetricContent(
                            title: 'ESTIMASI JARAK',
                            value: '${displayDistanceKm.toStringAsFixed(2)} km',
                            subtitle: '$displayDistanceMeters meter',
                            icon: Icons.map_outlined,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  GlassCard(
                    child: Row(
                      children: [
                        Container(
                          width: 10, height: 10,
                          decoration: BoxDecoration(
                            color: trackingState.latitude != null ? DSColors.primaryDark : DSColors.errorDark,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('KOORDINAT TERAKHIR', style: DSText.sectionLabel(color: DSColors.onDarkMuted)),
                              const SizedBox(height: 4),
                              Text(
                                trackingState.latitude != null
                                    ? '${trackingState.latitude!.toStringAsFixed(5)} S, ${trackingState.longitude!.toStringAsFixed(5)} E'
                                    : 'Lokasi belum tersedia',
                                style: DSText.coordinate(
                                  color: trackingState.latitude != null ? DSColors.onDark : DSColors.onDarkMuted,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildAccelerometerCard(trackingState),
                  const SizedBox(height: 24),
                  if (!trackingState.isTracking) ...[
                    ElevatedButton(
                      onPressed: permState.isMinimumGranted
                          ? () {
                              setState(() => _isPaused = false);
                              ref.read(trackingProvider.notifier).startTracking();
                            }
                          : null,
                      style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 18)),
                      child: const Text('Mulai Pelacakan'),
                    ),
                  ] else ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // ── Pause / Resume button (circular outline) ──
                        _buildCircleOutlineButton(
                          icon: _isPaused ? Icons.play_arrow_rounded : Icons.pause_rounded,
                          label: _isPaused ? 'Lanjutkan' : 'Jeda',
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
                        ),
                        const SizedBox(width: 24),
                        // ── Stop / Done button (solid red circle) ──
                        _buildCircleStopButton(
                          onPressed: () async {
                            setState(() => _isPaused = false);
                            await ref.read(trackingProvider.notifier).stopTracking();
                            // Only pop if we were pushed onto a route (e.g. from Dashboard).
                            // When embedded in IndexedStack, canPop() is false —
                            // the UI auto-updates via state, no navigation needed.
                            if (context.mounted && Navigator.of(context).canPop()) {
                              Navigator.of(context).pop();
                            }
                          },
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 12),
                  _buildSyncSection(syncState),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricContent({required String title, required String value, required String subtitle, required IconData icon}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: DSColors.primaryDark, size: 22),
        const SizedBox(height: 10),
        Text(title, style: DSText.sectionLabel(color: DSColors.onDarkMuted)),
        const SizedBox(height: 4),
        Text(value, style: GoogleFonts.jetBrainsMono(fontSize: 18, fontWeight: FontWeight.w600, color: DSColors.onDark)),
        const SizedBox(height: 2),
        Text(subtitle, style: DSText.caption(color: DSColors.onDarkMuted)),
      ],
    );
  }

  // ── Circular control buttons ──────────────────────────────────────────────

  Widget _buildCircleOutlineButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Material(
          color: Colors.transparent,
          shape: const CircleBorder(),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: onPressed,
            splashColor: DSColors.primaryDark.withOpacity(0.15),
            highlightColor: DSColors.primaryDark.withOpacity(0.08),
            child: Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white.withOpacity(0.25),
                  width: 2,
                ),
              ),
              child: Icon(icon, color: DSColors.onDark, size: 30),
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: DSColors.onDarkMuted,
          ),
        ),
      ],
    );
  }

  Widget _buildCircleStopButton({required VoidCallback onPressed}) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Material(
          color: Colors.transparent,
          shape: const CircleBorder(),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: onPressed,
            splashColor: Colors.white.withOpacity(0.20),
            highlightColor: Colors.white.withOpacity(0.10),
            child: Container(
              width: 64,
              height: 64,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: DSColors.errorDark,
              ),
              child: Center(
                child: Container(
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(5),
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Selesai',
          style: GoogleFonts.inter(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: DSColors.onDark,
          ),
        ),
      ],
    );
  }

  Widget _buildSyncSection(SyncState syncState) {
    Color dotColor;
    String label;
    switch (syncState.status) {
      case SyncStatus.neverSynced:
        dotColor = DSColors.onDarkMuted; label = 'Belum tersinkron'; break;
      case SyncStatus.waitingConnection:
        dotColor = DSColors.accentOrange; label = 'Menunggu koneksi'; break;
      case SyncStatus.syncing:
        dotColor = DSColors.accentOrange; label = 'Menyinkron...'; break;
      case SyncStatus.success:
        dotColor = DSColors.primaryDark;
        label = syncState.lastSyncedAt != null ? 'Tersinkron ${_formatTime(syncState.lastSyncedAt!)}' : 'Tersinkron';
        break;
      case SyncStatus.failed:
        dotColor = DSColors.errorDark; label = 'Gagal, akan retry'; break;
    }
    return GlassCard(
      radius: DSRadius.control,
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          Container(width: 8, height: 8, decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle)),
          const SizedBox(width: 10),
          Expanded(child: Text(label, style: DSText.body(color: DSColors.onDark))),
          TextButton.icon(
            onPressed: syncState.status == SyncStatus.syncing ? null : () => ref.read(syncProvider.notifier).syncUnsyncedData(),
            icon: syncState.status == SyncStatus.syncing
                ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: DSColors.primaryDark))
                : const Icon(Icons.cloud_upload_outlined, size: 16),
            label: Text(
              syncState.status == SyncStatus.syncing ? 'Mengirim...' : 'Sync',
              style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600),
            ),
            style: TextButton.styleFrom(foregroundColor: DSColors.primaryDark, padding: const EdgeInsets.symmetric(horizontal: 8)),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime dt) {
    final local = dt.toLocal();
    return '${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}';
  }

  Widget _buildAccelerometerCard(TrackingState state) {
    final xN = ((state.accelX + 15) / 30).clamp(0.0, 1.0);
    final yN = ((state.accelY + 15) / 30).clamp(0.0, 1.0);
    final zN = ((state.accelZ + 15) / 30).clamp(0.0, 1.0);
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('AKSELEROMETER REAL-TIME', style: DSText.sectionLabel(color: DSColors.onDarkMuted)),
          const SizedBox(height: 16),
          _buildSensorBar('Axis X', state.accelX, xN, DSColors.accentBlue),
          const SizedBox(height: 12),
          _buildSensorBar('Axis Y', state.accelY, yN, DSColors.primaryDark),
          const SizedBox(height: 12),
          _buildSensorBar('Axis Z', state.accelZ, zN, DSColors.accentOrange),
        ],
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
            Text(label, style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: DSColors.onDarkMuted)),
            Text('${val.toStringAsFixed(2)} m/s2',
                style: GoogleFonts.jetBrainsMono(fontSize: 12, fontWeight: FontWeight.w600, color: DSColors.onDark)),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(DSRadius.progressBar),
          child: LinearProgressIndicator(
            value: progress, minHeight: 6,
            backgroundColor: Colors.white.withOpacity(0.08),
            valueColor: AlwaysStoppedAnimation<Color>(barColor),
          ),
        ),
      ],
    );
  }
}

class _GridPainter extends CustomPainter {
  final Color color;
  final double spacing;
  _GridPainter({required this.color, required this.spacing});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color..strokeWidth = 0.5..style = PaintingStyle.stroke;
    for (double x = 0; x < size.width; x += spacing) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += spacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
