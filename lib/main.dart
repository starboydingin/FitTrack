import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'core/constants/app_theme.dart';
import 'features/auth/presentation/providers/auth_provider.dart';
import 'features/auth/presentation/pages/login_page.dart';
import 'features/auth/presentation/pages/complete_profile_page.dart';
import 'features/activity/presentation/providers/permission_provider.dart';
import 'features/activity/presentation/pages/permission_onboarding_page.dart';
import 'features/dashboard/presentation/pages/home_navigator.dart';
import 'features/splash/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('id_ID', null);
  runApp(
    const ProviderScope(
      child: FitnessTrackerApp(),
    ),
  );
}

class FitnessTrackerApp extends StatelessWidget {
  const FitnessTrackerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FitTrack',
      theme: AppTheme.dark,
      debugShowCheckedModeBanner: false,
      home: const RootNavigator(),
    );
  }
}

class RootNavigator extends ConsumerStatefulWidget {
  const RootNavigator({super.key});

  @override
  ConsumerState<RootNavigator> createState() => _RootNavigatorState();
}

class _RootNavigatorState extends ConsumerState<RootNavigator> {
  bool _forceShowPermissionOnboarding = false;
  bool _isBootstrapping = true;

  // Teks status yang dikirim ke SplashScreen — berganti sesuai progres
  String _splashStatus = 'Memulai aplikasi...';

  @override
  void initState() {
    super.initState();
    Future.microtask(() async {
      _updateSplashStatus('Memeriksa sesi login...');
      await Future.wait([
        ref.read(authStateProvider.notifier).checkAuthStatus(),
        Future<void>.delayed(const Duration(milliseconds: 1400)),
      ]);
      if (mounted) {
        setState(() => _isBootstrapping = false);
      }
    });
  }

  void _updateSplashStatus(String text) {
    if (mounted) setState(() => _splashStatus = text);
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateProvider);
    final permState = ref.watch(permissionProvider);

    // ── 1. SPLASH AWAL APLIKASI ───────────────────────────────────────────────
    if (_isBootstrapping || authState is AuthInitial) {
      return SplashScreen(statusText: _splashStatus);
    }

    if (authState is AuthLoading) {
      return const Scaffold(
        backgroundColor: DSColors.brandTealDeep,
        body: Center(child: CircularProgressIndicator(color: DSColors.primaryDark)),
      );
    }

    // ── 2. UNAUTHENTICATED ────────────────────────────────────────────────────
    if (authState is AuthUnauthenticated) {
      return const LoginPage();
    }

    // ── 3. PROFILE COMPLETION ─────────────────────────────────────────────────
    if (authState is AuthProfileCompletionRequired) {
      return CompleteProfilePage(initialName: authState.user.name);
    }

    // ── 4. PERMISSION ONBOARDING ──────────────────────────────────────────────
    if (authState is AuthAuthenticated) {
      if (!permState.isMinimumGranted || _forceShowPermissionOnboarding) {
        return PermissionOnboardingPage(
          onCompleted: () {
            setState(() => _forceShowPermissionOnboarding = false);
          },
        );
      }

      // ── 5. MAIN APP ──────────────────────────────────────────────────────────
      return const HomeNavigator();
    }

    return const Scaffold(
      backgroundColor: DSColors.brandTealDeep,
      body: Center(child: CircularProgressIndicator(color: DSColors.primaryDark)),
    );
  }
}
