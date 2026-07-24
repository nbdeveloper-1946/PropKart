import 'package:dio/dio.dart';
import 'api_constants.dart';
import 'interceptors.dart';

class DioClient {
  static final Dio dio = _initDio();

  static Dio _initDio() {
    final dioInstance = Dio(
      BaseOptions(
        baseUrl: ApiConstants.baseUrl,
        connectTimeout: const Duration(seconds: 20),
        receiveTimeout: const Duration(seconds: 20),
        headers: {
          "Content-Type": "application/json",
        },
      ),
    );
    dioInstance.interceptors.add(JwtInterceptor());
    return dioInstance;
  }
}