import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ApiService {
  static const String baseUrl = 'http://localhost:8080/api/v1';

  final Dio _dio = Dio();
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  ApiService() {
    _dio.options.baseUrl = baseUrl;
    _dio.options.connectTimeout = const Duration(seconds: 30);
    _dio.options.receiveTimeout = const Duration(seconds: 30);

    // Interceptor para agregar JWT automáticamente
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await _storage.read(key: 'jwt_token');
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          return handler.next(options);
        },
        onError: (error, handler) {
          return handler.next(error);
        },
      ),
    );
  }

  // ── AUTH ──────────────────────────────────────
  Future<Map<String, dynamic>> register(Map<String, dynamic> data) async {
    final response = await _dio.post('/auth/register', data: data);
    return response.data;
  }

  Future<Map<String, dynamic>> login(String email, String password) async {
    final response = await _dio.post(
      '/auth/login',
      data: {'email': email, 'password': password},
    );
    return response.data;
  }

  Future<void> logout() async {
    await _dio.post('/auth/logout');
    await _storage.delete(key: 'jwt_token');
  }

  // ── PROFILE ───────────────────────────────────
  Future<Map<String, dynamic>> getMiPerfil() async {
    final response = await _dio.get('/profile/me');
    return response.data;
  }

  Future<Map<String, dynamic>> crearPerfil(Map<String, dynamic> data) async {
    final response = await _dio.post('/profile', data: data);
    return response.data;
  }

  Future<Map<String, dynamic>> editarPerfil(Map<String, dynamic> data) async {
    final response = await _dio.put('/profile', data: data);
    return response.data;
  }

  // ── SWIPE ─────────────────────────────────────
  Future<List<dynamic>> discover() async {
    final response = await _dio.get('/discover');
    return response.data;
  }

  Future<Map<String, dynamic>> darLike(int usuarioId) async {
    final response = await _dio.post('/swipe/like/$usuarioId');
    return response.data;
  }

  Future<Map<String, dynamic>> darDislike(int usuarioId) async {
    final response = await _dio.post('/swipe/dislike/$usuarioId');
    return response.data;
  }

  // ── MATCH ─────────────────────────────────────
  Future<List<dynamic>> getMisMatches() async {
    final response = await _dio.get('/matches');
    return response.data;
  }

  // ── CHAT ──────────────────────────────────────
  Future<List<dynamic>> getMensajes(int matchId) async {
    final response = await _dio.get('/messages/$matchId');
    return response.data;
  }

  Future<Map<String, dynamic>> enviarMensaje(
    int matchId,
    String contenido,
  ) async {
    final response = await _dio.post(
      '/messages/$matchId',
      data: {'contenido': contenido},
    );
    return response.data;
  }

  // ── PREMIUM ───────────────────────────────────
  Future<Map<String, dynamic>> getSuscripcion() async {
    final response = await _dio.get('/subscription');
    return response.data;
  }

  // ── STORAGE ───────────────────────────────────
  Future<void> saveToken(String token) async {
    await _storage.write(key: 'jwt_token', value: token);
  }

  Future<String?> getToken() async {
    return await _storage.read(key: 'jwt_token');
  }

  Future<bool> isLoggedIn() async {
    final token = await _storage.read(key: 'jwt_token');
    return token != null;
  }

  Future<void> marcarComoLeido(int matchId) async {
    await _dio.put('/messages/$matchId/read');
  }
}
