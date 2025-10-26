import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../services/api_service.dart';
import '../models/sorteio_detalhe_model.dart';

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

  // estado “já votei”
  bool _jaVotei = false;

  @override
  void initState() {
    super.initState();
    _carregarMeuJogador();
  }

  Future<void> _carregarMeuJogador() async {
    try {
      final me = await ApiService.getMeusDados();
      setState(() {
        _meuJogadorId = me['jogador']?['id'] as int?;
        _loadingUser = false;
      });
    } catch (_) {
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

      final msg = e.toString();
      if (msg.toLowerCase().contains('já votou')) {
        setState(() => _jaVotei = true);
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao votar: $e')),
      );
    } finally {
      if (mounted) setState(() => _enviandoVoto = false);
    }
  }

  Icon _iconForPosition(String? posicao) {
    switch (posicao?.toLowerCase()) {
      case 'ataque':
        return const Icon(Icons.sports_soccer, color: Colors.red);
      case 'meio':
        return const Icon(Icons.sports, color: Colors.orange);
      case 'defesa':
        return const Icon(Icons.shield, color: Colors.blue);
      default:
        return const Icon(Icons.help_outline, color: Colors.grey);
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final sorteio = widget.sorteio;

    // rótulo/estado do botão
    final String botaoTexto = _loadingUser
        ? 'Carregando...'
        : (!_souParticipante)
            ? 'Somente participantes podem votar'
            : (_jaVotei ? 'Voto registrado' : 'Votar neste sorteio');

    final bool botaoHabilitado =
        !_loadingUser && _souParticipante && !_jaVotei && !_enviandoVoto;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Sorteio nº ${sorteio.numero}'),
            Text(
              'Data: ${DateFormat('dd/MM/yyyy').format(DateTime.parse(sorteio.data))}',
              // usa a cor “onPrimary” do appbar atual (fica ok no light/dark)
              style: theme.textTheme.bodySmall?.copyWith(
                color: cs.onPrimary.withOpacity(0.72),
              ),
            ),
          ],
        ),
      ),

      // LISTA DE TIMES
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: sorteio.times.length,
        separatorBuilder: (_, __) => const SizedBox(height: 16),
        itemBuilder: (context, index) {
          final time = sorteio.times[index];

          // Card respeita o tema automaticamente (cores, elevation, etc.)
          return Card(
            color: cs.surface, // superfície temática (funciona no dark)
            elevation: 2,
            shadowColor: theme.shadowColor,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    time.nome ?? 'Time',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ...time.jogadores.map((jogador) {
                    final hasFoto = (jogador.foto != null && jogador.foto!.isNotEmpty);
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 20,
                            backgroundImage: hasFoto ? NetworkImage(jogador.foto!) : null,
                            backgroundColor: cs.surfaceContainerHighest, // tema
                            child: hasFoto
                                ? null
                                : Icon(Icons.person, color: cs.onSurfaceVariant),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${jogador.numeroCamisa} - ${jogador.apelido}',
                                  style: theme.textTheme.bodyLarge,
                                ),
                                Row(
                                  children: [
                                    _iconForPosition(jogador.posicao),
                                    const SizedBox(width: 4),
                                    Text(
                                      jogador.posicao ?? 'Sem posição',
                                      style: theme.textTheme.bodyMedium?.copyWith(
                                        color: _colorForPosition(jogador.posicao),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      const Icon(Icons.star, size: 18, color: Colors.amber),
                      const SizedBox(width: 4),
                      Text(
                        'Média: ${time.mediaCalculada?.toStringAsFixed(2) ?? '-'}',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),

      // BOTÃO FIXO
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
