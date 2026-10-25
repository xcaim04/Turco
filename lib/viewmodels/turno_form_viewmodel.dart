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

  /// Error de reglas del store (solape, horario) que se muestra bajo la hora.
  String? errorHora;
  String? errorGeneral;

  /// Aviso cuando un cambio de servicios deja sin efecto al estilista elegido.
  String? avisoEstilista;
  bool intentoGuardar = false;
  bool guardado = false;

  static const maxNotas = 500;

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

  List<DateTime> get franjas => Reglas.franjasDelDia(_fecha);

  /// Hay día abierto pero ninguna franja disponible.
  bool get sinFranjasLibres =>
      !esDomingo && franjas.every((f) => estadoFranja(f) == EstadoFranja.ocupada);

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
    _quitarEstilistaSiInvalido();
    _limpiarHoraSiInvalida();
    notifyListeners();
  }

  void cambiarEstilista(int? id) {
    if (id == _estilistaId) return;
    _estilistaId = id;
    avisoEstilista = null;
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
    errorGeneral = null;
    notifyListeners();
  }

  void actualizarNotas(String v) {
    if (v == _notas) return;
    _notas = v;
    notifyListeners();
  }

  // ---------- validadores de cada campo (los usa el Form de la vista) ----------
  String? validarCliente() => _clienteId == null ? 'Selecciona un cliente' : null;

  String? validarServicios() => _seleccionados.isEmpty ? 'Elige al menos un servicio' : null;

  String? validarEstilista() {
    if (_estilistaId != null) return null;
    return _seleccionados.isEmpty ? 'Primero elige los servicios' : 'Selecciona un estilista';
  }

  String? validarFecha() {
    if (esDomingo) return 'El salón está cerrado los domingos';
    if (_fecha.isBefore(Fmt.soloFecha(DateTime.now()))) return 'No se permiten fechas pasadas';
    return null;
  }

  String? validarHora() {
    if (esDomingo) return 'El salón está cerrado los domingos';
    if (_hora == null) return 'Elige una hora para el turno';
    return errorHora;
  }

  String? validarNotas(String? v) =>
      (v ?? '').length > maxNotas ? 'Las notas admiten hasta $maxNotas caracteres' : null;

  /// Comprueba campos obligatorios y reglas de negocio (solapes, horario).
  bool validar() {
    intentoGuardar = true;
    errorHora = null;
    errorGeneral = null;
    final camposOk = validarCliente() == null &&
        validarServicios() == null &&
        validarEstilista() == null &&
        validarFecha() == null &&
        validarHora() == null &&
        validarNotas(_notas) == null;
    if (!camposOk) {
      notifyListeners();
      return false;
    }
    errorHora = store.validarTurno(
      clienteId: _clienteId,
      estilistaId: _estilistaId,
      servicios: serviciosSeleccionados,
      inicio: inicio,
      excluirId: turnoId,
    );
    notifyListeners();
    return errorHora == null;
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
    _quitarEstilistaSiInvalido();
  }

  /// Si el estilista elegido ya no realiza todos los servicios, se limpia y se avisa.
  void _quitarEstilistaSiInvalido() {
    if (_estilistaId == null) return;
    final e = store.estilistaPorId(_estilistaId!);
    if (e != null && e.realizaTodos(serviciosSeleccionados)) return;
    _estilistaId = null;
    avisoEstilista = e == null
        ? 'Elige de nuevo el estilista'
        : 'Se quitó a ${e.primerNombre}: no realiza todos los servicios elegidos';
  }

  /// Tras cualquier cambio el error de reglas anterior deja de valer, y la
  /// hora elegida se quita si dejó de estar disponible.
  void _limpiarHoraSiInvalida() {
    errorHora = null;
    errorGeneral = null;
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

  /// Fecha inicial válida: nunca en el pasado ni en domingo.
  static DateTime _fechaValida(DateTime d) {
    final hoy = Fmt.soloFecha(DateTime.now());
    var f = Fmt.soloFecha(d);
    if (f.isBefore(hoy)) f = hoy;
    return Reglas.diaAbierto(f) ? f : Fmt.sumarDias(f, 1);
  }

  static FiltroPublico _publicoDeServicios(List<Servicio> s) {
    if (s.isNotEmpty && s.every((x) => x.publico == Publico.mujeres)) return FiltroPublico.mujeres;
    if (s.isNotEmpty && s.every((x) => x.publico == Publico.hombres)) return FiltroPublico.hombres;
    return FiltroPublico.todos;
  }
}
