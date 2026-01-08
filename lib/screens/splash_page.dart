import 'dart:convert';
import 'package:flutter/material.dart';
import '../services/auth_service.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  @override
  void initState() {
    super.initState();
    _tryAutoLogin();
  }

  Future<void> _tryAutoLogin() async {
    final token = await AuthService.getValidToken();

    if (token != null && token.isNotEmpty) {
      // ok: vai direto pra Home
      if (!mounted) return;
      Navigator.of(context).pushReplacementNamed('/home');
    } else {
      // sem token ou expirado → Login
      if (!mounted) return;
      Navigator.of(context).pushReplacementNamed('/');
    }
  }

  bool _isExpired(String jwt) {
    try {
      final parts = jwt.split('.');
      if (parts.length != 3) return true;
      final payload = json.decode(utf8.decode(base64Url.decode(base64Url.normalize(parts[1]))));
      final exp = payload['exp'];
      if (exp == null) return true;
      final nowSec = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      return exp <= nowSec;
    } catch (_) {
      return true; // se não conseguir decodificar, trata como expirado
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}
