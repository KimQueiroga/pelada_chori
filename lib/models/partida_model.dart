import 'dart:convert';

class Partida {
  final int id;
  final int sorteioId;
  final int timeAId;
  final int timeBId;
  final String timeANome;
  final String timeBNome;
  final int placarA;
  final int placarB;
  final int tempoSegundos;          // tempo-alvo definido (ex.: 420 = 7min)
  final int? iniciadoEm;            // epoch seconds (opcional)
  final int? encerradoEm;           // epoch seconds (opcional)
  final String status;              // criado | em_andamento | encerrado

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
    this.iniciadoEm,
    this.encerradoEm,
    required this.status,
  });

  bool get emAndamento => status == 'em_andamento';
  bool get encerrada => status == 'encerrado';

  factory Partida.fromJson(Map<String, dynamic> j) => Partida(
        id: j['id'] as int,
        sorteioId: j['sorteio_id'] as int,
        timeAId: j['time_a_id'] as int,
        timeBId: j['time_b_id'] as int,
        timeANome: (j['time_a_nome'] ?? 'Time A') as String,
        timeBNome: (j['time_b_nome'] ?? 'Time B') as String,
        placarA: (j['placar_a'] ?? 0) as int,
        placarB: (j['placar_b'] ?? 0) as int,
        tempoSegundos: (j['tempo_segundos'] ?? 420) as int,
        iniciadoEm: j['iniciado_em'] as int?,
        encerradoEm: j['encerrado_em'] as int?,
        status: (j['status'] ?? 'criado') as String,
      );

  static List<Partida> listFromRaw(String raw) {
    final data = jsonDecode(raw) as List;
    return data.map((e) => Partida.fromJson((e as Map).cast<String, dynamic>())).toList();
  }
}
