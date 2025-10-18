import 'package:flutter/material.dart';
import '../services/api_service.dart';

class VerifyResetCodePage extends StatefulWidget {
  final String email;
  const VerifyResetCodePage({super.key, required this.email});

  @override
  State<VerifyResetCodePage> createState() => _VerifyResetCodePageState();
}

class _VerifyResetCodePageState extends State<VerifyResetCodePage> {
  final _formKey = GlobalKey<FormState>();
  final _codeCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  bool _loading = false;
  bool _obscure = true;

  @override
  void dispose() {
    _codeCtrl.dispose();
    _passCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _reset() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);

    // 1) valida código -> obtém reset_token
    final resetToken = await ApiService.verifyResetCode(
      email: widget.email,
      code: _codeCtrl.text.trim(), // não converter para int
    );

    if (!mounted) return;

    if (resetToken == null) {
      setState(() => _loading = false);
      ScaffoldMessenger.of(context)
        ..clearSnackBars()
        ..showSnackBar(
          const SnackBar(content: Text('Código inválido ou expirado.')),
        );
      return;
    }

    // 2) usa o reset_token para alterar a senha
    final ok = await ApiService.resetPassword(
      email: widget.email,
      resetToken: resetToken,          // <- AGORA vai o reset_token
      newPassword: _passCtrl.text,
    );

    if (!mounted) return;
    setState(() => _loading = false);

    if (ok) {
      ScaffoldMessenger.of(context)
        ..clearSnackBars()
        ..showSnackBar(
          const SnackBar(content: Text('Senha redefinida com sucesso!')),
        );
      // volta para a primeira rota (login)
      Navigator.popUntil(context, (route) => route.isFirst);
    } else {
      ScaffoldMessenger.of(context)
        ..clearSnackBars()
        ..showSnackBar(
          const SnackBar(
            content: Text('Não foi possível redefinir a senha. Tente novamente.'),
          ),
        );
    }
  }

  Future<void> _resend() async {
    final ok = await ApiService.requestPasswordReset(widget.email);
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(
        SnackBar(content: Text(ok ? 'Código reenviado.' : 'Falha ao reenviar código.')),
      );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Redefinir senha')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              Text('Enviamos um código para ${widget.email}.'),
              const SizedBox(height: 16),

              TextFormField(
                controller: _codeCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Código (6 dígitos)'),
                validator: (v) {
                  final s = v?.trim() ?? '';
                  if (s.length != 6) return 'Informe os 6 dígitos';
                  if (int.tryParse(s) == null) return 'Apenas números';
                  return null;
                },
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _passCtrl,
                obscureText: _obscure,
                decoration: InputDecoration(
                  labelText: 'Nova senha',
                  suffixIcon: IconButton(
                    onPressed: () => setState(() => _obscure = !_obscure),
                    icon: Icon(_obscure ? Icons.visibility : Icons.visibility_off),
                  ),
                ),
                validator: (v) {
                  if (v == null || v.length < 6) return 'Mínimo 6 caracteres';
                  return null;
                },
              ),
              const SizedBox(height: 12),

              TextFormField(
                controller: _confirmCtrl,
                obscureText: _obscure,
                decoration: const InputDecoration(labelText: 'Confirmar senha'),
                validator: (v) {
                  if (v != _passCtrl.text) return 'As senhas não conferem';
                  return null;
                },
              ),
              const SizedBox(height: 24),

              _loading
                  ? const Center(child: CircularProgressIndicator())
                  : FilledButton(
                      onPressed: _reset,
                      child: const Text('Redefinir senha'),
                    ),
              const SizedBox(height: 8),

              TextButton(
                onPressed: _resend,
                child: const Text('Reenviar código'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
