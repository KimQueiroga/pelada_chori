import 'dart:convert';

class Partida {
  final int id;
  final int sorteioId;
  final int timeAId;
  final int timeBId;

  /// Nome amigável dos times (preferimos "Time 2", "Time 3"...)
  final String timeANome;
  final String timeBNome;

  final int placarA;
  final int placarB;

  /// Tempo alvo configurado (segundos)
  final int tempoSegundos;

  /// Datas vindas do backend (ISO8601) mapeadas para DateTime?
  final DateTime? iniciadaEm;
  final DateTime? encerradaEm;
  final DateTime? createdAt;

  /// agendada | em_andamento | encerrada
  final String status;

  Partida({
    required this.id,
    required this.sorteioId,
    required this.timeAId,
    required this.timeBId,
    required this.timeANome,
    required this.timeBNome,
    required this.placarA,
    required this.placarB,
    required this.tempoSegundos,
    required this.status,
    this.iniciadaEm,
    this.encerradaEm,
    this.createdAt,
  });

  // ---- helpers de status ----
  bool get isLive => status == 'em_andamento';
  bool get isFT => status == 'encerrada';
  bool get isAgendada => status == 'agendada';

  // ---- helpers p/ nome com fallback ----
  String nomeA() => (timeANome.trim().isEmpty) ? 'Time A' : timeANome.trim();
  String nomeB() => (timeBNome.trim().isEmpty) ? 'Time B' : timeBNome.trim();

  static DateTime? _parseDt(dynamic v) {
    if (v == null) return null;
    if (v is DateTime) return v;
    if (v is String && v.trim().isNotEmpty) {
      final parsed = DateTime.tryParse(v);
      if (parsed == null) return null;
      return parsed.isUtc ? parsed.toLocal() : parsed;
    }
    return null;
  }

  factory Partida.fromJson(Map<String, dynamic> j) {
    // nomes dos times podem vir "achatados" (time_a_nome) ou dentro de objetos time_a/time_b
    final timeANome = (j['time_a_nome'] ??
            (j['time_a'] is Map ? (j['time_a']['nome'] ?? '') : '') ??
            '') as String;
    final timeBNome = (j['time_b_nome'] ??
            (j['time_b'] is Map ? (j['time_b']['nome'] ?? '') : '') ??
            '') as String;

    // tempo alvo
    final tempoSeg = (j['duracao_prevista_segundos'] ??
            j['tempo_segundos'] ??
            420) as int;

    // status normalizado
    final st = (j['status'] ?? 'agendada').toString();

    return Partida(
      id: j['id'] as int,
      sorteioId: j['sorteio_id'] as int,
      timeAId: j['time_a_id'] as int,
      timeBId: j['time_b_id'] as int,
      timeANome: timeANome.isEmpty ? 'Time A' : timeANome,
      timeBNome: timeBNome.isEmpty ? 'Time B' : timeBNome,
      placarA: (j['placar_a'] ?? 0) as int,
      placarB: (j['placar_b'] ?? 0) as int,
      tempoSegundos: tempoSeg,
      iniciadaEm: _parseDt(j['iniciada_em'] ?? j['iniciado_em']),
      encerradaEm: _parseDt(j['encerrada_em'] ?? j['encerrado_em']),
      createdAt: _parseDt(j['created_at']),
      status: st,
    );
  }

  static List<Partida> listFromRaw(String raw) {
    final data = jsonDecode(raw) as List;
    return data
        .map((e) => Partida.fromJson((e as Map).cast<String, dynamic>()))
        .toList();
  }
}
