import 'package:flutter/material.dart';
import 'package:go_transitions/go_transitions.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';
import 'package:signals_flutter/signals_flutter.dart';

import 'features/home/adaptive_glass_home_page.dart' show themeMode;
import 'app/app_router.dart';

part 'main.g.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await LiquidGlassWidgets.initialize();
  runApp(LiquidGlassWidgets.wrap(child: const App()));
}

class App extends StatefulWidget {
  const App({super.key});

  @override
  State<App> createState() => _AppState();
}

class _AppState extends State<App> {
  @override
  void initState() {
    // TODO: implement initState
    super.initState();

    GoTransition.defaultCurve = Curves.easeInOut;
    GoTransition.defaultDuration = const Duration(milliseconds: 600);
  }

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
      return MaterialApp.router(
        debugShowCheckedModeBanner: false,
        title: '光影边框',
        themeMode: themeMode.value,
        theme: _buildTheme(lightScheme),
        darkTheme: _buildTheme(darkScheme),
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
