import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// ═══════════════════════════════════════════════════════════════════════════════
// DESIGN TOKENS — Dark Mode (Default)
// ═══════════════════════════════════════════════════════════════════════════════

class DSColors {
  DSColors._();

  // ── Dark Mode ─────────────────────────────────────────────────────────────
  static const Color primaryDark       = Color(0xFF00ED64);
  static const Color primaryDeepDark   = Color(0xFF00B545);
  static const Color primaryPressedDark = Color(0xFF008C34);
  static const Color onPrimaryDark     = Color(0xFF001E2B);
  static const Color brandGreenDarkDk  = Color(0xFF00684A);
  static const Color brandGreenMidDk   = Color(0xFF00A35C);
  static const Color brandGreenSoftDk  = Color(0xFFC3F0D2);
  static const Color brandTealDeep     = Color(0xFF001E2B);
  static const Color brandTeal         = Color(0xFF003D4F);
  static const Color accentPurple      = Color(0xFF7B3FF2);
  static const Color accentOrange      = Color(0xFFFA6E39);
  static const Color accentPink        = Color(0xFFF06BB8);
  static const Color accentBlue        = Color(0xFF3D4F9F);
  static const Color hairlineDark      = Color(0xFF1C2D38);
  static const Color ink               = Color(0xFF001E2B);
  static const Color onDark            = Color(0xFFFFFFFF);
  static const Color onDarkMuted       = Color(0xFFA8B3BC);
  static const Color errorDark         = Color(0xFFFF5A5A);

  // ── Light Mode ────────────────────────────────────────────────────────────
  static const Color primaryLight      = Color(0xFF00B545);
  static const Color primaryDeepLight  = Color(0xFF008C34);
  static const Color onPrimaryLight    = Color(0xFFFFFFFF);
  static const Color canvasLight       = Color(0xFFFFFFFF);
  static const Color surfaceLight      = Color(0xFFF9FBFA);
  static const Color surfaceSoftLight  = Color(0xFFF4F7F6);
  static const Color surfaceFeatureLt  = Color(0xFFE3FCEF);
  static const Color hairlineLight     = Color(0xFFE1E5E8);
  static const Color hairlineSoftLt    = Color(0xFFECEFF1);
  static const Color hairlineStrongLt  = Color(0xFFC1CCD6);
  static const Color inkLight          = Color(0xFF001E2B);
  static const Color charcoalLight     = Color(0xFF1C2D38);
  static const Color slateLight        = Color(0xFF3D4F5B);
  static const Color steelLight        = Color(0xFF5C6C7A);
  static const Color stoneLight        = Color(0xFF7C8C9A);
  static const Color mutedLight        = Color(0xFFA8B3BC);
  static const Color errorLight        = Color(0xFFE2453F);
  static const Color warningBgLight    = Color(0xFFFFF8E0);
  static const Color warningTextLight  = Color(0xFF946F3F);
}

// ═══════════════════════════════════════════════════════════════════════════════
// BORDER RADIUS TOKENS
// ═══════════════════════════════════════════════════════════════════════════════

class DSRadius {
  DSRadius._();
  static const double frame   = 30.0;
  static const double hero    = 26.0;
  static const double card    = 22.0;
  static const double control = 18.0;
  static const double button  = 16.0;
  static const double pill    = 20.0;
  static const double permIcon = 13.0;
  static const double sensorChip = 8.0;
  static const double progressBar = 3.0;
}

// ═══════════════════════════════════════════════════════════════════════════════
// SPACING TOKENS
// ═══════════════════════════════════════════════════════════════════════════════

class DSSpacing {
  DSSpacing._();
  static const double xs  = 4.0;
  static const double sm  = 8.0;
  static const double md  = 12.0;
  static const double lg  = 16.0;
  static const double xl  = 24.0;
  static const double xxl = 32.0;
  static const double page = 24.0;
}

// ═══════════════════════════════════════════════════════════════════════════════
// TYPOGRAPHY HELPERS
// ═══════════════════════════════════════════════════════════════════════════════

class DSText {
  DSText._();

  // ── Sora — titles, identity ─────────────────────────────────────────────
  static TextStyle screenTitle({Color color = DSColors.onDark}) =>
      GoogleFonts.sora(fontSize: 22, fontWeight: FontWeight.w600, color: color, letterSpacing: -0.01 * 22);

