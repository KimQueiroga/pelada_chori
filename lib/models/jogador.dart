class Jogador {
  final String id;
  final String nome;
  final String apelido;
  final String posicao;
  final String numeroCamisa;
  /// String vazia quando não há foto (API pode retornar null)
  final String foto;

  Jogador({
    required this.id,
    required this.nome,
    required this.apelido,
    required this.posicao,
    required this.numeroCamisa,
    required this.foto,
  });

  factory Jogador.fromJson(Map<String, dynamic> json) {
    // helpers para evitar null
    String _s(dynamic v) => (v is String) ? v : (v == null ? '' : v.toString());

    return Jogador(
      id: _s(json['id']),
      nome: _s(json['nome']),
      apelido: _s(json['apelido']),
      posicao: _s(json['posicao']),
      numeroCamisa: _s(json['numero_camisa'] ?? json['camisa'] ?? json['numero']),
      foto: (json['foto'] is String) ? (json['foto'] as String) : '',
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'nome': nome,
    'apelido': apelido,
    'posicao': posicao,
    'numero_camisa': numeroCamisa,
    'foto': foto.isEmpty ? null : foto,
  };
}
