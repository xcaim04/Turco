import 'enums.dart';
import 'servicio.dart';

class Turno {
  const Turno({
    required this.id,
    required this.clienteId,
    required this.estilistaId,
    required this.servicios,
    required this.inicio,
    this.notas,
    required this.estado,
    required this.creadoEn,
    required this.modificadoEn,
  });

  final int id;
  final int clienteId;
  final int estilistaId;
  final List<Servicio> servicios;
  final DateTime inicio;
  final String? notas;
  final EstadoTurno estado;
  final DateTime creadoEn;
  final DateTime modificadoEn;

  // Calculados: no se guardan.
  int get duracionMin => servicios.fold<int>(0, (s, e) => s + e.duracionMin);
  int get total => servicios.fold<int>(0, (s, e) => s + e.precio);
  DateTime get fin => DateTime(
      inicio.year, inicio.month, inicio.day, inicio.hour, inicio.minute + duracionMin);

  bool get esProgramado => estado == EstadoTurno.programado;
  String get resumenServicios => servicios.map((s) => s.nombre).join(' + ');

  Turno copyWith({EstadoTurno? estado, DateTime? modificadoEn}) => Turno(
        id: id,
        clienteId: clienteId,
        estilistaId: estilistaId,
        servicios: servicios,
        inicio: inicio,
        notas: notas,
        estado: estado ?? this.estado,
        creadoEn: creadoEn,
        modificadoEn: modificadoEn ?? this.modificadoEn,
      );
}
