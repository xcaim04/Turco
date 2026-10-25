import 'package:flutter/foundation.dart';
import '../core/utils/fmt.dart';
import '../data/in_memory_store.dart';
import '../models/models.dart';

class ClientesViewModel extends ChangeNotifier {
  ClientesViewModel(this.store) {
    store.addListener(_alCambiarStore);
  }

  final InMemoryStore store;
  String _busqueda = '';
  FiltroPublico _filtro = FiltroPublico.todos;

  String get busqueda => _busqueda;
  FiltroPublico get filtro => _filtro;

  List<Cliente> get clientes {
    final q = Fmt.normalizar(_busqueda.trim());
    final lista = store.clientes.where((c) {
      if (!_filtro.aceptaGenero(c.genero)) return false;
      if (q.isEmpty) return true;
      return Fmt.normalizar(c.nombre).contains(q) || c.telefono.contains(q);
    }).toList()
      ..sort((a, b) => a.nombre.compareTo(b.nombre));
    return lista;
  }

  int get total => clientes.length;
  int get mujeres => clientes.where((c) => c.genero == Genero.mujer).length;
  int get hombres => clientes.where((c) => c.genero == Genero.hombre).length;

  bool get hayBusquedaOFiltro => _busqueda.trim().isNotEmpty || _filtro != FiltroPublico.todos;

  void buscar(String valor) {
    if (valor == _busqueda) return;
    _busqueda = valor;
    notifyListeners();
  }

  void filtrar(FiltroPublico f) {
    if (f == _filtro) return;
    _filtro = f;
    notifyListeners();
  }

  void limpiar() {
    _busqueda = '';
    _filtro = FiltroPublico.todos;
    notifyListeners();
  }

  String? eliminar(int id) => store.eliminarCliente(id);

  void _alCambiarStore() => notifyListeners();

  @override
  void dispose() {
    store.removeListener(_alCambiarStore);
    super.dispose();
  }
}
