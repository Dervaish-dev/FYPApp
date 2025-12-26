class ApiException implements Exception {
  final String message;
  final int? statusCode;
  final Object? details;

  const ApiException({
    required this.message,
    this.statusCode,
    this.details,
  });

  @override
  String toString() {
    final code = statusCode != null ? ' (HTTP $statusCode)' : '';
    return 'ApiException$code: $message';
  }
}
