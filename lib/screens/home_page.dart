import 'package:flutter/material.dart';
import 'package:pelada_chori/screens/configuracoes_page.dart';
import 'package:pelada_chori/screens/votacao_page.dart';
import 'package:pelada_chori/screens/meus_dados_page.dart';
import 'package:pelada_chori/screens/sorteio_page.dart';
import 'package:pelada_chori/widgets/home_highlights_carousel.dart';
import 'package:pelada_chori/screens/configuracoes_page.dart';


class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  bool expandido = true;

  static const String kLogoUrl =
      'https://dapis-fotos-publicas.s3.us-east-2.amazonaws.com/logo_pelada.png';

  List<Map<String, dynamic>> getBotoesExtras(BuildContext context) => [
        {
          'label': 'Meus Dados',
          'icon': Icons.person,
          'onTap': () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const MeusDadosPage()),
          ),
        },
        {
          'label': 'Configurações', 
          'icon': Icons.settings, 
          'onTap': () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const ConfiguracoesPage()),
           ),
         }, 
        {'label': 'Sair', 'icon': Icons.logout, 'onTap': () {}},
      ];

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    final List<Map<String, dynamic>> botoesFixos = [
      {
        'label': 'Votação',
        'icon': Icons.groups,
        'onTap': () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const VotacaoPage()),
        ),
      },
      {
        'label': 'Sorteio',
        'icon': Icons.format_list_bulleted,
        'onTap': () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const SorteioPage()),
          );
        },
      },
      {'label': 'Estatísticas', 'icon': Icons.show_chart, 'onTap': () {}},
    ];

    final botoes = [...botoesFixos, if (expandido) ...getBotoesExtras(context)];

    return Scaffold(
      appBar: AppBar(
        leadingWidth: 56,
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Image.network(
            kLogoUrl,
            fit: BoxFit.contain,
            errorBuilder: (_, __, ___) =>
                Image.asset('assets/logo_pelada.png', fit: BoxFit.contain),
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Icon(Icons.menu, color: cs.primary),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // GRID
              GridView.count(
                crossAxisCount: 3,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                children: botoes.map((btn) {
                  return GestureDetector(
                    onTap: btn['onTap'],
                    child: Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: cs.primary),
                        borderRadius: BorderRadius.circular(12),
                        color: Theme.of(context).cardColor, // integra com tema
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(btn['icon'], size: 30, color: cs.onSurface),
                          const SizedBox(height: 8),
                          Text(btn['label'], style: TextStyle(color: cs.onSurface)),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),

              // COLAPSE
              Center(
                child: IconButton(
                  onPressed: () => setState(() => expandido = !expandido),
                  iconSize: 28,
                  color: cs.primary,
                  icon: Icon(expandido ? Icons.expand_less : Icons.expand_more),
                ),
              ),

              const SizedBox(height: 8),

              // TÍTULO + CARROSSEL
              Text(
                'Destaques do mês',
                style: Theme.of(context)
                    .textTheme
                    .titleLarge
                    ?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 8),
              const HomeHighlightsCarousel(),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
