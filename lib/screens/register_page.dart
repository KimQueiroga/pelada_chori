import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import '../services/auth_service.dart';
import '../theme/colors.dart';
import 'home_page.dart';
import 'package:pelada_chori/widgets/app_version_text.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final nomeController = TextEditingController();
  final apelidoController = TextEditingController();
  final numeroCamisaController = TextEditingController();
  final emailController = TextEditingController();
  final senhaController = TextEditingController();
  String? posicaoSelecionada;

  bool loading = false;
  bool _senhaVisivel = false;

  Future<void> cadastrarUsuario() async {
    setState(() => loading = true);

    final response = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/register'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'name': nomeController.text,
        'email': emailController.text,
        'password': senhaController.text,
        'password_confirmation': senhaController.text,
      }),
    );

    if (response.statusCode == 201) {
      // Registro OK, agora login
      final loginResponse = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': emailController.text,
          'password': senhaController.text,
        }),
      );

      if (loginResponse.statusCode == 200) {
        final data = jsonDecode(loginResponse.body);
        final token = data['token'];

        await AuthService.saveToken(token as String);

        // Cadastra o jogador
        final jogadorResponse = await http.post(
          Uri.parse('${ApiConfig.baseUrl}/jogador'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
          body: jsonEncode({
            'nome': nomeController.text,
            'apelido': apelidoController.text,
            'numero_camisa': numeroCamisaController.text,
            'posicao': posicaoSelecionada,
            'foto': null,
          }),
        );

        if (jogadorResponse.statusCode == 201) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Cadastro realizado com sucesso!'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 2),
            ),
          );
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const HomePage()),
          );
        } else {
          if (!mounted) return;
          exibirErro('Erro ao cadastrar jogador', jogadorResponse.body);
        }
      } else {
        if (!mounted) return;
        exibirErro('Erro ao fazer login', loginResponse.body);
      }
    } else {
      if (!mounted) return;
      exibirErro('Erro ao registrar usuario', response.body);
    }

    if (mounted) setState(() => loading = false);
  }

  void exibirErro(String titulo, String conteudo) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(titulo),
        content: Text(conteudo),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Ok')),
        ],
      ),
    );
  }

  InputDecoration _inputDecoration({
    required String label,
    required IconData icon,
    required ColorScheme cs,
    String? hint,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: Icon(icon),
      suffixIcon: suffixIcon,
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
    );
  }

  @override
  void dispose() {
    nomeController.dispose();
    apelidoController.dispose();
    numeroCamisaController.dispose();
    emailController.dispose();
    senhaController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Cadastro')),
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
                    padding: const EdgeInsets.all(14),
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
                    child: const Icon(Icons.person_add_alt_1, size: 52, color: AppColors.primary),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Crie sua conta',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                      ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Preencha seus dados para entrar no app',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: cs.onSurface.withOpacity(0.6),
                      ),
                ),
                const SizedBox(height: 20),
                Container(
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
                      TextField(
                        controller: nomeController,
                        decoration: _inputDecoration(
                          label: 'Nome completo',
                          icon: Icons.badge_outlined,
                          cs: cs,
                        ),
                        textCapitalization: TextCapitalization.words,
                        textInputAction: TextInputAction.next,
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: apelidoController,
                        decoration: _inputDecoration(
                          label: 'Apelido',
                          icon: Icons.person_outline,
                          cs: cs,
                        ),
                        textCapitalization: TextCapitalization.words,
                        textInputAction: TextInputAction.next,
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: numeroCamisaController,
                        decoration: _inputDecoration(
                          label: 'Numero da camisa',
                          icon: Icons.tag_outlined,
                          cs: cs,
                        ),
                        keyboardType: TextInputType.number,
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                        textInputAction: TextInputAction.next,
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        value: posicaoSelecionada,
                        items: const [
                          DropdownMenuItem(value: 'Defesa', child: Text('Defesa')),
                          DropdownMenuItem(value: 'Meio', child: Text('Meio')),
                          DropdownMenuItem(value: 'Ataque', child: Text('Ataque')),
                        ],
                        onChanged: (val) => setState(() => posicaoSelecionada = val),
                        decoration: _inputDecoration(
                          label: 'Posicao',
                          icon: Icons.sports_soccer,
                          cs: cs,
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: emailController,
                        decoration: _inputDecoration(
                          label: 'E-mail',
                          icon: Icons.alternate_email,
                          cs: cs,
                        ),
                        keyboardType: TextInputType.emailAddress,
                        textCapitalization: TextCapitalization.none,
                        textInputAction: TextInputAction.next,
                        onChanged: (value) {
                          emailController.value = emailController.value.copyWith(
                            text: value.toLowerCase(),
                            selection: emailController.selection,
                          );
                        },
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: senhaController,
                        obscureText: !_senhaVisivel,
                        decoration: _inputDecoration(
                          label: 'Senha',
                          icon: Icons.lock_outline,
                          cs: cs,
                          suffixIcon: IconButton(
                            onPressed: () => setState(() => _senhaVisivel = !_senhaVisivel),
                            icon: Icon(_senhaVisivel ? Icons.visibility_off : Icons.visibility),
                            tooltip: _senhaVisivel ? 'Ocultar senha' : 'Mostrar senha',
                          ),
                        ),
                        textInputAction: TextInputAction.done,
                      ),
                      const SizedBox(height: 18),
                      loading
                          ? const Padding(
                              padding: EdgeInsets.symmetric(vertical: 6),
                              child: CircularProgressIndicator(),
                            )
                          : ElevatedButton(
                              onPressed: cadastrarUsuario,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                foregroundColor: AppColors.textLight,
                                minimumSize: const Size.fromHeight(50),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                              child: const Text('Cadastrar'),
                            ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                const Center(child: AppVersionText()),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
