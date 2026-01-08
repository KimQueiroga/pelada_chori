import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';

class AppVersionText extends StatelessWidget {
  const AppVersionText({
    super.key,
    this.textAlign = TextAlign.center,
    this.padding = const EdgeInsets.only(top: 16),
  });

  final TextAlign textAlign;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final textStyle = Theme.of(context)
        .textTheme
        .bodySmall
        ?.copyWith(color: Theme.of(context).hintColor);

    return Padding(
      padding: padding,
      child: FutureBuilder<PackageInfo>(
        future: PackageInfo.fromPlatform(),
        builder: (context, snapshot) {
          final info = snapshot.data;
          if (info == null) {
            return const SizedBox.shrink();
          }

          return Text(
            'Versão ${info.version}+${info.buildNumber}',
            textAlign: textAlign,
            style: textStyle,
          );
        },
      ),
    );
  }
}
