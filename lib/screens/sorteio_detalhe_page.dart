import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../services/api_service.dart';
import '../models/jogador_sorteio_model.dart';
import '../models/sorteio_detalhe_model.dart';
import '../models/sorteio_time_model.dart';

class SorteioDetalhePage extends StatefulWidget {
  final SorteioDetalhe sorteio;

  const SorteioDetalhePage({super.key, required this.sorteio});

  @override
  State<SorteioDetalhePage> createState() => _SorteioDetalhePageState();
}

class _SorteioDetalhePageState extends State<SorteioDetalhePage> {
  int? _meuJogadorId;
  bool _loadingUser = true;
  bool _enviandoVoto = false;
  bool _jaVotei = false;

  @override
  void initState() {
    super.initState();
    _carregarMeuJogador();
  }

  Future<void> _carregarMeuJogador() async {
    try {
      final me = await ApiService.getMeusDados();
      if (!mounted) return;
      setState(() {
        _meuJogadorId = me['jogador']?['id'] as int?;
        _loadingUser = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loadingUser = false);
    }
  }

  bool get _souParticipante {
    final id = _meuJogadorId;
    if (id == null) return false;
    for (final time in widget.sorteio.times) {
      for (final j in time.jogadores) {
        if (j.id == id) return true;
      }
    }
    return false;
  }

  Future<void> _votar() async {
    if (_meuJogadorId == null) return;

    setState(() => _enviandoVoto = true);
    try {
      await ApiService.votarNoSorteio(
        sorteioId: widget.sorteio.id,
        jogadorId: _meuJogadorId!,
      );

      if (!mounted) return;
      setState(() => _jaVotei = true);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Voto computado com sucesso!')),
      );

      await Future.delayed(const Duration(milliseconds: 900));
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;

      final msg = e.toString().toLowerCase();
      if (msg.contains('já votou') || msg.contains('ja votou')) {
        setState(() => _jaVotei = true);
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao votar: $e')),
      );
    } finally {
      if (mounted) setState(() => _enviandoVoto = false);
    }
  }

  IconData _iconForPosition(String? posicao) {
    switch (posicao?.toLowerCase()) {
      case 'ataque':
        return Icons.sports_soccer;
      case 'meio':
        return Icons.sports;
      case 'defesa':
        return Icons.shield;
      default:
        return Icons.help_outline;
    }
  }

