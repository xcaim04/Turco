import 'package:flutter/foundation.dart';
import '../core/rules/reglas.dart';
import '../models/models.dart';

typedef ResultadoTurno = ({Turno? turno, String? error});
typedef ResultadoCliente = ({Cliente? cliente, String? error});

/// Fuente de verdad en memoria. Los ViewModels la escuchan.
class InMemoryStore extends ChangeNotifier {
  InMemoryStore({
    required this.servicios,
    required this.estilistas,
    required List<Cliente> clientes,
    required List<Turno> turnos,
  })  : _clientes = List.of(clientes),
        _turnos = List.of(turnos),
        _sigClienteId = clientes.fold<int>(0, (m, c) => c.id > m ? c.id : m) + 1,
        _sigTurnoId = turnos.fold<int>(0, (m, t) => t.id > m ? t.id : m) + 1;

  final List<Servicio> servicios; // solo lectura
  final List<Estilista> estilistas; // solo lectura
  final List<Cliente> _clientes;
  final List<Turno> _turnos;
  int _sigClienteId;
  int _sigTurnoId;

  List<Cliente> get clientes => List.unmodifiable(_clientes);
  List<Turno> get turnos => List.unmodifiable(_turnos);

  // ---------- consultas ----------
  Cliente? clientePorId(int id) {
    for (final c in _clientes) {
      if (c.id == id) return c;
    }
    return null;
  }

  Estilista? estilistaPorId(int id) {
    for (final e in estilistas) {
      if (e.id == id) return e;
    }
    return null;
  }

  Servicio? servicioPorId(int id) {
    for (final s in servicios) {
      if (s.id == id) return s;
    }
    return null;
  }

  Turno? turnoPorId(int id) {
    for (final t in _turnos) {
      if (t.id == id) return t;
    }
    return null;
  }

  List<Turno> turnosDeCliente(int clienteId) =>
      _turnos.where((t) => t.clienteId == clienteId).toList()
        ..sort((a, b) => b.inicio.compareTo(a.inicio));

  int programadosDeCliente(int id) =>
      _turnos.where((t) => t.clienteId == id && t.esProgramado).length;

  List<Turno> turnosDelDia(DateTime dia) =>
      _turnos.where((t) => _mismoDia(t.inicio, dia)).toList()
        ..sort((a, b) => a.inicio.compareTo(b.inicio));

  int programadosHoy(int estilistaId, [DateTime? ahora]) {
    final hoy = ahora ?? DateTime.now();
    return _turnos
        .where((t) => t.estilistaId == estilistaId && t.esProgramado && _mismoDia(t.inicio, hoy))
        .length;
  }

  bool telefonoDisponible(String tel, {int? excluirId}) =>
      !_clientes.any((c) => c.telefono == tel.trim() && c.id != excluirId);

  // ---------- clientes ----------
  ResultadoCliente guardarCliente({
    int? id,
    required String nombre,
    required String telefono,
    required Genero genero,
    String? correo,
  }) {
    if (!telefonoDisponible(telefono, excluirId: id)) {
      return (cliente: null, error: 'Este teléfono ya está registrado');
    }
    final mail = (correo ?? '').trim();
    if (id == null) {
      final c = Cliente(
        id: _sigClienteId++,
        nombre: nombre.trim(),
        telefono: telefono.trim(),
        genero: genero,
        correo: mail.isEmpty ? null : mail,
        fechaRegistro: DateTime.now(),
      );
      _clientes.add(c);
      notifyListeners();
      return (cliente: c, error: null);
    }
    final i = _clientes.indexWhere((c) => c.id == id);
    if (i < 0) return (cliente: null, error: 'El cliente no existe');
    final c = _clientes[i].copyWith(
      nombre: nombre.trim(),
      telefono: telefono.trim(),
      genero: genero,
      correo: mail,
      sinCorreo: mail.isEmpty,
    );
    _clientes[i] = c;
    notifyListeners();
    return (cliente: c, error: null);
  }

