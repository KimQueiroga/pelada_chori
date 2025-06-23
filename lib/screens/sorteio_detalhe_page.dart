import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/sorteio_detalhe_model.dart';

class SorteioDetalhePage extends StatelessWidget {
  final SorteioDetalhe sorteio;

  const SorteioDetalhePage({super.key, required this.sorteio});

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
    );
  }
}
