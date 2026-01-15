import 'dart:async';

import 'package:flutter/material.dart';
import 'package:pelada_chori/screens/estatisticas_page.dart';
import 'package:pelada_chori/services/api_service.dart';

class StatEntry {
  final String nome;
  final int valor;
  final int posicao;
  const StatEntry(this.nome, this.valor, this.posicao);
}

class HomeHighlightsCarousel extends StatefulWidget {
  const HomeHighlightsCarousel({super.key});

  @override
  State<HomeHighlightsCarousel> createState() => _HomeHighlightsCarouselState();
}

class _Top5CardData {
  final String title;
  final String statKey;
  final List<StatEntry> items;

  const _Top5CardData({
    required this.title,
    required this.statKey,
    required this.items,
  });
}

class _HomeHighlightsCarouselState extends State<HomeHighlightsCarousel> {
  int _index = 0;
  bool _loading = true;
  String? _erro;
  List<StatEntry> _vitorias = const [];
  List<StatEntry> _gols = const [];
  List<StatEntry> _assist = const [];
  bool _fetching = false;
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _carregarDestaques(showLoading: true);
    _refreshTimer = Timer.periodic(
      const Duration(minutes: 30),
      (_) => _carregarDestaques(),
    );
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _carregarDestaques({bool showLoading = false}) async {
    if (_fetching) return;
    _fetching = true;
    if (showLoading && mounted) {
      setState(() {
        _loading = true;
        _erro = null;
      });
    }

    try {
      final resp = await ApiService.getDestaquesDoMes();
      if (!mounted) return;
      setState(() {
        _vitorias = _mapEntries(resp.vitorias);
        _gols = _mapEntries(resp.gols);
        _assist = _mapEntries(resp.assistencias);
        _loading = false;
        _erro = null;
      });
    } catch (_) {
      if (mounted) {
        final hasData =
            _vitorias.isNotEmpty || _gols.isNotEmpty || _assist.isNotEmpty;
        if (showLoading || !hasData) {
          setState(() {
            _loading = false;
            _erro = 'Erro ao carregar destaques.';
          });
        } else {
          setState(() {
            _loading = false;
          });
        }
      }
    } finally {
      _fetching = false;
    }
  }

  List<StatEntry> _mapEntries(List<Map<String, dynamic>> raw) {
    final items = <StatEntry>[];
    for (var i = 0; i < raw.length; i++) {
      final e = raw[i];
      final nome = (e['nome'] ?? '').toString().trim();
      final valor = (e['valor'] is num)
          ? (e['valor'] as num).toInt()
          : int.tryParse((e['valor'] ?? '0').toString()) ?? 0;
      final posicao = (e['posicao'] as num?)?.toInt() ?? (i + 1);
      items.add(StatEntry(nome.isEmpty ? 'Jogador' : nome, valor, posicao));
    }
    return items;
  }

  // breakpoints responsivos
  double _fractionForWidth(double w) {
    if (w < 360) return 0.92;
    if (w < 480) return 0.88;
    if (w < 840) return 0.86;
    return 0.80;
  }

  double _heightForWidth(double w) {
    if (w < 360) return 182;
    if (w < 480) return 200;
    if (w < 840) return 220;
    return 240;
  }

  double _itemExtentForWidth(double w) {
    if (w < 360) return 28;
    if (w < 480) return 30;
    return 32;
  }

