import '../../../../core/utils/local_database.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/auth_repository.dart';
import '../models/user_model.dart';

/// Repository autentikasi dummy — digunakan saat [kUseDummyMode] = true.
///
/// - Menyimpan sesi ke [LocalDatabase] (in-memory di Web, SQLite di mobile)
///   agar [checkAuthStatus] tetap bekerja setelah hot-restart.
/// - Akun bawaan: demo@fittrack.local / password123
class DummyAuthRepository implements AuthRepository {
  // ── Akun bawaan ────────────────────────────────────────────────────────────
  static final Map<String, _DummyAccount> _accounts = {
    'demo@fittrack.local': const _DummyAccount(
      password: 'password123',
      user: UserEntity(
        id:       'dummy-user-1',
        email:    'demo@fittrack.local',
        name:     'Demo FitTrack',
        weightKg: 65,
        heightCm: 170,
      ),
    ),
  };

  static String _norm(String email) => email.trim().toLowerCase();

  Future<void> _delay() =>
      Future<void>.delayed(const Duration(milliseconds: 300));

  // ── Auth ───────────────────────────────────────────────────────────────────

  @override
  Future<({UserEntity user, String accessToken})> register({
    required String name,
    required String email,
    required String password,
    required String passwordConfirmation,
  }) async {
    await _delay();
    if (password != passwordConfirmation) {
      throw Exception('Konfirmasi password tidak cocok.');
    }
    final norm = _norm(email);
    if (_accounts.containsKey(norm)) {
      throw Exception('Email sudah terdaftar. Silakan masuk.');
    }

    final user = UserEntity(
      id:    'dummy-user-${DateTime.now().microsecondsSinceEpoch}',
      email: norm,
      name:  name.trim(),
    );
    _accounts[norm] = _DummyAccount(password: password, user: user);

    // Simpan ke local storage agar sesi bertahan
    await LocalDatabase.saveUserProfile(
        UserModel(id: user.id, email: user.email, name: user.name).toJson());

    return (user: user, accessToken: 'dummy-token-${user.id}');
  }

  @override
  Future<({UserEntity user, String accessToken})> login({
    required String email,
    required String password,
  }) async {
    await _delay();
    final norm    = _norm(email);
    final account = _accounts[norm];
    if (account == null || account.password != password) {
      throw Exception('Email atau password salah.');
    }

    await LocalDatabase.saveUserProfile(UserModel(
      id:       account.user.id,
      email:    account.user.email,
      name:     account.user.name,
      weightKg: account.user.weightKg,
      heightCm: account.user.heightCm,
    ).toJson());

    return (user: account.user, accessToken: 'dummy-token-${account.user.id}');
  }

  @override
  Future<void> logout() async {
    await _delay();
    await LocalDatabase.clearUserProfile();
    await LocalDatabase.clearAllActivities();
  }

  @override
  Future<UserEntity> getProfile() async {
    await _delay();
    final cached = await getCachedUser();
    if (cached == null) throw Exception('Belum ada akun yang sedang login.');
    return cached;
  }

  @override
  Future<UserEntity> updateProfile({
    required String name,
    double? weightKg,
    double? heightCm,
  }) async {
    await _delay();
    final cached = await getCachedUser();
    if (cached == null) throw Exception('Belum ada akun yang sedang login.');

    final updated = UserEntity(
      id:       cached.id,
      email:    cached.email,
      name:     name.trim(),
      weightKg: weightKg ?? cached.weightKg,
      heightCm: heightCm ?? cached.heightCm,
    );

    // Update di map in-memory
    final norm = _norm(cached.email);
    final account = _accounts[norm];
    if (account != null) {
      _accounts[norm] = _DummyAccount(
          password: account.password, user: updated);
    }

    // Persist ke local storage
    await LocalDatabase.saveUserProfile(UserModel(
      id:       updated.id,
      email:    updated.email,
      name:     updated.name,
      weightKg: updated.weightKg,
      heightCm: updated.heightCm,
    ).toJson());

    return updated;
  }

  @override
  Future<bool> isLoggedIn() async {
    final profile = await LocalDatabase.getUserProfile();
    return profile != null;
  }

  @override
  Future<UserEntity?> getCachedUser() async {
    final map = await LocalDatabase.getUserProfile();
    if (map == null) return null;
    return UserModel.fromJson(map);
  }
}

// ── Internal model ─────────────────────────────────────────────────────────

class _DummyAccount {
  final String password;
  final UserEntity user;

  const _DummyAccount({required this.password, required this.user});

  _DummyAccount copyWith({String? password, UserEntity? user}) =>
      _DummyAccount(
        password: password ?? this.password,
        user:     user ?? this.user,
      );
}
