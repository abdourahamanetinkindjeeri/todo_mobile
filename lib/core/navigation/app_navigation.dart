import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

import '../../app/app_routes.dart';

extension AppNavigation on BuildContext {
  void popOrGo([String fallbackLocation = AppRoutes.recipes]) {
    final router = GoRouter.of(this);

    if (router.canPop()) {
      router.pop();
      return;
    }

    router.go(fallbackLocation);
  }
}