  static TextStyle userName({Color color = DSColors.onDark}) =>
      GoogleFonts.sora(fontSize: 20, fontWeight: FontWeight.w600, color: color, letterSpacing: -0.01 * 20);

  static TextStyle heroCardTitle({Color color = DSColors.onDark}) =>
      GoogleFonts.sora(fontSize: 20, fontWeight: FontWeight.w600, color: color, letterSpacing: -0.01 * 20);

  // ── JetBrains Mono — measured data ──────────────────────────────────────
  static TextStyle stepCountHero({Color color = DSColors.onDark}) =>
      GoogleFonts.jetBrainsMono(fontSize: 50, fontWeight: FontWeight.w600, color: color);

  static TextStyle stepCountRealtime({Color color = DSColors.onDark}) =>
      GoogleFonts.jetBrainsMono(fontSize: 56, fontWeight: FontWeight.w600, color: color);

  static TextStyle metricLarge({Color color = DSColors.onDark, double size = 28}) =>
      GoogleFonts.jetBrainsMono(fontSize: size, fontWeight: FontWeight.w600, color: color);

  static TextStyle coordinate({Color color = DSColors.onDarkMuted}) =>
      GoogleFonts.jetBrainsMono(fontSize: 12, fontWeight: FontWeight.w500, color: color);

  static TextStyle progressPct({Color color = DSColors.onDark}) =>
      GoogleFonts.jetBrainsMono(fontSize: 12, fontWeight: FontWeight.w600, color: color);

  // ── Inter — functional text ─────────────────────────────────────────────
  static TextStyle body({Color color = DSColors.onDark}) =>
      GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w500, color: color);

  static TextStyle caption({Color color = DSColors.onDarkMuted}) =>
      GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w400, color: color);

  static TextStyle sectionLabel({Color color = DSColors.onDarkMuted}) =>
      GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: color, letterSpacing: 0.08 * 11);

  static TextStyle navLabel({Color color = DSColors.onDark, bool active = false}) =>
      GoogleFonts.inter(fontSize: 11, fontWeight: active ? FontWeight.w600 : FontWeight.w500, color: color);

  static TextStyle chipLabel({Color color = DSColors.onDarkMuted}) =>
      GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w500, color: color);
}

// ═══════════════════════════════════════════════════════════════════════════════
// GLASS CARD WIDGET
// ═══════════════════════════════════════════════════════════════════════════════

class GlassCard extends StatelessWidget {
  final Widget child;
  final double radius;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final Color? borderColor;
  final Color? bgColor;
  final double blurSigma;

  const GlassCard({
    super.key,
    required this.child,
    this.radius = DSRadius.card,
    this.padding,
    this.margin,
    this.borderColor,
    this.bgColor,
    this.blurSigma = 18.0,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
        child: Container(
          margin: margin,
          padding: padding ?? const EdgeInsets.all(DSSpacing.lg),
          decoration: BoxDecoration(
            color: bgColor ?? Colors.white.withOpacity(0.06),
            borderRadius: BorderRadius.circular(radius),
            border: Border.all(
              color: borderColor ?? Colors.white.withOpacity(0.12),
              width: 0.5,
            ),
          ),
          child: child,
        ),
      ),
    );
  }
}

/// Glass card with a subtle green border for hero elements
class GlassHeroCard extends StatelessWidget {
  final Widget child;
  final double radius;
  final EdgeInsetsGeometry? padding;

  const GlassHeroCard({
    super.key,
    required this.child,
    this.radius = DSRadius.hero,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          padding: padding ?? const EdgeInsets.all(DSSpacing.xl),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.06),
            borderRadius: BorderRadius.circular(radius),
            border: Border.all(
              color: DSColors.primaryDark.withOpacity(0.25),
              width: 0.5,
            ),
          ),
          child: child,
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// GLASS BOTTOM NAVIGATION BAR
// ═══════════════════════════════════════════════════════════════════════════════

class GlassBottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  final List<BottomNavigationBarItem> items;

