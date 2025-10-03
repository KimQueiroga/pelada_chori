import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/api_config.dart';

class AuthService {
  static const _kTokenKey = 'jwt_token';

  /// Tenta invalidar no backend e SEMPRE remove o token local.
  /// Não faz navegação: quem chama decide o fluxo.
  static Future<void> logout() async {
    String? token;
    try {
      final prefs = await SharedPreferences.getInstance();
      token = prefs.getString(_kTokenKey);

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
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_kTokenKey);
    }
  }
}
