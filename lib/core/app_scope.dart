import 'package:flutter/widgets.dart';
import '../data/in_memory_store.dart';
import '../viewmodels/theme_viewmodel.dart';

/// Acceso a las dependencias globales sin paquetes externos.
class AppScope extends InheritedWidget {
  const AppScope({
    super.key,
    required this.store,
    required this.themeVm,
    required super.child,
  });

  final InMemoryStore store;
  final ThemeViewModel themeVm;

  static AppScope of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<AppScope>();
    assert(scope != null, 'AppScope no encontrado');
    return scope!;
  }

  @override
  bool updateShouldNotify(AppScope old) => store != old.store || themeVm != old.themeVm;
}
