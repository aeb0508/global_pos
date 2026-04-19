import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  static SharedPreferences? _prefs;
  static String? _cachedToken;

  static String _clean(String? t) {
    if (t == null) return '';
    if (t.startsWith('"') && t.endsWith('"')) {
      return t.substring(1, t.length - 1);
    }
    return t;
  }

  static void prewarm(SharedPreferences prefs) {
    _prefs = prefs;
    _cachedToken = _clean(prefs.getString('token'));
    if (_cachedToken!.isEmpty) _cachedToken = null;
  }

  static Future<SharedPreferences> _getPrefs() async {
    _prefs ??= await SharedPreferences.getInstance();
    return _prefs!;
  }

  static Future<String?> getToken() async {
    if (_cachedToken != null) return _cachedToken;
    try {
      final prefs = await _getPrefs();
      final raw = prefs.getString('token');
      _cachedToken = raw != null ? _clean(raw) : null;
      if (_cachedToken != null && _cachedToken!.isEmpty) _cachedToken = null;
      return _cachedToken;
    } catch (e) {
      return null;
    }
  }

  static Future<void> saveToken(String token) async {
    _cachedToken = token;
    try {
      final prefs = await _getPrefs();
      await prefs.setString('token', token);
    } catch (e) {}
  }

  static Future<void> removeToken() async {
    _cachedToken = null;
    try {
      final prefs = await _getPrefs();
      await prefs.remove('token');
    } catch (e) {}
  }

  static Future<Map<String, String>> getHeaders() async {
    final token = _cachedToken ?? await getToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  // Append token as query param (InfinityFree strips Authorization header)
  static String _withToken(String url) {
    var token = _cachedToken;
    if (token == null) return url;
    // Strip surrounding quotes added by SharedPreferences JSON encoding
    if (token.startsWith('"') && token.endsWith('"')) {
      token = token.substring(1, token.length - 1);
    }
    final sep = url.contains('?') ? '&' : '?';
    return '$url${sep}token=$token';
  }

  static Future<Map<String, dynamic>> post(
      String url, Map<String, dynamic> body) async {
    try {
      final headers = await getHeaders();
      final response = await http.post(
        Uri.parse(_withToken(url)),
        headers: headers,
        body: jsonEncode(body),
      );
      return _decode(response.body, response.statusCode);
    } catch (e) {
      return {'success': false, 'message': 'Connection error: $e'};
    }
  }

  static Future<dynamic> get(String url) async {
    try {
      final headers = await getHeaders();
      final response = await http.get(
        Uri.parse(_withToken(url)),
        headers: headers,
      );
      return _decodeAny(response.body, response.statusCode);
    } catch (e) {
      return {'success': false, 'message': 'Connection error: $e'};
    }
  }

  static Future<Map<String, dynamic>> put(
      String url, Map<String, dynamic> body) async {
    try {
      final headers = await getHeaders();
      final response = await http.put(
        Uri.parse(_withToken(url)),
        headers: headers,
        body: jsonEncode(body),
      );
      return _decode(response.body, response.statusCode);
    } catch (e) {
      return {'success': false, 'message': 'Connection error: $e'};
    }
  }

  static Future<Map<String, dynamic>> delete(String url) async {
    try {
      final headers = await getHeaders();
      final response = await http.delete(
        Uri.parse(_withToken(url)),
        headers: headers,
      );
      return _decode(response.body, response.statusCode);
    } catch (e) {
      return {'success': false, 'message': 'Connection error: $e'};
    }
  }

  static bool _looksLikeHtml(String body) {
    final lowered = body.toLowerCase();
    return lowered.contains('<html') ||
        lowered.contains('<!doctype html') ||
        lowered.contains('<script');
  }

  static dynamic _decodeAny(String body, int statusCode) {
    final trimmed = body.trim();
    if (trimmed.isEmpty) {
      return {
        'success': false,
        'message': 'Empty response from server (HTTP $statusCode)'
      };
    }
    if (_looksLikeHtml(trimmed)) {
      final preview =
          trimmed.length > 120 ? trimmed.substring(0, 120) : trimmed;
      return {
        'success': false,
        'message':
            'Server returned HTML instead of JSON. This usually means the API URL is wrong, the backend is not reachable, or the remote host is blocking direct API calls. Preview: $preview'
      };
    }
    try {
      return jsonDecode(trimmed);
    } catch (_) {
      final preview =
          trimmed.length > 120 ? trimmed.substring(0, 120) : trimmed;
      return {
        'success': false,
        'message': 'Invalid server response (HTTP $statusCode): $preview'
      };
    }
  }

  static Map<String, dynamic> _decode(String body, int statusCode) {
    final result = _decodeAny(body, statusCode);
    if (result is Map<String, dynamic>) return result;
    return {'success': false, 'message': 'Unexpected response format'};
  }

  static Future<Map<String, dynamic>> uploadImage(
      String url, String fileName, List<int> bytes) async {
    try {
      final token = await getToken();
      final request = http.MultipartRequest('POST', Uri.parse(_withToken(url)));
      request.headers['Accept'] = 'application/json';
      if (token != null) {
        request.headers['Authorization'] = 'Bearer $token';
      }
      request.files.add(http.MultipartFile.fromBytes(
        'image',
        bytes,
        filename: fileName,
      ));
      final streamed = await request.send();
      final body = await streamed.stream.bytesToString();
      if (body.trim().isEmpty) {
        return {
          'success': false,
          'message':
              'Server returned empty response (HTTP ${streamed.statusCode})'
        };
      }
      return jsonDecode(body);
    } catch (e) {
      return {'success': false, 'message': 'Upload error: $e'};
    }
  }
}
