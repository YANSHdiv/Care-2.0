/// Care 2.0 — API Client
/// Dio-based HTTP client with JWT auth support for FastAPI backend.
library;

import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ApiClient {
  static const String baseUrl = 'http://localhost:8000';
  
  static final Dio _dio = Dio(BaseOptions(
    baseUrl: baseUrl,
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 30),
    headers: {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    },
  ));

  static bool _interceptorAdded = false;

  /// Initialize the auth interceptor — call once at app start.
  static Future<void> init() async {
    if (_interceptorAdded) return;
    _interceptorAdded = true;
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final prefs = await SharedPreferences.getInstance();
        final token = prefs.getString('care2_token');
        if (token != null && token.isNotEmpty) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        handler.next(options);
      },
    ));
  }
  
  static Dio get instance => _dio;

  // ── Auth Endpoints ──
  static Future<Map<String, dynamic>> register({
    required String email,
    required String password,
    required String displayName,
  }) async {
    final response = await _dio.post('/api/v1/auth/register', data: {
      'email': email,
      'password': password,
      'display_name': displayName,
    });
    return response.data;
  }

  static Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    final response = await _dio.post('/api/v1/auth/login', data: {
      'email': email,
      'password': password,
    });
    return response.data;
  }

  static Future<Map<String, dynamic>> verifyToken() async {
    final response = await _dio.get('/api/v1/auth/me');
    return response.data;
  }

  static Future<Map<String, dynamic>> forgotPassword(String email) async {
    final response = await _dio.post('/api/v1/auth/forgot-password', data: {
      'email': email,
    });
    return response.data;
  }

  static Future<Map<String, dynamic>> resetPassword({
    required String token,
    required String newPassword,
  }) async {
    final response = await _dio.post('/api/v1/auth/reset-password', data: {
      'token': token,
      'new_password': newPassword,
    });
    return response.data;
  }
  
  // ── Profile Endpoints ──
  static Future<Map<String, dynamic>> createProfile(Map<String, dynamic> data) async {
    final response = await _dio.post('/api/v1/profile/', data: data);
    return response.data;
  }
  
  static Future<Map<String, dynamic>> getProfile(String uid) async {
    final response = await _dio.get('/api/v1/profile/$uid');
    return response.data;
  }
  
  // ── Environment Endpoints ──
  static Future<Map<String, dynamic>> getAqi(double lat, double lon) async {
    final response = await _dio.get('/api/v1/environment/aqi', queryParameters: {
      'lat': lat,
      'lon': lon,
    });
    return response.data;
  }
  
  static Future<Map<String, dynamic>> getExerciseRecommendation({
    required double lat,
    required double lon,
    List<String> conditions = const [],
  }) async {
    final response = await _dio.post('/api/v1/environment/recommendation', data: {
      'latitude': lat,
      'longitude': lon,
      'user_conditions': conditions,
    });
    return response.data;
  }
  
  // ── Nutrition Endpoints ──
  static Future<Map<String, dynamic>> analyzeFood(
    String imagePath,
    String uid, {
    String mealType = 'other',
  }) async {
    final formData = FormData.fromMap({
      'image': await MultipartFile.fromFile(imagePath, filename: 'food.jpg'),
      'uid': uid,
      'meal_type': mealType,
    });
    final response = await _dio.post('/api/v1/nutrition/analyze', data: formData);
    return response.data;
  }
  
  static Future<Map<String, dynamic>> getMealHistory(String uid) async {
    final response = await _dio.get('/api/v1/nutrition/history/$uid');
    return response.data;
  }
  
  // ── Prediction Endpoints ──
  static Future<Map<String, dynamic>> generateDemoReport(String uid) async {
    final response = await _dio.post('/api/v1/prediction/demo/$uid');
    return response.data;
  }
  
  static Future<Map<String, dynamic>> getLatestReport(String uid) async {
    final response = await _dio.get('/api/v1/prediction/report/$uid');
    return response.data;
  }
  
  // ── Nearby Endpoints ──
  static Future<Map<String, dynamic>> findNearbyCare({
    required double lat,
    required double lon,
    String? uid,
    double radiusKm = 25,
  }) async {
    final response = await _dio.get('/api/v1/nearby/care', queryParameters: {
      'lat': lat,
      'lon': lon,
      if (uid != null) 'uid': uid,
      'radius_km': radiusKm,
    });
    return response.data;
  }
}
