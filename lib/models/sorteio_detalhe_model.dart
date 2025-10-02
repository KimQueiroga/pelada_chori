import 'sorteio_time_model.dart';

class SorteioDetalhe {
  final int id;
  final String descricao;
  final int quantidadeTimes;
  final int quantidadeJogadoresTime;
  final String data;
  final int numero;
  

  // NOVO: quando vier da rota /votacao-ativa
  final int? votosCount;
  final int? tentativa;// 1, 2, 3...
  final String? status; // 'rascunho', 'aberto', 'fechado'...
  final bool? emVotacao;        

  final List<SorteioTime> times;

  SorteioDetalhe({
    required this.id,
    required this.descricao,
    required this.quantidadeTimes,
    required this.quantidadeJogadoresTime,
    required this.data,
    required this.numero,
    required this.times,
    this.votosCount,
    this.tentativa,
    this.status,
    this.emVotacao,
  });

  factory SorteioDetalhe.fromJson(Map<String, dynamic> json) {
    return SorteioDetalhe(
      id: json['id'],
      descricao: json['descricao'] ?? '',
      quantidadeTimes: json['quantidade_times'],
      quantidadeJogadoresTime: json['quantidade_jogadores_time'],
      data: json['data'],
      numero: json['numero'],
      times: (json['times'] as List<dynamic>)
          .map((t) => SorteioTime.fromJson(t))
          .toList(),
      votosCount: json['votos_count'] as int?, // pode vir nulo
      tentativa: json['tentativa'],
      status: json['status'],
      emVotacao: json['em_votacao'] == true,

    );
  }
}
