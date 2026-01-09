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
    final data = await _dadosFuturos;
    if (!mounted) return;

    final jogador = Jogador.fromJson(data['jogador']);

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

    if (outcome == true) {
      final fresh = ApiService.getMeusDados();
      setState(() {
        _dadosFuturos = fresh;
      });

      ScaffoldMessenger.of(context)
        ..clearSnackBars()
        ..showSnackBar(
          const SnackBar(content: Text('Dados atualizados com sucesso!')),
        );
    }

    if (outcome is String && outcome.isNotEmpty) {
      ScaffoldMessenger.of(context)
        ..clearSnackBars()
        ..showSnackBar(SnackBar(content: Text(outcome)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Meus dados'),
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
      body: SafeArea(
        child: Container(
          width: double.infinity,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                cs.background,
                cs.surface.withOpacity(0.98),
                cs.background,
              ],
            ),
          ),
          child: FutureBuilder<Map<String, dynamic>>(
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

              return SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildPerfilCard(jogador),
                    const SizedBox(height: 12),
                    _buildResumoCard(media, soma, votos.length),
                    const SizedBox(height: 12),
                    _buildNotasCard(votos),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildPerfilCard(Jogador jogador) {
    final cs = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final displayNameRaw =
        (jogador.apelido.trim().isNotEmpty ? jogador.apelido : jogador.nome).trim();
    final displayName = displayNameRaw.isNotEmpty ? displayNameRaw : 'Jogador';
    final String? fotoUrl = jogador.foto.trim().isEmpty ? null : jogador.foto.trim();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: cs.primary.withOpacity(0.15)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: cs.primary.withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              jogador.numeroCamisa.isNotEmpty ? jogador.numeroCamisa : '-',
              style: textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
                color: cs.primary,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  jogador.nome.isNotEmpty ? jogador.nome : displayName,
                  style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 2),
                Text(
                  displayName,
                  style: textTheme.bodyMedium?.copyWith(
                    color: cs.onSurface.withOpacity(0.7),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: cs.secondaryContainer.withOpacity(0.7),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: cs.primary.withOpacity(0.12)),
                  ),
                  child: Text(
                    jogador.posicao.isNotEmpty ? jogador.posicao : 'Sem posição',
                    style: textTheme.labelMedium?.copyWith(
                      color: cs.onSurface.withOpacity(0.75),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          AvatarInicial(
            displayName: displayName,
            photoUrl: fotoUrl,
            radius: 26,
          ),
        ],
      ),
    );
  }

  Widget _buildResumoCard(double media, double soma, int qtdNotas) {
    final cs = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: cs.primary.withOpacity(0.15)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Média geral',
                  style: textTheme.bodyMedium?.copyWith(
                    color: cs.onSurface.withOpacity(0.7),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  media.toStringAsFixed(2),
                  style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
                ),
              ],
            ),
          ),
          Container(
            width: 1,
            height: 48,
            color: cs.onSurface.withOpacity(0.08),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Soma das médias',
                  style: textTheme.bodyMedium?.copyWith(
                    color: cs.onSurface.withOpacity(0.7),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  soma.toStringAsFixed(2),
                  style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 2),
                Text(
                  '$qtdNotas avaliações',
                  style: textTheme.labelMedium?.copyWith(
                    color: cs.onSurface.withOpacity(0.6),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotasCard(List<VotoAggregado> votos) {
    final cs = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: cs.primary.withOpacity(0.15)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Notas por fundamento',
            style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 10),
          if (votos.isEmpty)
            Text(
              'Sem avaliações registradas.',
              style: textTheme.bodyMedium?.copyWith(
                color: cs.onSurface.withOpacity(0.6),
              ),
            )
          else
            ListView.separated(
              itemCount: votos.length,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              separatorBuilder: (_, __) => Divider(color: cs.onSurface.withOpacity(0.08)),
              itemBuilder: (context, index) {
                final item = votos[index];
                return Row(
                  children: [
                    Expanded(
                      child: Text(
                        item.nome,
                        style: textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: cs.primary.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        item.media.toStringAsFixed(2),
                        style: textTheme.labelLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: cs.primary,
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
        ],
      ),
    );
  }
}
