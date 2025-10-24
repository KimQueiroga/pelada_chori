import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../services/api_service.dart';
import '../models/sorteio_detalhe_model.dart';
import '../utils/app_date.dart';
import '../screens/sorteio_page.dart';

class RascunhosDiaPage extends StatefulWidget {
  const RascunhosDiaPage({Key? key}) : super(key: key);

  @override
  State<RascunhosDiaPage> createState() => _RascunhosDiaPageState();
}

class _RascunhosDiaPageState extends State<RascunhosDiaPage> {
  bool _loading = true;
  String? _erro;

  /// Lista de pares (cada item é a lista de sorteios de uma tentativa).
  late List<List<SorteioDetalhe>> _pares;
  int? _tentativaSelecionada;

  final _nf = NumberFormat('0.00', 'pt_BR');

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  Future<void> _carregar() async {
    setState(() {
      _loading = true;
      _erro = null;
    });

    try {
      final lista = await ApiService.getRascunhosDoDia();

      // Agrupa por tentativa (cada tentativa deve ter 2 sorteios: nº1 e nº2)
      final Map<int, List<SorteioDetalhe>> porTentativa = {};
      for (final s in lista) {
        final t = s.tentativa ?? 0;
        porTentativa.putIfAbsent(t, () => []).add(s);
      }

      // Ordena tentativas desc e monta pares (ordenando nº 1 e nº 2 por 'numero')
      final chaves = porTentativa.keys.toList()..sort((a, b) => b.compareTo(a));
      final pares = <List<SorteioDetalhe>>[];
      for (final t in chaves) {
        final arr = porTentativa[t]!..sort((a, b) => a.numero.compareTo(b.numero));
        pares.add(arr);
      }

      setState(() {
        _pares = pares;
        _loading = false;
        if (_pares.isNotEmpty && _pares.first.length == 2) {
          _tentativaSelecionada = _pares.first.first.tentativa;
        } else {
          _tentativaSelecionada = null;
        }
      });
    } catch (e) {
      setState(() {
        _erro = 'Erro ao carregar rascunhos: $e';
        _loading = false;
      });
    }
  }

  Future<void> _publicarSelecionado() async {
    if (_tentativaSelecionada == null) return;

    // Localiza o par da tentativa selecionada
    final par = _pares.firstWhere(
      (p) => p.isNotEmpty && p.first.tentativa == _tentativaSelecionada,
      orElse: () => const <SorteioDetalhe>[],
    );

    if (par.length != 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Esta tentativa não está completa.')),
      );
      return;
    }

    final id1 = par[0].id;
    final id2 = par[1].id;

    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Publicar dupla'),
        content: Text(
          'Publicar a tentativa ${par.first.tentativa} para votação?\n'
          'Data: ${AppDate.brFromApi(par.first.data)}',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Publicar'),
          ),
        ],
      ),
    );

    if (confirmar != true) return;

    try {
      await ApiService.publicarDuplaPorIds(sorteioId1: id1, sorteioId2: id2);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Dupla publicada! Abrindo sorteios ativos...')),
      );

      // Troca a tela por SorteioPage:
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const SorteioPage()),
      );

      // (Opcional) se quiser limpar a pilha inteira:
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const SorteioPage()),
        (route) => false,
      );

      // Recarrega rascunhos (a dupla não deve mais aparecer)
      _carregar();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao publicar: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Título com a data: usa a do 1º card (se houver),
    // senão usa a data de hoje — SEM toLocal().
    final tituloData = (!_loading &&
            _erro == null &&
            _pares.isNotEmpty &&
            _pares.first.isNotEmpty)
        ? AppDate.brFromApi(_pares.first.first.data)
        : AppDate.br(DateTime.now());

    return Scaffold(
      appBar: AppBar(
        title: Text('Rascunhos de Hoje • $tituloData'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _erro != null
              ? Center(child: Text(_erro!))
              : RefreshIndicator(
                  onRefresh: _carregar,
                  child: ListView.separated(
                    padding: const EdgeInsets.only(top: 8, bottom: 100),
                    itemCount: _pares.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final par = _pares[index];
                      final tentativa = par.isNotEmpty ? par.first.tentativa : null;
                      final completa = par.length == 2;

                      return Card(
                        margin: const EdgeInsets.symmetric(horizontal: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Cabeçalho (radio + “Tentativa X” + status)
                              Row(
                                children: [
                                  Radio<int>(
                                    value: tentativa ?? -1,
                                    groupValue: _tentativaSelecionada,
                                    onChanged: completa
                                        ? (v) =>
                                            setState(() => _tentativaSelecionada = v)
                                        : null,
                                  ),
                                  const SizedBox(width: 4),
                                  Flexible(
                                    child: Text(
                                      'Tentativa ${tentativa ?? '-'}',
                                      style: theme.textTheme.titleMedium,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Chip(
                                    label: Text(completa ? 'Par completo' : 'Incompleto'),
                                    visualDensity: VisualDensity.compact,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),

                              // Cartões dos sorteios desta tentativa (1 e 2)
                              ...par
                                  .map(_cardSorteio)
                                  .expand((w) => [w, const SizedBox(height: 8)])
                                  .toList()
                                ..removeLast(),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: FilledButton.icon(
            onPressed: (_tentativaSelecionada != null &&
                    _pares.any((p) =>
                        p.isNotEmpty &&
                        p.first.tentativa == _tentativaSelecionada &&
                        p.length == 2))
                ? _publicarSelecionado
                : null,
            icon: const Icon(Icons.publish),
            label: const Text('Publicar dupla selecionada'),
          ),
        ),
      ),
    );
  }

  /// Card com *um sorteio* (título + data + times e jogadores).
  Widget _cardSorteio(SorteioDetalhe s) {
    final theme = Theme.of(context);

    return Card(
      color: theme.colorScheme.surfaceVariant.withOpacity(.5),
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Título + data do sorteio (sem timezone)
            Row(
              children: [
                Flexible(
                  child: Text(
                    'Rascunho • Sorteio nº ${s.numero}',
                    style: theme.textTheme.titleMedium,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  AppDate.brFromApi(s.data),
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),

            if ((s.descricao ?? '').isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                s.descricao!,
                style: theme.textTheme.bodySmall,
              ),
            ],

            const SizedBox(height: 10),

            // Times e jogadores
            ...s.times.map((t) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          t.nome ?? 'Time',
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (t.media != null)
                        Padding(
                          padding: const EdgeInsets.only(left: 6),
                          child: Chip(
                            label: Text('Média ${_nf.format(t.media)}'),
                            visualDensity: VisualDensity.compact,
                            materialTapTargetSize:
                                MaterialTapTargetSize.shrinkWrap,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 6),

                  ...t.jogadores.map((j) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 14,
                            backgroundImage: (j.foto != null && j.foto!.isNotEmpty)
                                ? NetworkImage(j.foto!)
                                : null,
                            child: (j.foto == null || j.foto!.isEmpty)
                                ? const Icon(Icons.person, size: 16)
                                : null,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              '${j.numeroCamisa ?? ''} - ${j.apelido ?? j.nome ?? ''}',
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            j.posicao ?? '',
                            style: const TextStyle(color: Colors.grey),
                          ),
                        ],
                      ),
                    );
                  }),
                  const SizedBox(height: 8),
                ],
              );
            }),
          ],
        ),
      ),
    );
  }
}
