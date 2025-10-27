import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../models/sorteio_detalhe_model.dart';
import '../models/partida_model.dart';
import 'partida_rodando_page.dart';
import '../widgets/nova_partida_sheet.dart';

class RegistrarPartidasPage extends StatefulWidget {
  final SorteioDetalhe sorteio;
  const RegistrarPartidasPage({super.key, required this.sorteio});

  @override
  State<RegistrarPartidasPage> createState() => _RegistrarPartidasPageState();
}

class _RegistrarPartidasPageState extends State<RegistrarPartidasPage> {
  bool _loading = true;
  List<Partida> _partidas = [];

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  Future<void> _carregar() async {
    setState(() => _loading = true);
    try {
      final list = await ApiService.getPartidasDoSorteio(widget.sorteio.id);
      if (!mounted) return;
      setState(() => _partidas = list);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _novaPartida() async {
    final criada = await showModalBottomSheet<Partida>(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      builder: (_) => NovaPartidaSheet(sorteio: widget.sorteio),
    );
    if (criada != null) {
      setState(() => _partidas = [criada, ..._partidas]);
      // opcional: abrir já a tela de jogo
      _abrirPartida(criada);
    }
  }

  Future<void> _abrirPartida(Partida p) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => PartidaRodandoPage(partida: p)),
    );
    await _carregar();
  }

  @override
  Widget build(BuildContext context) {
    final body = _loading
        ? const Center(child: CircularProgressIndicator())
        : _partidas.isEmpty
            ? const Center(child: Text('Nenhuma partida cadastrada ainda.'))
            : ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
                itemCount: _partidas.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (_, i) {
                  final p = _partidas[i];
                  return ListTile(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    tileColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                    title: Text('${p.timeANome}  ${p.placarA}  x  ${p.placarB}  ${p.timeBNome}'),
                    subtitle: Text(p.status == 'em_andamento'
                        ? 'Em andamento'
                        : p.status == 'encerrado'
                            ? 'Encerrada'
                            : 'Criada'),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                    onTap: () => _abrirPartida(p),
                  );
                },
              );

    return Scaffold(
      appBar: AppBar(title: Text('Partidas — Sorteio nº ${widget.sorteio.numero}')),
      body: RefreshIndicator(onRefresh: _carregar, child: body),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _novaPartida,
        icon: const Icon(Icons.sports_soccer),
        label: const Text('Nova Partida'),
      ),
    );
  }
}
