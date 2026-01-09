import 'package:flutter/material.dart';
import 'package:pelada_chori/services/api_service.dart';

class EstatisticasPage extends StatefulWidget {
  const EstatisticasPage({super.key, this.initialStat});

  final String? initialStat;

  @override
  State<EstatisticasPage> createState() => _EstatisticasPageState();
}

class _EstatisticasPageState extends State<EstatisticasPage> {
  static const _meses = <String>[
    'Jan',
    'Fev',
    'Mar',
    'Abr',
    'Mai',
    'Jun',
    'Jul',
    'Ago',
    'Set',
    'Out',
    'Nov',
    'Dez',
  ];

  final _estatisticas = const <_Option<String>>[
    _Option('vitorias', 'Vitórias'),
    _Option('gols', 'Gols'),
    _Option('assistencias', 'Assistências'),
  ];

  bool _loading = true;
  String? _erro;
  List<_StatItem> _items = const [];

  List<Map<String, dynamic>> _jogadores = const [];
  int? _ano;
  int? _mes;
  int? _jogadorId;
  late String _estatistica;

  @override
  void initState() {
    super.initState();
    _estatistica = widget.initialStat ?? 'vitorias';
    _carregarJogadores();
    _carregarStats(showLoading: true);
  }

  Future<void> _carregarJogadores() async {
    try {
      final lista = await ApiService.getJogadoresTodos();
      if (!mounted) return;
      lista.sort((a, b) {
        final la = _playerLabel(a);
        final lb = _playerLabel(b);
        return la.compareTo(lb);
      });
      setState(() {
        _jogadores = lista;
      });
    } catch (_) {}
  }

  Future<void> _carregarStats({bool showLoading = false}) async {
    if (showLoading && mounted) {
      setState(() {
        _loading = true;
        _erro = null;
      });
    }

    try {
      final lista = await ApiService.getEstatisticasAnaliticas(
        ano: _ano,
        mes: _mes,
        jogadorId: _jogadorId,
        estatistica: _estatistica,
        limite: 50,
      );
      if (!mounted) return;
      setState(() {
        _items = lista.map(_StatItem.fromMap).toList();
        _loading = false;
        _erro = null;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _erro = 'Erro ao carregar estatísticas.';
      });
    }
  }

  String _playerLabel(Map<String, dynamic> j) {
    final apelido = (j['apelido'] ?? '').toString().trim();
    final nome = (j['nome'] ?? '').toString().trim();
    if (apelido.isNotEmpty) return apelido;
    if (nome.isNotEmpty) return nome;
    return 'Jogador ${j['id']}';
  }

  String _estatisticaLabel(String key) {
    return _estatisticas
        .firstWhere(
          (e) => e.value == key,
          orElse: () => const _Option('vitorias', 'Vitórias'),
        )
        .label;
  }

  Future<void> _selecionarAno() async {
    final agora = DateTime.now().year;
    final anos = List.generate(6, (i) => agora - i);
    final opt = <_Option<int?>>[
      const _Option<int?>(null, 'Todos'),
      ...anos.map((a) => _Option<int?>(a, a.toString())),
    ];
    final escolhido = await _showOptions<int?>(
      title: 'Ano',
      options: opt,
      selected: _ano,
    );
    if (escolhido != _ano) {
      setState(() => _ano = escolhido);
      _carregarStats(showLoading: true);
    }
  }

  Future<void> _selecionarMes() async {
    final opt = <_Option<int?>>[
      const _Option<int?>(null, 'Todos'),
      ...List.generate(
        12,
        (i) => _Option<int?>(i + 1, _meses[i]),
      ),
    ];
    final escolhido = await _showOptions<int?>(
      title: 'Mês',
      options: opt,
      selected: _mes,
    );
    if (escolhido != _mes) {
      setState(() => _mes = escolhido);
      _carregarStats(showLoading: true);
    }
  }

  Future<void> _selecionarJogador() async {
    if (_jogadores.isEmpty) {
      _carregarJogadores();
    }
    final opt = <_Option<int?>>[
      const _Option<int?>(null, 'Todos'),
      ..._jogadores.map(
        (j) => _Option<int?>(
          (j['id'] as num?)?.toInt(),
          _playerLabel(j),
        ),
      ),
    ];
    final escolhido = await _showOptions<int?>(
      title: 'Jogador',
      options: opt,
      selected: _jogadorId,
    );
    if (escolhido != _jogadorId) {
      setState(() => _jogadorId = escolhido);
      _carregarStats(showLoading: true);
    }
  }

  Future<void> _selecionarEstatistica() async {
    final escolhido = await _showOptions<String>(
      title: 'Estatística',
      options: _estatisticas,
      selected: _estatistica,
    );
    if (escolhido != null && escolhido != _estatistica) {
      setState(() => _estatistica = escolhido);
      _carregarStats(showLoading: true);
    }
  }

