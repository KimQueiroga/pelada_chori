import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../config/api_config.dart';
import '../theme/colors.dart';
import 'package:flutter/services.dart';
import '../screens/home_page.dart';
import 'package:shared_preferences/shared_preferences.dart';
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
        // ✅ Registro OK, agora login
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

          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('jwt_token', token);

          // ✅ Cadastra o jogador
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
            // ✅ Tudo certo, vai para a Home!
            // ✅ Tudo certo, vai para a Home!
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
            exibirErro('Erro ao cadastrar jogador', jogadorResponse.body);
          }
        } else {
          exibirErro('Erro ao fazer login', loginResponse.body);
        }
      } else {
        exibirErro('Erro ao registrar usuário', response.body);
      }

      setState(() => loading = false);
}


  Future<void> criarJogador(String token) async {
    final jogadorResponse = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/jogador'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
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
      // Tudo certo, volta pra tela de login
      Navigator.pop(context);
    } else {
      exibirErro('Erro ao cadastrar jogador', jogadorResponse.body);
    }
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Cadastro")),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: SingleChildScrollView(
          child: Column(
            children: [
              TextField(
                controller: nomeController, 
                decoration: const InputDecoration(labelText: 'Nome completo'),
                textCapitalization: TextCapitalization.words,
                ),
              TextField(controller: apelidoController, 
              decoration: const InputDecoration(labelText: 'Apelido'),
              textCapitalization: TextCapitalization.words,
              ),
              TextField(controller: numeroCamisaController, 
              decoration: const InputDecoration(labelText: 'Número da camisa'),
              keyboardType: TextInputType.number,
              inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                ],
              ),
              DropdownButtonFormField<String>(
                value: posicaoSelecionada,
                items: const [
                  DropdownMenuItem(value: 'Defesa', child: Text('Defesa')),
                  DropdownMenuItem(value: 'Meio', child: Text('Meio')),
                  DropdownMenuItem(value: 'Ataque', child: Text('Ataque')),
                ],
                onChanged: (val) => setState(() => posicaoSelecionada = val),
                decoration: const InputDecoration(labelText: 'Posição'),
              ),
              const SizedBox(height: 16),
              TextField(controller: emailController, 
              decoration: const InputDecoration(labelText: 'E-mail'),
              keyboardType: TextInputType.emailAddress,
              textCapitalization: TextCapitalization.none,
              onChanged: (value) {
                  emailController.value = emailController.value.copyWith(
                    text: value.toLowerCase(),
                    selection: emailController.selection,
                  );
                },
              ),
              TextField(controller: senhaController, decoration: const InputDecoration(labelText: 'Senha'), obscureText: true),
              const SizedBox(height: 24),
              loading
                  ? const CircularProgressIndicator()
                  : ElevatedButton(
                      onPressed: cadastrarUsuario,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: AppColors.textLight,
                        minimumSize: const Size.fromHeight(50),
                      ),
                      child: const Text('Cadastrar'),
                    ),
              const AppVersionText(),
            ],
          ),
        ),
      ),
    );
  }
}
