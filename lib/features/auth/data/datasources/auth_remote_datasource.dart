import 'package:dio/dio.dart';
import '../../../../core/network/api_client.dart';
import '../models/user_model.dart';

class AuthRemoteDataSource {
  final ApiClient _apiClient;

  AuthRemoteDataSource(this._apiClient);

  Future<({UserModel user, String accessToken})> register({
    required String name,
    required String email,
    required String password,
    required String passwordConfirmation,
  }) async {
    try {
      final res = await _apiClient.post('/auth/register', data: {
        'name':                 name,
        'email':                email,
        'password':             password,
        'passwordConfirmation': passwordConfirmation,
      });
      final data = res.data['data'];
      return (
        user:        UserModel.fromJson(data['user'] as Map<String, dynamic>),
        accessToken: data['accessToken'] as String,
      );
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Gagal mendaftar.');
    }
  }

  Future<({UserModel user, String accessToken})> login({
    required String email,
    required String password,
  }) async {
    try {
      final res = await _apiClient.post('/auth/login', data: {
        'email':    email,
        'password': password,
      });
      final data = res.data['data'];
      return (
        user:        UserModel.fromJson(data['user'] as Map<String, dynamic>),
        accessToken: data['accessToken'] as String,
      );
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Gagal login.');
    }
  }

  Future<void> logout() async {
    try {
      await _apiClient.post('/auth/logout');
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Gagal logout.');
    }
  }

  Future<UserModel> getProfile() async {
    try {
      final res = await _apiClient.get('/users/me');
      final data = res.data['data'];
      return UserModel.fromJson(data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Gagal mengambil profil.');
    }
  }

  Future<UserModel> updateProfile({
    required String name,
    double? weightKg,
    double? heightCm,
  }) async {
    try {
      final res = await _apiClient.put('/users/me', data: {
        'name':     name,
        if (weightKg != null) 'weightKg': weightKg,
        if (heightCm != null) 'heightCm': heightCm,
      });
      final data = res.data['data'];
      return UserModel.fromJson(data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Gagal memperbarui profil.');
    }
  }
}
