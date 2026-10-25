import 'package:flutter/foundation.dart';
import '../core/utils/fmt.dart';
import '../data/in_memory_store.dart';
import '../models/models.dart';

class AgendaViewModel extends ChangeNotifier {
  AgendaViewModel(this.store, {int? estilistaId})
      : _estilistaId = estilistaId,
        _diaSeleccionado = _diaInicial() {
    _semanaInicio = Fmt.lunesDe(_diaSeleccionado);
    store.addListener(_alCambiarStore);
  }

  final InMemoryStore store;
  late DateTime _semanaInicio;
  DateTime _diaSeleccionado;
  int? _estilistaId;
  EstadoTurno? _filtroEstado;

  static DateTime _diaInicial() {
    final hoy = Fmt.soloFecha(DateTime.now());
    return hoy.weekday == DateTime.sunday ? Fmt.sumarDias(hoy, 1) : hoy;
  }

  DateTime get diaSeleccionado => _diaSeleccionado;
  DateTime get semanaInicio => _semanaInicio;
  int? get estilistaId => _estilistaId;
  EstadoTurno? get filtroEstado => _filtroEstado;

  List<DateTime> get diasSemana =>
      [for (var i = 0; i < 7; i++) Fmt.sumarDias(_semanaInicio, i)];

  List<Estilista> get estilistas => store.estilistas;

  List<Turno> get turnosDelDia => store.turnosDelDia(_diaSeleccionado);

  List<Turno> get turnosVisibles {
    return turnosDelDia.where((t) {
      if (_estilistaId != null && t.estilistaId != _estilistaId) return false;
      if (_filtroEstado != null && t.estado != _filtroEstado) return false;
      return true;
    }).toList();
  }

  int get programados => turnosDelDia
      .where((t) => t.esProgramado && (_estilistaId == null || t.estilistaId == _estilistaId))
      .length;

  int get completados => turnosDelDia
      .where((t) => t.estado == EstadoTurno.completado && (_estilistaId == null || t.estilistaId == _estilistaId))
      .length;

  int get ingresoEstimado => turnosDelDia
      .where((t) => t.estado != EstadoTurno.cancelado && (_estilistaId == null || t.estilistaId == _estilistaId))
      .fold(0, (total, t) => total + t.total);

  bool get esDomingo => _diaSeleccionado.weekday == DateTime.sunday;

  bool get sinFiltros => _estilistaId == null && _filtroEstado == null;

  String get mesSemana => Fmt.mesAnio(_diaSeleccionado);

  void seleccionarDia(DateTime dia) {
    final d = Fmt.soloFecha(dia);
    if (Fmt.mismoDia(d, _diaSeleccionado)) return;
    _diaSeleccionado = d;
    _semanaInicio = Fmt.lunesDe(d);
    notifyListeners();
  }

  void cambiarSemana(int delta) {
    _semanaInicio = Fmt.sumarDias(_semanaInicio, delta * 7);
    _diaSeleccionado = Fmt.sumarDias(_diaSeleccionado, delta * 7);
    notifyListeners();
  }

  void seleccionarEstilista(int? id) {
    if (_estilistaId == id) return;
    _estilistaId = id;
    notifyListeners();
  }

  void seleccionarEstado(EstadoTurno? estado) {
    if (_filtroEstado == estado) return;
    _filtroEstado = estado;
    notifyListeners();
  }

  void limpiarFiltros() {
    _estilistaId = null;
    _filtroEstado = null;
    notifyListeners();
  }

  String? completar(int id) {
    final error = store.completarTurno(id);
    return error;
  }

  String? cancelar(int id) => store.cancelarTurno(id);

  void _alCambiarStore() => notifyListeners();

  @override
  void dispose() {
    store.removeListener(_alCambiarStore);
    super.dispose();
  }
}
