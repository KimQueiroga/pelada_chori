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
  final FocusNode _descricaoFocus = FocusNode();
  String? _descricaoError; // <- erro do campo obrigatório
  String _estrategia = 'balanceado';

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
    _descricaoFocus.dispose();
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
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isWideCounters = constraints.maxWidth >= 600; // counters lado a lado
            final isWidePair = constraints.maxWidth >= 520; // estratégia+data lado a lado
            final tituloJog = isWideCounters ? 'Jogadores/time' : 'Jog/time';

            // --- Counters (Times / Jogadores por time) ---
            final counters = isWideCounters
                ? Row(
                    children: [
                      Expanded(
                        child: _CounterTile(
                          titulo: 'Times',
                          valor: _qtdTimes,
                          onInc: _incTimes,
                          onDec: _decTimes,
                          compact: true,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _CounterTile(
                          titulo: tituloJog,
                          valor: _qtdJogadoresPorTime,
                          onInc: _incJogPorTime,
                          onDec: _decJogPorTime,
                          compact: true,
                        ),
                      ),
                    ],
                  )
                : Column(
                    children: [
                      _CounterTile(
                        titulo: 'Times',
                        valor: _qtdTimes,
                        onInc: _incTimes,
                        onDec: _decTimes,
                        compact: true,
                      ),
                      const SizedBox(height: 10),
                      _CounterTile(
                        titulo: tituloJog,
                        valor: _qtdJogadoresPorTime,
                        onInc: _incJogPorTime,
                        onDec: _decJogPorTime,
                        compact: true,
                      ),
                    ],
                  );

            // --- Estratégia + Data (responsivo) ---
            final pair = isWidePair
                ? Row(
                    children: [
                      Expanded(
                        child: _StrategyField(
                          value: _estrategia,
                          onChanged: (v) => setState(() => _estrategia = v ?? 'balanceado'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(child: _DateField(date: _data, onPick: _pickDate)),
                    ],
                  )
                : Column(
                    children: [
                      _StrategyField(
                        value: _estrategia,
                        onChanged: (v) => setState(() => _estrategia = v ?? 'balanceado'),
                        compact: true,
                      ),
                      const SizedBox(height: 10),
                      _DateField(date: _data, onPick: _pickDate, compact: true),
                    ],
                  );

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Configurações do sorteio',
                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),

                const SizedBox(height: 12),

                counters,

                const SizedBox(height: 12),

                pair,

                const SizedBox(height: 12),

                // DESCRIÇÃO — obrigatório
                TextField(
                  controller: _descricaoCtrl,
                  focusNode: _descricaoFocus,
                  maxLength: 80,
                  onChanged: (_) {
                    if (_descricaoError != null) {
                      setState(() => _descricaoError = null);
                    }
                  },
                  decoration: InputDecoration(
                    labelText: 'Descrição (*)',
                    errorText: _descricaoError, // mostra erro quando necessário
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
                        style:
                            theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
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
            );
          },
        ),
      ),
    );
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _data,
      firstDate: DateTime(DateTime.now().year - 1),
      lastDate: DateTime(DateTime.now().year + 1),
    );
    if (picked != null) setState(() => _data = picked);
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

    // validações
    if (qtdTimes <= 0 || qtdPorTime <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Informe quantidades válidas.')),
      );
      return;
    }

    final desc = _descricaoCtrl.text.trim();
    if (desc.isEmpty) {
      setState(() => _descricaoError = 'Informe a descrição');
      _descricaoFocus.requestFocus();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('O campo Descrição é obrigatório.')),
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
        descricao: desc, // agora sempre vem preenchido
        quantidadeTimes: qtdTimes,
        quantidadeJogadoresTime: qtdPorTime,
        jogadoresIds: selecionados,
        estrategia: _estrategia,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Dois rascunhos gerados com sucesso!')),
      );

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

/// Controle de quantidade com +/-
/// Quando `compact == true`, o rótulo fica acima e os botões ficam mais “magrinhos”.
class _CounterTile extends StatelessWidget {
  final String titulo;
  final int valor;
  final VoidCallback onInc;
  final VoidCallback onDec;
  final bool compact;

  const _CounterTile({
    Key? key,
    required this.titulo,
    required this.valor,
    required this.onInc,
    required this.onDec,
    this.compact = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final minusBtn = IconButton(
      icon: const Icon(Icons.remove),
      onPressed: onDec,
      tooltip: 'Diminuir',
      visualDensity: compact ? VisualDensity.compact : VisualDensity.standard,
      padding: compact ? const EdgeInsets.all(6) : null,
      constraints:
          compact ? const BoxConstraints(minWidth: 36, minHeight: 36) : const BoxConstraints(),
    );

    final plusBtn = IconButton(
      icon: const Icon(Icons.add),
      onPressed: onInc,
      tooltip: 'Aumentar',
      visualDensity: compact ? VisualDensity.compact : VisualDensity.standard,
      padding: compact ? const EdgeInsets.all(6) : null,
      constraints:
          compact ? const BoxConstraints(minWidth: 36, minHeight: 36) : const BoxConstraints(),
    );

    final numberText = Text(
      '$valor',
      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
    );

    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: theme.colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(10),
      ),
      padding: compact
          ? const EdgeInsets.symmetric(horizontal: 10, vertical: 8)
          : const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: compact
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(titulo, style: theme.textTheme.bodySmall),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    minusBtn,
                    numberText,
                    plusBtn,
                  ],
                ),
              ],
            )
          : Row(
              children: [
                Text(titulo, style: theme.textTheme.bodyMedium),
                const Spacer(),
                minusBtn,
                numberText,
                plusBtn,
              ],
            ),
    );
  }
}

/// Campo de Estratégia (Dropdown) com opção compact
class _StrategyField extends StatelessWidget {
  final String value;
  final ValueChanged<String?> onChanged;
  final bool compact;

  const _StrategyField({
    Key? key,
    required this.value,
    required this.onChanged,
    this.compact = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final contentPadding =
        compact ? const EdgeInsets.symmetric(horizontal: 12, vertical: 8) : const EdgeInsets.symmetric(horizontal: 12, vertical: 10);

    return InputDecorator(
      decoration: InputDecoration(
        labelText: 'Estratégia',
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        contentPadding: contentPadding,
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isDense: true,
          onChanged: onChanged,
          items: const [
            DropdownMenuItem(
              value: 'balanceado',
              child: Text('Balanceado'),
            ),
          ],
        ),
      ),
    );
  }
}

/// Campo de Data (InkWell) com opção compact e texto elíptico para não estourar
class _DateField extends StatelessWidget {
  final DateTime date;
  final VoidCallback onPick;
  final bool compact;

  const _DateField({
    Key? key,
    required this.date,
    required this.onPick,
    this.compact = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final pad =
        compact ? const EdgeInsets.symmetric(horizontal: 12, vertical: 10) : const EdgeInsets.symmetric(horizontal: 12, vertical: 12);

    return InkWell(
      onTap: onPick,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: pad,
        decoration: BoxDecoration(
          border: Border.all(color: theme.colorScheme.outlineVariant),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            const Icon(Icons.event),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Data: ${DateFormat('dd/MM/yyyy').format(date)}',
                style: theme.textTheme.bodyMedium,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                softWrap: false,
              ),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.edit_calendar, size: 18),
          ],
        ),
      ),
    );
  }
}
