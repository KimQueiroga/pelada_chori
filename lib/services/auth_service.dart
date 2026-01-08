import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/api_config.dart';

class AuthService {
  static const _kTokenKey = 'jwt_token';

  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(_kTokenKey);
    if (token == null || token.isEmpty) return null;
    return token;
  }

  static Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kTokenKey, token);
  }

  static Future<void> clearToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kTokenKey);
  }

  static bool isExpired(String jwt) {
    try {
      final parts = jwt.split('.');
      if (parts.length != 3) return true;
      final payload = json.decode(
        utf8.decode(base64Url.decode(base64Url.normalize(parts[1]))),
      );
      final exp = payload['exp'];
      if (exp == null) return true;
      final nowSec = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      return exp <= nowSec;
    } catch (_) {
      return true;
    }
  }

  static Future<String?> refreshToken({String? token}) async {
    final current = token ?? await getToken();
    if (current == null || current.isEmpty) return null;

    final uri = Uri.parse('${ApiConfig.baseUrl}/auth/refresh');
    try {
      final resp = await http.post(
        uri,
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $current',
        },
      );

      if (resp.statusCode == 200) {
        try {
          final data = jsonDecode(resp.body) as Map<String, dynamic>;
          final newToken = data['token']?.toString();
          if (newToken != null && newToken.isNotEmpty) {
            await saveToken(newToken);
            return newToken;
          }
        } catch (_) {
          return null;
        }
      }

      if (resp.statusCode == 401) {
        await clearToken();
      }
    } catch (_) {
      return null;
    }

    return null;
  }

  static Future<String?> getValidToken() async {
    final token = await getToken();
    if (token == null || token.isEmpty) return null;
    if (!isExpired(token)) return token;
    return refreshToken(token: token);
  }

  static Future<http.Response> sendWithRefresh(
    Future<http.Response> Function(String token) requestBuilder,
  ) async {
    final token = await getToken();
    if (token == null || token.isEmpty) {
      return requestBuilder('');
    }

    final response = await requestBuilder(token);
    if (response.statusCode != 401) return response;

    final newToken = await refreshToken(token: token);
    if (newToken == null || newToken.isEmpty) return response;

    return requestBuilder(newToken);
  }

  /// Tenta invalidar no backend e SEMPRE remove o token local.
  /// Não faz navegação: quem chama decide o fluxo.
  static Future<void> logout() async {
    String? token;
    try {
      token = await getToken();

      // 1) tenta chamar o backend mesmo sem token (só para depurar/ver network)
      final uri = Uri.parse('${ApiConfig.baseUrl}/auth/logout');
      await http.post(
        uri,
        headers: {
          if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
      );
    } catch (_) {
      // ignoramos falhas de rede/servidor: o logout local vai acontecer de qualquer forma
    } finally {
      // 2) limpa o token local
      await clearToken();
    }
  }
}
