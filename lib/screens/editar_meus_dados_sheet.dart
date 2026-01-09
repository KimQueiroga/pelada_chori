import 'package:flutter/material.dart';
import '../models/jogador.dart';
import '../services/api_service.dart';

class EditarMeusDadosSheet extends StatefulWidget {
  final Jogador jogador;
  const EditarMeusDadosSheet({super.key, required this.jogador});

  @override
  State<EditarMeusDadosSheet> createState() => _EditarMeusDadosSheetState();
}

class _EditarMeusDadosSheetState extends State<EditarMeusDadosSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nome;
  late final TextEditingController _apelido;
  late final TextEditingController _numero;
  late final TextEditingController _foto;
  String _posicao = 'Meio';
  bool _salvando = false;
  final List<String> _posicoes = const ['Defesa', 'Meio', 'Ataque'];

  @override
  void initState() {
    super.initState();
    _nome = TextEditingController(text: widget.jogador.nome);
    _apelido = TextEditingController(text: widget.jogador.apelido);
    _numero = TextEditingController(text: widget.jogador.numeroCamisa);
    _foto = TextEditingController(text: widget.jogador.foto);

    final p = widget.jogador.posicao.trim();
    if (p.isNotEmpty) _posicao = p[0].toUpperCase() + p.substring(1).toLowerCase();
  }

  @override
  void dispose() {
    _nome.dispose();
    _apelido.dispose();
    _numero.dispose();
    _foto.dispose();
    super.dispose();
  }

  Future<void> _salvar() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _salvando = true);

    final payload = {
      'nome': _nome.text.trim(),
      'apelido': _apelido.text.trim().isEmpty ? null : _apelido.text.trim(),
      'posicao': _posicao,
      'numero_camisa':
          _numero.text.trim().isEmpty ? null : int.tryParse(_numero.text.trim()),
      'foto': _foto.text.trim().isEmpty ? null : _foto.text.trim(),
    };

    final ok = await ApiService.updateMeusDados(payload);

    if (!mounted) return;
    setState(() => _salvando = false);

    if (ok) {
      Navigator.pop(context, true);
    } else {
      Navigator.pop(context, 'Erro ao salvar');
    }
  }

  @override
  Widget build(BuildContext context) {
    final insets = MediaQuery.of(context).viewInsets;
    final cs = Theme.of(context).colorScheme;

    InputDecoration deco(String label, IconData icon, {String? hint}) {
      return InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon),
        filled: true,
        fillColor: cs.surfaceVariant.withOpacity(0.45),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: cs.primary.withOpacity(0.15)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: cs.primary.withOpacity(0.12)),
        ),
      );
    }

    return Padding(
      padding: EdgeInsets.only(bottom: insets.bottom),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 44,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 14),
                  decoration: BoxDecoration(
                    color: cs.onSurface.withOpacity(0.25),
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              Text(
                'Editar meus dados',
                style: Theme.of(context)
                    .textTheme
                    .titleLarge
                    ?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 6),
              Text(
                'Atualize suas informacoes pessoais',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: cs.onSurface.withOpacity(0.6),
                    ),
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _nome,
                decoration: deco('Nome', Icons.badge_outlined),
                textInputAction: TextInputAction.next,
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Informe seu nome' : null,
              ),
              const SizedBox(height: 12),

              TextFormField(
                controller: _apelido,
                decoration: deco('Apelido (opcional)', Icons.person_outline),
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 12),

              DropdownButtonFormField<String>(
                value: _posicao,
                decoration: deco('Posicao', Icons.sports_soccer),
                items: _posicoes
                    .map((p) => DropdownMenuItem(value: p, child: Text(p)))
                    .toList(),
                onChanged: (v) => setState(() => _posicao = v ?? 'Meio'),
              ),
              const SizedBox(height: 12),

              TextFormField(
                controller: _numero,
                keyboardType: TextInputType.number,
                decoration: deco('Numero da camisa (opcional)', Icons.tag_outlined),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return null;
                  final n = int.tryParse(v.trim());
                  if (n == null || n < 0 || n > 99) return '0 a 99';
                  return null;
                },
              ),
              const SizedBox(height: 12),

              TextFormField(
                controller: _foto,
                decoration: deco('URL da foto (opcional)', Icons.link),
              ),
              const SizedBox(height: 18),

              _salvando
                  ? const Center(child: CircularProgressIndicator())
                  : FilledButton(
                      onPressed: _salvar,
                      child: const Text('Salvar'),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}
