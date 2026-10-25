import '../../models/models.dart';

enum MotivoNoDisponible { cerrado, pasada, fueraDeHorario, estilistaOcupado, clienteOcupado }

/// Reglas de negocio puras (sin Flutter), fáciles de probar.
class Reglas {
  static const int apertura = 9;
  static const int cierre = 19;
  static const int pasoMin = 30;

  static bool diaAbierto(DateTime d) => d.weekday != DateTime.sunday;

  /// Franjas de inicio 09:00 ... 18:30 (cada 30 min).
  static List<DateTime> franjasDelDia(DateTime f) {
    const n = (cierre - apertura) * 60 ~/ pasoMin;
    return [for (var i = 0; i < n; i++) DateTime(f.year, f.month, f.day, apertura, i * pasoMin)];
  }

  static int duracionDe(Iterable<Servicio> s) => s.fold<int>(0, (a, e) => a + e.duracionMin);

  static DateTime finDe(DateTime ini, int min) =>
      DateTime(ini.year, ini.month, ini.day, ini.hour, ini.minute + min);

  /// Intervalos semiabiertos: terminar a las 10:00 no solapa con empezar a las 10:00.
  static bool solapan(DateTime i1, DateTime f1, DateTime i2, DateTime f2) =>
      i1.isBefore(f2) && f1.isAfter(i2);

  /// null = franja libre. Considera solo turnos programados (los cancelados no ocupan).
  static MotivoNoDisponible? motivo({
    required Iterable<Turno> turnos,
    required DateTime inicio,
    required int duracionMin,
    int? estilistaId,
    int? clienteId,
    int? excluirTurnoId,
    DateTime? ahora,
  }) {
    if (!diaAbierto(inicio)) return MotivoNoDisponible.cerrado;
    if (inicio.isBefore(ahora ?? DateTime.now())) return MotivoNoDisponible.pasada;
    final fin = finDe(inicio, duracionMin <= 0 ? pasoMin : duracionMin);
    final abre = DateTime(inicio.year, inicio.month, inicio.day, apertura);
    final cierra = DateTime(inicio.year, inicio.month, inicio.day, cierre);
    if (inicio.isBefore(abre) || fin.isAfter(cierra)) return MotivoNoDisponible.fueraDeHorario;
    for (final t in turnos) {
      if (!t.esProgramado || t.id == excluirTurnoId) continue;
      if (!solapan(inicio, fin, t.inicio, t.fin)) continue;
      if (estilistaId != null && t.estilistaId == estilistaId) {
        return MotivoNoDisponible.estilistaOcupado;
      }
      if (clienteId != null && t.clienteId == clienteId) {
        return MotivoNoDisponible.clienteOcupado;
      }
    }
    return null;
  }

  static String mensaje(MotivoNoDisponible m) => switch (m) {
        MotivoNoDisponible.cerrado => 'El salón está cerrado los domingos',
        MotivoNoDisponible.pasada => 'No se puede reservar en una fecha u hora que ya pasó',
        MotivoNoDisponible.fueraDeHorario => 'El turno debe terminar a las 19:00 como máximo',
        MotivoNoDisponible.estilistaOcupado => 'El estilista ya tiene un turno en ese horario',
        MotivoNoDisponible.clienteOcupado => 'El cliente ya tiene un turno en ese horario',
      };
}
