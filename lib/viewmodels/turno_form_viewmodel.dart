import 'package:flutter/foundation.dart';
import '../core/rules/reglas.dart';
import '../core/utils/fmt.dart';
import '../data/in_memory_store.dart';
import '../models/models.dart';

enum EstadoFranja { libre, ocupada, elegida }

class TurnoFormViewModel extends ChangeNotifier {
  TurnoFormViewModel(this.store, {TurnoFormInicial? inicial, this.turnoId}) {
    final turno = turnoId == null ? null : store.turnoPorId(turnoId!);
    if (turno != null) {
      _clienteId = turno.clienteId;
      _estilistaId = turno.estilistaId;
      _seleccionados.addAll(turno.servicios.map((s) => s.id));
      _fecha = Fmt.soloFecha(turno.inicio);
      _hora = turno.inicio;
      _notas = turno.notas ?? '';
      _publico = _publicoDeServicios(turno.servicios);
    } else {
      _clienteId = inicial?.clienteId;
      if (inicial?.servicioId != null) _seleccionados.add(inicial!.servicioId!);
      final hoy = Fmt.soloFecha(DateTime.now());
      _fecha = _fechaValida(inicial?.fecha ?? hoy);
      final cliente = _clienteId == null ? null : store.clientePorId(_clienteId!);
      _publico = cliente != null ? FiltroPublico.deGenero(cliente.genero) : FiltroPublico.todos;
    }
    _snapshot = _estadoActual();
  }

  final InMemoryStore store;
  final int? turnoId;

  int? _clienteId;
  int? _estilistaId;
  final Set<int> _seleccionados = {};
  late DateTime _fecha;
  DateTime? _hora;
  String _notas = '';
  FiltroPublico _publico = FiltroPublico.todos;
  late String _snapshot;

  String? errorCliente;
  String? errorServicios;
  String? errorEstilista;
  String? errorHora;
  String? errorGeneral;
  bool intentoGuardar = false;
  bool guardado = false;

  bool get esEdicion => turnoId != null;
  int? get clienteId => _clienteId;
  int? get estilistaId => _estilistaId;
  DateTime get fecha => _fecha;
  DateTime? get hora => _hora;
  String get notas => _notas;
  FiltroPublico get publico => _publico;
  Set<int> get idsSeleccionados => Set.unmodifiable(_seleccionados);

  Cliente? get cliente => _clienteId == null ? null : store.clientePorId(_clienteId!);
  Estilista? get estilista => _estilistaId == null ? null : store.estilistaPorId(_estilistaId!);

  List<Servicio> get serviciosVisibles => store.servicios
      .where((s) => _publico.aceptaPublico(s.publico))
      .toList();

  List<Servicio> get serviciosSeleccionados =>
      [for (final s in store.servicios) if (_seleccionados.contains(s.id)) s];

  List<Servicio> serviciosPorCategoria(Categoria c) =>
      serviciosVisibles.where((s) => s.categoria == c).toList();

  List<Estilista> get estilistasDisponibles {
    final servicios = serviciosSeleccionados;
    if (servicios.isEmpty) return store.estilistas;
    return store.estilistas.where((e) => e.realizaTodos(servicios)).toList();
  }

  int get duracion => Reglas.duracionDe(serviciosSeleccionados);
  int get total => serviciosSeleccionados.fold(0, (a, s) => a + s.precio);
  DateTime? get inicio {
    if (_hora == null) return null;
    return DateTime(_fecha.year, _fecha.month, _fecha.day, _hora!.hour, _hora!.minute);
  }

  DateTime? get fin => inicio == null ? null : Reglas.finDe(inicio!, duracion <= 0 ? 30 : duracion);
  bool get esDomingo => !Reglas.diaAbierto(_fecha);

  bool get hayCambios => _estadoActual() != _snapshot;

  bool servicioSeleccionado(int id) => _seleccionados.contains(id);

  EstadoFranja estadoFranja(DateTime franja) {
    final ini = inicio;
    if (ini != null && Fmt.hora(ini) == Fmt.hora(franja)) return EstadoFranja.elegida;
    final motivo = Reglas.motivo(
      turnos: store.turnos,
      inicio: franja,
      duracionMin: duracion <= 0 ? 30 : duracion,
      estilistaId: _estilistaId,
      clienteId: _clienteId,
      excluirTurnoId: turnoId,
    );
    return motivo == null ? EstadoFranja.libre : EstadoFranja.ocupada;
  }

  void cambiarCliente(int? id) {
    if (id == _clienteId) return;
    _clienteId = id;
    errorCliente = null;
    final c = id == null ? null : store.clientePorId(id);
    if (c != null) {
      _aplicarPublico(FiltroPublico.deGenero(c.genero));
    }
    _limpiarHoraSiInvalida();
    notifyListeners();
  }

  void cambiarPublico(FiltroPublico f) {
    if (f == _publico) return;
    _aplicarPublico(f);
    notifyListeners();
  }

