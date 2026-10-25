import 'package:flutter_test/flutter_test.dart';
import 'package:turco/core/rules/reglas.dart';
import 'package:turco/data/seed_data.dart';
import 'package:turco/models/models.dart';

void main() {
  final ahora = DateTime(2026, 10, 21, 8); // miércoles
  final store = SeedData.crear(ahora);

  test('terminar a las 10:00 no solapa con empezar a las 10:00', () {
    expect(
      Reglas.solapan(DateTime(2026, 10, 21, 9), DateTime(2026, 10, 21, 10),
          DateTime(2026, 10, 21, 10), DateTime(2026, 10, 21, 11)),
      isFalse,
    );
    expect(
      Reglas.solapan(DateTime(2026, 10, 21, 9), DateTime(2026, 10, 21, 10, 30),
          DateTime(2026, 10, 21, 10), DateTime(2026, 10, 21, 11)),
      isTrue,
    );
  });

  test('domingo cerrado, pasado y límite de 19:00', () {
    MotivoNoDisponible? m(DateTime i, int dur) => Reglas.motivo(
        turnos: store.turnos, inicio: i, duracionMin: dur, estilistaId: 4, clienteId: 6, ahora: ahora);
    expect(m(DateTime(2026, 10, 25, 10), 30), MotivoNoDisponible.cerrado);
    expect(m(DateTime(2026, 10, 21, 7, 30), 30), MotivoNoDisponible.pasada);
    expect(m(DateTime(2026, 10, 22, 18), 90), MotivoNoDisponible.fueraDeHorario);
    expect(m(DateTime(2026, 10, 22, 17, 30), 90), isNull); // termina 19:00 exacto
  });

  test('las franjas van de 09:00 a 18:30 (20 franjas)', () {
    final f = Reglas.franjasDelDia(DateTime(2026, 10, 22));
    expect(f.length, 20);
    expect(f.first.hour, 9);
    expect(f.last.hour * 60 + f.last.minute, 18 * 60 + 30);
  });

  test('turno cancelado no ocupa horario', () {
    final canc = store.turnos.firstWhere((t) => t.estado == EstadoTurno.cancelado);
    final m = Reglas.motivo(
      turnos: store.turnos,
      inicio: canc.inicio,
      duracionMin: canc.duracionMin,
      estilistaId: canc.estilistaId,
      clienteId: canc.clienteId,
      ahora: DateTime(2020),
    );
    expect(m, isNull);
  });

  test('datos de prueba cumplen mínimos y no hay solapes programados', () {
    expect(store.servicios.length, greaterThanOrEqualTo(12));
    expect(store.estilistas.length, 5);
    expect(store.clientes.length, 10);
    expect(store.turnos.length, 16);
    expect(store.turnos.where((t) => t.estado == EstadoTurno.completado).length, greaterThanOrEqualTo(3));
    expect(store.turnos.where((t) => t.estado == EstadoTurno.cancelado).length, greaterThanOrEqualTo(2));
    expect(store.turnos.any((t) => t.servicios.length == 3), isTrue);
    expect(store.turnos.any((t) => t.notas == null), isTrue);
    expect(store.turnos.any((t) => (t.notas ?? '').length > 300), isTrue);
    expect(store.turnos.any((t) => t.fin.hour == 19 && t.fin.minute == 0), isTrue);
    expect(store.clientes.any((c) => store.turnosDeCliente(c.id).isEmpty), isTrue);
    final prog = store.turnos.where((t) => t.esProgramado).toList();
    for (var i = 0; i < prog.length; i++) {
      for (var j = i + 1; j < prog.length; j++) {
        final a = prog[i], b = prog[j];
        if (a.estilistaId == b.estilistaId || a.clienteId == b.clienteId) {
          expect(Reglas.solapan(a.inicio, a.fin, b.inicio, b.fin), isFalse, reason: '${a.id} vs ${b.id}');
        }
      }
    }
  });

  test('no se elimina un cliente con turnos programados', () {
    final conProg = store.clientes.firstWhere((c) => store.programadosDeCliente(c.id) > 0);
    expect(store.eliminarCliente(conProg.id), isNotNull);
    final sin = store.clientes.firstWhere((c) => store.turnosDeCliente(c.id).isEmpty);
    expect(store.eliminarCliente(sin.id), isNull);
  });
}
