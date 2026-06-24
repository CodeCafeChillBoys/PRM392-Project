import 'package:google_sign_in/google_sign_in.dart';

import '../../core/config/api_config.dart';
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

  final GoogleSignIn _googleSignIn = GoogleSignIn(
    serverClientId:
        '642269070314-u0sust2rp5gcqgqtdsdhrvs0dmc1uees.apps.googleusercontent.com',
    scopes: ['email', 'profile'],
  );
  Future<void> login({
    required String email,
    required String password,
    required String deviceId,
    required String deviceName,
    required String deviceType,
    required String fcmToken,
  }) async {
    await _client.post(
      ApiConfig.login,
      body: {
        'email': email,
        'passWord': password,
        'deviceId': deviceId,
        'deviceName': deviceName,
        'deviceType': deviceType,
        'fcmToken': fcmToken,
      },
    );
  }

  /// Triggers the Google Sign-in flow, extracts the ID token, and sends it to the BE.
  Future<void> googleLogin({
    required String deviceId,
    required String deviceName,
    required String deviceType,
    required String fcmToken,
  }) async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        throw Exception('Đăng nhập Google bị hủy bởi người dùng.');
      }

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      final String? idToken = googleAuth.idToken;

      if (idToken == null) {
        throw Exception('Không lấy được Google ID Token.');
      }

      final response = await _client.post(
        ApiConfig.googleLogin,
        body: {
          'idToken': idToken,
          'deviceId': deviceId,
          'deviceName': deviceName,
          'deviceType': deviceType,
          'fcmToken': fcmToken,
        },
      );

      if (response?['success'] == true) {
        final data = response['data'];

        if (data?['accessToken'] != null) {
          _client.authToken = data['accessToken'];
          return;
        }
      }

      throw Exception(response?['message'] ?? 'Đăng nhập Google thất bại.');
    } catch (e) {
      await _googleSignIn.signOut();
      rethrow;
    }
  }

  Future<void> register({
    required String name,
    required String email,
    required String phone,
    required String password,
  }) async {
    await _client.post(
      ApiConfig.register,
      body: {
        'fullName': name,
        'email': email,
        'phone': phone,
        'password': password,
      },
    );
  }

  /// Send the chosen verification challenge to [email].
  Future<void> requestVerification(VerifyMethod method, String email) async {
    final endpoint = method == VerifyMethod.emailLink
        ? ApiConfig.sendEmailLink
        : ApiConfig.sendOtp;
    await _client.get(endpoint, query: {'email': email});
  }

  /// Check current status of the magic link sign-in session.
  Future<bool> checkSessionStatus(String email) async {
    final response = await _client.get(
      ApiConfig.sessionStatus,
      query: {'email': email},
    );
    if (response != null && response['success'] == true) {
      final data = response['data'];
      if (data != null && data['accessToken'] != null) {
        _client.authToken = data['accessToken'];
        return true;
      }
    }
    return false;
  }

  Future<void> verifyOtp({required String email, required String code}) async {
    final response = await _client.post(
      ApiConfig.verifyOtp,
      body: {'email': email, 'otp': code},
    );
    if (response != null && response['success'] == true) {
      final data = response['data'];
      if (data != null && data['accessToken'] != null) {
        _client.authToken = data['accessToken'];
      }
    }
  }
}