  void alternarServicio(int id) {
    final servicio = store.servicioPorId(id);
    if (servicio == null) return;
    if (!_seleccionados.remove(id)) _seleccionados.add(id);
    errorServicios = null;
    if (_estilistaId != null) {
      final e = store.estilistaPorId(_estilistaId!);
      if (e == null || !e.realizaTodos(serviciosSeleccionados)) _estilistaId = null;
    }
    errorEstilista = null;
    _limpiarHoraSiInvalida();
    notifyListeners();
  }

  void cambiarEstilista(int? id) {
    if (id == _estilistaId) return;
    _estilistaId = id;
    errorEstilista = null;
    _limpiarHoraSiInvalida();
    notifyListeners();
  }

  void cambiarFecha(DateTime f) {
    final nueva = _fechaValida(f);
    if (Fmt.mismoDia(nueva, _fecha)) return;
    _fecha = nueva;
    _limpiarHoraSiInvalida();
    notifyListeners();
  }

  void seleccionarHora(DateTime franja) {
    if (estadoFranja(franja) == EstadoFranja.ocupada) return;
    final ini = inicio;
    _hora = ini != null && Fmt.hora(ini) == Fmt.hora(franja) ? null : franja;
    errorHora = null;
    notifyListeners();
  }

  void actualizarNotas(String v) {
    if (v == _notas) return;
    _notas = v;
    notifyListeners();
  }

  void limpiarErrores() {
    errorCliente = null;
    errorServicios = null;
    errorEstilista = null;
    errorHora = null;
    errorGeneral = null;
  }

  bool validar() {
    intentoGuardar = true;
    limpiarErrores();
    var ok = true;
    if (_clienteId == null) {
      errorCliente = 'Selecciona un cliente';
      ok = false;
    }
    if (_seleccionados.isEmpty) {
      errorServicios = 'Elige al menos un servicio';
      ok = false;
    }
    if (_estilistaId == null) {
      errorEstilista = serviciosSeleccionados.isEmpty
          ? 'Primero elige los servicios'
          : 'Selecciona un estilista';
      ok = false;
    }
    if (esDomingo) {
      errorHora = 'El salón está cerrado los domingos';
      ok = false;
    } else if (_hora == null) {
      errorHora = 'Elige una hora para el turno';
      ok = false;
    }
    if (!ok) {
      notifyListeners();
      return false;
    }
    final error = store.validarTurno(
      clienteId: _clienteId,
      estilistaId: _estilistaId,
      servicios: serviciosSeleccionados,
      inicio: inicio,
      excluirId: turnoId,
    );
    if (error != null) {
      errorHora = error;
      notifyListeners();
      return false;
    }
    notifyListeners();
    return true;
  }

  Turno? guardar() {
    if (!validar()) return null;
    final resultado = store.guardarTurno(
      id: turnoId,
      clienteId: _clienteId,
      estilistaId: _estilistaId,
      servicios: serviciosSeleccionados,
      inicio: inicio,
      notas: _notas,
    );
    if (resultado.error != null) {
      errorGeneral = resultado.error;
      notifyListeners();
      return null;
    }
    guardado = true;
    _snapshot = _estadoActual();
    notifyListeners();
    return resultado.turno;
  }

  void _aplicarPublico(FiltroPublico f) {
    _publico = f;
    final incompatibles = serviciosSeleccionados
        .where((s) => !f.aceptaPublico(s.publico))
        .map((s) => s.id)
        .toList();
    _seleccionados.removeAll(incompatibles);
    if (_estilistaId != null) {
      final e = store.estilistaPorId(_estilistaId!);
      if (e == null || !e.realizaTodos(serviciosSeleccionados)) _estilistaId = null;
    }
  }

  void _limpiarHoraSiInvalida() {
    final ini = inicio;
    if (ini == null) return;
    if (estadoFranja(ini) == EstadoFranja.ocupada) {
      _hora = null;
      errorHora = null;
    }
  }

  String _estadoActual() {
    final ids = _seleccionados.toList()..sort();
    return '$_clienteId|$_estilistaId|${ids.join(',')}|${Fmt.soloFecha(_fecha).toIso8601String()}|'
        '${_hora == null ? '' : Fmt.hora(_hora!)}|${_notas.trim()}|${_publico.name}';
  }

  static DateTime _fechaValida(DateTime d) {
    final f = Fmt.soloFecha(d);
    return Reglas.diaAbierto(f) ? f : Fmt.sumarDias(f, 1);
  }

  static FiltroPublico _publicoDeServicios(List<Servicio> s) {
    if (s.isNotEmpty && s.every((x) => x.publico == Publico.mujeres)) return FiltroPublico.mujeres;
    if (s.isNotEmpty && s.every((x) => x.publico == Publico.hombres)) return FiltroPublico.hombres;
    return FiltroPublico.todos;
  }
}
