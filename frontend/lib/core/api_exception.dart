class ApiException implements Exception {
  const ApiException({required this.message, this.statusCode, this.data});

  final String message;
  final int? statusCode;
  final Object? data;

  bool get isUnauthorized => statusCode == 401;
  bool get isForbidden => statusCode == 403;

  @override
  String toString() => message;
}
