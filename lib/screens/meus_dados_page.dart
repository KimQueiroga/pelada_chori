import 'package:flutter/material.dart';
import '../theme/colors.dart';
import '../models/jogador.dart';
import '../models/voto_aggregado.dart';
import '../services/api_service.dart';
import 'package:pelada_chori/shared/widgets/avatar_inicial.dart';

class MeusDadosPage extends StatefulWidget {
  const MeusDadosPage({super.key});

  @override
  State<MeusDadosPage> createState() => _MeusDadosPageState();
}

class _MeusDadosPageState extends State<MeusDadosPage> {
  late Future<Map<String, dynamic>> _dadosFuturos;

  @override
  void initState() {
    super.initState();
    _dadosFuturos = ApiService.getMeusDados();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Meus Dados'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _dadosFuturos,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Erro: ${snapshot.error}'));
          }

          final data = snapshot.data!;
          final jogador = Jogador.fromJson(data['jogador']);
          final votos = (data['notas'] as List)
              .map((e) => VotoAggregado.fromJson(e))
              .toList();
          final media = (data['media'] as num).toDouble();
          final soma = (data['soma'] as num).toDouble();

          return Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _buildJogadorCard(jogador),
                const SizedBox(height: 16),
                Expanded(
                  child: ListView.separated(
                    itemCount: votos.length,
                    separatorBuilder: (_, index) =>
                        index < votos.length - 1 ? const Divider() : const SizedBox.shrink(),
                    itemBuilder: (context, index) {
                      final item = votos[index];
                      return ListTile(
                        title: Text(item.nome),
                        trailing: Text(item.media.toStringAsFixed(2)),
                      );
                    },
                  ),
                ),
                const Divider(thickness: 2),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Column(
                    children: [
                      Text(
                        'Média Geral: ${media.toStringAsFixed(2)}',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Soma das Médias: ${soma.toStringAsFixed(2)}',
                        style: const TextStyle(fontSize: 14),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildJogadorCard(Jogador jogador) {
    final displayName = (jogador.apelido.isNotEmpty ? jogador.apelido : jogador.nome).trim();
    final fotoUrl = jogador.foto; // pode ser vazio

    return Card(
      child: ListTile(
        leading: Text(
          jogador.numeroCamisa,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        title: Text(jogador.nome),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              jogador.apelido,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            Text(
              jogador.posicao,
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        // >>> aqui substituímos o CircleAvatar + NetworkImage
        trailing: AvatarInicial(
          displayName: displayName.isNotEmpty ? displayName : 'Jogador',
          photoUrl: fotoUrl, // se vazio/null → mostra inicial
          radius: 24,
        ),
      ),
    );
  }
}
