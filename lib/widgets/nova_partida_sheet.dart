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

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: 16, right: 16,
          top: 16,
          bottom: 16 + MediaQuery.of(context).viewInsets.bottom,
        ),
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Nova Partida', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<int>(
                    value: _timeAId,
                    items: _times.map((t) => DropdownMenuItem<int>(
                      value: t['id'] as int, child: Text(t['nome']?.toString() ?? 'Time'))).toList(),
                    onChanged: (v) => setState(() => _timeAId = v),
                    decoration: const InputDecoration(labelText: 'Time A'),
                  ),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<int>(
                    value: _timeBId,
                    items: _times.map((t) => DropdownMenuItem<int>(
                      value: t['id'] as int, child: Text(t['nome']?.toString() ?? 'Time'))).toList(),
                    onChanged: (v) => setState(() => _timeBId = v),
                    decoration: const InputDecoration(labelText: 'Time B'),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      const Text('Tempo (min):'),
                      const SizedBox(width: 8),
                      DropdownButton<int>(
                        value: _tempoMin,
                        items: const [5,7,10,12].map((m)=>DropdownMenuItem(value: m, child: Text('$m'))).toList(),
                        onChanged: (v) => setState(() => _tempoMin = v ?? 7),
                      ),
                      const Spacer(),
                      FilledButton.icon(
                        onPressed: _salvar,
                        icon: const Icon(Icons.check),
                        label: const Text('Criar'),
                      )
                    ],
                  ),
                ],
              ),
      ),
    );
  }
}
