import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/network/api_client.dart';
import '../../data/datasources/auth_remote_datasource.dart';
import '../../data/repositories/auth_repository_impl.dart';
import '../../data/repositories/dummy_auth_repository.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/auth_repository.dart';

// ─── Providers ───────────────────────────────────────────────────────────────

final apiClientProvider = Provider<ApiClient>((ref) {
  return ApiClient();
});

/// Toggle antara DummyAuthRepository dan AuthRepositoryImpl
/// berdasarkan flag `kUseDummyMode` di app_constants.dart.
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  if (kUseDummyMode) {
    return DummyAuthRepository();
  }
  final apiClient = ref.watch(apiClientProvider);
  final remoteDataSource = AuthRemoteDataSource(apiClient);
  return AuthRepositoryImpl(remoteDataSource, apiClient);
});

final authStateProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final repository = ref.watch(authRepositoryProvider);
  return AuthNotifier(repository);
});

// ─── State ───────────────────────────────────────────────────────────────────

abstract class AuthState {
  const AuthState();
}

class AuthInitial extends AuthState {
  const AuthInitial();
}

class AuthLoading extends AuthState {
  const AuthLoading();
}

class AuthAuthenticated extends AuthState {
  final UserEntity user;
  const AuthAuthenticated(this.user);
}

class AuthUnauthenticated extends AuthState {
  final String? errorMessage;
  const AuthUnauthenticated({this.errorMessage});
}

class AuthProfileCompletionRequired extends AuthState {
  final UserEntity user;
  const AuthProfileCompletionRequired(this.user);
}

// ─── Notifier ────────────────────────────────────────────────────────────────

class AuthNotifier extends StateNotifier<AuthState> {
  final AuthRepository _repository;

  AuthNotifier(this._repository) : super(const AuthInitial());

  Future<void> checkAuthStatus() async {
    state = const AuthLoading();
    try {
      final isLoggedIn = await _repository.isLoggedIn();
      if (isLoggedIn) {
        // Coba ambil dari cache dulu
        var user = await _repository.getCachedUser();
        if (user == null) {
          // Fallback ke network
          user = await _repository.getProfile();
        }

        if (user.weightKg == null || user.heightCm == null) {
          state = AuthProfileCompletionRequired(user);
        } else {
          state = AuthAuthenticated(user);
        }
      } else {
        state = const AuthUnauthenticated();
      }
    } catch (e) {
      state = AuthUnauthenticated(
          errorMessage: e.toString().replaceAll('Exception: ', ''));
    }
  }

  Future<void> login(String email, String password) async {
    state = const AuthLoading();
    try {
      final result = await _repository.login(email: email, password: password);
      final user = result.user;

      if (user.weightKg == null || user.heightCm == null) {
        state = AuthProfileCompletionRequired(user);
      } else {
        state = AuthAuthenticated(user);
      }
    } catch (e) {
      state = AuthUnauthenticated(
          errorMessage: e.toString().replaceAll('Exception: ', ''));
    }
  }

  Future<void> register({
    required String name,
    required String email,
    required String password,
    required String passwordConfirmation,
  }) async {
    state = const AuthLoading();
    try {
      final result = await _repository.register(
        name: name,
        email: email,
        password: password,
        passwordConfirmation: passwordConfirmation,
      );
      // Pendaftaran sukses mengarah ke pengisian data tubuh (lengkapi profil)
      state = AuthProfileCompletionRequired(result.user);
    } catch (e) {
      state = AuthUnauthenticated(
          errorMessage: e.toString().replaceAll('Exception: ', ''));
    }
  }

  Future<void> completeProfile({
    required String name,
    required double weightKg,
    required double heightCm,
  }) async {
    final currentStatus = state;
    state = const AuthLoading();
    try {
      final updatedUser = await _repository.updateProfile(
        name: name,
        weightKg: weightKg,
        heightCm: heightCm,
      );
      state = AuthAuthenticated(updatedUser);
    } catch (e) {
      // Kembalikan ke state sebelumnya jika gagal
      if (currentStatus is AuthProfileCompletionRequired) {
        state = currentStatus;
      } else {
        state = const AuthUnauthenticated();
      }
      rethrow;
    }
  }

  Future<void> updateProfile({
    required String name,
    double? weightKg,
    double? heightCm,
  }) async {
    try {
      final updatedUser = await _repository.updateProfile(
        name: name,
        weightKg: weightKg,
        heightCm: heightCm,
      );
      state = AuthAuthenticated(updatedUser);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> logout() async {
    state = const AuthLoading();
    await _repository.logout();
    state = const AuthUnauthenticated();
  }
}
