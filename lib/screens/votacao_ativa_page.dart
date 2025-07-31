import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/sorteio_detalhe_model.dart';
import '../services/api_service.dart';

class VotacaoAtivaPage extends StatefulWidget {
  const VotacaoAtivaPage({Key? key}) : super(key: key);

  @override
  State<VotacaoAtivaPage> createState() => _VotacaoAtivaPageState();
}

class _VotacaoAtivaPageState extends State<VotacaoAtivaPage> {
  bool _loading = true;
  SorteioDetalhe? _sorteio;

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  Future<void> _carregar() async {
    try {
      final s = await ApiService.getVotacaoAtiva();
      setState(() {
        _sorteio = s;
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao carregar votação ativa: $e')),
      );
    }
  }

  // --- UI helpers -----------------------------------------------------------

  Widget _linhaJogador(dynamic j) {
    final foto = (j.foto ?? '').trim();
    final apelido = (j.apelido ?? '').trim();
    final posicao = (j.posicao ?? '').trim();
    final numero = (j.numeroCamisa ?? '').toString();

    String _inicial() {
      if (apelido.isNotEmpty) return apelido.substring(0, 1).toUpperCase();
      return '?';
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          CircleAvatar(
            radius: 14,
            backgroundImage: foto.isNotEmpty ? NetworkImage(foto) : null,
            child: foto.isEmpty ? Text(_inicial()) : null,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '$numero - ${apelido.isNotEmpty ? apelido : 'Sem apelido'}  •  ${posicao.isNotEmpty ? posicao : '-'}',
              style: const TextStyle(fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  Widget _cardSorteio(SorteioDetalhe s) {
    final dataFmt =
        DateFormat('dd/MM/yyyy').format(DateTime.parse(s.data).toLocal());

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cabeçalho
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Votação Ativa • Sorteio nº ${s.numero}',
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                ),
                Text(
                  dataFmt,
                  style: TextStyle(
                    color: Theme.of(context).textTheme.bodySmall?.color,
                  ),
                ),
              ],
            ),
            if ((s.descricao ?? '').isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                s.descricao!,
                style: const TextStyle(color: Colors.grey),
              ),
            ],
            const SizedBox(height: 10),

            // Times
            ...s.times.map(
              (t) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: Theme.of(context)
                        .colorScheme
                        .primaryContainer
                        .withOpacity(.25),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          t.nome ?? 'Time',
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                          ),
                        ),
                        const SizedBox(height: 6),
                        ...t.jogadores.map(_linhaJogador),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- build ---------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final s = _sorteio;

    return Scaffold(
      appBar: AppBar(title: const Text('Votação Ativa')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : s == null
              ? const Center(child: Text('Nenhuma votação ativa no momento.'))
              : RefreshIndicator(
                  onRefresh: _carregar,
                  child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    children: [_cardSorteio(s)],
                  ),
                ),
    );
  }
}