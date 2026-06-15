import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../../../core/constants/app_theme.dart';
import '../providers/auth_provider.dart';
import '../../../../features/activity/presentation/providers/sync_provider.dart';
import '../../../../features/activity/presentation/providers/permission_provider.dart';
import 'edit_profile_page.dart';

class ProfilePage extends ConsumerWidget {
  const ProfilePage({super.key});

  double _calculateBmi(double weight, double height) {
    if (height <= 0) return 0.0;
    final heightMeters = height / 100.0;
    return weight / (heightMeters * heightMeters);
  }

  String _getBmiCategory(double bmi) {
    if (bmi <= 0) return 'Tidak Diketahui';
    if (bmi < 18.5) return 'Kurus';
    if (bmi < 25.0) return 'Normal';
    if (bmi < 30.0) return 'Gemuk';
    return 'Obesitas';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);
    final syncState = ref.watch(syncProvider);
    final permState = ref.watch(permissionProvider);

    if (authState is! AuthAuthenticated) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final user = authState.user;
    final weight = user.weightKg ?? 0.0;
    final height = user.heightCm ?? 0.0;
    final bmi = _calculateBmi(weight, height);
    final bmiCategory = _getBmiCategory(bmi);

    // Hitung status izin sensor
    int grantedCount = 0;
    if (permState.locationForeground == PermissionStatus.granted) grantedCount++;
    if (permState.locationBackground == PermissionStatus.granted) grantedCount++;
    if (permState.activityRecognition == PermissionStatus.granted) grantedCount++;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Profil Saya'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: AppColors.danger),
            onPressed: () {
              _showLogoutConfirmation(context, ref);
            },
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Avatar & Name Card
              Center(
                child: Column(
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withOpacity(0.15),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        user.name.isNotEmpty ? user.name[0].toUpperCase() : 'U',
                        style: GoogleFonts.inter(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      user.name,
                      style: GoogleFonts.inter(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      user.email,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.secondaryPale,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        'BMI: ${bmi.toStringAsFixed(1)} • $bmiCategory',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primaryLight,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),

              // DATA FISIK (Stat Chips 3-Col)
              Text(
                'DATA FISIK',
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textSecondary,
                  letterSpacing: 0.08 * 11,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildStatChip(
                      value: '${weight.toStringAsFixed(0)} kg',
                      label: 'Berat Badan',
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildStatChip(
                      value: '${height.toStringAsFixed(0)} cm',
                      label: 'Tinggi Badan',
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildStatChip(
                      value: bmi.toStringAsFixed(1),
                      label: 'Indeks BMI',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 28),

              // SINKRONISASI STATUS
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border, width: 1),
                ),
                child: Row(
                  children: [
                    Icon(
                      syncState.status == SyncStatus.success
                          ? Icons.cloud_done_outlined
                          : syncState.status == SyncStatus.syncing
                              ? Icons.cloud_sync_outlined
                              : syncState.status == SyncStatus.failed
                                  ? Icons.cloud_off_outlined
                                  : Icons.cloud_outlined,
                      color: syncState.status == SyncStatus.success
                          ? AppColors.secondary
                          : syncState.status == SyncStatus.failed
                              ? AppColors.danger
                              : syncState.status == SyncStatus.syncing ||
                                      syncState.status ==
                                          SyncStatus.waitingConnection
                                  ? AppColors.warning
                                  : AppColors.textMuted,
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'SINKRONISASI CLOUD',
                            style: GoogleFonts.inter(
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          Text(
                            syncState.lastSyncedAt != null
                                ? 'Terakhir: ${_formatDateTime(syncState.lastSyncedAt!)}'
                                : 'Belum pernah disinkronkan',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    TextButton(
                      onPressed: () async {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Memulai pemulihan data dari cloud...')),
                        );
                        try {
                          await ref.read(syncProvider.notifier).restoreCloudData();
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Data berhasil dipulihkan dari cloud!'),
                                backgroundColor: AppColors.secondary,
                              ),
                            );
                          }
                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Gagal memulihkan: ${e.toString()}'),
                                backgroundColor: AppColors.danger,
                              ),
                            );
                          }
                        }
                      },
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.secondary,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                      ),
                      child: const Text('Restore'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // M3 LIST ROWS
              Text(
                'PENGATURAN',
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textSecondary,
                  letterSpacing: 0.08 * 11,
                ),
              ),
              const SizedBox(height: 8),
              _buildM3Row(
                icon: Icons.edit_rounded,
                iconColor: Colors.blue,
                label: 'Edit Profil',
                trailing: '',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const EditProfilePage()),
                  );
                },
              ),
              _buildM3Row(
                icon: Icons.sync_rounded,
                iconColor: AppColors.secondary,
                label: 'Sinkronisasi Manual',
                trailing: syncState.status == SyncStatus.syncing
                    ? 'Sedang sync'
                    : syncState.status == SyncStatus.success
                        ? 'Tersinkron'
                        : syncState.status == SyncStatus.failed
                            ? 'Gagal'
                            : syncState.status == SyncStatus.waitingConnection
                                ? 'Menunggu koneksi'
                                : 'Siap',
                onTap: () => ref.read(syncProvider.notifier).syncUnsyncedData(),
              ),
              _buildM3Row(
                icon: Icons.verified_user_rounded,
                iconColor: AppColors.warning,
                label: 'Izin Sensor',
                trailing: '$grantedCount/3 diberikan',
                onTap: () => ref.read(permissionProvider.notifier).checkAllPermissions(),
              ),
              _buildM3Row(
                icon: Icons.logout_rounded,
                iconColor: AppColors.danger,
                label: 'Keluar Akun',
                trailing: '',
                onTap: () => _showLogoutConfirmation(context, ref),
                isDestructive: true,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatChip({required String value, required String label}) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: AppColors.surface2,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border, width: 0.5),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 11,
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildM3Row({
    required IconData icon,
    required Color iconColor,
    required String label,
    required String trailing,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border, width: 1),
      ),
      child: ListTile(
        onTap: onTap,
        leading: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: iconColor.withOpacity(0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: iconColor, size: 20),
        ),
        title: Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: isDestructive ? AppColors.danger : AppColors.textPrimary,
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (trailing.isNotEmpty) ...[
              Text(
                trailing,
                style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary, fontWeight: FontWeight.w500),
              ),
              const SizedBox(width: 8),
            ],
            Icon(Icons.chevron_right_rounded, color: isDestructive ? AppColors.danger.withOpacity(0.5) : AppColors.textMuted, size: 20),
          ],
        ),
      ),
    );
  }

  void _showLogoutConfirmation(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Keluar Akun'),
        content: const Text('Apakah Anda yakin ingin keluar? Seluruh data offline yang belum disinkronkan akan terhapus.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ref.read(authStateProvider.notifier).logout();
            },
            child: const Text('Keluar', style: TextStyle(color: AppColors.danger)),
          ),
        ],
      ),
    );
  }

  String _formatDateTime(DateTime dt) {
    try {
      final local = dt.toLocal();
      return '${local.day}/${local.month} ${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return dt.toIso8601String();
    }
  }
}
