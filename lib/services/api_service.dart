import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import 'auth_service.dart';
import '../models/sorteio_simplificado_model.dart';
import '../models/sorteio_detalhe_model.dart';
import '../models/partida_model.dart';
import 'package:intl/intl.dart';

/// Exceção específica quando o backend exige médias manuais.
class NeedMediaException implements Exception {
  final List<int> ids;
  final String? message;
  NeedMediaException(this.ids, {this.message});
  @override
  String toString() => message ?? 'Jogadores sem média: $ids';
}

/// Exceção específica para empate ao encerrar votação.
class EmpateVotacaoException implements Exception {
  final List<Map<String, dynamic>> empate; // [{id, votos}, {id, votos}]
  final String message;
  EmpateVotacaoException(this.empate, {this.message = 'Empate detectado.'});
  @override
  String toString() => message;
}

class ApiService {
  static Map<String, String> _mergeHeaders(
    Map<String, String>? headers,
    String token,
  ) {
    final merged = <String, String>{};
    if (headers != null) merged.addAll(headers);
    merged.putIfAbsent('Accept', () => 'application/json');
    if (token.isNotEmpty) {
      merged['Authorization'] = 'Bearer $token';
    } else {
      merged.remove('Authorization');
    }
    return merged;
  }

  static Future<http.Response> _getWithAuth(
    Uri uri, {
    Map<String, String>? headers,
  }) {
    return AuthService.sendWithRefresh(
      (token) => http.get(uri, headers: _mergeHeaders(headers, token)),
    );
  }

  static Future<http.Response> _postWithAuth(
    Uri uri, {
    Map<String, String>? headers,
    Object? body,
  }) {
    return AuthService.sendWithRefresh(
      (token) => http.post(uri, headers: _mergeHeaders(headers, token), body: body),
    );
  }

  static Future<http.Response> _putWithAuth(
    Uri uri, {
    Map<String, String>? headers,
    Object? body,
  }) {
    return AuthService.sendWithRefresh(
      (token) => http.put(uri, headers: _mergeHeaders(headers, token), body: body),
    );
  }

