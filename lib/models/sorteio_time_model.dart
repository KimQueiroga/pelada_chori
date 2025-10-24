import 'jogador_sorteio_model.dart';

class SorteioTime {
  final int id;
  final String? nome;
  final double? media;
  final List<JogadorSorteio> jogadores;

  SorteioTime({
    required this.id,
    this.nome,
    this.media,
    required this.jogadores,
  });

  /// 🔁 Compatibilidade: quem ainda usa `mediaCalculada` continua funcionando.
  double? get mediaCalculada => media;

  factory SorteioTime.fromJson(Map<String, dynamic> json) {
    double? _parseMedia(dynamic v) {
      if (v == null) return null;
      if (v is num) return v.toDouble();
      return double.tryParse(v.toString());
    }

    final m = _parseMedia(json['media']) ?? _parseMedia(json['media_calculada']);

    return SorteioTime(
      id: json['id'],
      nome: json['nome'],
      media: m,
      jogadores: (json['jogadores'] as List<dynamic>)
          .map((j) => JogadorSorteio.fromJson(j as Map<String, dynamic>))
          .toList(),
    );
  }
}
