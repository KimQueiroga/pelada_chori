class JogadorSorteio {
  final int id;
  final String? nome;
  final String? apelido;
  final String? numeroCamisa;
  final String? foto;
  final String? posicao;

  /// Média individual do jogador (opcional – se quiser exibir depois).
  final double? media;

  JogadorSorteio({
    required this.id,
    this.nome,
    this.apelido,
    this.numeroCamisa,
    this.foto,
    this.posicao,
    this.media,
  });

  factory JogadorSorteio.fromJson(Map<String, dynamic> json) {
    final jogador = json['jogador'] as Map<String, dynamic>?;

    double? _parseMedia(dynamic v) {
      if (v == null) return null;
      if (v is num) return v.toDouble();
      return double.tryParse(v.toString());
    }

    return JogadorSorteio(
      id: json['jogador_id'],
      nome: jogador?['nome'],
      apelido: jogador?['apelido'],
      numeroCamisa: jogador?['numero_camisa'],
      foto: jogador?['foto'],
      posicao: jogador?['posicao'],
      media: _parseMedia(json['media']),
    );
  }
}
