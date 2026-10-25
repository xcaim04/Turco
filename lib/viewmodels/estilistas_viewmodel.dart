import 'package:flutter/foundation.dart';
import '../data/in_memory_store.dart';
import '../models/models.dart';

class EstilistasViewModel extends ChangeNotifier {
  EstilistasViewModel(this.store) {
    store.addListener(_alCambiarStore);
  }

  final InMemoryStore store;

  List<Estilista> get estilistas => store.estilistas;

  int get programadosHoy => store.turnos
      .where((t) => t.esProgramado && _mismoDia(t.inicio, DateTime.now()))
      .length;

  int turnosHoy(Estilista e) => store.programadosHoy(e.id);

  /// Servicios que realiza el estilista, agrupados por categoría.
  Map<Categoria, List<Servicio>> serviciosPorCategoria(Estilista e) {
    final grupos = <Categoria, List<Servicio>>{};
    for (final c in categoriasDe(e)) {
      grupos[c] = [
        for (final id in e.servicioIds)
          if (store.servicioPorId(id) case final s? when s.categoria == c) s,
      ];
    }
    return grupos;
  }

  List<Categoria> categoriasDe(Estilista e) {
    final result = <Categoria>[];
    for (final id in e.servicioIds) {
      final s = store.servicioPorId(id);
      if (s != null && !result.contains(s.categoria)) result.add(s.categoria);
    }
    result.sort((a, b) => a.index.compareTo(b.index));
    return result;
  }

  static bool _mismoDia(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  void _alCambiarStore() => notifyListeners();

  @override
  void dispose() {
    store.removeListener(_alCambiarStore);
    super.dispose();
  }
}
