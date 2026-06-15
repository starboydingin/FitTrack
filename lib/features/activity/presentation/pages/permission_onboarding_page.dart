import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../../../core/constants/app_theme.dart';
import '../providers/permission_provider.dart';

class PermissionOnboardingPage extends ConsumerWidget {
  final VoidCallback onCompleted;

  const PermissionOnboardingPage({super.key, required this.onCompleted});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final permState = ref.watch(permissionProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(),
              // Icon Shield
              Center(
                child: Container(
                  width: 96,
                  height: 96,
                  decoration: BoxDecoration(
                    color: AppColors.secondaryPale,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.security_rounded,
                    color: AppColors.primary,
                    size: 48,
                  ),
                ),
              ),
              const SizedBox(height: 32),
              Text(
                'Izin Akses Sensor',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                  letterSpacing: -0.03 * 24,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'FitTrack memerlukan akses sensor agar dapat melacak langkah, menghitung jarak tempuh, dan mendeteksi aktivitas Anda saat berjalan atau berlari.',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w500,
                  height: 1.5,
                ),
              ),
              const Spacer(),

              // Permissions List Cards
              _buildPermissionItem(
                context: context,
                title: 'Lokasi Foreground',
                description: 'Digunakan untuk kalkulasi jarak GPS real-time.',
                status: permState.locationForeground,
                onRequest: () => ref.read(permissionProvider.notifier).requestLocationForeground(),
              ),
              const SizedBox(height: 12),
              _buildPermissionItem(
                context: context,
                title: 'Lokasi Background',
                description: 'Melacak rute saat ponsel berada di dalam saku.',
                status: permState.locationBackground,
                onRequest: () => ref.read(permissionProvider.notifier).requestLocationBackground(),
              ),
              const SizedBox(height: 12),
              _buildPermissionItem(
                context: context,
                title: 'Activity Recognition',
                description: 'Membaca sensor step counter dan deteksi gerak.',
                status: permState.activityRecognition,
                onRequest: () => ref.read(permissionProvider.notifier).requestActivityRecognition(),
              ),

              const Spacer(),

              // Warning Banner jika izin minimum belum lengkap
              if (!permState.isMinimumGranted) ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF3C7), // Pale amber
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFFDE68A)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.warning_amber_rounded, color: Color(0xFFB45309), size: 24),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Izin Lokasi (Foreground) & Activity Recognition wajib diberikan agar aplikasi dapat bekerja.',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            color: const Color(0xFF92400E),
                            fontWeight: FontWeight.w500,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
              ],

              // Action Buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => ref.read(permissionProvider.notifier).openAppSettingsPage(),
                      child: const Text('Ke Pengaturan'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: permState.isMinimumGranted ? onCompleted : null,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Text('Lanjutkan'),
                          SizedBox(width: 4),
                          Icon(Icons.arrow_forward_rounded, size: 18),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPermissionItem({
    required BuildContext context,
    required String title,
    required String description,
    required PermissionStatus status,
    required VoidCallback onRequest,
  }) {
    Color badgeBgColor;
    Color badgeTextColor;
    String statusLabel;

    if (status.isGranted) {
      badgeBgColor = AppColors.secondaryPale;
      badgeTextColor = AppColors.primaryLight;
      statusLabel = 'Diberikan';
    } else if (status.isPermanentlyDenied) {
      badgeBgColor = AppColors.danger.withOpacity(0.1);
      badgeTextColor = AppColors.danger;
      statusLabel = 'Ditolak';
    } else {
      badgeBgColor = AppColors.warning.withOpacity(0.1);
      badgeTextColor = AppColors.warning;
      statusLabel = 'Menunggu';
    }

    return Card(
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        title: Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: GoogleFonts.inter(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: badgeBgColor,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                statusLabel,
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: badgeTextColor,
                ),
              ),
            ),
          ],
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4.0),
          child: Text(
            description,
            style: GoogleFonts.inter(
              fontSize: 13,
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w400,
            ),
          ),
        ),
        trailing: status.isGranted
            ? const Icon(Icons.check_circle_rounded, color: AppColors.secondary, size: 28)
            : IconButton(
                icon: const Icon(Icons.add_moderator_rounded, color: AppColors.primary),
                onPressed: onRequest,
              ),
      ),
    );
  }
}
