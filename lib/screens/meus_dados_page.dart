import 'package:flutter/material.dart';
import '../models/jogador.dart';
import '../models/voto_aggregado.dart';
import '../services/api_service.dart';
import 'package:pelada_chori/shared/widgets/avatar_inicial.dart';
import 'package:pelada_chori/screens/editar_meus_dados_sheet.dart';

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

  Future<void> _abrirEdicao() async {
    // 1) pega os dados atuais para popular o form
    final data = await _dadosFuturos;
    if (!mounted) return;

    final jogador = Jogador.fromJson(data['jogador']);

    // 2) abre o bottom sheet
    final outcome = await showModalBottomSheet<Object?>(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => EditarMeusDadosSheet(jogador: jogador),
    );

    if (!mounted || outcome == null) return;

    // 3) sucesso → recarrega Future de forma SÍNCRONA dentro do setState
    if (outcome == true) {
      final fresh = ApiService.getMeusDados();
      setState(() {
        _dadosFuturos = fresh; // <- síncrono, sem 'await' e sem 'async'
      });

      ScaffoldMessenger.of(context)
        ..clearSnackBars()
        ..showSnackBar(
          const SnackBar(content: Text('Dados atualizados com sucesso!')),
        );
    }

    // 4) erro vindo do sheet
    if (outcome is String && outcome.isNotEmpty) {
      ScaffoldMessenger.of(context)
        ..clearSnackBars()
        ..showSnackBar(SnackBar(content: Text(outcome)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Meus Dados'),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'editar') _abrirEdicao();
            },
            itemBuilder: (_) => const [
              PopupMenuItem(
                value: 'editar',
                child: Row(
                  children: [Icon(Icons.edit), SizedBox(width: 8), Text('Editar meus dados')],
                ),
              ),
            ],
          ),
        ],
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

          if (!snapshot.hasData) {
            return const Center(child: Text('Sem dados.'));
          }

          final data = snapshot.data!;
          final jogador = Jogador.fromJson(data['jogador'] as Map<String, dynamic>);
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
                        title: Text(item.nome, style: textTheme.bodyMedium),
                        trailing: Text(item.media.toStringAsFixed(2), style: textTheme.bodyMedium),
                      );
                    },
                  ),
                ),
                const Divider(),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Column(
                    children: [
                      Text(
                        'Média Geral: ${media.toStringAsFixed(2)}',
                        style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Soma das Médias: ${soma.toStringAsFixed(2)}',
                        style: textTheme.bodyMedium,
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
    final textTheme = Theme.of(context).textTheme;
    final displayNameRaw =
        (jogador.apelido.trim().isNotEmpty ? jogador.apelido : jogador.nome).trim();
    final displayName = displayNameRaw.isNotEmpty ? displayNameRaw : 'Jogador';

    final String? fotoUrl = jogador.foto.trim().isEmpty ? null : jogador.foto.trim();

    return Card(
      child: ListTile(
        leading: Text(
          jogador.numeroCamisa.isNotEmpty ? jogador.numeroCamisa : '-',
          style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        title: Text(
          jogador.nome.isNotEmpty ? jogador.nome : displayName,
          style: textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              jogador.apelido.isNotEmpty ? jogador.apelido : displayName,
              style: textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            Text(
              jogador.posicao.isNotEmpty ? jogador.posicao : '—',
              style: textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
          ],
        ),
        trailing: AvatarInicial(
          displayName: displayName,
          photoUrl: fotoUrl,
          radius: 24,
        ),
      ),
    );
  }
}
