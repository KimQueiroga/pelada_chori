import 'package:flutter/material.dart';
import '../../services/api_service.dart';

class SelecionarJogadoresPage extends StatefulWidget {
  const SelecionarJogadoresPage({Key? key}) : super(key: key);

  @override
  _SelecionarJogadoresPageState createState() => _SelecionarJogadoresPageState();
}

class _SelecionarJogadoresPageState extends State<SelecionarJogadoresPage> {
  List<Map<String, dynamic>> _jogadores = [];
  List<int> _jogadoresSelecionados = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _buscarJogadores();
  }

  Future<void> _buscarJogadores() async {
    try {
      final dados = await ApiService.getJogadoresTodos();
      setState(() {
        _jogadores = dados;
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Erro ao carregar jogadores')),
      );
    }
  }

  Widget _buildJogadorItem(Map<String, dynamic> jogador) {
    final nome = jogador['nome'] ?? '';
    final avatarUrl = jogador['foto'];
    final isSelected = _jogadoresSelecionados.contains(jogador['id']);

    return CheckboxListTile(
      title: Text(nome),
      value: isSelected,
      onChanged: (bool? selected) {
        setState(() {
          if (selected == true) {
            _jogadoresSelecionados.add(jogador['id']);
          } else {
            _jogadoresSelecionados.remove(jogador['id']);
          }
        });
      },
      secondary: avatarUrl != null
          ? CircleAvatar(backgroundImage: NetworkImage(avatarUrl))
          : CircleAvatar(child: Text(nome.isNotEmpty ? nome[0].toUpperCase() : '?')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Criar Sorteio')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text(
                    'Selecione os jogadores para o sorteio:',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    itemCount: _jogadores.length,
                    itemBuilder: (context, index) {
                      return _buildJogadorItem(_jogadores[index]);
                    },
                  ),
                ),
              ],
            ),
    );
  }
}