  Future<T?> _showOptions<T>({
    required String title,
    required List<_Option<T>> options,
    required T? selected,
  }) {
    return showModalBottomSheet<T>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return _OptionSheet<T>(
          title: title,
          options: options,
          selected: selected,
        );
      },
    );
  }

  void _resetFiltros() {
    setState(() {
      _ano = null;
      _mes = null;
      _jogadorId = null;
      _estatistica = widget.initialStat ?? 'vitorias';
    });
    _carregarStats(showLoading: true);
  }

  Widget _sectionCard(Widget child, ColorScheme cs) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: cs.primary.withOpacity(0.15)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final bgTop = cs.background;
    final bgBottom = Color.lerp(cs.background, cs.primary, 0.04) ?? cs.background;
    final textStrong = cs.onBackground;
    final textMuted = cs.onBackground.withOpacity(0.6);
    final pillBorder = cs.primary.withOpacity(0.5);

    return Scaffold(
      backgroundColor: bgBottom,
      appBar: AppBar(
        backgroundColor: bgTop,
        elevation: 0,
        title: Text(
          'Estatísticas',
          style: TextStyle(
            color: textStrong,
            fontWeight: FontWeight.w600,
          ),
        ),
        iconTheme: IconThemeData(color: textStrong),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [bgTop, bgBottom],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                child: _sectionCard(
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Filtros',
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: [
                          _FilterButton(
                            label: 'Ano',
                            value: _ano?.toString() ?? 'Todos',
                            borderColor: pillBorder,
                            fillColor: cs.surfaceVariant.withOpacity(0.45),
                            textColor: textStrong,
                            onTap: _selecionarAno,
                          ),
                          _FilterButton(
                            label: 'Mês',
                            value: (_mes != null && _mes! >= 1 && _mes! <= 12)
                                ? _meses[_mes! - 1]
                                : 'Todos',
                            borderColor: pillBorder,
                            fillColor: cs.surfaceVariant.withOpacity(0.45),
                            textColor: textStrong,
                            onTap: _selecionarMes,
                          ),
                          _FilterButton(
                            label: 'Tipo',
                            value: _estatisticaLabel(_estatistica),
                            borderColor: pillBorder,
                            fillColor: cs.surfaceVariant.withOpacity(0.45),
                            textColor: textStrong,
                            onTap: _selecionarEstatistica,
                          ),
                          _FilterButton(
                            label: 'Jogador',
                            value: _jogadorId == null
                                ? 'Todos'
                                : _jogadores.isEmpty
                                    ? 'Jogador $_jogadorId'
                                    : _playerLabel(
                                        _jogadores.firstWhere(
                                          (j) =>
                                              (j['id'] as num?)?.toInt() == _jogadorId,
                                          orElse: () => const {},
                                        ),
                                      ),
                            borderColor: pillBorder,
                            fillColor: cs.surfaceVariant.withOpacity(0.45),
                            textColor: textStrong,
                            onTap: _selecionarJogador,
                          ),
                          OutlinedButton.icon(
                            onPressed: _resetFiltros,
                            style: OutlinedButton.styleFrom(
                              side: BorderSide(color: pillBorder),
                              foregroundColor: textStrong,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 10,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            icon: const Icon(Icons.refresh, size: 18),
                            label: const Text('Reset'),
                          ),
                        ],
                      ),
                    ],
                  ),
                  cs,
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: _sectionCard(
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              'Resultados',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(fontWeight: FontWeight.w800),
                            ),
                            const Spacer(),
                            Text(
                              _estatisticaLabel(_estatistica),
                              style: TextStyle(
                                color: cs.primary,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${_items.length} registros',
                          style: TextStyle(color: textMuted),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            SizedBox(
                              width: 44,
                              child: Text(
                                'Rank',
                                style: TextStyle(color: textMuted),
                              ),
                            ),
                            Expanded(
                              child: Text(
                                'Jogador',
                                style: TextStyle(color: textMuted),
                              ),
                            ),
                            Text(
                              _estatisticaLabel(_estatistica),
                              style: TextStyle(color: textMuted),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Expanded(
                          child: _loading
                              ? Center(
                                  child: CircularProgressIndicator(
                                    color: cs.primary,
                                  ),
                                )
                              : _erro != null
                                  ? Center(
                                      child: Text(
                                        _erro!,
                                        style: TextStyle(color: textStrong),
                                      ),
                                    )
                                  : _items.isEmpty
                                      ? Center(
                                          child: Column(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Opacity(
                                                opacity: 0.35,
                                                child: Image.asset(
                                                  'assets/logo_pelada.png',
                                                  width: 72,
                                                  height: 72,
                                                ),
                                              ),
                                              const SizedBox(height: 12),
                                              Text(
                                                'Sem dados',
                                                style: TextStyle(
                                                  color: textStrong,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            ],
                                          ),
                                        )
                                      : RefreshIndicator(
                                          onRefresh: () =>
                                              _carregarStats(showLoading: true),
                                          child: ListView.separated(
                                            padding:
                                                const EdgeInsets.fromLTRB(0, 0, 0, 8),
                                            itemCount: _items.length,
                                            separatorBuilder: (_, __) => Divider(
                                              height: 16,
                                              color: cs.onSurface.withOpacity(0.08),
                                            ),
                                            itemBuilder: (context, index) {
                                              final item = _items[index];
                                              return Padding(
                                                padding: const EdgeInsets.symmetric(
                                                  horizontal: 4,
                                                  vertical: 2,
                                                ),
                                                child: Row(
                                                  children: [
                                                    Container(
                                                      width: 32,
                                                      height: 32,
                                                      alignment: Alignment.center,
                                                      decoration: BoxDecoration(
                                                        color:
                                                            cs.primary.withOpacity(0.12),
                                                        borderRadius:
                                                            BorderRadius.circular(10),
                                                      ),
                                                      child: Text(
                                                        '${index + 1}',
                                                        style: TextStyle(
                                                          color: cs.primary,
                                                          fontWeight: FontWeight.w800,
                                                        ),
                                                      ),
                                                    ),
                                                    const SizedBox(width: 12),
                                                    Expanded(
                                                      child: Text(
                                                        item.nome,
                                                        style: TextStyle(
                                                          color: textStrong,
                                                          fontWeight: FontWeight.w700,
                                                          fontSize: 16,
                                                        ),
                                                      ),
                                                    ),
                                                    Container(
                                                      padding: const EdgeInsets.symmetric(
                                                        horizontal: 10,
                                                        vertical: 4,
                                                      ),
                                                      decoration: BoxDecoration(
                                                        color:
                                                            cs.primary.withOpacity(0.12),
                                                        borderRadius:
                                                            BorderRadius.circular(10),
                                                      ),
                                                      child: Text(
                                                        '${item.valor}',
                                                        style: TextStyle(
                                                          color: cs.primary,
                                                          fontWeight: FontWeight.w800,
                                                          fontSize: 14,
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              );
                                            },
                                          ),
                                        ),
                        ),
                      ],
                    ),
                    cs,
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatItem {
  final int jogadorId;
  final String nome;
  final int valor;

  const _StatItem({
    required this.jogadorId,
    required this.nome,
    required this.valor,
  });

  factory _StatItem.fromMap(Map<String, dynamic> map) {
    final nome = (map['nome'] ?? '').toString().trim();
    return _StatItem(
      jogadorId: (map['jogador_id'] as num?)?.toInt() ?? 0,
      nome: nome.isEmpty ? 'Jogador' : nome,
      valor: (map['valor'] as num?)?.toInt() ??
          int.tryParse((map['valor'] ?? '0').toString()) ??
          0,
    );
  }
}

class _FilterButton extends StatelessWidget {
  const _FilterButton({
    required this.label,
    required this.value,
    required this.onTap,
    required this.borderColor,
    required this.fillColor,
    required this.textColor,
  });

  final String label;
  final String value;
  final VoidCallback onTap;
  final Color borderColor;
  final Color fillColor;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: label,
      child: OutlinedButton(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: borderColor),
          foregroundColor: textColor,
          backgroundColor: fillColor,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('$value '),
            const Icon(Icons.expand_more, size: 18),
          ],
        ),
      ),
    );
  }
}

class _Option<T> {
  final T value;
  final String label;

  const _Option(this.value, this.label);
}

class _OptionSheet<T> extends StatelessWidget {
  const _OptionSheet({
    required this.title,
    required this.options,
    required this.selected,
  });

  final String title;
  final List<_Option<T>> options;
  final T? selected;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final sheetColor = cs.surface;
    final textStrong = cs.onSurface;

    return Container(
      decoration: BoxDecoration(
        color: sheetColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: textStrong.withOpacity(0.25),
                borderRadius: BorderRadius.circular(999),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: textStrong,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: options.length,
                separatorBuilder: (_, __) => Divider(
                  height: 1,
                  color: textStrong.withOpacity(0.08),
                ),
                itemBuilder: (context, index) {
                  final opt = options[index];
                  final isSelected = opt.value == selected;
                  return ListTile(
                    title: Text(
                      opt.label,
                      style: TextStyle(color: textStrong),
                    ),
                    trailing: isSelected
                        ? Icon(Icons.check, color: textStrong)
                        : null,
                    onTap: () => Navigator.pop(context, opt.value),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