  /// Devuelve un mensaje de error, o null si se eliminó.
  String? eliminarCliente(int id) {
    final c = clientePorId(id);
    if (c == null) return 'El cliente no existe';
    final prog = programadosDeCliente(id);
    if (prog > 0) {
      return 'No se puede eliminar: ${c.nombre} tiene ${prog == 1 ? '1 turno programado' : '$prog turnos programados'}.';
    }
    _turnos.removeWhere((t) => t.clienteId == id);
    _clientes.removeWhere((x) => x.id == id);
    notifyListeners();
    return null;
  }

  // ---------- turnos ----------
  /// Valida todas las reglas. null = válido.
  String? validarTurno({
    required int? clienteId,
    required int? estilistaId,
    required List<Servicio> servicios,
    required DateTime? inicio,
    int? excluirId,
    DateTime? ahora,
  }) {
    if (clienteId == null) return 'Selecciona un cliente';
    if (servicios.isEmpty) return 'Elige al menos un servicio';
    final est = estilistaId == null ? null : estilistaPorId(estilistaId);
    if (est == null) return 'Selecciona un estilista';
    if (!est.realizaTodos(servicios)) {
      return 'El estilista no realiza todos los servicios elegidos';
    }
    if (inicio == null) return 'Elige una hora para el turno';
    final m = Reglas.motivo(
      turnos: _turnos,
      inicio: inicio,
      duracionMin: Reglas.duracionDe(servicios),
      estilistaId: estilistaId,
      clienteId: clienteId,
      excluirTurnoId: excluirId,
      ahora: ahora,
    );
    return m == null ? null : Reglas.mensaje(m);
  }

  /// Crea (id == null) o edita un turno programado.
  ResultadoTurno guardarTurno({
    int? id,
    required int? clienteId,
    required int? estilistaId,
    required List<Servicio> servicios,
    required DateTime? inicio,
    String? notas,
  }) {
    final error = validarTurno(
      clienteId: clienteId,
      estilistaId: estilistaId,
      servicios: servicios,
      inicio: inicio,
      excluirId: id,
    );
    if (error != null) return (turno: null, error: error);
    final ahora = DateTime.now();
    final n = (notas ?? '').trim();
    final Turno t;
    if (id == null) {
      t = Turno(
        id: _sigTurnoId++,
        clienteId: clienteId!,
        estilistaId: estilistaId!,
        servicios: List.of(servicios),
        inicio: inicio!,
        notas: n.isEmpty ? null : n,
        estado: EstadoTurno.programado,
        creadoEn: ahora,
        modificadoEn: ahora,
      );
      _turnos.add(t);
    } else {
      final i = _turnos.indexWhere((x) => x.id == id);
      if (i < 0) return (turno: null, error: 'El turno no existe');
      final ant = _turnos[i];
      if (!ant.esProgramado) {
        return (turno: null, error: 'Solo los turnos programados se pueden editar');
      }
      t = Turno(
        id: id,
        clienteId: clienteId!,
        estilistaId: estilistaId!,
        servicios: List.of(servicios),
        inicio: inicio!,
        notas: n.isEmpty ? null : n,
        estado: EstadoTurno.programado,
        creadoEn: ant.creadoEn,
        modificadoEn: ahora,
      );
      _turnos[i] = t;
    }
    notifyListeners();
    return (turno: t, error: null);
  }

  String? completarTurno(int id) => _cambiarEstado(id, EstadoTurno.completado);
  String? cancelarTurno(int id) => _cambiarEstado(id, EstadoTurno.cancelado);

  String? _cambiarEstado(int id, EstadoTurno nuevo) {
    final i = _turnos.indexWhere((t) => t.id == id);
    if (i < 0) return 'El turno no existe';
    if (!_turnos[i].esProgramado) return 'Solo los turnos programados se pueden modificar';
    _turnos[i] = _turnos[i].copyWith(estado: nuevo, modificadoEn: DateTime.now());
    notifyListeners();
    return null;
  }

  static bool _mismoDia(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
}
