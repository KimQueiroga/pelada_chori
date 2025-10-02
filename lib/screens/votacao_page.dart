import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../config/api_config.dart';
import '../theme/colors.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pelada_chori/shared/widgets/avatar_inicial.dart';

class VotacaoPage extends StatefulWidget {
  const VotacaoPage({super.key});

  @override
  State<VotacaoPage> createState() => _VotacaoPageState();
}

class _VotacaoPageState extends State<VotacaoPage> {
  List<dynamic> jogadoresParaVotar = [];
  int indiceAtual = 0;
  bool loading = true;
  bool enviando = false;

  final Map<String, double> notas = {
    'tecnica': 3.0,
    'inteligencia': 3.0,
    'velocidade_preparo': 3.0,
    'disciplina_tatica': 3.0,
    'poder_ofensivo': 3.0,
    'poder_defensivo': 3.0,
    'fundamentos_basicos': 3.0,
  };

  @override
  void initState() {
    super.initState();
    carregarJogadoresParaVotar();
  }

  Future<void> carregarJogadoresParaVotar() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt_token') ?? '';

    final response = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/jogadores'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      setState(() {
        jogadoresParaVotar = data;
        loading = false;
      });
    } else {
      setState(() => loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Erro ao carregar jogadores')),
      );
    }
  }

  Future<void> enviarVoto() async {
    setState(() => enviando = true);

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt_token') ?? '';
    final jogador = jogadoresParaVotar[indiceAtual];

    final response = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/votos'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: jsonEncode({
        'jogador_destino_id': jogador['id'],
        'notas': notas,
      }),
    );

    if (response.statusCode == 201) {
      setState(() {
        jogadoresParaVotar.removeAt(indiceAtual);
        enviando = false;
      });

      if (jogadoresParaVotar.isEmpty) {
        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('Obrigado!'),
            content: const Text('Você completou todas as votações disponíveis.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
            ],
          ),
        ).then((_) => Navigator.pop(context));
      }
    } else {
      setState(() => enviando = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Erro ao enviar voto')),
      );
    }
  }

  void pularJogador() {
    setState(() {
      jogadoresParaVotar.removeAt(indiceAtual);
    });

    if (jogadoresParaVotar.isEmpty) {
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Fim da votação'),
          content: const Text('Você finalizou ou pulou todos os jogadores.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        ),
      ).then((_) => Navigator.pop(context));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (jogadoresParaVotar.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Votação')),
        body: const Center(
          child: Text('Nenhum jogador disponível para votar.'),
        ),
      );
    }

    final jogador = jogadoresParaVotar[indiceAtual];

    // Campos usados no header
    final numeroCamisa = (jogador['numero_camisa']?.toString() ?? '').trim();
    final nome = (jogador['nome'] ?? '').toString();
    final apelido = (jogador['apelido'] ?? '').toString();
    final posicao = (jogador['posicao'] ?? '').toString();
    final displayName =
        apelido.trim().isNotEmpty ? apelido.trim() : (nome.trim().isNotEmpty ? nome.trim() : 'Jogador');
    final fotoUrl = (jogador['foto'] ?? jogador['fotoUrl'] ?? '').toString();

    return Scaffold(
      appBar: AppBar(title: const Text('Votação')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Row(
                children: [
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            numeroCamisa,
                            style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
                          ),
                          Text(
                            nome,
                            style: const TextStyle(fontSize: 16),
                          ),
                          Text(
                            displayName,
                            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                          ),
                          Text(
                            posicao,
                            style: const TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(12.0),
                    // >>> Substituição do default_avatar.png pelo AvatarInicial <<<
                    child: AvatarInicial(
                      displayName: displayName,
                      photoUrl: fotoUrl, // vazio/null => inicial; erro de load => inicial
                      radius: 40,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            ...notas.entries.map(
              (entry) => Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    entry.key.replaceAll('_', ' ').toUpperCase(),
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Slider(
                    value: entry.value,
                    min: 1,
                    max: 5,
                    divisions: 8, // mantém seu padrão atual
                    label: entry.value.toString(),
                    onChanged: (value) {
                      setState(() {
                        notas[entry.key] = value;
                      });
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            enviando
                ? const Center(child: CircularProgressIndicator())
                : Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: pularJogador,
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.primary,
                            side: const BorderSide(color: AppColors.primary),
                            minimumSize: const Size.fromHeight(50),
                          ),
                          child: const Text('Pular Jogador'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: enviarVoto,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: AppColors.textLight,
                            minimumSize: const Size.fromHeight(50),
                          ),
                          child: const Text('Próximo'),
                        ),
                      ),
                    ],
                  ),
          ],
        ),
      ),
    );
  }
}
