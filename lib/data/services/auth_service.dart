import '../../core/config/api_config.dart';
import '../../core/config/app_config.dart';
import 'api_client.dart';

/// The verification method chosen after sign-in (per "Luồng BE / Register").
enum VerifyMethod { emailLink, otp }

/// Customer auth — register, login, and the two-track email verification
/// (magic-link OR 6-digit OTP) from the BE flow doc.
///
/// Mock mode simulates network latency and always succeeds (with light input
/// validation) so the UI's loading states behave exactly as they will live.
class AuthService {
  AuthService({ApiClient? client}) : _client = client ?? apiClient;

  final ApiClient _client;

  Future<void> login({required String email, required String password}) async {
    if (AppConfig.useMockData) {
      await Future.delayed(const Duration(milliseconds: 1100));
      if (email.trim().isEmpty || password.isEmpty) {
        throw Exception('Email và mật khẩu không được để trống.');
      }
      return;
    }
    await _client.post(ApiConfig.login, body: {'email': email, 'password': password});
  }

  Future<void> register({
    required String name,
    required String email,
    required String phone,
    required String password,
  }) async {
    if (AppConfig.useMockData) {
      await Future.delayed(const Duration(milliseconds: 1100));
      return;
    }
    await _client.post(ApiConfig.register, body: {
      'fullName': name,
      'email': email,
      'phone': phone,
      'password': password,
    });
  }

  /// Send the chosen verification challenge to [email].
  Future<void> requestVerification(VerifyMethod method, String email) async {
    final endpoint =
        method == VerifyMethod.emailLink ? ApiConfig.sendEmailLink : ApiConfig.sendOtp;
    if (AppConfig.useMockData) {
      await Future.delayed(AppConfig.mockLatency);
      return;
    }
    await _client.post(endpoint, body: {'email': email});
  }

  Future<void> verifyOtp({required String email, required String code}) async {
    if (AppConfig.useMockData) {
      await Future.delayed(const Duration(milliseconds: 900));
      return;
    }
    await _client.post(ApiConfig.verifyOtp, body: {'email': email, 'otp': code});
  }
}
