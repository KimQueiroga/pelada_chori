import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/sorteio_detalhe_model.dart';
import '../services/api_service.dart';
import '../../utils/app_date.dart';


class RascunhosDiaPage extends StatefulWidget {
  const RascunhosDiaPage({Key? key}) : super(key: key);

  @override
  State<RascunhosDiaPage> createState() => _RascunhosDiaPageState();
}

class _RascunhosDiaPageState extends State<RascunhosDiaPage> {
  bool _loading = true;
  List<SorteioDetalhe> _sorteios = [];

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  Future<void> _carregar() async {
    try {
      final lista = await ApiService.getRascunhosDoDia();
      setState(() {
        _sorteios = lista;
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao carregar rascunhos: $e')),
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
        AppDate.brFromApi(s.data);

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
                    'Rascunho • Sorteio nº ${s.numero}',
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
    return Scaffold(
      appBar: AppBar(title: const Text('Rascunhos de Hoje')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _sorteios.isEmpty
              ? const Center(child: Text('Nenhum rascunho encontrado para hoje.'))
              : RefreshIndicator(
                  onRefresh: _carregar,
                  child: ListView.builder(
                    physics: const AlwaysScrollableScrollPhysics(),
                    itemCount: _sorteios.length,
                    itemBuilder: (_, i) => _cardSorteio(_sorteios[i]),
                  ),
                ),
    );
  }
}


