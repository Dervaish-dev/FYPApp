import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:neurocompanion_flutter/services/api_exceptions.dart';
import 'package:neurocompanion_flutter/services/token_store.dart';

class ApiClient {
  final String baseUrl;
  final TokenStore tokenStore;
  final http.Client _http;

  ApiClient({
    required this.baseUrl,
    required this.tokenStore,
    http.Client? httpClient,
  }) : _http = httpClient ?? http.Client();

  Uri _uri(String path) {
    final normalizedBase = baseUrl.endsWith('/') ? baseUrl.substring(0, baseUrl.length - 1) : baseUrl;
    final normalizedPath = path.startsWith('/') ? path : '/$path';
    return Uri.parse('$normalizedBase$normalizedPath');
  }

  Future<Map<String, String>> _headers({required bool authenticated}) async {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    if (authenticated) {
      final token = await tokenStore.readToken();
      if (token != null && token.isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
      }
    }

    return headers;
  }

  Future<Map<String, String>> _authHeaders({required bool authenticated}) async {
    final headers = <String, String>{
      'Accept': 'application/json',
    };

    if (authenticated) {
      final token = await tokenStore.readToken();
      if (token != null && token.isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
      }
    }

    return headers;
  }

  Future<dynamic> get(String path, {bool authenticated = true}) async {
    final uri = _uri(path);
    print('🌐 [GET] $uri');
    
    final res = await _http.get(
      uri,
      headers: await _headers(authenticated: authenticated),
    );
    
    print('✅ [GET] $uri - Status: ${res.statusCode}');
    if (res.statusCode >= 400) {
      print('❌ [GET] Response: ${res.body}');
    }
    
    return _decodeOrThrow(res);
  }

  Future<dynamic> post(String path, {Object? body, bool authenticated = true}) async {
    final uri = _uri(path);
    print('🌐 [POST] $uri');
    if (body != null) {
      print('📤 [POST] Body: ${jsonEncode(body)}');
    }
    
    final res = await _http.post(
      uri,
      headers: await _headers(authenticated: authenticated),
      body: body == null ? null : jsonEncode(body),
    );
    
    print('✅ [POST] $uri - Status: ${res.statusCode}');
    if (res.statusCode >= 400) {
      print('❌ [POST] Response: ${res.body}');
    } else {
      print('📥 [POST] Response: ${res.body.length > 200 ? res.body.substring(0, 200) + "..." : res.body}');
    }
    
    return _decodeOrThrow(res);
  }

  Future<dynamic> put(String path, {Object? body, bool authenticated = true}) async {
    final uri = _uri(path);
    print('🌐 [PUT] $uri');
    if (body != null) {
      print('📤 [PUT] Body: ${jsonEncode(body)}');
    }
    
    final res = await _http.put(
      uri,
      headers: await _headers(authenticated: authenticated),
      body: body == null ? null : jsonEncode(body),
    );
    
    print('✅ [PUT] $uri - Status: ${res.statusCode}');
    if (res.statusCode >= 400) {
      print('❌ [PUT] Response: ${res.body}');
    }
    
    return _decodeOrThrow(res);
  }

  Future<dynamic> delete(String path, {Object? body, bool authenticated = true}) async {
    final uri = _uri(path);
    print('🌐 [DELETE] $uri');
    if (body != null) {
      print('📤 [DELETE] Body: ${jsonEncode(body)}');
    }
    
    final request = http.Request('DELETE', uri);
    request.headers.addAll(await _headers(authenticated: authenticated));
    if (body != null) {
      request.body = jsonEncode(body);
    }

    final streamed = await _http.send(request);
    final res = await http.Response.fromStream(streamed);
    
    print('✅ [DELETE] $uri - Status: ${res.statusCode}');
    if (res.statusCode >= 400) {
      print('❌ [DELETE] Response: ${res.body}');
    }
    
    return _decodeOrThrow(res);
  }

  Future<dynamic> postMultipart(
    String path, {
    required String fileField,
    required File file,
    Map<String, String>? fields,
    Map<String, String>? extraHeaders,
    bool authenticated = true,
  }) async {
    final uri = _uri(path);
    print('🌐 [POST-MULTIPART] $uri');
    print('📤 [MULTIPART] File: ${file.path}');
    if (fields != null && fields.isNotEmpty) {
      print('📤 [MULTIPART] Fields: $fields');
    }
    
    final request = http.MultipartRequest('POST', uri);
    request.headers.addAll(await _authHeaders(authenticated: authenticated));
    if (extraHeaders != null && extraHeaders.isNotEmpty) {
      request.headers.addAll(extraHeaders);
    }

    if (fields != null && fields.isNotEmpty) {
      request.fields.addAll(fields);
    }

    request.files.add(await http.MultipartFile.fromPath(fileField, file.path));

    final streamed = await request.send();
    final res = await http.Response.fromStream(streamed);
    
    print('✅ [POST-MULTIPART] $uri - Status: ${res.statusCode}');
    if (res.statusCode >= 400) {
      print('❌ [MULTIPART] Response: ${res.body}');
    }
    
    return _decodeOrThrow(res);
  }

  dynamic _decodeOrThrow(http.Response res) {
    dynamic decoded;
    try {
      decoded = res.body.isEmpty ? null : jsonDecode(res.body);
    } catch (_) {
      decoded = res.body;
    }

    if (res.statusCode >= 200 && res.statusCode < 300) {
      return decoded;
    }

    // Backend generally returns { success: false, message, ... }
    String message = 'Request failed';
    Object? details;

    if (decoded is Map<String, dynamic>) {
      message = (decoded['message'] ?? decoded['error'] ?? message).toString();
      details = decoded;
    } else if (decoded is String && decoded.isNotEmpty) {
      message = decoded;
    }

    throw ApiException(message: message, statusCode: res.statusCode, details: details);
  }
}
