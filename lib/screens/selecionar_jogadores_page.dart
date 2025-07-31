import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../services/api_service.dart';
import '../screens/rascunhos_dia_page.dart';

class SelecionarJogadoresPage extends StatefulWidget {
  const SelecionarJogadoresPage({Key? key}) : super(key: key);

  @override
  State<SelecionarJogadoresPage> createState() => _SelecionarJogadoresPageState();
}

class _SelecionarJogadoresPageState extends State<SelecionarJogadoresPage> {
  // Dados vindos da API
  List<Map<String, dynamic>> _jogadores = [];

  // Seleção do usuário
  final Set<int> _selecionados = {};

  // Configurações do sorteio
  int _qtdTimes = 2;
  int _qtdJogadoresPorTime = 5;
  DateTime _data = DateTime.now();
  final TextEditingController _descricaoCtrl = TextEditingController();
  String _estrategia = 'balanceado'; // outras opções no futuro

  // Estado
  bool _loading = true;
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    _carregarJogadores();
  }

  @override
  void dispose() {
    _descricaoCtrl.dispose();
    super.dispose();
  }

  Future<void> _carregarJogadores() async {
    try {
      final dados = await ApiService.getJogadoresTodos();
      setState(() {
        _jogadores = dados;
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao carregar jogadores: $e')),
      );
    }
  }

  // Cálculos auxiliares
  int get _necessarios => _qtdTimes * _qtdJogadoresPorTime;
  int get _selecionadosQtde => _selecionados.length;
  int get _faltam => (_necessarios - _selecionadosQtde).clamp(0, _necessarios);
  bool get _atingiuCapacidade => _selecionadosQtde >= _necessarios;

  void _toggleSelecionado(int jogadorId, bool? marcado) {
    setState(() {
      if (marcado == true) {
        if (_selecionados.length < _necessarios) {
          _selecionados.add(jogadorId);
        } else {
          // Capacidade atingida; ignora clique e avisa
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Limite atingido: $_necessarios jogadores ($_qtdTimes x $_qtdJogadoresPorTime).',
              ),
            ),
          );
        }
      } else {
        _selecionados.remove(jogadorId);
      }
    });
  }

  // Controles de incremento/decremento com limite
  void _incTimes() => setState(() => _qtdTimes = (_qtdTimes + 1).clamp(1, 20));
  void _decTimes() => setState(() {
        if (_qtdTimes > 1) _qtdTimes--;
        // Se reduzir a capacidade total, ajuste a seleção (evita ficar “excedida”)
        while (_selecionados.length > _necessarios) {
          _selecionados.remove(_selecionados.last);
        }
      });

  void _incJogPorTime() =>
      setState(() => _qtdJogadoresPorTime = (_qtdJogadoresPorTime + 1).clamp(1, 25));
  void _decJogPorTime() => setState(() {
        if (_qtdJogadoresPorTime > 1) _qtdJogadoresPorTime--;
        while (_selecionados.length > _necessarios) {
          _selecionados.remove(_selecionados.last);
        }
      });

  // --------- UI helpers ---------

  Widget _buildConfigCard(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Configurações do sorteio',
                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),

            const SizedBox(height: 12),

            Row(
              children: [
                Expanded(
                  child: _CounterTile(
                    titulo: 'Times',
                    valor: _qtdTimes,
                    onInc: _incTimes,
                    onDec: _decTimes,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _CounterTile(
                    titulo: 'Jogadores/time',
                    valor: _qtdJogadoresPorTime,
                    onInc: _incJogPorTime,
                    onDec: _decJogPorTime,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Data + Estratégia
            Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: _data,
                        firstDate: DateTime(DateTime.now().year - 1),
                        lastDate: DateTime(DateTime.now().year + 1),
                      );
                      if (picked != null) setState(() => _data = picked);
                    },
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                      decoration: BoxDecoration(
                        border: Border.all(color: theme.colorScheme.outlineVariant),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.event),
                          const SizedBox(width: 8),
                          Text(
                            'Data: ${DateFormat('dd/MM/yyyy').format(_data)}',
                            style: theme.textTheme.bodyMedium,
                          ),
                          const Spacer(),
                          const Icon(Icons.edit_calendar, size: 18),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: InputDecorator(
                    decoration: InputDecoration(
                      labelText: 'Estratégia',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _estrategia,
                        isDense: true,
                        onChanged: (v) => setState(() => _estrategia = v ?? 'balanceado'),
                        items: const [
                          DropdownMenuItem(
                            value: 'balanceado',
                            child: Text('Balanceado'),
                          ),
                          // Futuras estratégias podem entrar aqui
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            TextField(
              controller: _descricaoCtrl,
              maxLength: 80,
              decoration: InputDecoration(
                labelText: 'Descrição (opcional)',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                hintText: 'Ex.: Sorteio semanal da terça-feira',
              ),
            ),

            const SizedBox(height: 8),

            // Indicadores
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Selecionados: $_selecionadosQtde', style: theme.textTheme.bodyMedium),
                Text('Necessários: $_necessarios',
                    style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
              ],
            ),

            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                minHeight: 8,
                value: _necessarios == 0 ? 0 : _selecionadosQtde / _necessarios,
                backgroundColor: theme.colorScheme.surfaceVariant,
              ),
            ),

            const SizedBox(height: 8),
            if (_faltam > 0)
              Text(
                'Faltam $_faltam jogador(es) para completar a capacidade.',
                style: theme.textTheme.bodySmall?.copyWith(color: Colors.orange[800]),
              )
            else
              Text(
                'Capacidade completa!',
                style: theme.textTheme.bodySmall?.copyWith(color: Colors.green[800]),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildJogadorItem(Map<String, dynamic> jogador) {
    final nome = (jogador['nome'] ?? '') as String;
    final avatarUrl = (jogador['foto'] as String?)?.trim();
    final id = jogador['id'] as int;
    final marcado = _selecionados.contains(id);

    final inicial = nome.isNotEmpty ? nome[0].toUpperCase() : '?';

    // Se atingiu a capacidade, bloqueia novas marcações (mas permite desmarcar)
    final bloqueado = _atingiuCapacidade && !marcado;

    return CheckboxListTile(
      title: Text(nome),
      value: marcado,
      onChanged: bloqueado ? null : (v) => _toggleSelecionado(id, v),
      controlAffinity: ListTileControlAffinity.trailing,
      secondary: (avatarUrl != null && avatarUrl.isNotEmpty)
          ? CircleAvatar(backgroundImage: NetworkImage(avatarUrl))
          : CircleAvatar(child: Text(inicial)),
    );
  }

  // --------- Envio ao backend ---------

  Future<void> _gerarDuplo() async {
    final qtdTimes = _qtdTimes;
    final qtdPorTime = _qtdJogadoresPorTime;
    final totalNecessario = _necessarios;

    final selecionados = _selecionados.toList();

    if (qtdTimes <= 0 || qtdPorTime <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Informe quantidades válidas.')),
      );
      return;
    }

    if (selecionados.length < totalNecessario) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Selecione pelo menos $totalNecessario jogadores.')),
      );
      return;
    }

    setState(() => _sending = true);

    try {
      await ApiService.criarDuploCompleto(
        data: _data,
        descricao: _descricaoCtrl.text.trim().isEmpty ? null : _descricaoCtrl.text.trim(),
        quantidadeTimes: qtdTimes,
        quantidadeJogadoresTime: qtdPorTime,
        jogadoresIds: selecionados,
        estrategia: _estrategia,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Dois rascunhos gerados com sucesso!')),
      );

      // Levar o usuário para revisar os rascunhos do dia:
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const RascunhosDiaPage()),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao gerar sorteios: $e')),
      );
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Criar Sorteio'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                _buildConfigCard(context),
                const SizedBox(height: 4),
                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(8, 0, 8, 88),
                    itemCount: _jogadores.length,
                    separatorBuilder: (_, __) => const Divider(height: 0),
                    itemBuilder: (context, index) {
                      return _buildJogadorItem(_jogadores[index]);
                    },
                  ),
                ),
              ],
            ),

      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: FilledButton.icon(
            onPressed: (_faltam == 0 && !_sending) ? _gerarDuplo : null,
            icon: _sending
                ? const SizedBox(
                    width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.casino),
            label: Text(
              _sending
                  ? 'Gerando...'
                  : 'Gerar dois sorteios (${_selecionadosQtde}/$_necessarios)',
              style: theme.textTheme.titleSmall?.copyWith(color: Colors.white),
            ),
          ),
        ),
      ),
    );
  }
}

/// Mini-componente para o controle de quantidade com +/-
class _CounterTile extends StatelessWidget {
  final String titulo;
  final int valor;
  final VoidCallback onInc;
  final VoidCallback onDec;

  const _CounterTile({
    Key? key,
    required this.titulo,
    required this.valor,
    required this.onInc,
    required this.onDec,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: theme.colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(10),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        children: [
          Text(titulo, style: theme.textTheme.bodyMedium),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.remove),
            onPressed: onDec,
            tooltip: 'Diminuir',
          ),
          Text(
            '$valor',
            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: onInc,
            tooltip: 'Aumentar',
          ),
        ],
      ),
    );
  }
}