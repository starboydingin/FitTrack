import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/constants/app_theme.dart';
import '../../../../features/activity/presentation/pages/activity_page.dart';
import '../../../../features/activity/presentation/pages/history_page.dart';
import '../../../../features/auth/presentation/pages/profile_page.dart';
import 'dashboard_page.dart';

class HomeNavigator extends ConsumerStatefulWidget {
  const HomeNavigator({super.key});

  @override
  ConsumerState<HomeNavigator> createState() => _HomeNavigatorState();
}

class _HomeNavigatorState extends ConsumerState<HomeNavigator> {
  int _currentIndex = 0;
  final List<Widget> _pages = const [
    DashboardPage(), ActivityPage(), HistoryPage(), ProfilePage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: _pages),
      extendBody: true,
      bottomNavigationBar: _buildGlassBottomNav(),
    );
  }

  Widget _buildGlassBottomNav() {
    final tabs = [
      (icon: Icons.home_outlined, active: Icons.home, label: 'Dashboard'),
      (icon: Icons.directions_run_outlined, active: Icons.directions_run, label: 'Aktivitas'),
      (icon: Icons.bar_chart_outlined, active: Icons.bar_chart, label: 'Riwayat'),
      (icon: Icons.person_outline, active: Icons.person, label: 'Profil'),
    ];
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(DSRadius.control)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 22, sigmaY: 22),
        child: Container(
          decoration: BoxDecoration(
            color: DSColors.brandTealDeep.withOpacity(0.85),
            border: Border(top: BorderSide(color: Colors.white.withOpacity(0.08), width: 0.5)),
          ),
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: List.generate(tabs.length, (i) {
                  final t = tabs[i];
                  final sel = _currentIndex == i;
                  return GestureDetector(
                    onTap: () => setState(() => _currentIndex = i),
                    behavior: HitTestBehavior.opaque,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      curve: Curves.easeOutCubic,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                      decoration: BoxDecoration(
                        color: sel ? DSColors.primaryDark.withOpacity(0.15) : Colors.transparent,
                        borderRadius: BorderRadius.circular(DSRadius.pill),
                      ),
                      child: Column(mainAxisSize: MainAxisSize.min, children: [
                        Icon(sel ? t.active : t.icon, size: 24,
                            color: sel ? DSColors.primaryDark : DSColors.onDarkMuted),
                        const SizedBox(height: 2),
                        Text(t.label, style: GoogleFonts.inter(fontSize: 10,
                            fontWeight: sel ? FontWeight.w600 : FontWeight.w500,
                            color: sel ? DSColors.onDark : DSColors.onDarkMuted)),
                      ]),
                    ),
                  );
                }),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
