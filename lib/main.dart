import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:go_transitions/go_transitions.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';
import 'package:signals_flutter/signals_flutter.dart';

import 'presentation/routes/routes.dart';
import 'shared/theme_controller.dart';

part 'main.g.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await initializeThemeMode();
  await LiquidGlassWidgets.initialize();

  debugProfileBuildsEnabled = false;
  debugProfilePaintsEnabled = false;
  debugProfileLayoutsEnabled = false;
  debugRepaintRainbowEnabled = false;
  debugPaintSizeEnabled = false;

  runApp(const App());
}

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    final lightScheme = ColorScheme.fromSeed(
      seedColor: const Color(0xFF79D6FF),
      brightness: Brightness.light,
    );
    final darkScheme = ColorScheme.fromSeed(
      seedColor: const Color(0xFF79D6FF),
      brightness: Brightness.dark,
    );

    return Watch((context) {
      final currentFont = fontFamily.value;
      return MaterialApp.router(
        debugShowCheckedModeBanner: false,
        title: 'AdaptiveGlass',
        themeMode: themeMode.value,
        theme: _buildAppTheme(lightScheme, currentFont),
        darkTheme: _buildAppTheme(darkScheme, currentFont),
        routerConfig: appRouter,
        builder: (context, child) {
          return GlassTheme(
            data: _glassThemeData,
            child: child ?? const SizedBox.shrink(),
          );
        },
      );
    });
  }
}

ThemeData _buildAppTheme(ColorScheme scheme, String fontFamily) {
  final isDark = scheme.brightness == Brightness.dark;

  return ThemeData(
    pageTransitionsTheme: const PageTransitionsTheme(
      builders: {
        TargetPlatform.android: GoTransitions.cupertino,
        TargetPlatform.iOS: GoTransitions.cupertino,
        TargetPlatform.macOS: GoTransitions.cupertino,
      },
    ),
    colorScheme: scheme,
    scaffoldBackgroundColor: isDark
        ? const Color(0xFF0E1116)
        : const Color(0xFFF4F7F5),
    fontFamily: fontFamily.isEmpty ? null : fontFamily,
    useMaterial3: true,
  );
}
