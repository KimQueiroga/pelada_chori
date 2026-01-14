import 'package:flutter/material.dart';
import '../models/partida_model.dart';
import '../models/sorteio_detalhe_model.dart';
import '../services/api_service.dart';
import '../utils/app_date.dart';
import 'partida_rodando_page.dart';

class PartidasRegistradasPage extends StatefulWidget {
  const PartidasRegistradasPage({super.key});

  @override
  State<PartidasRegistradasPage> createState() => _PartidasRegistradasPageState();
}

class _PartidasRegistradasPageState extends State<PartidasRegistradasPage> {
  DateTime _data = DateTime.now();
  bool _loading = true;
  String? _erro;
  List<SorteioDetalhe> _sorteios = [];
  final Map<int, List<Partida>> _partidasPorSorteio = {};

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
      final sorteios = await ApiService.getSorteiosPorData(_data);
      final partidasPorSorteio = <int, List<Partida>>{};
      var parcial = false;

      for (final s in sorteios) {
        try {
          partidasPorSorteio[s.id] = await ApiService.getPartidasDoSorteio(s.id);
        } catch (_) {
          parcial = true;
          partidasPorSorteio[s.id] = const <Partida>[];
        }
      }

      if (!mounted) return;
      setState(() {
        _sorteios = sorteios;
        _partidasPorSorteio
          ..clear()
          ..addAll(partidasPorSorteio);
        if (parcial) {
          _erro = 'Falha ao carregar algumas partidas.';
        }
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _erro = 'Erro ao carregar partidas.';
        _sorteios = [];
        _partidasPorSorteio.clear();
      });
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _selecionarData() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _data,
      firstDate: DateTime(DateTime.now().year - 1),
      lastDate: DateTime(DateTime.now().year + 1),
    );
    if (picked == null) return;
    setState(() => _data = picked);
    await _carregar();
  }

  Future<void> _abrirPartida(Partida p) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => PartidaRodandoPage(partida: p)),
    );
    await _carregar();
  }

  String _statusRotulo(Partida p) {
    switch (p.status.toLowerCase()) {
      case 'encerrada':
        return 'ENCERRADA';
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

  String _formatWhen(DateTime dt) {
    final now = DateTime.now();
    final d = DateTime(dt.year, dt.month, dt.day);
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));

    final hh = dt.hour.toString().padLeft(2, '0');
    final mm = dt.minute.toString().padLeft(2, '0');
    final hm = '$hh:$mm';

    if (d == today) return 'Hoje $hm';
    if (d == yesterday) return 'Ontem $hm';
    return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')} $hm';
  }

  Widget _pill(ThemeData theme, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withOpacity(0.35)),
      ),
      child: Text(
        label,
        style: theme.textTheme.bodySmall?.copyWith(
          color: color,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _buildDatePickerCard(ThemeData theme) {
    final cs = theme.colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: InkWell(
        onTap: _selecionarData,
        borderRadius: BorderRadius.circular(12),
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          decoration: BoxDecoration(
            color: cs.surfaceVariant.withOpacity(0.25),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: cs.outlineVariant),
          ),
          child: Row(
            children: [
              Icon(Icons.event, color: cs.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Data: ${AppDate.br(_data)}',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Icon(Icons.edit_calendar, color: cs.primary),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildErrorBanner(ThemeData theme, String message) {
    final cs = theme.colorScheme;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: cs.errorContainer.withOpacity(0.7),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cs.error.withOpacity(0.4)),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, color: cs.onErrorContainer),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: cs.onErrorContainer,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 120),
      children: [
        if (_erro != null) _buildErrorBanner(theme, _erro!),
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
                'Nenhuma partida registrada',
                style: theme.textTheme.titleMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Tente outra data para ver partidas registradas.',
                style: theme.textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: _selecionarData,
                icon: const Icon(Icons.event),
                label: const Text('Selecionar data'),
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

  Widget _buildSorteioSection(
    ThemeData theme,
    SorteioDetalhe sorteio,
    List<Partida> partidas,
  ) {
    final desc = sorteio.descricao.trim();
    final tentativa = sorteio.tentativa;
    final cs = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Sorteio ${sorteio.numero}',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            if (tentativa != null) ...[
              const SizedBox(width: 8),
              _pill(theme, 'Tentativa $tentativa', cs.primary),
            ],
          ],
        ),
        if (desc.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(desc, style: theme.textTheme.bodySmall),
        ],
        const SizedBox(height: 10),
        ...partidas.map((p) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _partidaRow(p),
            )),
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
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final sorteiosComPartidas = _sorteios
        .where((s) => (_partidasPorSorteio[s.id] ?? const <Partida>[]).isNotEmpty)
        .toList();

    Widget body;
    if (_loading) {
      body = ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 24, 16, 120),
        children: const [
          SizedBox(height: 120),
          Center(child: CircularProgressIndicator()),
        ],
      );
    } else if (sorteiosComPartidas.isEmpty) {
      body = _buildEmptyState(theme);
    } else {
      final children = <Widget>[];
      if (_erro != null) {
        children.add(_buildErrorBanner(theme, _erro!));
      }
      for (final s in sorteiosComPartidas) {
        final partidas = _partidasPorSorteio[s.id] ?? const <Partida>[];
        children.add(_buildSorteioSection(theme, s, partidas));
        children.add(const SizedBox(height: 16));
      }

      body = ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
        children: children,
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Partidas registradas'),
      ),
      body: Column(
        children: [
          _buildDatePickerCard(theme),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _carregar,
              child: body,
            ),
          ),
        ],
      ),
    );
  }
}
