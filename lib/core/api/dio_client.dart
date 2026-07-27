import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import 'dio_credentials_stub.dart'
    if (dart.library.html) 'dio_credentials_web.dart' as credentials;

import 'api_constants.dart';
import 'interceptors.dart';
import 'fallback_interceptor.dart';

class DioClient {
  static final Dio dio = _initDio();

  static Dio _initDio() {
    final dioInstance = Dio(
      BaseOptions(
        baseUrl: ApiConstants.baseUrl,
        connectTimeout: const Duration(seconds: 20),
        receiveTimeout: const Duration(seconds: 20),
        headers: {
          'Content-Type': 'application/json',
          if (kIsWeb) 'X-Auth-Transport': 'cookie',
        },
      ),
    );

    credentials.configureDioCredentials(dioInstance);
    dioInstance.interceptors.add(JwtInterceptor());
    dioInstance.interceptors.add(FallbackInterceptor());
    return dioInstance;
  }
}
