import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/app_theme.dart';

class SplashScreen extends StatelessWidget {
  final String statusText;

  const SplashScreen({super.key, required this.statusText});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DSColors.brandTealDeep,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Glass logo container
            ClipRRect(
              borderRadius: BorderRadius.circular(DSRadius.frame),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.06),
                    borderRadius: BorderRadius.circular(DSRadius.frame),
                    border: Border.all(
                      color: DSColors.primaryDark.withOpacity(0.25),
                      width: 0.5,
                    ),
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.directions_run_rounded,
                      size: 48,
                      color: DSColors.primaryDark,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // App name
            Text(
              'FitTrack',
              style: GoogleFonts.sora(
                fontSize: 28,
                fontWeight: FontWeight.w700,
                color: DSColors.onDark,
                letterSpacing: -0.01 * 28,
              ),
            ),
            const SizedBox(height: 8),

            // Tagline
            Text(
              'Monitoring Aktivitas Fisik',
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w400,
                color: DSColors.onDarkMuted,
              ),
            ),
            const SizedBox(height: 48),

            // Loading indicator
            const SizedBox(
              width: 32,
              height: 32,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                valueColor: AlwaysStoppedAnimation<Color>(DSColors.primaryDark),
              ),
            ),
            const SizedBox(height: 16),

            // Status text
            Text(
              statusText,
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: DSColors.onDarkMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
