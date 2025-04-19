class Jogador {
  final int id;
  final String nome;
  final String apelido;
  final String numeroCamisa;
  final String foto;
  final String posicao;

  Jogador({
    required this.id,
    required this.nome,
    required this.apelido,
    required this.numeroCamisa,
    required this.foto,
    required this.posicao,
  });

  factory Jogador.fromJson(Map<String, dynamic> json) {
    return Jogador(
      id: json['id'],
      nome: json['nome'],
      apelido: json['apelido'],
      numeroCamisa: json['numero_camisa'],
      foto: json['foto'],
      posicao: json['posicao'],
    );
  }
}