  Color _colorForPosition(String? posicao) {
    switch (posicao?.toLowerCase()) {
      case 'ataque':
        return Colors.red;
      case 'meio':
        return Colors.orange;
      case 'defesa':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  String _labelForPosition(String? posicao) {
    final raw = (posicao ?? '').trim();
    if (raw.isEmpty) return 'Sem posição';
    final lower = raw.toLowerCase();
    return '${lower[0].toUpperCase()}${lower.substring(1)}';
  }

  Widget _infoChip({required IconData icon, required String label}) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: cs.primary.withOpacity(0.08),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: cs.primary.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: cs.primary),
          const SizedBox(width: 6),
          Text(
            label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: cs.primary,
                  fontWeight: FontWeight.w700,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(SorteioDetalhe sorteio) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final data = DateTime.tryParse(sorteio.data);
    final dataLabel = data == null ? sorteio.data : DateFormat('dd/MM/yyyy').format(data);
    final descricao = sorteio.descricao.trim();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: cs.primary.withOpacity(0.15)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 14,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: cs.primary.withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.emoji_events, color: cs.primary, size: 26),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Detalhes do sorteio',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Data: $dataLabel',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: cs.onSurface.withOpacity(0.65),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _infoChip(icon: Icons.groups, label: '${sorteio.quantidadeTimes} times'),
              _infoChip(
                icon: Icons.person_outline,
                label: '${sorteio.quantidadeJogadoresTime} por time',
              ),
              if (sorteio.tentativa != null)
                _infoChip(icon: Icons.refresh, label: 'Tentativa ${sorteio.tentativa}'),
            ],
          ),
          if (descricao.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              descricao,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: cs.onSurface.withOpacity(0.7),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPlayerRow(JogadorSorteio jogador) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final foto = jogador.foto?.trim();
    final hasFoto = foto != null && foto.isNotEmpty;
    final nome = (jogador.apelido?.trim().isNotEmpty == true)
        ? jogador.apelido!.trim()
        : (jogador.nome?.trim().isNotEmpty == true)
            ? jogador.nome!.trim()
            : 'Jogador';
    final numero = (jogador.numeroCamisa?.trim().isNotEmpty == true)
        ? jogador.numeroCamisa!.trim()
        : '--';
    final posColor = _colorForPosition(jogador.posicao);
    final posLabel = _labelForPosition(jogador.posicao);

    return Row(
      children: [
        CircleAvatar(
          radius: 18,
          backgroundImage: hasFoto ? NetworkImage(foto!) : null,
          backgroundColor: cs.surfaceContainerHighest,
          child: hasFoto ? null : Icon(Icons.person, color: cs.onSurfaceVariant),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$numero - $nome',
                style: theme.textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: posColor.withOpacity(0.12),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: posColor.withOpacity(0.3)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(_iconForPosition(jogador.posicao), size: 14, color: posColor),
              const SizedBox(width: 4),
              Text(
                posLabel,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: posColor,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTeamCard(SorteioTime time, int index) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final nome = (time.nome?.trim().isNotEmpty == true)
        ? time.nome!.trim()
        : 'Time ${index + 1}';
    final mediaText = time.mediaCalculada?.toStringAsFixed(2) ?? '-';

    final jogadores = time.jogadores;
    final List<Widget> rows = [];

    if (jogadores.isEmpty) {
      rows.add(
        Text(
          'Nenhum jogador informado',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: cs.onSurface.withOpacity(0.6),
          ),
        ),
      );
    } else {
      for (var i = 0; i < jogadores.length; i++) {
        rows.add(_buildPlayerRow(jogadores[i]));
        if (i != jogadores.length - 1) {
          rows.add(
            Divider(
              height: 18,
              color: cs.outlineVariant.withOpacity(0.35),
            ),
          );
        }
      }
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(20),
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
          Row(
            children: [
              Expanded(
                child: Text(
                  nome,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: cs.secondaryContainer.withOpacity(0.7),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.star, size: 14, color: Colors.amber.shade700),
                    const SizedBox(width: 4),
                    Text(
                      'Média $mediaText',
                      style: theme.textTheme.labelMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...rows,
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final sorteio = widget.sorteio;

    final String botaoTexto = _loadingUser
        ? 'Carregando...'
        : (!_souParticipante)
            ? 'Somente participantes podem votar'
            : (_jaVotei ? 'Voto registrado' : 'Votar neste sorteio');

    final bool botaoHabilitado =
        !_loadingUser && _souParticipante && !_jaVotei && !_enviandoVoto;

    return Scaffold(
      appBar: AppBar(
        title: Text('Sorteio nº ${sorteio.numero}'),
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
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            children: [
              _buildHeader(sorteio),
              const SizedBox(height: 16),
              if (sorteio.times.isEmpty)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: cs.surface,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: cs.primary.withOpacity(0.15)),
                  ),
                  child: Text(
                    'Nenhum time gerado para este sorteio.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: cs.onSurface.withOpacity(0.6),
                    ),
                  ),
                )
              else
                ...sorteio.times
                    .asMap()
                    .entries
                    .map(
                      (entry) => Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: _buildTeamCard(entry.value, entry.key),
                      ),
                    )
                    .toList(),
            ],
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: FilledButton.icon(
            icon: _enviandoVoto
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Icon(_jaVotei ? Icons.verified : Icons.how_to_vote),
            label: Text(botaoTexto),
            onPressed: botaoHabilitado ? _votar : null,
          ),
        ),
      ),
    );
  }
}
