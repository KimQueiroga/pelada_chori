import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/sorteio_detalhe_model.dart';

class SorteioDetalhePage extends StatelessWidget {
  final SorteioDetalhe sorteio;

  const SorteioDetalhePage({super.key, required this.sorteio});

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
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: sorteio.times.length,
        itemBuilder: (context, index) {
          final time = sorteio.times[index];
          return Card(
            margin: const EdgeInsets.only(bottom: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            elevation: 4,
            child: Padding(
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
                                Text(
                                  jogador.posicao ?? 'Sem posição',
                                  style: const TextStyle(color: Colors.grey),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),

                  if (time.mediaCalculada != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: Row(
                        children: [
                          const Icon(Icons.bar_chart, color: Colors.deepPurple),
                          const SizedBox(width: 8),
                          Text(
                            'Média do time: ${time.mediaCalculada!.toStringAsFixed(2)}',
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                    ),

                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
