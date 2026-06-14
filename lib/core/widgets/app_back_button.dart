import 'package:flutter/material.dart';

import '../../app/app_routes.dart';
import '../navigation/app_navigation.dart';

class AppBackButton extends StatelessWidget {
  final String fallbackLocation;

  const AppBackButton({
    super.key,
    this.fallbackLocation = AppRoutes.recipes,
  });

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: 'Retour',
      onPressed: () => context.popOrGo(fallbackLocation),
      icon: const Icon(Icons.arrow_back_rounded),
    );
  }
}
