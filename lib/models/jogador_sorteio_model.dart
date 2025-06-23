class JogadorSorteio {
  final int id;
  final String? nome;
  final String? apelido;
  final String? numeroCamisa;
  final String? foto;
  final String? posicao;

  JogadorSorteio({
    required this.id,
    this.nome,
    this.apelido,
    this.numeroCamisa,
    this.foto,
    this.posicao,
  });

  factory JogadorSorteio.fromJson(Map<String, dynamic> json) {
    final jogador = json['jogador'];
    return JogadorSorteio(
      id: json['jogador_id'],
      nome: jogador?['nome'],
      apelido: jogador?['apelido'],
      numeroCamisa: jogador?['numero_camisa'],
      foto: jogador?['foto'],
      posicao: jogador?['posicao'],
    );
  }
}