  @override
  Widget build(BuildContext context) {
    final cards = <_Top5CardData>[
      _Top5CardData(
        title: 'Top 5 Vitorias',
        statKey: 'vitorias',
        items: _vitorias,
      ),
      _Top5CardData(
        title: 'Top 5 Gols',
        statKey: 'gols',
        items: _gols,
      ),
      _Top5CardData(
        title: 'Top 5 Assistencias',
        statKey: 'assistencias',
        items: _assist,
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;
        final h = _heightForWidth(w);

        if (_loading) {
          return SizedBox(
            height: h,
            child: const Center(child: CircularProgressIndicator()),
          );
        }

        if (_erro != null) {
          return SizedBox(
            height: h,
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _erro!,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: () => _carregarDestaques(showLoading: true),
                    child: const Text('Tentar novamente'),
                  ),
                ],
              ),
            ),
          );
        }

        final fraction = _fractionForWidth(w);
        final itemExtent = _itemExtentForWidth(w);
        final controller = PageController(viewportFraction: fraction);

        return SizedBox(
          height: h,
          child: Stack(
            alignment: Alignment.bottomCenter,
            children: [
              PageView.builder(
                controller: controller,
                onPageChanged: (i) => setState(() => _index = i),
                allowImplicitScrolling: true,
                padEnds: false,
                clipBehavior: Clip.none,
                itemCount: cards.length,
                itemBuilder: (_, i) => Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: _Top5Card(
                    title: cards[i].title,
                    items: cards[i].items,
                    itemExtentOverride: itemExtent,
                    onDetails: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => EstatisticasPage(
                            initialStat: cards[i].statKey,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
              Positioned(
                bottom: 6,
                child: _Dots(count: cards.length, index: _index),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _Top5Card extends StatelessWidget {
  const _Top5Card({
    required this.title,
    required this.items,
    this.itemExtentOverride,
    this.onDetails,
  });

  final String title;
  final List<StatEntry> items;
  final double? itemExtentOverride;
  final VoidCallback? onDetails;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final max = (items.isEmpty)
        ? 1
        : items.map((e) => e.valor).reduce((a, b) => a > b ? a : b);
    final safeMax = max <= 0 ? 1 : max;
    final itemExtent = itemExtentOverride ?? 30.0;
    final hasItems = items.isNotEmpty;

    final Color primary = cs.primary;
    final Color track = primary.withOpacity(0.16);
    final Color badgeBg = primary.withOpacity(0.12);
    final Color cardBg = cs.surface;
    final Color textStrong = cs.onSurface;

    return Card(
      elevation: 2.0,
      color: cardBg,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: cs.primary.withOpacity(0.16)),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cabecalho
            Row(
              children: [
                Text(
                  title,
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: textStrong,
                  ),
                ),
                const Spacer(),
                TextButton(
                  onPressed: onDetails,
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                    minimumSize: const Size(0, 0),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    visualDensity: VisualDensity.compact,
                    foregroundColor: textStrong.withOpacity(0.50),
                  ),
                  child: const Text('Ver detalhes'),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Lista compacta
            Expanded(
              child: hasItems
                  ? ListView.builder(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      physics: const ClampingScrollPhysics(),
                      itemCount: items.length,
                      itemExtent: itemExtent,
                      itemBuilder: (context, i) {
                        final e = items[i];
                        final frac = (e.valor / safeMax).clamp(0.0, 1.0);
                        return Row(
                          children: [
                            // posicao
                            Container(
                              width: 22,
                              height: 22,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: badgeBg,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                '${e.posicao}',
                                style: textTheme.labelMedium?.copyWith(
                                  fontWeight: FontWeight.w800,
                                  color: textStrong,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            // nome
                            Expanded(
                              flex: 32,
                              child: Text(
                                e.nome,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: textTheme.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: textStrong,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            // barra
                            Expanded(
                              flex: 60,
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: SizedBox(
                                  height: 10,
                                  child: Stack(
                                    children: [
                                      Container(color: track),
                                      FractionallySizedBox(
                                        widthFactor: frac,
                                        child: Container(color: primary),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            // valor
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: badgeBg,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                '${e.valor}',
                                style: textTheme.labelLarge?.copyWith(
                                  fontWeight: FontWeight.w800,
                                  color: textStrong,
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    )
                  : Center(
                      child: Text(
                        'Sem dados',
                        style: textTheme.bodyMedium?.copyWith(
                          color: textStrong.withOpacity(0.6),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Dots extends StatelessWidget {
  const _Dots({required this.count, required this.index});
  final int count;
  final int index;

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).colorScheme.primary;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(count, (i) {
        final active = i == index;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 240),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: active ? 18 : 7,
          height: 7,
          decoration: BoxDecoration(
            color: active ? c : c.withOpacity(0.25),
            borderRadius: BorderRadius.circular(999),
          ),
        );
      }),
    );
  }
}
