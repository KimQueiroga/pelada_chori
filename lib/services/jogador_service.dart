import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/jogador_model.dart';
import '../config/api_config.dart'; // para usar baseUrl e token
import 'auth_service.dart';

class JogadorService {
  static Future<List<JogadorModel>> listarTodos(String token) async {
    final response = await AuthService.sendWithRefresh((storedToken) {
      final useToken = storedToken.isNotEmpty ? storedToken : token;
      return http.get(
        Uri.parse('${ApiConfig.baseUrl}/jogadores/todos'),
        headers: {
          'Accept': 'application/json',
          if (useToken.isNotEmpty) 'Authorization': 'Bearer $useToken',
        },
      );
    });

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => JogadorModel.fromJson(json)).toList();
    } else {
      throw Exception('Erro ao carregar jogadores');
    }
  }
}