  // Buscar os dados do jogador autenticado
  static Future<Map<String, dynamic>> getMeusDados() async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/meus-dados');
    final response = await _getWithAuth(uri);
    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Erro ao buscar dados do jogador: ${response.body}');
    }
  }

  // Buscar todos os jogadores cadastrados (sem filtro de votação)
  static Future<List<Map<String, dynamic>>> getJogadoresTodos() async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/jogadores/todos');
    final response = await _getWithAuth(uri);
    if (response.statusCode == 200) {
      final List dados = json.decode(response.body);
      return dados.cast<Map<String, dynamic>>();
    } else {
      throw Exception('Erro ao buscar jogadores: ${response.body}');
    }
  }

  // --- ANTIGOS (ainda usados em alguns fluxos) ---
  static Future<List<SorteioSimplificadoModel>> getSorteiosAtivos() async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/sorteios/ativos');
    final response = await _getWithAuth(uri);

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => SorteioSimplificadoModel.fromJson(json)).toList();
    } else {
      throw Exception('Erro ao carregar sorteios ativos: ${response.body}');
    }
  }

  static Future<SorteioDetalhe> getSorteioDetalhe(int id) async {
    final response = await _getWithAuth(
      Uri.parse('${ApiConfig.baseUrl}/sorteios/$id'),
    );

    if (response.statusCode == 200) {
      return SorteioDetalhe.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Erro ao buscar detalhes do sorteio');
    }
  }

  static String _ymd(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  /// NOVO: endpoint "inteligente" — votacao → retorna votando; senão → confirmados
  /// Resposta:
  /// { modo: "votacao"|"confirmado"|"vazio", sorteios: [...], data: "YYYY-MM-DD" }
  /// Cada item tem "votos_count" e estrutura de SorteioDetalhe (com times/jogadores).
  static Future<({
    String modo,
    List<SorteioDetalhe> sorteios,
    Map<int, int> votosPorId,
  })> getExibirDoDia({DateTime? data}) async {
    final d = data ?? DateTime.now();
    final uri = Uri.parse(
        '${ApiConfig.baseUrl}/sorteios/exibir-do-dia?data=${_ymd(d)}');
    final resp = await _getWithAuth(uri);

    if (resp.statusCode != 200) {
      throw Exception('Erro ao buscar sorteios do dia: ${resp.body}');
    }

    final body = jsonDecode(resp.body) as Map<String, dynamic>;
    final modo = (body['modo'] as String?) ?? 'vazio';
    final list = (body['sorteios'] as List? ?? const [])
        .map((e) => e as Map<String, dynamic>)
        .toList();

    final sorteios = <SorteioDetalhe>[];
    final votos = <int, int>{};

    for (final m in list) {
      final s = SorteioDetalhe.fromJson(m);
      sorteios.add(s);
      final vc = (m['votos_count'] is num) ? (m['votos_count'] as num).toInt() : 0;
      votos[s.id] = vc;
    }

    return (modo: modo, sorteios: sorteios, votosPorId: votos);
  }

  static Future<({
    String mesReferencia,
    List<Map<String, dynamic>> vitorias,
    List<Map<String, dynamic>> gols,
    List<Map<String, dynamic>> assistencias,
  })> getDestaquesDoMes({DateTime? data, int limite = 5}) async {
    var safeLimite = limite;
    if (safeLimite < 1) safeLimite = 1;
    if (safeLimite > 20) safeLimite = 20;
    final params = <String, String>{
      'limite': safeLimite.toString(),
    };
    if (data != null) {
      params['data'] = _ymd(data);
    }

    final uri = Uri.parse('${ApiConfig.baseUrl}/destaques/mes')
        .replace(queryParameters: params);
    final resp = await _getWithAuth(uri);

    if (resp.statusCode != 200) {
      throw Exception('Erro ao carregar destaques: ${resp.body}');
    }

    final body = jsonDecode(resp.body) as Map<String, dynamic>;
    final top5 = (body['top5'] as Map?)?.cast<String, dynamic>() ?? const {};

    List<Map<String, dynamic>> listFrom(String key) {
      final raw = (top5[key] as List?) ?? const [];
      return raw
          .map<Map<String, dynamic>>((e) => (e as Map).cast<String, dynamic>())
          .toList();
    }

    return (
      mesReferencia: (body['mes_referencia'] ?? '').toString(),
      vitorias: listFrom('vitorias'),
      gols: listFrom('gols'),
      assistencias: listFrom('assistencias'),
    );
  }

  /// Publica a dupla mais recente do dia para votação
  static Future<void> publicarDupla(DateTime data) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/sorteios/publicar');
    final response = await _postWithAuth(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'data': _ymd(data)}),
    );
    if (response.statusCode != 200) {
      throw Exception('Erro ao publicar: ${response.body}');
    }
  }

  /// Retorna a dupla atualmente em votação (com votos_count)
  static Future<SorteioDetalhe?> getVotacaoAtiva() async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/votacao-ativa');
    final resp = await _getWithAuth(uri);

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

  /// Encerrar votação do dia (com suporte a empate via vencedorId)
  static Future<Map<String, dynamic>> fecharVotacaoDoDia({
    required DateTime data,
    int? vencedorId,
  }) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/sorteios/fechar-votacao');

    final body = <String, dynamic>{'data': _ymd(data)};
    if (vencedorId != null) body['vencedor_id'] = vencedorId;

    final response = await _postWithAuth(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(body),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }

    if (response.statusCode == 409) {
      final j = jsonDecode(response.body);
      final lista = (j['empate'] as List?)
              ?.map<Map<String, dynamic>>((e) => (e as Map).cast<String, dynamic>())
              .toList() ??
          const [];
      throw EmpateVotacaoException(lista, message: (j['message'] ?? 'Empate') as String);
    }

    throw Exception('Erro ao fechar votação: ${response.statusCode} ${response.body}');
  }

  /// Votar em um sorteio publicado (envia jogador_id como o backend exige).
  static Future<void> votarNoSorteio({
    required int sorteioId,
    required int jogadorId,
  }) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/sorteios/$sorteioId/votos');
    final response = await _postWithAuth(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'jogador_id': jogadorId}),
    );

    if (response.statusCode == 201 || response.statusCode == 200) {
      return;
    }

    try {
      final j = jsonDecode(response.body);
      if (j is Map && j['message'] is String) {
        throw Exception(j['message']);
      }
    } catch (_) {}

    throw Exception('Erro ao votar: ${response.statusCode} ${response.body}');
  }

  /// Resumo de votos dos sorteios em votação hoje. Retorna {sorteio_id: total_votos}.
  static Future<Map<int, int>> getResumoVotosHoje() async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/sorteios/votacao-ativa/resumo');
    final resp = await _getWithAuth(uri);

    if (resp.statusCode == 200) {
      final List list = jsonDecode(resp.body) as List;
      final map = <int, int>{};
      for (final e in list) {
        final id = (e['sorteio_id'] ?? e['id']) as int;
        final total = (e['total_votos'] ?? e['total'] ?? 0) as int;
        map[id] = total;
      }
      return map;
    }
    throw Exception('Erro ao carregar resumo de votos: ${resp.body}');
  }

  /// Detalhes de votos de um sorteio (usa ?detalhe=1).
  /// Retorna { total: int, votos: [ {jogador_nome, jogador_foto, user_name, created_at}, ... ] }
  static Future<Map<String, dynamic>> getVotosDetalheSorteio(int sorteioId) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/sorteios/$sorteioId/votos?detalhe=1');
    final resp = await _getWithAuth(uri);

    if (resp.statusCode == 200) {
      final body = jsonDecode(resp.body) as Map<String, dynamic>;
      final total = (body['total_votos'] is num) ? (body['total_votos'] as num).toInt() : 0;
      final List votosRaw = (body['detalhes']?['votos'] as List?) ?? const [];
      final votos = votosRaw
          .map<Map<String, dynamic>>((e) => (e as Map).cast<String, dynamic>())
          .toList();
      return {'total': total, 'votos': votos};
    }
    throw Exception('Erro ao carregar votos do sorteio: ${resp.body}');
  }

  // Recuperar o token JWT armazenado
  static Future<String> getToken() async {
    return (await AuthService.getToken()) ?? '';
  }

  // Rascunhos do dia (lista)
  static Future<List<SorteioDetalhe>> getRascunhosDoDia() async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/sorteios/rascunhos-dia');
    final resp = await _getWithAuth(uri);

    if (resp.statusCode == 200 || resp.statusCode == 200) { // proteção
      final raw = jsonDecode(resp.body);
      if (raw is List) {
        return raw.map<SorteioDetalhe>((e) => SorteioDetalhe.fromJson(e)).toList();
      }
      return const <SorteioDetalhe>[];
    } else if (resp.statusCode == 204) {
      return const <SorteioDetalhe>[];
    }
    throw Exception('Erro ao carregar rascunhos do dia: ${resp.body}');
  }

  /// (LEGADO) Mantido se alguma tela ainda usar.
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
      'descricao': descricao,
      'quantidade_times': quantidadeTimes,
      'quantidade_jogadores_time': quantidadeJogadoresTime,
      'jogadores_ids': jogadoresIds,
      'estrategia': estrategia,
    };

    final res = await _postWithAuth(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(body),
    );

    if (res.statusCode != 201) {
      throw Exception('Erro ao criar sorteios: ${res.statusCode} ${res.body}');
    }
  }

  /// Novo fluxo do sorteio em 2 passos (mantido do seu código)
  static Future<Map<String, dynamic>> criarSorteioDuploCompleto({
    required DateTime data,
    String? descricao,
    required int quantidadeTimes,
    required int quantidadeJogadoresTime,
    required List<int> jogadoresIds,
    Map<int, double>? mediasOverride,
    bool requireMediaForUnrated = true,
    double? limite,
  }) async {
    final url = Uri.parse('${ApiConfig.baseUrl}/sorteios/duplo-completo');

    List<Map<String, dynamic>>? jogadoresArray;
    if (mediasOverride != null && mediasOverride.isNotEmpty) {
      jogadoresArray = jogadoresIds.map((id) {
        if (mediasOverride.containsKey(id)) {
          return {'id': id, 'media': mediasOverride[id]};
        }
        return {'id': id};
      }).toList();
    }

    final body = <String, dynamic>{
      'data': DateFormat('yyyy-MM-dd').format(data),
      'descricao': descricao,
      'quantidade_times': quantidadeTimes,
      'quantidade_jogadores_time': quantidadeJogadoresTime,
      'require_media_for_unrated': requireMediaForUnrated,
      if (limite != null) 'limite': limite,
      if (jogadoresArray != null)
        'jogadores': jogadoresArray
      else
        'jogadores_ids': jogadoresIds,
    };

    final resp = await _postWithAuth(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(body),
    );

    if (resp.statusCode == 201 || resp.statusCode == 200) {
      return jsonDecode(resp.body) as Map<String, dynamic>;
    }

    if (resp.statusCode == 422) {
      final json = jsonDecode(resp.body);
      if (json is Map && json['ids'] is List) {
        final ids = (json['ids'] as List)
            .map((e) => int.parse(e.toString()))
            .toList();
        throw NeedMediaException(ids, message: json['error']?.toString());
      }
      throw Exception(json['error'] ?? 'Erro de validação.');
    }

    throw Exception('Erro ${resp.statusCode}: ${resp.body}');
  }

  static Future<void> publicarDuplaPorIds({
    required int sorteioId1,
    required int sorteioId2,
  }) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/sorteios/publicar');
    final resp = await _postWithAuth(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'sorteio_id_1': sorteioId1,
        'sorteio_id_2': sorteioId2,
      }),
    );

    if (resp.statusCode != 200) {
      throw Exception('Erro ao publicar: ${resp.body}');
    }
  }

    // ===== PARTIDAS =====

  // Lista times de um sorteio (com jogadores) para montar confrontos
  static Future<List<Map<String, dynamic>>> getTimesDoSorteio(int sorteioId) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/sorteios/$sorteioId/times');
    final resp = await _getWithAuth(uri);
    if (resp.statusCode == 200) {
      final list = (jsonDecode(resp.body) as List).cast<Map<String, dynamic>>();
      return list;
    }
    throw Exception('Erro ao carregar times do sorteio: ${resp.body}');
  }

  // Lista partidas já criadas do sorteio (seu backend: GET /sorteios/{id}/partidas)
  static Future<List<Partida>> getPartidasDoSorteio(int sorteioId) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/sorteios/$sorteioId/partidas');
    final resp = await _getWithAuth(uri);
    if (resp.statusCode == 200) {
      return Partida.listFromRaw(resp.body);
    }
    throw Exception('Erro ao carregar partidas: ${resp.body}');
  }

  // Cria partida
  static Future<Partida> criarPartida({
    required int sorteioId,
    required int timeAId,
    required int timeBId,
    int tempoSegundos = 420, // 7 min
  }) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/sorteios/$sorteioId/partidas');
    final resp = await _postWithAuth(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'time_a_id': timeAId,
        'time_b_id': timeBId,
        'tempo_segundos': tempoSegundos,
      }),
    );
    if (resp.statusCode == 201 || resp.statusCode == 200) {
      return Partida.fromJson(jsonDecode(resp.body));
    }
    throw Exception('Erro ao criar partida: ${resp.statusCode} ${resp.body}');
  }

  // Iniciar partida (opcional se já iniciar no criar)
  static Future<Partida> iniciarPartida(int partidaId) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/partidas/$partidaId/iniciar');
    final resp = await _postWithAuth(uri);
    if (resp.statusCode == 200) {
      return Partida.fromJson(jsonDecode(resp.body));
    }
    throw Exception('Erro ao iniciar partida: ${resp.body}');
  }

    // Registrar gol
    static Future<Map<String, dynamic>> registrarGol({
    required int partidaId,
    required int timeId,
    required int jogadorId,
    int? assistJogadorId,
    int? segundoRelativo,
  }) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/partidas/$partidaId/gols');
    final body = <String, dynamic>{
      'time_id': timeId,
      'jogador_id': jogadorId,
      if (assistJogadorId != null) 'assist_jogador_id': assistJogadorId,
      if (segundoRelativo != null) 'segundo_relativo': segundoRelativo,
    };

    final resp = await _postWithAuth(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(body),
    );

    if (resp.statusCode == 200 || resp.statusCode == 201) {
      return jsonDecode(resp.body) as Map<String, dynamic>;
    }

    throw Exception('Erro ao registrar gol: ${resp.statusCode} ${resp.body}');
  }


  // Encerrar partida (registra vencedor/empate e vitórias individuais)
  static Future<Partida> encerrarPartida(int partidaId) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/partidas/$partidaId/encerrar');
    final resp = await _postWithAuth(uri);
    if (resp.statusCode == 200) {
      return Partida.fromJson(jsonDecode(resp.body));
    }
    throw Exception('Erro ao encerrar partida: ${resp.body}');
  }

  // Buscar uma partida específica (com placar e gols)
  static Future<Map<String, dynamic>> getPartidaDetalhe(int partidaId) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/partidas/$partidaId');
    final resp = await _getWithAuth(uri);
    if (resp.statusCode == 200) {
      return (jsonDecode(resp.body) as Map).cast<String, dynamic>();
    }
    throw Exception('Erro ao buscar partida: ${resp.body}');
  }


  static Future<bool> updateMeusDados(Map<String, dynamic> payload) async {
    try {
      final resp = await _putWithAuth(
        Uri.parse('${ApiConfig.baseUrl}/meus-dados'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(payload),
      );

      return resp.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  static Future<bool> requestPasswordReset(String email) async {
    try {
      final r = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/password/forgot'),
        headers: {'Content-Type': 'application/json', 'Accept': 'application/json'},
        body: jsonEncode({'email': email}),
      );
      return r.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  static Future<String?> verifyResetCode({
    required String email,
    required String code,
  }) async {
    try {
      final r = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/password/verify'),
        headers: {'Content-Type': 'application/json', 'Accept': 'application/json'},
        body: jsonEncode({'email': email, 'code': code}),
      );
      if (r.statusCode == 200) {
        final json = jsonDecode(r.body) as Map<String, dynamic>;
        return json['reset_token'] as String?;
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  static Future<bool> resetPassword({
    required String email,
    required String resetToken,
    required String newPassword,
  }) async {
    try {
      final r = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/password/reset'),
        headers: {'Content-Type': 'application/json', 'Accept': 'application/json'},
        body: jsonEncode({
          'email': email,
          'reset_token': resetToken,
          'password': newPassword,
          'password_confirmation': newPassword,
        }),
      );
      return r.statusCode == 200;
    } catch (_) {
      return false;
    }
  }
}
