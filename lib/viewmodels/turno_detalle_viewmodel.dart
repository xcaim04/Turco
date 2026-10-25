import 'package:flutter/foundation.dart';
import '../data/in_memory_store.dart';
import '../models/models.dart';

class TurnoDetalleViewModel extends ChangeNotifier {
  TurnoDetalleViewModel(this.store, this.turnoId) {
    store.addListener(_alCambiarStore);
  }

  final InMemoryStore store;
  final int turnoId;

  Turno? get turno => store.turnoPorId(turnoId);
  Cliente? get cliente {
    final t = turno;
    return t == null ? null : store.clientePorId(t.clienteId);
  }

  Estilista? get estilista {
    final t = turno;
    return t == null ? null : store.estilistaPorId(t.estilistaId);
  }

  String? completar() => store.completarTurno(turnoId);
  String? cancelar() => store.cancelarTurno(turnoId);

  void _alCambiarStore() => notifyListeners();

  @override
  void dispose() {
    store.removeListener(_alCambiarStore);
    super.dispose();
  }
}
