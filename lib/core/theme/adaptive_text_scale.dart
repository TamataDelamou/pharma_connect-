import 'package:flutter/material.dart';

import 'typography.dart';

/// C233 : applique l'échelle de texte adaptative à tout ce qui est en
/// dessous (voir PharmaConnectTypography.textScalerFor). Posé une fois à la
/// racine de l'application (MaterialApp.builder).
class AdaptiveTextScale extends StatelessWidget {
  final Widget child;

  const AdaptiveTextScale({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    return MediaQuery(
      data: media.copyWith(
        textScaler: PharmaConnectTypography.textScalerFor(
          width: media.size.width,
          system: media.textScaler,
        ),
      ),
      child: child,
    );
  }
}
