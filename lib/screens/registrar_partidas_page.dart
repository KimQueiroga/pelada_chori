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

  bool _isLive(Partida p) => p.status.toLowerCase() == 'em_andamento';

  Color _statusCor(Partida p, BuildContext ctx) {
    final s = p.status.toLowerCase();
    if (s == 'encerrada') {
      return Theme.of(ctx).colorScheme.secondary;
    }
    if (s == 'em_andamento') {
      return Theme.of(ctx).colorScheme.primary;
    }
    return Theme.of(ctx).colorScheme.outline;
  }

  DateTime _dataDeExibicao(Partida p) =>
      p.encerradaEm ?? p.iniciadaEm ?? p.createdAt ?? DateTime.now();

  // ----------------- row -----------------

  Widget _buildEmptyState(BuildContext context) {
    final theme = Theme.of(context);

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(24, 80, 24, 120),
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceVariant.withOpacity(0.4),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: theme.colorScheme.outlineVariant),
          ),
          child: Column(
            children: [
              Icon(
                Icons.sports_soccer,
                size: 56,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(height: 12),
              Text(
                'Sem partidas cadastradas',
                style: theme.textTheme.titleMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Crie a primeira partida para este sorteio.',
                style: theme.textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: _novaPartida,
                icon: const Icon(Icons.add),
                label: const Text('Criar partida'),
              ),
              const SizedBox(height: 8),
              Text(
                'Puxe para atualizar.',
                style: theme.textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _partidaRow(Partida p) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final statusColor = _statusCor(p, context);
    final isLive = _isLive(p);

    Widget pill(String label, {Color? color, bool liveDot = false}) {
      final pillColor = color ?? cs.outline;
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: pillColor.withOpacity(0.12),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: pillColor.withOpacity(0.35)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (liveDot) ...[
              Icon(Icons.circle, size: 8, color: pillColor),
              const SizedBox(width: 6),
            ],
            Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: pillColor,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      );
    }

    return InkWell(
      onTap: () => _abrirPartida(p),
      borderRadius: BorderRadius.circular(16),
      child: Ink(
        decoration: BoxDecoration(
          color: isLive
              ? cs.primary.withOpacity(0.08)
              : cs.surfaceVariant.withOpacity(0.35),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: statusColor.withOpacity(0.2)),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      p.nomeA(),
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: cs.surface,
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(color: statusColor.withOpacity(0.25)),
                    ),
                    child: Text(
                      '${p.placarA} x ${p.placarB}',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      p.nomeB(),
                      textAlign: TextAlign.right,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  pill(_statusRotulo(p), color: statusColor, liveDot: isLive),
                  const SizedBox(width: 8),
                  pill(_formatWhen(_dataDeExibicao(p))),
                  const Spacer(),
                  Icon(Icons.chevron_right, color: cs.outline),
                ],
              ),
            ],
          ),
        ),
      ),
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
            ? _buildEmptyState(context)
            : ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
                itemCount: _partidas.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (_, i) => _partidaRow(_partidas[i]),
              );

    return Scaffold(
      appBar: AppBar(
        title: Text('Partidas - Sorteio no ${widget.sorteio.numero}'),
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
