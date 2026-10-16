import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../constants/route_names.dart';
import '../services/feature_service.dart';

/// A consistent back control for pages whose title is rendered in the body.
class PageBackButton extends StatelessWidget {
  const PageBackButton({super.key});

  @override
  Widget build(BuildContext context) => IconButton(
    tooltip: 'Back',
    icon: const Icon(Icons.arrow_back_rounded),
    onPressed: () {
      // In investing-only mode, route back to its overview directly. Popping
      // browser history could otherwise expose the trading dashboard.
      if (!Features.tradingEnabled) {
        context.goNamed(RouteNames.invest);
        return;
      }
      final router = GoRouter.of(context);
      if (router.canPop()) {
        router.pop();
      } else {
        context.goNamed(RouteNames.home);
      }
    },
  );
}
