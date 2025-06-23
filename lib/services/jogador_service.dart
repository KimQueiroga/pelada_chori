import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/jogador_model.dart';
import '../config/api_config.dart'; // para usar baseUrl e token

class JogadorService {
  static Future<List<JogadorModel>> listarTodos(String token) async {
    final response = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/jogadores/todos'),
      headers: {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => JogadorModel.fromJson(json)).toList();
    } else {
      throw Exception('Erro ao carregar jogadores');
    }
  }
}
