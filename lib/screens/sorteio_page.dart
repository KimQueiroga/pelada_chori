import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/api_service.dart';
import '../models/sorteio_simplificado_model.dart';
import 'selecionar_jogadores_page.dart';
import 'sorteio_detalhe_page.dart';
import '../models/sorteio_detalhe_model.dart';
import '../../utils/app_date.dart';




class SorteioPage extends StatefulWidget {
  const SorteioPage({Key? key}) : super(key: key);

  @override
  State<SorteioPage> createState() => _SorteioPageState();
}

class _SorteioPageState extends State<SorteioPage> {
  List<SorteioSimplificadoModel> _sorteios = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _carregarSorteios();
  }

  Future<void> _carregarSorteios() async {
    try {
      final sorteios = await ApiService.getSorteiosAtivos();
      setState(() {
        _sorteios = sorteios;
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Erro ao carregar sorteios ativos')),
      );
    }
  }

  Widget _buildSorteioItem(SorteioSimplificadoModel sorteio) {
    final dataFormatada = AppDate.brFromApi(sorteio.data);
    return GestureDetector(
      onTap: () async {
        final detalhe = await ApiService.getSorteioDetalhe(sorteio.id);
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => SorteioDetalhePage(sorteio: detalhe),
          ),
        );
      },
      child: Stack(
        children: [
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            elevation: 4,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Sorteio nº ${sorteio.numero}',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text('Data: $dataFormatada'),
                  if (sorteio.descricao.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        sorteio.descricao,
                        style: const TextStyle(color: Colors.grey),
                      ),
                    ),
                  const Align(
                    alignment: Alignment.bottomRight,
                    child: Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            top: 0,
            right: 0,
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.redAccent,
                borderRadius: BorderRadius.only(
                  topRight: Radius.circular(16),
                  bottomLeft: Radius.circular(8),
                ),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: const Text(
                'ABERTO',
                style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Sorteios Ativos')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _sorteios.isEmpty
              ? const Center(child: Text('Nenhum sorteio ativo encontrado.'))
              : ListView.builder(
                  itemCount: _sorteios.length,
                  itemBuilder: (context, index) => _buildSorteioItem(_sorteios[index]),
                ),
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.add),
        label: const Text('Novo Sorteio'),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const SelecionarJogadoresPage()),
          );
        },
      ),
    );
  }
}
