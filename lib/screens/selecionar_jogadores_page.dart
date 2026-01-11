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
  bool _configExpanded = true;
  final TextEditingController _searchCtrl = TextEditingController();
  String _filtroPosicao = 'Todas';
  double _filterHeaderHeight = 168;

  static const List<String> _posicoes = ['Todas', 'Defesa', 'Meio', 'Ataque'];

  @override
  void initState() {
    super.initState();
    _carregarJogadores();
  }

  @override
  void dispose() {
    _descricaoCtrl.dispose();
    _descricaoFocus.dispose();
    _searchCtrl.dispose();
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

  List<Map<String, dynamic>> _jogadoresFiltrados() {
    final query = _searchCtrl.text.trim().toLowerCase();
    final filtroPos = _filtroPosicao.toLowerCase();

    return _jogadores.where((j) {
      final nome = (j['nome'] ?? '').toString().toLowerCase();
      final apelido = (j['apelido'] ?? '').toString().toLowerCase();
      final posicao = (j['posicao'] ?? '').toString().toLowerCase();

      if (_filtroPosicao != 'Todas' && !posicao.contains(filtroPos)) {
        return false;
      }

      if (query.isEmpty) return true;
      return nome.contains(query) || apelido.contains(query);
    }).toList();
  }

  String _estrategiaLabel() {
    switch (_estrategia) {
      case 'balanceado':
        return 'Balanceado';
      default:
        return _estrategia;
    }
  }

  Widget _buildConfigResumo(ThemeData theme) {
    final dataTxt = DateFormat('dd/MM').format(_data);
    return Text(
      '$_qtdTimes times • $_qtdJogadoresPorTime jog/time • ${_estrategiaLabel()} • $dataTxt',
      style: theme.textTheme.bodySmall,
    );
  }

  Widget _buildConfigCard(BuildContext context) {
    final theme = Theme.of(context);
    final content = LayoutBuilder(
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

        final countersBox = Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceVariant.withOpacity(0.35),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: theme.colorScheme.outlineVariant),
          ),
          child: counters,
        );

        final pairBox = Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceVariant.withOpacity(0.35),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: theme.colorScheme.outlineVariant),
          ),
          child: pair,
        );

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            countersBox,
            const SizedBox(height: 12),
            pairBox,
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
                errorText: _descricaoError,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                hintText: 'Ex.: Sorteio semanal da terça-feira',
              ),
            ),

            const SizedBox(height: 10),
            _buildResumo(theme),
          ],
        );
      },
    );

    return Card(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            InkWell(
              onTap: () => setState(() => _configExpanded = !_configExpanded),
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  children: [
                    Icon(Icons.tune, color: theme.colorScheme.primary),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Configurações do sorteio',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          if (!_configExpanded) ...[
                            const SizedBox(height: 4),
                            _buildConfigResumo(theme),
                          ],
                        ],
                      ),
                    ),
                    AnimatedRotation(
                      turns: _configExpanded ? 0.5 : 0.0,
                      duration: const Duration(milliseconds: 200),
                      child: Icon(
                        Icons.expand_more,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            AnimatedSize(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeInOut,
              child: ClipRect(
                child: Align(
                  alignment: Alignment.topCenter,
                  heightFactor: _configExpanded ? 1.0 : 0.0,
                  child: content,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFiltroHeader(ThemeData theme, bool overlapsContent) {
    return _MeasureSize(
      onChange: (size) {
        if (!mounted) return;
        if ((size.height - _filterHeaderHeight).abs() > 1) {
          setState(() => _filterHeaderHeight = size.height);
        }
      },
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 6, 16, 8),
        decoration: BoxDecoration(
          color: theme.scaffoldBackgroundColor,
          boxShadow: overlapsContent
              ? [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Divider(
              height: 1,
              thickness: 1,
              color: theme.colorScheme.outlineVariant.withOpacity(0.6),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _searchCtrl,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                hintText: 'Buscar jogador',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchCtrl.text.isEmpty
                    ? null
                    : IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () {
                          _searchCtrl.clear();
                          setState(() {});
                        },
                      ),
                filled: true,
                fillColor: theme.colorScheme.surfaceVariant.withOpacity(0.25),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _posicoes.map((p) {
                final selected = _filtroPosicao == p;
                return ChoiceChip(
                  label: Text(p),
                  selected: selected,
                  onSelected: (_) => setState(() => _filtroPosicao = p),
                );
              }).toList(),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  Icons.people_alt_outlined,
                  size: 18,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 6),
                Text(
                  'Jogadores',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                _statPill(
                  theme,
                  label: 'Selecionados',
                  value: '$_selecionadosQtde',
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text('de $_necessarios', style: theme.textTheme.bodySmall),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResumo(ThemeData theme) {
    final progress = _necessarios == 0 ? 0.0 : _selecionadosQtde / _necessarios;
    final okColor = Colors.green[700] ?? theme.colorScheme.primary;
    final statusOk = _faltam == 0;
    final statusColor = statusOk ? okColor : theme.colorScheme.error;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _statPill(
              theme,
              label: 'Selecionados',
              value: '$_selecionadosQtde',
              color: theme.colorScheme.primary,
            ),
            _statPill(
              theme,
              label: 'Necessários',
              value: '$_necessarios',
              color: theme.colorScheme.secondary,
            ),
            _statPill(
              theme,
              label: statusOk ? 'Status' : 'Faltam',
              value: statusOk ? 'Completo' : '$_faltam',
              color: statusColor,
            ),
          ],
        ),
        const SizedBox(height: 10),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            minHeight: 8,
            value: progress,
            backgroundColor: theme.colorScheme.surfaceVariant,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Icon(
              statusOk ? Icons.check_circle : Icons.warning_amber_rounded,
              size: 16,
              color: statusColor,
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                statusOk
                    ? 'Capacidade completa!'
                    : 'Faltam $_faltam jogador(es) para completar a capacidade.',
                style: theme.textTheme.bodySmall?.copyWith(color: statusColor),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _statPill(
    ThemeData theme, {
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withOpacity(0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(color: color),
          ),
          const SizedBox(width: 6),
          Text(
            value,
            style: theme.textTheme.bodySmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
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
    final theme = Theme.of(context);
    final nome = (jogador['nome'] ?? '') as String;
    final avatarUrl = (jogador['foto'] as String?)?.trim();
    final id = jogador['id'] as int;
    final marcado = _selecionados.contains(id);

    final inicial = nome.isNotEmpty ? nome[0].toUpperCase() : '?';

    // Se atingiu a capacidade, bloqueia novas marcações (mas permite desmarcar)
    final bloqueado = _atingiuCapacidade && !marcado;

    final isSelected = marcado;
    final borderColor =
        isSelected ? theme.colorScheme.primary : theme.colorScheme.outlineVariant;
    final tileColor = isSelected
        ? theme.colorScheme.primary.withOpacity(0.08)
        : theme.colorScheme.surfaceVariant.withOpacity(0.2);

    return Card(
      margin: EdgeInsets.zero,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: borderColor),
      ),
      clipBehavior: Clip.antiAlias,
      child: CheckboxListTile(
        title: Text(nome),
        value: marcado,
        dense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        onChanged: bloqueado ? null : (v) => _toggleSelecionado(id, v),
        controlAffinity: ListTileControlAffinity.trailing,
        tileColor: tileColor,
        secondary: (avatarUrl != null && avatarUrl.isNotEmpty)
            ? CircleAvatar(backgroundImage: NetworkImage(avatarUrl))
            : CircleAvatar(child: Text(inicial)),
      ),
    );
  }

  // --------- Envio ao backend (two-step) ---------

  /// Dialog que coleta as médias dos IDs faltantes.
  Future<Map<int, double>?> _pedirMediasFaltantes({
    required List<int> idsFaltantes,
  }) async {
    // montar mapa id->nome para exibir
    final nomesPorId = <int, String>{};
    for (final j in _jogadores) {
      final id = (j['id'] as num).toInt();
      if (idsFaltantes.contains(id)) {
        final apelido = (j['apelido'] ?? '') as String;
        final nome = (j['nome'] ?? '') as String;
        final rotulo = (apelido.trim().isNotEmpty ? apelido : nome).trim();
        nomesPorId[id] = rotulo.isNotEmpty ? rotulo : 'Jogador $id';
      }
    }

    final formKey = GlobalKey<FormState>();
    final Map<int, TextEditingController> ctrls = {
      for (final id in idsFaltantes) id: TextEditingController(text: '3,00'),
    };

    Map<int, double>? parseMedias() {
      final out = <int, double>{};
      for (final id in idsFaltantes) {
        final raw = ctrls[id]!.text.trim().replaceAll(',', '.');
        final v = double.tryParse(raw);
        if (v == null || v < 0 || v > 5) return null;
        out[id] = double.parse(v.toStringAsFixed(2));
      }
      return out;
    }

    final result = await showDialog<Map<int, double>>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Informar médias dos convidados'),
          content: Form(
            key: formKey,
            child: SizedBox(
              width: 380,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: idsFaltantes.map((id) {
                    final nome = nomesPorId[id] ?? 'Jogador $id';
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: TextFormField(
                        controller: ctrls[id],
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: InputDecoration(
                          labelText: '$nome (ID $id)',
                          hintText: '0,00 a 5,00',
                        ),
                        validator: (v) {
                          final raw = (v ?? '').trim().replaceAll(',', '.');
                          final val = double.tryParse(raw);
                          if (val == null) return 'Informe um número';
                          if (val < 0 || val > 5) return '0 a 5';
                          return null;
                        },
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, null),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () {
                if (!formKey.currentState!.validate()) return;
                final m = parseMedias();
                if (m == null) return;
                Navigator.pop(ctx, m);
              },
              child: const Text('Usar estas médias'),
            ),
          ],
        );
      },
    );

    for (final c in ctrls.values) {
      c.dispose();
    }
    return result;
  }

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

    Map<int, double>? overrides; // id -> média (para os sem nota)

    while (true) {
      try {
        // NOVO método com require_media_for_unrated
        await ApiService.criarSorteioDuploCompleto(
          data: _data,
          descricao: desc,
          quantidadeTimes: qtdTimes,
          quantidadeJogadoresTime: qtdPorTime,
          jogadoresIds: selecionados,
          mediasOverride: overrides,
          requireMediaForUnrated: true,
        );

        if (!mounted) return;
        setState(() => _sending = false);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Dois rascunhos gerados com sucesso!')),
        );

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const RascunhosDiaPage()),
        );
        return;

      } on NeedMediaException catch (e) {
        // pede as médias e repete o loop
        setState(() => _sending = false);

        final coletadas = await _pedirMediasFaltantes(idsFaltantes: e.ids);
        if (coletadas == null) {
          _snack('Operação cancelada.');
          return;
        }
        overrides ??= {};
        overrides.addAll(coletadas);

        setState(() => _sending = true);
        // loop continua e reenviará com overrides

      } catch (e) {
        if (!mounted) return;
        setState(() => _sending = false);
        _snack('Erro ao gerar sorteios: $e');
        return;
      }
    }
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final jogadoresFiltrados = _jogadoresFiltrados();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Criar Sorteio'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : CustomScrollView(
              slivers: [
                SliverToBoxAdapter(child: _buildConfigCard(context)),
                SliverPersistentHeader(
                  pinned: true,
                  delegate: _FilterHeaderDelegate(
                    minHeight: _filterHeaderHeight,
                    maxHeight: _filterHeaderHeight,
                    builder: (context, overlapsContent) =>
                        _buildFiltroHeader(theme, overlapsContent),
                  ),
                ),
                if (jogadoresFiltrados.isEmpty)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 20, 16, 40),
                      child: Column(
                        children: [
                          Icon(
                            Icons.search_off,
                            size: 36,
                            color: theme.colorScheme.outline,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Nenhum jogador encontrado',
                            style: theme.textTheme.bodyMedium,
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Ajuste a busca ou os filtros.',
                            style: theme.textTheme.bodySmall,
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(12, 0, 12, 96),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final isLast = index == jogadoresFiltrados.length - 1;
                          return Padding(
                            padding: EdgeInsets.only(bottom: isLast ? 0 : 8),
                            child: _buildJogadorItem(jogadoresFiltrados[index]),
                          );
                        },
                        childCount: jogadoresFiltrados.length,
                      ),
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
                  : _faltam == 0
                      ? 'Gerar dois sorteios (${_selecionadosQtde}/$_necessarios)'
                      : 'Faltam $_faltam para gerar',
              style: theme.textTheme.titleSmall?.copyWith(color: Colors.white),
            ),
          ),
        ),
      ),
    );
  }
}

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
        color: theme.colorScheme.surfaceVariant.withOpacity(0.25),
        border: Border.all(color: theme.colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(12),
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
        filled: true,
        fillColor: theme.colorScheme.surfaceVariant.withOpacity(0.25),
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
          color: theme.colorScheme.surfaceVariant.withOpacity(0.25),
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

class _FilterHeaderDelegate extends SliverPersistentHeaderDelegate {
  _FilterHeaderDelegate({
    required this.minHeight,
    required this.maxHeight,
    required this.builder,
  });

  final double minHeight;
  final double maxHeight;
  final Widget Function(BuildContext context, bool overlapsContent) builder;

  @override
  double get minExtent => minHeight;

  @override
  double get maxExtent => maxHeight;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return builder(context, overlapsContent);
  }

  @override
  bool shouldRebuild(covariant _FilterHeaderDelegate oldDelegate) {
    return minHeight != oldDelegate.minHeight ||
        maxHeight != oldDelegate.maxHeight ||
        builder != oldDelegate.builder;
  }
}

class _MeasureSize extends StatefulWidget {
  const _MeasureSize({required this.onChange, required this.child});

  final ValueChanged<Size> onChange;
  final Widget child;

  @override
  State<_MeasureSize> createState() => _MeasureSizeState();
}

class _MeasureSizeState extends State<_MeasureSize> {
  Size _oldSize = Size.zero;

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final newSize = context.size;
      if (newSize == null) return;
      final widthDiff = (newSize.width - _oldSize.width).abs();
      final heightDiff = (newSize.height - _oldSize.height).abs();
      if (widthDiff > 1 || heightDiff > 1) {
        _oldSize = newSize;
        widget.onChange(newSize);
      }
    });
    return widget.child;
  }
}
