import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_remote_datasource.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/utils/local_database.dart';
import '../models/user_model.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource _remoteDataSource;
  final ApiClient _apiClient;

  AuthRepositoryImpl(this._remoteDataSource, this._apiClient);

  @override
  Future<({UserEntity user, String accessToken})> register({
    required String name,
    required String email,
    required String password,
    required String passwordConfirmation,
  }) async {
    final result = await _remoteDataSource.register(
      name: name,
      email: email,
      password: password,
      passwordConfirmation: passwordConfirmation,
    );
    await _apiClient.saveToken(result.accessToken);
    await LocalDatabase.saveUserProfile(result.user.toJson());
    return (user: result.user, accessToken: result.accessToken);
  }

  @override
  Future<({UserEntity user, String accessToken})> login({
    required String email,
    required String password,
  }) async {
    final result = await _remoteDataSource.login(email: email, password: password);
    await _apiClient.saveToken(result.accessToken);
    await LocalDatabase.saveUserProfile(result.user.toJson());
    return (user: result.user, accessToken: result.accessToken);
  }

  @override
  Future<void> logout() async {
    try {
      await _remoteDataSource.logout();
    } catch (_) {
      // Abaikan error jaringan saat logout agar tetap bisa membersihkan state lokal
    }
    await _apiClient.clearToken();
    await LocalDatabase.clearUserProfile();
    await LocalDatabase.clearAllActivities();
  }

  @override
  Future<UserEntity> getProfile() async {
    final userModel = await _remoteDataSource.getProfile();
    await LocalDatabase.saveUserProfile(userModel.toJson());
    return userModel;
  }

  @override
  Future<UserEntity> updateProfile({
    required String name,
    double? weightKg,
    double? heightCm,
  }) async {
    final userModel = await _remoteDataSource.updateProfile(
      name: name,
      weightKg: weightKg,
      heightCm: heightCm,
    );
    await LocalDatabase.saveUserProfile(userModel.toJson());
    return userModel;
  }

  @override
  Future<bool> isLoggedIn() async {
    final token = await _apiClient.getToken();
    return token != null && token.isNotEmpty;
  }

  @override
  Future<UserEntity?> getCachedUser() async {
    final userMap = await LocalDatabase.getUserProfile();
    if (userMap == null) return null;
    return UserModel.fromJson(userMap);
  }
}
