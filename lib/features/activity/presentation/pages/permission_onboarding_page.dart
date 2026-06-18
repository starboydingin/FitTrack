import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../../../core/constants/app_theme.dart';
import '../providers/permission_provider.dart';

class PermissionOnboardingPage extends ConsumerStatefulWidget {
  final VoidCallback onCompleted;

  const PermissionOnboardingPage({super.key, required this.onCompleted});

  @override
  ConsumerState<PermissionOnboardingPage> createState() =>
      _PermissionOnboardingPageState();
}

class _PermissionOnboardingPageState
    extends ConsumerState<PermissionOnboardingPage> {
  @override
  Widget build(BuildContext context) {
    final permState = ref.watch(permissionProvider);
    final canProceed = permState.isMinimumGranted;

    return Scaffold(
      backgroundColor: DSColors.brandTealDeep,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(DSSpacing.page),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(flex: 1),

              // ── GLASS SHIELD ICON ──────────────────────────────────────────────
              Center(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(DSRadius.frame),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                    child: Container(
                      width: 90,
                      height: 90,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.06),
                        borderRadius:
                            BorderRadius.circular(DSRadius.frame),
                        border: Border.all(
                          color: DSColors.primaryDark.withOpacity(0.25),
                          width: 0.5,
                        ),
                      ),
                      child: const Center(
                        child: Icon(Icons.shield_outlined,
                            size: 44, color: DSColors.primaryDark),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // ── TITLE ──────────────────────────────────────────────────────────
              Text(
                'Izin Akses',
                textAlign: TextAlign.center,
                style: GoogleFonts.sora(
                  fontSize: 22,
                  fontWeight: FontWeight.w600,
                  color: DSColors.onDark,
                  letterSpacing: -0.01 * 22,
                ),
              ),
              const SizedBox(height: 8),

              Text(
                'FitTrack membutuhkan izin berikut untuk memantau aktivitas fisik Anda secara akurat.',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w400,
                  color: DSColors.onDarkMuted,
                ),
              ),
              const SizedBox(height: 28),

              // ── PERMISSION CARDS ───────────────────────────────────────────────
              _buildPermCard(
                icon: Icons.location_on_outlined,
                label: 'Lokasi Foreground',
                desc: 'Untuk melacak posisi Anda saat beraktivitas',
                status: permState.locationForeground,
                onTap: () => ref
                    .read(permissionProvider.notifier)
                    .requestLocationForeground(),
              ),
              const SizedBox(height: 10),

              _buildPermCard(
                icon: Icons.location_searching,
                label: 'Lokasi Background',
                desc: 'Untuk tetap melacak meski aplikasi di latar belakang',
                status: permState.locationBackground,
                onTap: () => ref
                    .read(permissionProvider.notifier)
                    .requestLocationBackground(),
              ),
              const SizedBox(height: 10),

              _buildPermCard(
                icon: Icons.directions_walk_outlined,
                label: 'Aktivitas Fisik',
                desc: 'Untuk mendeteksi jenis pergerakan Anda',
                status: permState.activityRecognition,
                onTap: () => ref
                    .read(permissionProvider.notifier)
                    .requestActivityRecognition(),
              ),
              const SizedBox(height: 20),

              // ── WARNING BANNER ─────────────────────────────────────────────────
              if (!canProceed)
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: DSColors.accentOrange.withOpacity(0.10),
                    borderRadius:
                        BorderRadius.circular(DSRadius.control),
                    border: Border.all(
                      color: DSColors.accentOrange.withOpacity(0.25),
                      width: 0.5,
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.warning_amber_rounded,
                          color: DSColors.accentOrange, size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Tanpa izin lokasi dan aktivitas, fitur pelacakan real-time tidak dapat berfungsi penuh.',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: DSColors.onDark,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

              const Spacer(flex: 1),

              // ── ACTION BUTTONS ─────────────────────────────────────────────────
              if (!canProceed && _hasPermanentlyDenied(permState)) ...[
                SizedBox(
                  height: 52,
                  child: OutlinedButton.icon(
                    onPressed: () => ref
                        .read(permissionProvider.notifier)
                        .openAppSettingsPage(),
                    icon: const Icon(Icons.settings_outlined, size: 18),
                    label: Text(
                      'Ke Pengaturan',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(
                          color: DSColors.accentOrange, width: 1.5),
                      foregroundColor: DSColors.accentOrange,
                      shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(DSRadius.button),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
              ],

              SizedBox(
                height: 52,
                child: ElevatedButton(
                  onPressed: canProceed ? widget.onCompleted : null,
                  child: Text(
                    'Lanjutkan',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }

  // ── Helpers ──────────────────────────────────────────────────────────────

  Widget _buildPermCard({
    required IconData icon,
    required String label,
    required String desc,
    required PermissionStatus status,
    required VoidCallback onTap,
  }) {
    final statusColor = _statusColor(status);
    final statusLabel = _statusLabel(status);

    return ClipRRect(
      borderRadius: BorderRadius.circular(DSRadius.card),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          padding: const EdgeInsets.all(DSSpacing.lg),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.06),
            borderRadius: BorderRadius.circular(DSRadius.card),
            border: Border.all(
              color: Colors.white.withOpacity(0.12),
              width: 0.5,
            ),
          ),
          child: Row(children: [
            // Icon
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.15),
                borderRadius:
                    BorderRadius.circular(DSRadius.permIcon),
              ),
              child: Icon(icon, color: statusColor, size: 22),
            ),
            const SizedBox(width: 12),

            // Label + desc
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: DSColors.onDark)),
                  const SizedBox(height: 2),
                  Text(desc,
                      style: DSText.caption(
                          color: DSColors.onDarkMuted)),
                ],
              ),
            ),
            const SizedBox(width: 8),

            // Status badge or request button
            if (status == PermissionStatus.granted)
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: DSColors.primaryDark.withOpacity(0.15),
                  borderRadius:
                      BorderRadius.circular(DSRadius.pill),
                ),
                child: Text(statusLabel,
                    style: GoogleFonts.inter(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: DSColors.primaryDark)),
              )
            else
              GestureDetector(
                onTap: onTap,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.08),
                    borderRadius:
                        BorderRadius.circular(DSRadius.pill),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.12),
                      width: 0.5,
                    ),
                  ),
                  child: Text(statusLabel,
                      style: GoogleFonts.inter(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: DSColors.onDark)),
                ),
              ),
          ]),
        ),
      ),
    );
  }

  Color _statusColor(PermissionStatus status) {
    switch (status) {
      case PermissionStatus.granted:
        return DSColors.primaryDark;
      case PermissionStatus.denied:
        return DSColors.accentOrange;
      case PermissionStatus.restricted:
      case PermissionStatus.permanentlyDenied:
        return DSColors.errorDark;
      default:
        return DSColors.onDarkMuted;
    }
  }

  String _statusLabel(PermissionStatus status) {
    switch (status) {
      case PermissionStatus.granted:
        return 'Diberikan';
      case PermissionStatus.denied:
        return 'Izinkan';
      case PermissionStatus.restricted:
      case PermissionStatus.permanentlyDenied:
        return 'Ditolak';
      default:
        return 'Izinkan';
    }
  }

  bool _hasPermanentlyDenied(PermissionState state) {
    return state.locationForeground == PermissionStatus.permanentlyDenied ||
        state.activityRecognition == PermissionStatus.permanentlyDenied;
  }
}
