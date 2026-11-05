import 'package:dio/dio.dart';

import '../services/token_holder.dart';
import 'api_exception.dart';
import 'app_config.dart';

/// Cliente HTTP compartilhado para as chamadas à API do CATAS.
///
/// Respostas HTTP de erro são convertidas em [ApiException], preservando o
/// campo `detail` retornado pelo backend. Isso evita que uma regra de negócio
/// apareça na interface como erro de conexão.
class ApiClient {
  ApiClient({Dio? dio})
    : _dio =
          dio ??
          Dio(
            BaseOptions(
              baseUrl: AppConfig.apiBaseUrl,
              connectTimeout: const Duration(seconds: 15),
              receiveTimeout: const Duration(seconds: 60),
              headers: const {'Content-Type': 'application/json'},
              validateStatus: (status) => status != null && status < 500,
            ),
          ) {
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          final token = TokenHolder().token;
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          handler.next(options);
        },
      ),
    );
  }

  final Dio _dio;

  Future<Response<dynamic>> get(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) => _run(
    () => _dio.get(path, queryParameters: queryParameters, options: options),
  );

  Future<Response<dynamic>> post(
    String path, {
    Object? data,
    Options? options,
    CancelToken? cancelToken,
  }) => _run(
    () =>
        _dio.post(path, data: data, options: options, cancelToken: cancelToken),
  );

  Future<Response<dynamic>> patch(
    String path, {
    Object? data,
    Options? options,
  }) => _run(() => _dio.patch(path, data: data, options: options));

  Future<Response<dynamic>> delete(String path, {Options? options}) =>
      _run(() => _dio.delete(path, options: options));

  Future<Response<dynamic>> _run(
    Future<Response<dynamic>> Function() request,
  ) async {
    try {
      final response = await request();
      final statusCode = response.statusCode;
      if (statusCode != null && statusCode >= 200 && statusCode < 300) {
        return response;
      }
      throw _fromResponse(response);
    } on DioException catch (error) {
      if (CancelToken.isCancel(error)) rethrow;
      throw _fromDio(error);
    }
  }

  ApiException _fromResponse(Response<dynamic> response) {
    final data = response.data;
    final detail = data is Map ? data['detail']?.toString() : null;
    return ApiException(
      message: detail?.isNotEmpty == true
          ? detail!
          : 'A solicitação não pôde ser concluída.',
      statusCode: response.statusCode,
      data: data,
    );
  }

  ApiException _fromDio(DioException error) {
    if (error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.receiveTimeout ||
        error.type == DioExceptionType.connectionError) {
      return const ApiException(
        message:
            'Não foi possível conectar ao servidor. Verifique sua conexão.',
      );
    }
    return const ApiException(
      message: 'Não foi possível concluir a solicitação.',
    );
  }
}
