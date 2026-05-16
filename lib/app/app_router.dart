import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../features/editor/adaptive_glass_editor_page.dart';
import '../features/home/adaptive_glass_home_page.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();

final appRouter = GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: '/',
  routes: [
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) {
        return AdaptiveGlassHomePage(navigationShell: navigationShell);
      },
      branches: [
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/',
              builder: (context, state) => const AdaptiveGlassHomeShell(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/settings',
              builder: (context, state) =>
                  const AdaptiveGlassSettingsShell(),
            ),
          ],
        ),
      ],
    ),
    GoRoute(
      parentNavigatorKey: _rootNavigatorKey,
      path: '/editor',
      builder: (context, state) {
        final title = state.extra as String;
        return AdaptiveGlassEditorPage(title: title);
      },
    ),
  ],
);
