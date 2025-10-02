import 'package:flutter/material.dart';
import 'package:characters/characters.dart';

/// Mostra a foto se houver URL; caso contrário (ou se der erro)
/// exibe a inicial do displayName.
class AvatarInicial extends StatelessWidget {
  const AvatarInicial({
    super.key,
    required this.displayName,
    this.photoUrl,
    this.radius = 36,
    this.backgroundOpacity = 0.15,
  });

  final String displayName;
  final String? photoUrl;
  final double radius;
  final double backgroundOpacity;

  String _inicial(String nome) {
    final t = nome.trim();
    if (t.isEmpty) return '?';
    // se não quiser usar package:characters, troque por: t.substring(0, 1).toUpperCase()
    return t.characters.first.toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final hasUrl = (photoUrl ?? '').trim().isNotEmpty;

    Widget fallback() => Center(
          child: Text(
            _inicial(displayName),
            style: TextStyle(
              fontSize: radius * 0.9,
              fontWeight: FontWeight.w700,
              color: primary,
            ),
          ),
        );

    if (!hasUrl) {
      return CircleAvatar(
        radius: radius,
        backgroundColor: primary.withOpacity(backgroundOpacity),
        foregroundColor: primary,
        child: Text(
          _inicial(displayName),
          style: TextStyle(fontSize: radius * 0.9, fontWeight: FontWeight.w700),
        ),
      );
    }

    return CircleAvatar(
      radius: radius,
      backgroundColor: primary.withOpacity(backgroundOpacity),
      child: ClipOval(
        child: Image.network(
          photoUrl!.trim(),
          width: radius * 2,
          height: radius * 2,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => fallback(),
        ),
      ),
    );
  }
}
