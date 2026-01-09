import 'package:flutter/material.dart';

import '../services/api_service.dart';
import '../theme/colors.dart';

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

    // 1) valida codigo -> obtem reset_token
    final resetToken = await ApiService.verifyResetCode(
      email: widget.email,
      code: _codeCtrl.text.trim(),
    );

    if (!mounted) return;

    if (resetToken == null) {
      setState(() => _loading = false);
      ScaffoldMessenger.of(context)
        ..clearSnackBars()
        ..showSnackBar(
          const SnackBar(content: Text('Codigo invalido ou expirado.')),
        );
      return;
    }

    // 2) usa o reset_token para alterar a senha
    final ok = await ApiService.resetPassword(
      email: widget.email,
      resetToken: resetToken,
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
      Navigator.popUntil(context, (route) => route.isFirst);
    } else {
      ScaffoldMessenger.of(context)
        ..clearSnackBars()
        ..showSnackBar(
          const SnackBar(
            content: Text('Nao foi possivel redefinir a senha. Tente novamente.'),
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
        SnackBar(content: Text(ok ? 'Codigo reenviado.' : 'Falha ao reenviar codigo.')),
      );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Redefinir senha')),
      body: SafeArea(
        child: Container(
          width: double.infinity,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                cs.background,
                cs.surface.withOpacity(0.98),
                cs.background,
              ],
            ),
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: cs.secondaryContainer.withOpacity(0.65),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: cs.primary.withOpacity(0.18),
                          blurRadius: 16,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: const Icon(Icons.lock_reset, size: 48, color: AppColors.primary),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Redefinir senha',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                      ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Enviamos um codigo para ${widget.email}.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: cs.onSurface.withOpacity(0.6),
                      ),
                ),
                const SizedBox(height: 20),
                Form(
                  key: _formKey,
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: cs.surface,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: cs.primary.withOpacity(0.15)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 12,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        TextFormField(
                          controller: _codeCtrl,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            labelText: 'Codigo (6 digitos)',
                            prefixIcon: const Icon(Icons.key_outlined),
                            filled: true,
                            fillColor: cs.surfaceVariant.withOpacity(0.4),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: cs.primary.withOpacity(0.15)),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: cs.primary.withOpacity(0.12)),
                            ),
                          ),
                          validator: (v) {
                            final s = v?.trim() ?? '';
                            if (s.length != 6) return 'Informe os 6 digitos';
                            if (int.tryParse(s) == null) return 'Apenas numeros';
                            return null;
                          },
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _passCtrl,
                          obscureText: _obscure,
                          decoration: InputDecoration(
                            labelText: 'Nova senha',
                            prefixIcon: const Icon(Icons.lock_outline),
                            suffixIcon: IconButton(
                              onPressed: () => setState(() => _obscure = !_obscure),
                              icon: Icon(_obscure ? Icons.visibility : Icons.visibility_off),
                              tooltip: _obscure ? 'Mostrar senha' : 'Ocultar senha',
                            ),
                            filled: true,
                            fillColor: cs.surfaceVariant.withOpacity(0.4),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: cs.primary.withOpacity(0.15)),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: cs.primary.withOpacity(0.12)),
                            ),
                          ),
                          validator: (v) {
                            if (v == null || v.length < 6) return 'Minimo 6 caracteres';
                            return null;
                          },
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _confirmCtrl,
                          obscureText: _obscure,
                          decoration: InputDecoration(
                            labelText: 'Confirmar senha',
                            prefixIcon: const Icon(Icons.lock_outline),
                            suffixIcon: IconButton(
                              onPressed: () => setState(() => _obscure = !_obscure),
                              icon: Icon(_obscure ? Icons.visibility : Icons.visibility_off),
                              tooltip: _obscure ? 'Mostrar senha' : 'Ocultar senha',
                            ),
                            filled: true,
                            fillColor: cs.surfaceVariant.withOpacity(0.4),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: cs.primary.withOpacity(0.15)),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: cs.primary.withOpacity(0.12)),
                            ),
                          ),
                          validator: (v) {
                            if (v != _passCtrl.text) return 'As senhas nao conferem';
                            return null;
                          },
                        ),
                        const SizedBox(height: 18),
                        _loading
                            ? const Padding(
                                padding: EdgeInsets.symmetric(vertical: 6),
                                child: CircularProgressIndicator(),
                              )
                            : ElevatedButton(
                                onPressed: _reset,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primary,
                                  foregroundColor: AppColors.textLight,
                                  minimumSize: const Size.fromHeight(50),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                ),
                                child: const Text('Redefinir senha'),
                              ),
                        const SizedBox(height: 8),
                        TextButton(
                          onPressed: _resend,
                          child: const Text('Reenviar codigo'),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
