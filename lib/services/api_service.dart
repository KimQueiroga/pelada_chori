import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/sorteio_simplificado_model.dart';
import '../models/sorteio_detalhe_model.dart';
import 'package:intl/intl.dart';


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

      static String _ymd(DateTime d) =>
        '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

    /// Rascunhos do dia (as duas tentativas ainda não publicadas)
    /// Publica a dupla mais recente do dia para votação
    static Future<void> publicarDupla(DateTime data) async {
      final uri = Uri.parse('${ApiConfig.baseUrl}/sorteios/publicar');
      final response = await http.post(
        uri,
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${await getToken()}',
        },
        body: jsonEncode({'data': _ymd(data)}),
      );
      if (response.statusCode != 200) {
        throw Exception('Erro ao publicar: ${response.body}');
      }
    }

    /// Retorna a dupla atualmente em votação (com votos_count)
      static Future<SorteioDetalhe?> getVotacaoAtiva() async {
      final uri = Uri.parse('${ApiConfig.baseUrl}/votacao-ativa');
      final resp = await http.get(uri, headers: await _authHeaders());

      if (resp.statusCode == 200) {
        final raw = jsonDecode(resp.body);
        if (raw == null) return null;

        if (raw is List) {
          if (raw.isEmpty) return null;
          return SorteioDetalhe.fromJson(raw.first);
        }
        if (raw is Map<String, dynamic>) {
          return SorteioDetalhe.fromJson(raw);
        }
        return null;
      } else if (resp.statusCode == 204) {
        return null;
      }
      throw Exception('Erro ao carregar votação ativa: ${resp.body}');
    }

    /// Encerrar votação do dia (decide vencedor e descarta a outra)
    static Future<void> fecharVotacao(DateTime data) async {
      final uri = Uri.parse('${ApiConfig.baseUrl}/sorteios/fechar-votacao');
      final response = await http.post(
        uri,
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${await getToken()}',
        },
        body: jsonEncode({'data': _ymd(data)}),
      );
      if (response.statusCode != 200) {
        throw Exception('Erro ao fechar votação: ${response.body}');
      }
    }

    /// Votar em um dos sorteios (usa a rota /sorteios/{id}/votos)
    static Future<void> votarNoSorteio(int sorteioId) async {
      final uri = Uri.parse('${ApiConfig.baseUrl}/sorteios/$sorteioId/votos');
      final response = await http.post(
        uri,
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${await getToken()}',
        },
        body: jsonEncode({'sorteio_id': sorteioId}),
      );
      if (response.statusCode != 200 && response.statusCode != 201) {
        throw Exception('Erro ao votar: ${response.body}');
      }
    }

    // Recuperar o token JWT armazenado
    static Future<String> getToken() async {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString('jwt_token') ?? '';
    }

    static Future<Map<String, String>> _authHeaders() async => {
        'Accept': 'application/json',
        'Authorization': 'Bearer ${await getToken()}',
      };

  // Rascunhos do dia (lista)
  static Future<List<SorteioDetalhe>> getRascunhosDoDia() async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/sorteios/rascunhos-dia');
    final resp = await http.get(uri, headers: await _authHeaders());

    if (resp.statusCode == 200) {
      final raw = jsonDecode(resp.body);
      if (raw is List) {
        return raw
            .map<SorteioDetalhe>((e) => SorteioDetalhe.fromJson(e))
            .toList();
      }
      return const <SorteioDetalhe>[];
    } else if (resp.statusCode == 204) {
      return const <SorteioDetalhe>[];
    }
    throw Exception('Erro ao carregar rascunhos do dia: ${resp.body}');
  }

    static Future<void> criarDuploCompleto({
    required DateTime data,
    String? descricao,
    required int quantidadeTimes,
    required int quantidadeJogadoresTime,
    required List<int> jogadoresIds,
    String estrategia = 'balanceado',
  }) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/sorteios/duplo-completo');

    final body = {
      'data': DateFormat('yyyy-MM-dd').format(data),
      'descricao': descricao, // pode ser null
      'quantidade_times': quantidadeTimes,
      'quantidade_jogadores_time': quantidadeJogadoresTime,
      'jogadores_ids': jogadoresIds,
      'estrategia': estrategia,
    };

    final res = await http.post(
      uri,
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json', // <== IMPORTANTE
        'Authorization': 'Bearer ${await getToken()}',
      },
      body: jsonEncode(body), // <== IMPORTANTE
    );

    if (res.statusCode != 201) {
      throw Exception('Erro ao criar sorteios: ${res.statusCode} ${res.body}');
    }
  }

  static Future<void> publicarDuplaPorIds({
    required int sorteioId1,
    required int sorteioId2,
  }) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/sorteios/publicar');
    final resp = await http.post(
      uri,
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${await getToken()}',
      },
      body: jsonEncode({
        'sorteio_id_1': sorteioId1,
        'sorteio_id_2': sorteioId2,
      }),
    );

    if (resp.statusCode != 200) {
      throw Exception('Erro ao publicar: ${resp.body}');
    }
  }


}





