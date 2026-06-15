import '../entities/user_entity.dart';

abstract class AuthRepository {
  Future<({UserEntity user, String accessToken})> register({
    required String name,
    required String email,
    required String password,
    required String passwordConfirmation,
  });

  Future<({UserEntity user, String accessToken})> login({
    required String email,
    required String password,
  });

  Future<void> logout();

  Future<UserEntity> getProfile();

  Future<UserEntity> updateProfile({
    required String name,
    double? weightKg,
    double? heightCm,
  });

  Future<bool> isLoggedIn();
  Future<UserEntity?> getCachedUser();
}
