import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/api_client.dart';

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier();
});

class AuthState {
  final String? uid;
  final String? email;
  final String? displayName;
  final String? token;
  final bool isLoading;
  final String? error;
  final bool isNewUser;

  AuthState({
    this.uid,
    this.email,
    this.displayName,
    this.token,
    this.isLoading = true,
    this.error,
    this.isNewUser = false,
  });

  AuthState copyWith({
    String? uid,
    String? email,
    String? displayName,
    String? token,
    bool? isLoading,
    String? error,
    bool? isNewUser,
  }) {
    return AuthState(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      token: token ?? this.token,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      isNewUser: isNewUser ?? this.isNewUser,
    );
  }

  bool get isAuthenticated => token != null && token!.isNotEmpty && uid != null;
}

class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier() : super(AuthState()) {
    _restoreSession();
  }

  /// Try to restore session from stored token on app launch.
  Future<void> _restoreSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final storedToken = prefs.getString('care2_token');
      final storedUid = prefs.getString('care2_uid');
      final storedEmail = prefs.getString('care2_email');
      final storedName = prefs.getString('care2_display_name');

      if (storedToken != null && storedToken.isNotEmpty) {
        // Verify token is still valid with the server
        try {
          await ApiClient.init();
          final userInfo = await ApiClient.verifyToken();
          state = AuthState(
            uid: userInfo['uid'],
            email: userInfo['email'],
            displayName: userInfo['display_name'],
            token: storedToken,
            isLoading: false,
          );
          return;
        } catch (_) {
          // Token expired or invalid — clear it
          await _clearStorage();
        }
      }
    } catch (_) {
      // SharedPreferences not available yet
    }
    state = AuthState(isLoading: false);
  }

  /// Register new account.
  Future<bool> register(String email, String password, String displayName) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await ApiClient.init();
      final result = await ApiClient.register(
        email: email,
        password: password,
        displayName: displayName,
      );
      await _persistSession(result);
      state = AuthState(
        uid: result['uid'],
        email: result['email'],
        displayName: result['display_name'],
        token: result['access_token'],
        isLoading: false,
        isNewUser: true,
      );
      return true;
    } catch (e) {
      final msg = _extractError(e);
      state = state.copyWith(isLoading: false, error: msg);
      return false;
    }
  }

  /// Login with credentials.
  Future<bool> login(String email, String password) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await ApiClient.init();
      final result = await ApiClient.login(email: email, password: password);
      await _persistSession(result);
      state = AuthState(
        uid: result['uid'],
        email: result['email'],
        displayName: result['display_name'],
        token: result['access_token'],
        isLoading: false,
      );
      return true;
    } catch (e) {
      final msg = _extractError(e);
      state = state.copyWith(isLoading: false, error: msg);
      return false;
    }
  }

  /// Forgot password — request reset token.
  Future<String?> forgotPassword(String email) async {
    try {
      await ApiClient.init();
      final result = await ApiClient.forgotPassword(email);
      return result['reset_token'] as String?;
    } catch (e) {
      state = state.copyWith(error: _extractError(e));
      return null;
    }
  }

  /// Reset password with token.
  Future<bool> resetPassword(String token, String newPassword) async {
    try {
      await ApiClient.init();
      await ApiClient.resetPassword(token: token, newPassword: newPassword);
      return true;
    } catch (e) {
      state = state.copyWith(error: _extractError(e));
      return false;
    }
  }

  /// Logout — clear all stored auth data.
  Future<void> logout() async {
    await _clearStorage();
    state = AuthState(isLoading: false);
  }

  /// Clear error state.
  void clearError() {
    state = state.copyWith(error: null);
  }

  // ── Private helpers ──

  Future<void> _persistSession(Map<String, dynamic> data) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('care2_token', data['access_token'] ?? '');
    await prefs.setString('care2_uid', data['uid'] ?? '');
    await prefs.setString('care2_email', data['email'] ?? '');
    await prefs.setString('care2_display_name', data['display_name'] ?? '');
  }

  Future<void> _clearStorage() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('care2_token');
    await prefs.remove('care2_uid');
    await prefs.remove('care2_email');
    await prefs.remove('care2_display_name');
    // Also remove legacy key
    await prefs.remove('care2_username');
  }

  String _extractError(dynamic e) {
    if (e is Exception) {
      try {
        // DioException has response.data.detail
        final dioError = e as dynamic;
        final detail = dioError.response?.data?['detail'];
        if (detail != null) return detail.toString();
      } catch (_) {}
    }
    return 'Something went wrong. Please try again.';
  }
}
