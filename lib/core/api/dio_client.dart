import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import 'api_constants.dart';
import 'interceptors.dart';
import 'fallback_interceptor.dart';

class DioClient {
  static final Dio dio = _initDio();

  static Dio _initDio() {
    Duration timeout = const Duration(seconds: 20);
    if (!kIsWeb) {
      try {
        if (Platform.environment.containsKey('FLUTTER_TEST')) {
          timeout = const Duration(milliseconds: 100);
        }
      } catch (_) {}
    }

    final dioInstance = Dio(
      BaseOptions(
        baseUrl: ApiConstants.baseUrl,
        connectTimeout: timeout,
        receiveTimeout: timeout,
        headers: {
          "Content-Type": "application/json",
        },
      ),
    );
    dioInstance.interceptors.add(JwtInterceptor());
    dioInstance.interceptors.add(FallbackInterceptor());
    return dioInstance;
  }
}