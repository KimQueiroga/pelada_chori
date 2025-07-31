import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../models/sorteio_simplificado_model.dart';
import 'selecionar_jogadores_page.dart';
import 'sorteio_detalhe_page.dart';
import '../models/sorteio_detalhe_model.dart';
import '../../utils/app_date.dart';
import 'rascunhos_dia_page.dart';

class SorteioPage extends StatefulWidget {
  const SorteioPage({Key? key}) : super(key: key);

  @override
  State<SorteioPage> createState() => _SorteioPageState();
}

class _SorteioPageState extends State<SorteioPage> {
  List<SorteioSimplificadoModel> _sorteios = [];
  bool _loading = true;

  // + flag: existem rascunhos hoje?
  bool _temRascunhosHoje = false;

  @override
  void initState() {
    super.initState();
    _carregarTudo();
  }

  Future<void> _carregarTudo() async {
    await Future.wait([
      _carregarSorteios(),
      _verificarRascunhosHoje(),
    ]);
  }

  Future<void> _carregarSorteios() async {
    try {
      final sorteios = await ApiService.getSorteiosAtivos();
      if (!mounted) return;
      setState(() {
        _sorteios = sorteios;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao carregar sorteios ativos: $e')),
      );
    }
  }

  // + consulta rascunhos do dia
  Future<void> _verificarRascunhosHoje() async {
    try {
      final rasc = await ApiService.getRascunhosDoDia();
      if (!mounted) return;
      setState(() => _temRascunhosHoje = rasc.isNotEmpty);
    } catch (_) {
      // silencioso; não é crítico
    }
  }

  void _abrirRascunhos() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const RascunhosDiaPage()),
    ).then((_) {
      // Ao voltar, recarrega lista e status do banner
      _carregarTudo();
    });
  }

  void _abrirNovoSorteio() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const SelecionarJogadoresPage()),
    ).then((_) => _carregarTudo());
  }

  // + bottom sheet do FAB com 2 ações
  void _abrirMenuAcoes() {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.add),
                title: const Text('Criar novo sorteio'),
                onTap: () {
                  Navigator.pop(context);
                  _abrirNovoSorteio();
                },
              ),
              ListTile(
                leading: const Icon(Icons.description_outlined),
                title: const Text('Rascunhos de hoje'),
                enabled: _temRascunhosHoje,
                subtitle: _temRascunhosHoje
                    ? const Text('Selecione a dupla vencedora')
                    : const Text('Não há rascunhos hoje'),
                onTap: _temRascunhosHoje
                    ? () {
                        Navigator.pop(context);
                        _abrirRascunhos();
                      }
                    : null,
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSorteioItem(SorteioSimplificadoModel sorteio) {
    final dataFormatada = AppDate.brFromApi(sorteio.data);
    return GestureDetector(
      onTap: () async {
        final detalhe = await ApiService.getSorteioDetalhe(sorteio.id);
        if (!mounted) return;
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
    final bodyList = _loading
        ? const Center(child: CircularProgressIndicator())
        : _sorteios.isEmpty
            ? const Center(child: Text('Nenhum sorteio ativo encontrado.'))
            : ListView.builder(
                padding: const EdgeInsets.only(bottom: 96),
                itemCount: _sorteios.length,
                itemBuilder: (context, index) => _buildSorteioItem(_sorteios[index]),
              );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Sorteios Ativos'),
        actions: [
          IconButton(
            tooltip: 'Rascunhos de hoje',
            icon: const Icon(Icons.description_outlined),
            onPressed: _abrirRascunhos,
          ),
        ],
      ),

      // + RefreshIndicator para recarregar tudo ao puxar
      body: RefreshIndicator(
        onRefresh: _carregarTudo,
        child: Column(
          children: [
            if (_temRascunhosHoje)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                child: Card(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  child: ListTile(
                    leading: const Icon(Icons.info_outline),
                    title: const Text('Rascunhos de hoje disponíveis'),
                    subtitle: const Text('Escolha a dupla vencedora para abrir votação'),
                    trailing: TextButton(
                      onPressed: _abrirRascunhos,
                      child: const Text('Abrir'),
                    ),
                  ),
                ),
              ),
            Expanded(child: bodyList),
          ],
        ),
      ),

      // + FAB com menu
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.add),
        label: const Text('Novo Sorteio'),
        onPressed: _abrirMenuAcoes,
      ),
    );
  }
}