  const GlassBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(DSRadius.control)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 22, sigmaY: 22),
        child: Container(
          decoration: BoxDecoration(
            color: DSColors.brandTealDeep.withOpacity(0.85),
            border: Border(
              top: BorderSide(color: Colors.white.withOpacity(0.08), width: 0.5),
            ),
          ),
          child: BottomNavigationBar(
            currentIndex: currentIndex,
            onTap: onTap,
            type: BottomNavigationBarType.fixed,
            backgroundColor: Colors.transparent,
            elevation: 0,
            selectedItemColor: DSColors.primaryDark,
            unselectedItemColor: DSColors.onDarkMuted,
            selectedLabelStyle: DSText.navLabel(active: true),
            unselectedLabelStyle: DSText.navLabel(color: DSColors.onDarkMuted),
            items: items,
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// MATERIAL THEME (Dark — default)
// ═══════════════════════════════════════════════════════════════════════════════

class AppTheme {
  AppTheme._();

  static ThemeData get dark => ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: DSColors.brandTealDeep,
    colorScheme: const ColorScheme.dark(
      primary: DSColors.primaryDark,
      secondary: DSColors.primaryDeepDark,
      surface: DSColors.ink,
      error: DSColors.errorDark,
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: DSColors.brandTealDeep,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: DSText.screenTitle(),
      iconTheme: const IconThemeData(color: DSColors.onDark),
    ),
    cardTheme: CardThemeData(
      color: Colors.white.withOpacity(0.06),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(DSRadius.card),
        side: BorderSide(color: Colors.white.withOpacity(0.12), width: 0.5),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: DSColors.primaryDark,
        foregroundColor: DSColors.onPrimaryDark,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(DSRadius.button)),
        textStyle: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: DSColors.primaryDark,
        side: const BorderSide(color: DSColors.primaryDark, width: 1.5),
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(DSRadius.button)),
        textStyle: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white.withOpacity(0.06),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(DSRadius.button),
        borderSide: BorderSide(color: Colors.white.withOpacity(0.12), width: 0.5),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(DSRadius.button),
        borderSide: BorderSide(color: Colors.white.withOpacity(0.12), width: 0.5),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(DSRadius.button),
        borderSide: const BorderSide(color: DSColors.primaryDark, width: 1.5),
      ),
      hintStyle: GoogleFonts.inter(fontSize: 14, color: DSColors.onDarkMuted, fontWeight: FontWeight.w400),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    ),
    fontFamily: GoogleFonts.inter().fontFamily,
  );

  static ThemeData get light => ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    scaffoldBackgroundColor: DSColors.canvasLight,
    colorScheme: const ColorScheme.light(
      primary: DSColors.primaryLight,
      secondary: DSColors.primaryDeepLight,
      surface: DSColors.surfaceLight,
      error: DSColors.errorLight,
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: DSColors.canvasLight,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: DSText.screenTitle(color: DSColors.inkLight),
      iconTheme: const IconThemeData(color: DSColors.inkLight),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: DSColors.primaryLight,
        foregroundColor: DSColors.onPrimaryLight,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(DSRadius.button)),
        textStyle: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: DSColors.primaryLight,
        side: const BorderSide(color: DSColors.primaryLight, width: 1.5),
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(DSRadius.button)),
        textStyle: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: DSColors.surfaceLight,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(DSRadius.button),
        borderSide: const BorderSide(color: DSColors.hairlineLight, width: 1),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(DSRadius.button),
        borderSide: const BorderSide(color: DSColors.hairlineLight, width: 1),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(DSRadius.button),
        borderSide: const BorderSide(color: DSColors.primaryLight, width: 1.5),
      ),
      hintStyle: GoogleFonts.inter(fontSize: 14, color: DSColors.mutedLight, fontWeight: FontWeight.w400),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    ),
    fontFamily: GoogleFonts.inter().fontFamily,
  );
}

// Legacy color aliases used in providers/business logic (kept for compat)
class AppColors {
  AppColors._();
  static const Color primary       = DSColors.primaryDark;
  static const Color primaryLight  = DSColors.primaryDeepDark;
  static const Color secondary     = DSColors.primaryDark;
  static const Color secondaryPale = DSColors.brandGreenSoftDk;
  static const Color background    = DSColors.brandTealDeep;
  static const Color surface       = DSColors.ink;
  static const Color surface2      = Color(0xFF0A2A38);
  static const Color border        = DSColors.hairlineDark;
  static const Color textPrimary   = DSColors.onDark;
  static const Color textSecondary = DSColors.onDarkMuted;
  static const Color textMuted     = DSColors.onDarkMuted;
  static const Color warning       = DSColors.accentOrange;
  static const Color danger        = DSColors.errorDark;
}
