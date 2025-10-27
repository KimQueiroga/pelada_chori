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

  // ----------------- UI helpers -----------------

  /// Rotulo curto ao estilo "FT", "LIVE", "AGENDADA"
  String _statusRotulo(Partida p) {
    switch (p.status.toLowerCase()) {
      case 'encerrada':
        return 'CLOSED';
      case 'em_andamento':
        return 'LIVE';
      case 'agendada':
      default:
        return 'AGENDADA';
    }
  }

  /// Cor do chip de status
  Color _statusCor(Partida p, BuildContext ctx) {
    final s = p.status.toLowerCase();
    if (s == 'encerrada') {
      return Theme.of(ctx).colorScheme.secondary;
    }
    if (s == 'em_andamento') {
      return Theme.of(ctx).colorScheme.primary;
    }
    return Theme.of(ctx).colorScheme.outline; // agendada
  }

  /// Data para agrupar/exibir: encerrada > iniciada > criada > agora
  DateTime _dataDeExibicao(Partida p) =>
      p.encerradaEm ?? p.iniciadaEm ?? p.createdAt ?? DateTime.now();

  // ----------------- row -----------------

  Widget _partidaRow(Partida p) {
    final statusChip = Chip(
      label: Text(_statusRotulo(p)),
      visualDensity: VisualDensity.compact,
      backgroundColor: _statusCor(p, context).withOpacity(.12),
      labelStyle: TextStyle(
        color: _statusCor(p, context),
        fontWeight: FontWeight.w700,
        fontSize: 11,
      ),
      side: BorderSide(color: _statusCor(p, context).withOpacity(.35)),
      padding: const EdgeInsets.symmetric(horizontal: 6),
    );

    return ListTile(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      tileColor: Theme.of(context).colorScheme.surfaceContainerHighest,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      title: Row(
        children: [
          Expanded(
            child: Text(
              '${p.nomeA()}  ${p.placarA}  x  ${p.placarB}  ${p.nomeB()}',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          statusChip,
        ],
      ),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 4),
        child: Text(
          // exibe: “Hoje 14:07”, “Ontem 20:15”, ou “27/10 03:41”
          _formatWhen(_dataDeExibicao(p)),
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      onTap: () => _abrirPartida(p),
    );
  }

  String _formatWhen(DateTime dt) {
    final now = DateTime.now();
    final d = DateTime(dt.year, dt.month, dt.day);
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));

    String hh = dt.hour.toString().padLeft(2, '0');
    String mm = dt.minute.toString().padLeft(2, '0');
    final hm = '$hh:$mm';

    if (d == today) return 'Hoje $hm';
    if (d == yesterday) return 'Ontem $hm';
    return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')} $hm';
  }

  // ----------------- build -----------------

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
                itemBuilder: (_, i) => _partidaRow(_partidas[i]),
              );

    return Scaffold(
      appBar: AppBar(
        title: Text('Partidas — Sorteio nº ${widget.sorteio.numero}'),
      ),
      body: RefreshIndicator(onRefresh: _carregar, child: body),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _novaPartida,
        icon: const Icon(Icons.sports_soccer),
        label: const Text('Nova Partida'),
      ),
    );
  }
}
