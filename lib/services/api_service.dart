import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/sorteio_simplificado_model.dart';
import '../models/sorteio_detalhe_model.dart';




class ApiService {
  // Buscar os dados do jogador autenticado
  static Future<Map<String, dynamic>> getMeusDados() async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/meus-dados');

    final response = await http.get(
      uri,
      headers: {
        'Accept': 'application/json',
        'Authorization': 'Bearer ${await getToken()}',
      },
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Erro ao buscar dados do jogador: ${response.body}');
    }
  }

  // Buscar todos os jogadores cadastrados (sem filtro de votação)
  static Future<List<Map<String, dynamic>>> getJogadoresTodos() async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/jogadores/todos');

    final response = await http.get(
      uri,
      headers: {
        'Accept': 'application/json',
        'Authorization': 'Bearer ${await getToken()}',
      },
    );

    if (response.statusCode == 200) {
      final List dados = json.decode(response.body);
      return dados.cast<Map<String, dynamic>>();
    } else {
      throw Exception('Erro ao buscar jogadores: ${response.body}');
    }
  }
  
    static Future<List<SorteioSimplificadoModel>> getSorteiosAtivos() async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/sorteios/ativos');

    final response = await http.get(
      uri,
      headers: {
        'Accept': 'application/json',
        'Authorization': 'Bearer ${await getToken()}',
      },
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data
          .map((json) => SorteioSimplificadoModel.fromJson(json))
          .toList();
    } else {
      throw Exception('Erro ao carregar sorteios ativos: ${response.body}');
    }
  }

    static Future<SorteioDetalhe> getSorteioDetalhe(int id) async {
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/sorteios/$id'),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer ${await getToken()}',
        },
      );

      if (response.statusCode == 200) {
        return SorteioDetalhe.fromJson(jsonDecode(response.body));
      } else {
        throw Exception('Erro ao buscar detalhes do sorteio');
      }
    }





    // Recuperar o token JWT armazenado
    static Future<String> getToken() async {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString('jwt_token') ?? '';
    }
  }
