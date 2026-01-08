class PartidaGol {
  final int id;
  final int partidaId;
  final int timeId;
  final int autorId;
  final String autorNome;
  final int? assistenteId;
  final String? assistenteNome;
  final int minuto; // ou segundo no jogo, dependendo do backend
  final String createdAt;

  PartidaGol({
    required this.id,
    required this.partidaId,
    required this.timeId,
    required this.autorId,
    required this.autorNome,
    this.assistenteId,
    this.assistenteNome,
    required this.minuto,
    required this.createdAt,
  });

  factory PartidaGol.fromJson(Map<String, dynamic> j) => PartidaGol(
        id: j['id'] as int,
        partidaId: j['partida_id'] as int,
        timeId: j['time_id'] as int,
        autorId: j['autor_id'] as int,
        autorNome: (j['autor_nome'] ?? '') as String,
        assistenteId: j['assistente_id'] as int?,
        assistenteNome: j['assistente_nome'] as String?,
        minuto: (j['minuto'] ?? 0) as int,
        createdAt: (j['created_at'] ?? '') as String,
      );
}
