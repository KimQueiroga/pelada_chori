import 'package:flutter/material.dart';
import '../theme/colors.dart';
import 'package:pelada_chori/screens/votacao_page.dart';
import 'package:pelada_chori/screens/meus_dados_page.dart';
import 'package:pelada_chori/screens/sorteio_page.dart';


class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  bool expandido = false;

    List<Map<String, dynamic>> getBotoesExtras(BuildContext context) {
    return [
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
        'onTap': () {
          // implementar depois
        },
      },
      {
        'label': 'Sair',
        'icon': Icons.logout,
        'onTap': () {
          // implementar depois
        },
      },
    ];
  }

  @override
  Widget build(BuildContext context) {
    // Definimos os botões fixos aqui dentro para acessar o context
    final List<Map<String, dynamic>> botoesFixos = [
      {
        'label': 'Votacao',
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
      {
        'label': 'Estatisticas',
        'icon': Icons.show_chart,
        'onTap': () {
          // implementar depois
        },
      },
    ];

    final botoes = [
      ...botoesFixos,
      if (expandido)
        ...getBotoesExtras(context),
                // pode personalizar ações aqui também
    ];

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Image.asset('../assets/logo_pelada.png'), // ajuste o caminho se necessário
        ),
        actions: const [
          Padding(
            padding: EdgeInsets.all(16.0),
            child: Icon(Icons.menu, color: AppColors.primary),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: GridView.count(
              padding: const EdgeInsets.all(24),
              crossAxisCount: 3,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              children: botoes.map((btn) {
                return GestureDetector(
                  onTap: btn['onTap'],
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: AppColors.primary),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(btn['icon'], size: 30),
                        const SizedBox(height: 8),
                        Text(btn['label']),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          GestureDetector(
            onTap: () {
              setState(() {
                expandido = !expandido;
              });
            },
            child: Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Icon(
                expandido ? Icons.expand_less : Icons.expand_more,
                color: AppColors.primary,
                size: 32,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
