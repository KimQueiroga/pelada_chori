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

  // NOVO: controle do estado “já votei”
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
      // OBS: se seu ApiService espera o jogadorId, use esta chamada:
      await ApiService.votarNoSorteio(
        sorteioId: widget.sorteio.id,
        jogadorId: _meuJogadorId!,
      );

      if (!mounted) return;
      setState(() => _jaVotei = true);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Voto computado com sucesso!')),
      );

      // Mostra o rótulo por um instante e volta
      await Future.delayed(const Duration(milliseconds: 900));
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;

      final msg = e.toString();
      // Se o backend devolveu algo como “já votou…”, travamos o botão em “Voto registrado”
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
    final sorteio = widget.sorteio;

    // Decide rótulo/estado do botão
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
              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.white70),
            ),
          ],
        ),
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: sorteio.times.length,
        separatorBuilder: (_, __) => const SizedBox(height: 16),
        itemBuilder: (context, index) {
          final time = sorteio.times[index];

          return AnimatedContainer(
            duration: const Duration(milliseconds: 400),
            curve: Curves.easeInOut,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 3))],
            ),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  time.nome ?? 'Time',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                ...time.jogadores.map((jogador) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 20,
                          backgroundImage: jogador.foto != null && jogador.foto!.isNotEmpty
                              ? NetworkImage(jogador.foto!)
                              : null,
                          child: (jogador.foto == null || jogador.foto!.isEmpty)
                              ? const Icon(Icons.person)
                              : null,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${jogador.numeroCamisa} - ${jogador.apelido}',
                                style: const TextStyle(fontSize: 16),
                              ),
                              Row(
                                children: [
                                  _iconForPosition(jogador.posicao),
                                  const SizedBox(width: 4),
                                  Text(
                                    jogador.posicao ?? 'Sem posição',
                                    style: TextStyle(color: _colorForPosition(jogador.posicao)),
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
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
                    ),
                  ],
                )
              ],
            ),
          );
        },
      ),

      // BOTÃO FIXO (vira “Voto registrado” após votar)
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: FilledButton.icon(
            icon: _enviandoVoto
                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                : Icon(_jaVotei ? Icons.verified : Icons.how_to_vote),
            label: Text(botaoTexto),
            onPressed: botaoHabilitado ? _votar : null,
          ),
        ),
      ),
    );
  }
}
