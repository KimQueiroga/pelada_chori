import 'package:flutter/material.dart';
import '../../../services/api_service.dart';
import '../../models/sorteio_detalhe_model.dart';
import '../../models/partida_model.dart';

class NovaPartidaSheet extends StatefulWidget {
  final SorteioDetalhe sorteio;
  const NovaPartidaSheet({super.key, required this.sorteio});

  @override
  State<NovaPartidaSheet> createState() => _NovaPartidaSheetState();
}

class _NovaPartidaSheetState extends State<NovaPartidaSheet> {
  bool _loading = true;
  List<Map<String, dynamic>> _times = [];
  int? _timeAId;
  int? _timeBId;
  int _tempoMin = 7;

  @override
  void initState() {
    super.initState();
    _carregarTimes();
  }

  Future<void> _carregarTimes() async {
    setState(() => _loading = true);
    try {
      final t = await ApiService.getTimesDoSorteio(widget.sorteio.id);
      if (!mounted) return;
      setState(() {
        _times = t;
        if (_times.length >= 2) {
          _timeAId = _times[0]['id'] as int;
          _timeBId = _times[1]['id'] as int;
        }
      });
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _salvar() async {
    if (_timeAId == null || _timeBId == null || _timeAId == _timeBId) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Escolha dois times diferentes.')),
      );
      return;
    }
    try {
      final p = await ApiService.criarPartida(
        sorteioId: widget.sorteio.id,
        timeAId: _timeAId!,
        timeBId: _timeBId!,
        tempoSegundos: _tempoMin * 60,
      );
      if (!mounted) return;
      Navigator.pop<Partida>(context, p);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Falha ao criar partida: $e')),
      );
    }
  }

  InputDecoration _fieldDecoration(ThemeData theme, String label) {
    return InputDecoration(
      labelText: label,
      filled: true,
      fillColor: theme.colorScheme.surfaceVariant.withOpacity(0.25),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
    );
  }

  String _timeLabel(Map<String, dynamic> time) {
    final nome = (time['nome'] ?? 'Time').toString();
    final jogadores = (time['jogadores'] as List?) ?? const [];
    final apelidos = jogadores
        .map((j) {
          final map = (j as Map).cast<String, dynamic>();
          final jogador = (map['jogador'] as Map?)?.cast<String, dynamic>();
          return (map['apelido'] ??
                  map['nome'] ??
                  jogador?['apelido'] ??
                  jogador?['nome'] ??
                  '')
              .toString()
              .trim();
        })
        .where((s) => s.isNotEmpty)
        .toList();
    if (apelidos.isEmpty) return nome;
    const maxApelidos = 3;
    final base = apelidos.take(maxApelidos).join(', ');
    final suffix = apelidos.length > maxApelidos ? ', ...' : '';
    return '$nome - $base$suffix';
  }

  Widget _buildTimeDropdown({
    required ThemeData theme,
    required String label,
    required int? value,
    required ValueChanged<int?> onChanged,
  }) {
    return DropdownButtonFormField<int>(
      value: value,
      isExpanded: true,
      items: _times
          .map(
            (t) => DropdownMenuItem<int>(
              value: t['id'] as int,
              child: Text(
                _timeLabel(t),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          )
          .toList(),
      onChanged: onChanged,
      decoration: _fieldDecoration(theme, label),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: 16, right: 16,
          top: 16,
          bottom: 16 + MediaQuery.of(context).viewInsets.bottom,
        ),
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 48,
                        height: 4,
                        decoration: BoxDecoration(
                          color: theme.colorScheme.outlineVariant,
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Nova Partida',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Escolha os times e o tempo de jogo.',
                      style: theme.textTheme.bodySmall,
                    ),
                    const SizedBox(height: 16),
                    _buildTimeDropdown(
                      theme: theme,
                      label: 'Time A',
                      value: _timeAId,
                      onChanged: (v) => setState(() => _timeAId = v),
                    ),
                    const SizedBox(height: 10),
                    _buildTimeDropdown(
                      theme: theme,
                      label: 'Time B',
                      value: _timeBId,
                      onChanged: (v) => setState(() => _timeBId = v),
                    ),
                    const SizedBox(height: 10),
                    DropdownButtonFormField<int>(
                      value: _tempoMin,
                      isExpanded: true,
                      items: const [5, 7, 10, 12]
                          .map((m) => DropdownMenuItem(value: m, child: Text('$m')))
                          .toList(),
                      onChanged: (v) => setState(() => _tempoMin = v ?? 7),
                      decoration: _fieldDecoration(theme, 'Tempo (min)'),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Cancelar'),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: FilledButton.icon(
                            onPressed: _salvar,
                            icon: const Icon(Icons.check),
                            label: const Text('Criar partida'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}
