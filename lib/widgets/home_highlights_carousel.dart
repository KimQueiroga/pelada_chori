import 'package:flutter/material.dart';

class StatEntry {
  final String nome;
  final int valor;
  const StatEntry(this.nome, this.valor);
}

class HomeHighlightsCarousel extends StatefulWidget {
  const HomeHighlightsCarousel({super.key});

  @override
  State<HomeHighlightsCarousel> createState() => _HomeHighlightsCarouselState();
}

class _HomeHighlightsCarouselState extends State<HomeHighlightsCarousel> {
  int _index = 0;

  // MOCKS – troque pelos dados reais depois
  final _vitorias = const [
    StatEntry('Igor', 13),
    StatEntry('Fernando', 12),
    StatEntry('Kim', 11),
    StatEntry('Pablo', 11),
    StatEntry('Paulinho', 10),
  ];
  final _gols = const [
    StatEntry('Michael', 11),
    StatEntry('Pablo', 7),
    StatEntry('Paulinho', 4),
    StatEntry('Kim', 4),
    StatEntry('Diego', 3),
  ];
  final _assist = const [
    StatEntry('Paulinho', 6),
    StatEntry('Igor', 5),
    StatEntry('Fernando', 4),
    StatEntry('Darlan', 3),
    StatEntry('Leo', 3),
  ];

  // breakpoints responsivos
  double _fractionForWidth(double w) {
    if (w < 360) return 0.92;
    if (w < 480) return 0.88;
    if (w < 840) return 0.86;
    return 0.80;
  }

  double _heightForWidth(double w) {
    if (w < 360) return 170;
    if (w < 480) return 190;
    if (w < 840) return 210;
    return 230;
  }

  double _itemExtentForWidth(double w) {
    if (w < 360) return 26;
    if (w < 480) return 28;
    return 30;
  }

  @override
  Widget build(BuildContext context) {
    final cards = <_Top5Card>[
      _Top5Card(title: 'Top 5 Vitórias', items: _vitorias),
      _Top5Card(title: 'Top 5 Gols', items: _gols),
      _Top5Card(title: 'Top 5 Assistências', items: _assist),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;
        final h = _heightForWidth(w);
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
  });

  final String title;
  final List<StatEntry> items;
  final double? itemExtentOverride;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final max = (items.isEmpty) ? 1 : items.map((e) => e.valor).reduce((a, b) => a > b ? a : b);
    final itemExtent = itemExtentOverride ?? 30.0;

    final Color primary = cs.primary;
    final Color track = primary.withOpacity(0.18);
    final Color badgeBg = primary.withOpacity(0.12);
    final Color cardBg = Theme.of(context).cardColor;
    final Color textStrong = cs.onSurface;

    return Card(
      elevation: 1.5,
      color: cardBg,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: cs.primary.withOpacity(0.20)),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cabeçalho
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
                  onPressed: () {},
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                    minimumSize: const Size(0, 0),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    visualDensity: VisualDensity.compact,
                    foregroundColor: textStrong.withOpacity(0.60),
                  ),
                  child: const Text('Ver detalhes'),
                ),
              ],
            ),
            const SizedBox(height: 6),

            // Lista compacta
            Expanded(
              child: ListView.builder(
                padding: EdgeInsets.zero,
                physics: const ClampingScrollPhysics(),
                itemCount: items.length,
                itemExtent: itemExtent,
                itemBuilder: (context, i) {
                  final e = items[i];
                  final frac = (e.valor / max).clamp(0.0, 1.0);
                  return Row(
                    children: [
                      // posição
                      Container(
                        width: 22,
                        height: 22,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: badgeBg,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '${i + 1}',
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
                            height: 8,
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
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
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
