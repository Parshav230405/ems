import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class ApiException implements Exception {
  final String message;
  final int statusCode;
  final List<dynamic>? details;

  ApiException(this.message, {this.statusCode = 500, this.details});

  @override
  String toString() {
    if (details != null && details!.isNotEmpty) {
      final detailStrings = details!.map((d) {
        if (d is Map && d.containsKey('field') && d.containsKey('message')) {
          final f = d['field']?.toString() ?? '';
          final m = d['message']?.toString() ?? '';
          return f.isNotEmpty ? '$f: $m' : m;
        }
        return d.toString();
      }).join(', ');
      if (!message.contains(detailStrings)) {
        return '$message ($detailStrings)';
      }
    }
    return message;
  }
}

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  String get baseUrl {
    if (kIsWeb) {
      final origin = Uri.base.origin;
      if (origin.isNotEmpty && !origin.startsWith('file://')) {
        if (Uri.base.host != 'localhost' && Uri.base.host != '127.0.0.1') {
          return '$origin/api';
        }
      }
    }
    return const String.fromEnvironment('API_BASE_URL', defaultValue: 'http://localhost:5000/api');
  }
  String? _token;

  void setToken(String? token) {
    _token = token;
  }

  String? get token => _token;

  Map<String, String> _headers() {
    final headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    if (_token != null) {
      headers['Authorization'] = 'Bearer $_token';
    }
    return headers;
  }

  Future<dynamic> get(String endpoint, {Map<String, String>? queryParams}) async {
    Uri uri = Uri.parse('$baseUrl$endpoint');
    if (queryParams != null && queryParams.isNotEmpty) {
      uri = uri.replace(queryParameters: queryParams);
    }

    try {
      final response = await http.get(uri, headers: _headers());
      return _handleResponse(response);
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Network connection failed: $e');
    }
  }

  Future<dynamic> post(String endpoint, dynamic body) async {
    final uri = Uri.parse('$baseUrl$endpoint');
    try {
      final response = await http.post(
        uri,
        headers: _headers(),
        body: jsonEncode(body),
      );
      return _handleResponse(response);
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Network connection failed: $e');
    }
  }

  Future<dynamic> put(String endpoint, dynamic body) async {
    final uri = Uri.parse('$baseUrl$endpoint');
    try {
      final response = await http.put(
        uri,
        headers: _headers(),
        body: jsonEncode(body),
      );
      return _handleResponse(response);
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Network connection failed: $e');
    }
  }

  Future<dynamic> patch(String endpoint, dynamic body) async {
    final uri = Uri.parse('$baseUrl$endpoint');
    try {
      final response = await http.patch(
        uri,
        headers: _headers(),
        body: jsonEncode(body),
      );
      return _handleResponse(response);
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Network connection failed: $e');
    }
  }

  Future<dynamic> delete(String endpoint) async {
    final uri = Uri.parse('$baseUrl$endpoint');
    try {
      final response = await http.delete(uri, headers: _headers());
      return _handleResponse(response);
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Network connection failed: $e');
    }
  }

  dynamic _handleResponse(http.Response response) {
    dynamic decoded;
    try {
      decoded = jsonDecode(response.body);
    } catch (_) {
      decoded = {'error': response.body};
    }

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return decoded;
    }

    final errorMessage = decoded is Map && decoded.containsKey('message') && decoded['message'] != null
        ? decoded['message']
        : (decoded is Map && decoded.containsKey('error') && decoded['error'] != null
            ? decoded['error']
            : 'Request failed with status: ${response.statusCode}');

    final details = decoded is Map && decoded.containsKey('details') ? decoded['details'] : null;

    throw ApiException(
      errorMessage.toString(),
      statusCode: response.statusCode,
      details: details,
    );
  }
}
