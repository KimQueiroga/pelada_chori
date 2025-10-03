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

  // ---------- helpers ----------
  void _showSnack(String message, {bool success = true}) {
    final cs = Theme.of(context).colorScheme;
    // garante que um novo snack não empilhe no anterior
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          behavior: SnackBarBehavior.floating,
          backgroundColor:
              success ? cs.primaryContainer : cs.errorContainer,
          // em cores claras/esc    uras alterna bem:
          action: null,
        ),
      );
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
      _showSnack('Erro ao carregar jogadores', success: false);
    }
  }

  Future<void> enviarVoto() async {
    setState(() => enviando = true);

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt_token') ?? '';
    final jogador = jogadoresParaVotar[indiceAtual];

    final displayName = ((jogador['apelido'] ?? '') as String).trim().isNotEmpty
        ? (jogador['apelido'] as String).trim()
        : ((jogador['nome'] ?? '') as String).trim();

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
        // se quiser ir para o próximo automaticamente, indiceAtual já aponta para o 0 do restante
      });

      // feedback imediato
      _showSnack('Voto enviado para ${displayName.isEmpty ? "jogador" : displayName}');

      if (jogadoresParaVotar.isEmpty) {
        await showDialog(
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
        );
        if (mounted) Navigator.pop(context);
      }
    } else {
      setState(() => enviando = false);
      _showSnack('Erro ao enviar voto', success: false);
    }
  }

  void pularJogador() {
    // pega o nome antes de remover para mostrar no snackbar
    final jogador = jogadoresParaVotar[indiceAtual];
    final displayName = ((jogador['apelido'] ?? '') as String).trim().isNotEmpty
        ? (jogador['apelido'] as String).trim()
        : ((jogador['nome'] ?? '') as String).trim();

    setState(() {
      jogadoresParaVotar.removeAt(indiceAtual);
    });

    _showSnack('Você pulou ${displayName.isEmpty ? "o jogador" : displayName}');

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
      ).then((_) {
        if (mounted) Navigator.pop(context);
      });
    }
  }

  // ---------- UI ----------
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
                    // Avatar com inicial quando não há foto
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
                    divisions: 8,
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
