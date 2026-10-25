import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:go_router/go_router.dart';
import 'core/app_scope.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'data/in_memory_store.dart';
import 'data/seed_data.dart';
import 'viewmodels/theme_viewmodel.dart';

class TurcoApp extends StatefulWidget {
  const TurcoApp({super.key});

  @override
  State<TurcoApp> createState() => _TurcoAppState();
}

class _TurcoAppState extends State<TurcoApp> {
  late final InMemoryStore _store = SeedData.crear();
  final ThemeViewModel _theme = ThemeViewModel();
  late final GoRouter _router = construirRouter();

  @override
  void dispose() {
    _router.dispose();
    _store.dispose();
    _theme.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppScope(
      store: _store,
      themeVm: _theme,
      child: ListenableBuilder(
        listenable: _theme,
        builder: (context, _) => MaterialApp.router(
          title: 'Turco',
          debugShowCheckedModeBanner: false,
          theme: construirTema(Brightness.light),
          darkTheme: construirTema(Brightness.dark),
          themeMode: _theme.mode,
          routerConfig: _router,
          locale: const Locale('es'),
          supportedLocales: const [Locale('es')],
          localizationsDelegates: GlobalMaterialLocalizations.delegates,
        ),
      ),
    );
  }
}
