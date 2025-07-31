class JogadorModel {
  final int id;
  final String nome;
  final String apelido;
  final String numeroCamisa;
  final String? foto;
  final String? posicao;

  JogadorModel({
    required this.id,
    required this.nome,
    required this.apelido,
    required this.numeroCamisa,
    this.foto,
    this.posicao,
  });

  factory JogadorModel.fromJson(Map<String, dynamic> json) {
    return JogadorModel(
      id: json['id'],
      nome: json['nome'],
      apelido: json['apelido'],
      numeroCamisa: json['numero_camisa'],
      foto: json['foto'],
      posicao: json['posicao'],
    );
  }
}
