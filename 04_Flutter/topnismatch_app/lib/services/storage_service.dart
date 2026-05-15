import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class StorageService {
  static const _baseUrl = 'https://topnismatch.onrender.com';
  static const _storage = FlutterSecureStorage();

  static Future<String> subirFoto(File archivo, int usuarioId) async {
    final token = await _storage.read(key: 'jwt_token');
    
    if (token == null || token.isEmpty) {
      throw Exception('TOKEN NULL - Clave buscada: jwt_token');
    }

    final dio = Dio();
    dio.options.connectTimeout = const Duration(seconds: 30);
    dio.options.receiveTimeout = const Duration(seconds: 30);
    
    try {
      final formData = FormData.fromMap({
        'archivo': await MultipartFile.fromFile(archivo.path, filename: 'foto.jpg'),
      });
      
      final response = await dio.post(
        '$_baseUrl/api/v1/upload/foto',
        data: formData,
        options: Options(
          headers: {'Authorization': 'Bearer $token'},
        ),
      );
      return response.data['url'];
    } on DioException catch (e) {
      throw Exception('DIO ERROR: ${e.response?.statusCode} - ${e.response?.data} - ${e.message}');
    }
  }
}