class VotoAggregado {
  final String nome;
  final double media;

  VotoAggregado({
    required this.nome,
    required this.media,
  });

  factory VotoAggregado.fromJson(Map<String, dynamic> json) {
    return VotoAggregado(
      nome: json['nome'] ?? 'Sem nome',
      media: (json['nota'] as num?)?.toDouble() ?? 0.0, // <- aqui estava 'media'
    );
  }
}
