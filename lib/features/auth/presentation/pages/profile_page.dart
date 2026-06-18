import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/constants/app_theme.dart';
import '../../../activity/presentation/providers/sync_provider.dart';
import '../providers/auth_provider.dart';
import 'edit_profile_page.dart';

class ProfilePage extends ConsumerWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);
    final syncState = ref.watch(syncProvider);

    if (authState is! AuthAuthenticated) {
      return const Scaffold(
        backgroundColor: DSColors.brandTealDeep,
        body: Center(
          child: CircularProgressIndicator(color: DSColors.primaryDark),
        ),
      );
    }

    final user = authState.user;
    final initial = user.name.isNotEmpty ? user.name[0].toUpperCase() : 'U';
    final weightStr =
        user.weightKg != null ? user.weightKg!.toStringAsFixed(0) : '--';
    final heightStr =
        user.heightCm != null ? user.heightCm!.toStringAsFixed(0) : '--';
    final bmi = (user.weightKg != null && user.heightCm != null)
        ? user.weightKg! / ((user.heightCm! / 100) * (user.heightCm! / 100))
        : null;
    final bmiStr = bmi != null ? bmi.toStringAsFixed(1) : '--';
    final bmiLabel = _bmiLabel(bmi);

    return Scaffold(
      backgroundColor: DSColors.brandTealDeep,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(DSSpacing.page),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── HERO PROFILE CARD ────────────────────────────────────────────
              GlassHeroCard(
                child: Column(children: [
                  // Avatar
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: DSColors.primaryDark.withOpacity(0.35),
                        width: 1.5,
                      ),
                      color: Colors.white.withOpacity(0.08),
                    ),
                    child: Center(
                      child: Text(initial,
                          style: GoogleFonts.sora(
                              fontSize: 28,
                              fontWeight: FontWeight.w600,
                              color: DSColors.onDark)),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Name
                  Text(user.name, style: DSText.userName()),
                  const SizedBox(height: 4),

                  // Email
                  Text(user.email,
                      style: DSText.caption(color: DSColors.onDarkMuted)),
                  const SizedBox(height: 12),

                  // BMI pill
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(DSRadius.pill),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.12),
                        width: 0.5,
                      ),
                    ),
                    child: RichText(
                      text: TextSpan(children: [
                        TextSpan(
                          text: 'BMI ',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: DSColors.onDarkMuted,
                          ),
                        ),
                        TextSpan(
                          text: bmiStr,
                          style: GoogleFonts.jetBrainsMono(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: DSColors.onDark,
                          ),
                        ),
                        if (bmiLabel.isNotEmpty) ...[
                          TextSpan(
                            text: ' · $bmiLabel',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: DSColors.onDarkMuted,
                            ),
                          ),
                        ],
                      ]),
                    ),
                  ),
                ]),
              ),
              const SizedBox(height: 16),

              // ── DATA FISIK (STAT CHIPS) ──────────────────────────────────────
              GlassCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('DATA FISIK',
                        style: DSText.sectionLabel(
                            color: DSColors.onDarkMuted)),
                    const SizedBox(height: 14),
                    Row(children: [
                      Expanded(
                          child: _buildStatChip(
                              '$weightStr kg', 'BERAT BADAN')),
                      const SizedBox(width: 10),
                      Expanded(
                          child: _buildStatChip(
                              '$heightStr cm', 'TINGGI BADAN')),
                      const SizedBox(width: 10),
                      Expanded(
                          child:
                              _buildStatChip(bmiStr, 'BMI')),
                    ]),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // ── AKUN SECTION ──────────────────────────────────────────────────
              GlassCard(
                radius: DSRadius.control,
                padding: EdgeInsets.zero,
                child: Column(children: [
                  // Section label
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                        DSSpacing.lg, DSSpacing.lg, DSSpacing.lg, DSSpacing.sm),
                    child: Text('AKUN',
                        style: DSText.sectionLabel(
                            color: DSColors.onDarkMuted)),
                  ),

                  // Edit Profile row
                  _buildListRow(
                    icon: Icons.edit_outlined,
                    iconColor: DSColors.primaryDark,
                    label: 'Edit Profil',
                    onTap: () async {
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const EditProfilePage()),
                      );
                      if (result == true) {
                        ref
                            .read(authStateProvider.notifier)
                            .checkAuthStatus();
                      }
                    },
                  ),

                  // Divider
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: DSSpacing.lg),
                    child: Divider(
                        height: 1,
                        color: Colors.white.withOpacity(0.06)),
                  ),

                  // Restore Data row
                  _buildListRow(
                    icon: Icons.cloud_download_outlined,
                    iconColor: DSColors.accentBlue,
                    label: 'Restore Data',
                    onTap: () =>
                        ref.read(syncProvider.notifier).restoreCloudData(),
                  ),
                ]),
              ),
              const SizedBox(height: 16),

              // ── SYNC STATUS CARD ──────────────────────────────────────────────
              GlassCard(
                radius: DSRadius.control,
                child: Row(children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: _syncDotColor(syncState.status)
                          .withOpacity(0.15),
                      borderRadius:
                          BorderRadius.circular(DSRadius.permIcon),
                    ),
                    child: Icon(
                      _syncIcon(syncState.status),
                      color: _syncDotColor(syncState.status),
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('STATUS SINKRONISASI',
                            style: DSText.sectionLabel(
                                color: DSColors.onDarkMuted)),
                        const SizedBox(height: 2),
                        Text(
                          syncState.statusLabel,
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: DSColors.onDark,
                          ),
                        ),
                        if (syncState.lastSyncedAt != null)
                          Text(
                            'Terakhir: ${_formatDate(syncState.lastSyncedAt!)}',
                            style: DSText.caption(
                                color: DSColors.onDarkMuted),
                          ),
                      ],
                    ),
                  ),
                ]),
              ),
              const SizedBox(height: 24),

              // ── LOGOUT BUTTON ──────────────────────────────────────────────────
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => _showLogoutDialog(context, ref),
                  icon: const Icon(Icons.logout, size: 18),
                  label: Text(
                    'Keluar',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: DSColors.errorDark,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: DSColors.errorDark,
                    side: const BorderSide(
                        color: DSColors.errorDark, width: 1),
                    padding:
                        const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(DSRadius.button),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Helpers ──────────────────────────────────────────────────────────────

  Widget _buildStatChip(String value, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(DSRadius.control),
        border: Border.all(
          color: Colors.white.withOpacity(0.08),
          width: 0.5,
        ),
      ),
      child: Column(children: [
        Text(value,
            style: GoogleFonts.jetBrainsMono(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: DSColors.onDark)),
        const SizedBox(height: 4),
        Text(label,
            style: GoogleFonts.inter(
                fontSize: 9,
                fontWeight: FontWeight.w600,
                color: DSColors.onDarkMuted,
                letterSpacing: 0.08 * 9)),
      ]),
    );
  }

  Widget _buildListRow({
    required IconData icon,
    required Color iconColor,
    required String label,
    required VoidCallback onTap,
  }) {
    return ListTile(
      contentPadding:
          const EdgeInsets.symmetric(horizontal: DSSpacing.lg),
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: iconColor.withOpacity(0.12),
          borderRadius: BorderRadius.circular(DSRadius.sensorChip),
        ),
        child: Icon(icon, color: iconColor, size: 20),
      ),
      title: Text(label,
          style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: DSColors.onDark)),
      trailing: const Icon(Icons.chevron_right,
          color: DSColors.onDarkMuted, size: 20),
      onTap: onTap,
    );
  }

  void _showLogoutDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: DSColors.ink,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(DSRadius.card),
          side: BorderSide(
            color: Colors.white.withOpacity(0.12),
            width: 0.5,
          ),
        ),
        title: Text('Konfirmasi',
            style: GoogleFonts.sora(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: DSColors.onDark,
            )),
        content: Text(
          'Apakah Anda yakin ingin keluar?',
          style: GoogleFonts.inter(
            fontSize: 14,
            color: DSColors.onDarkMuted,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Batal',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: DSColors.onDarkMuted,
                )),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              ref.read(authStateProvider.notifier).logout();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: DSColors.errorDark,
              foregroundColor: DSColors.onDark,
            ),
            child: Text('Keluar',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                )),
          ),
        ],
      ),
    );
  }

  String _bmiLabel(double? bmi) {
    if (bmi == null) return '';
    if (bmi < 18.5) return 'Kurus';
    if (bmi < 25) return 'Normal';
    if (bmi < 30) return 'Berlebih';
    return 'Obesitas';
  }

  Color _syncDotColor(SyncStatus status) {
    switch (status) {
      case SyncStatus.success:
        return DSColors.primaryDark;
      case SyncStatus.syncing:
      case SyncStatus.waitingConnection:
        return DSColors.accentOrange;
      case SyncStatus.failed:
        return DSColors.errorDark;
      case SyncStatus.neverSynced:
        return DSColors.onDarkMuted;
    }
  }

  IconData _syncIcon(SyncStatus status) {
    switch (status) {
      case SyncStatus.success:
        return Icons.cloud_done_outlined;
      case SyncStatus.syncing:
        return Icons.cloud_upload_outlined;
      case SyncStatus.waitingConnection:
        return Icons.cloud_off_outlined;
      case SyncStatus.failed:
        return Icons.cloud_off_outlined;
      case SyncStatus.neverSynced:
        return Icons.cloud_outlined;
    }
  }

  String _formatDate(DateTime dt) {
    return '${dt.day}/${dt.month}/${dt.year} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }
}
