import 'jogador_sorteio_model.dart';

class SorteioTime {
  final int id;
  final String? nome;
  final double? mediaCalculada;
  final List<JogadorSorteio> jogadores;

  SorteioTime({
    required this.id,
    this.nome,
    this.mediaCalculada,
    required this.jogadores,
  });

  factory SorteioTime.fromJson(Map<String, dynamic> json) {
    return SorteioTime(
      id: json['id'],
      nome: json['nome'],
      mediaCalculada: (json['media_calculada'] as num?)?.toDouble(),
      jogadores: (json['jogadores'] as List<dynamic>)
          .map((j) => JogadorSorteio.fromJson(j))
          .toList(),
    );
  }
} 
