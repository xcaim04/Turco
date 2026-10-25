import 'package:flutter/foundation.dart';
import '../data/in_memory_store.dart';
import '../models/models.dart';

class ServiciosViewModel extends ChangeNotifier {
  ServiciosViewModel(this.store);
  final InMemoryStore store;

  Categoria? _categoria;
  FiltroPublico _publico = FiltroPublico.todos;

  Categoria? get categoria => _categoria;
  FiltroPublico get publico => _publico;

  List<Servicio> get servicios => store.servicios.where((s) {
        if (_categoria != null && s.categoria != _categoria) return false;
        return _publico.aceptaPublico(s.publico);
      }).toList();

  void filtrarCategoria(Categoria? c) {
    if (c == _categoria) return;
    _categoria = c;
    notifyListeners();
  }

  void filtrarPublico(FiltroPublico p) {
    if (p == _publico) return;
    _publico = p;
    notifyListeners();
  }

  void limpiar() {
    _categoria = null;
    _publico = FiltroPublico.todos;
    notifyListeners();
  }
}
