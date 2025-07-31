import 'sorteio_time_model.dart';

class SorteioDetalhe {
  final int id;
  final String descricao;
  final int quantidadeTimes;
  final int quantidadeJogadoresTime;
  final String data;
  final int numero;
  final List<SorteioTime> times;

  // NOVO: quando vier da rota /votacao-ativa
  final int? votosCount;

  SorteioDetalhe({
    required this.id,
    required this.descricao,
    required this.quantidadeTimes,
    required this.quantidadeJogadoresTime,
    required this.data,
    required this.numero,
    required this.times,
    this.votosCount,
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
    );
  }
}
