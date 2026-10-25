import '../models/models.dart';
import 'in_memory_store.dart';

/// Datos de prueba. Todas las fechas salen de `ahora` (DateTime.now()).
class SeedData {
  static const _notaLarga =
      'Clienta con cuero cabelludo sensible: usar productos sin sulfatos y evitar el agua muy caliente. '
      'Prefiere que le expliquen cada paso del tratamiento antes de empezar. '
      'Confirmar siempre la fórmula con ella antes de aplicarla. '
      'Suele llegar acompañada de su hija, que espera en recepción; ofrecer té o café y revistas. '
      'Si el tratamiento se extiende, avisar a recepción para reorganizar los siguientes turnos del día. '
      'Paga siempre en efectivo y deja propina para todo el equipo.';

  static InMemoryStore crear([DateTime? ahora]) {
    final now = ahora ?? DateTime.now();
    final hoy = DateTime(now.year, now.month, now.day);

    const servicios = <Servicio>[
      Servicio(id: 1, nombre: 'Corte mujer', categoria: Categoria.corte, duracionMin: 60, precio: 30, publico: Publico.mujeres),
      Servicio(id: 2, nombre: 'Corte caballero', categoria: Categoria.corte, duracionMin: 45, precio: 25, publico: Publico.hombres),
      Servicio(id: 3, nombre: 'Corte clásico', categoria: Categoria.corte, duracionMin: 30, precio: 18, publico: Publico.hombres),
      Servicio(id: 4, nombre: 'Color completo', categoria: Categoria.color, duracionMin: 120, precio: 70, publico: Publico.mujeres),
      Servicio(id: 5, nombre: 'Mechas', categoria: Categoria.color, duracionMin: 120, precio: 90, publico: Publico.mujeres),
      Servicio(id: 6, nombre: 'Barba', categoria: Categoria.barba, duracionMin: 45, precio: 20, publico: Publico.hombres),
      Servicio(id: 7, nombre: 'Afeitado', categoria: Categoria.barba, duracionMin: 30, precio: 15, publico: Publico.hombres),
      Servicio(id: 8, nombre: 'Peinado evento', categoria: Categoria.peinado, duracionMin: 60, precio: 40, publico: Publico.unisex),
      Servicio(id: 9, nombre: 'Peinado diario', categoria: Categoria.peinado, duracionMin: 30, precio: 20, publico: Publico.unisex),
      Servicio(id: 10, nombre: 'Hidratación', categoria: Categoria.tratamiento, duracionMin: 45, precio: 28, publico: Publico.unisex),
      Servicio(id: 11, nombre: 'Keratina', categoria: Categoria.tratamiento, duracionMin: 90, precio: 60, publico: Publico.unisex),
      Servicio(id: 12, nombre: 'Peinado novia', categoria: Categoria.peinado, duracionMin: 90, precio: 65, publico: Publico.mujeres),
    ];

    const estilistas = <Estilista>[
      // Solo servicios de mujeres
      Estilista(id: 1, nombre: 'Marta Salazar', avatar: 'assets/images/avatars/marta.jpg', servicioIds: [1, 4, 5, 12]),
      // Solo servicios de hombres
      Estilista(id: 2, nombre: 'Pedro Vega', avatar: 'assets/images/avatars/pedro.jpg', servicioIds: [2, 3, 6, 7]),
      // Ambos públicos
      Estilista(id: 3, nombre: 'Lucía Torres', avatar: 'assets/images/avatars/lucia.jpg', servicioIds: [1, 2, 3, 8, 9, 10, 11]),
      // Sin turnos hoy
      Estilista(id: 4, nombre: 'Rafael Núñez', avatar: 'assets/images/avatars/rafael.jpg', servicioIds: [2, 3, 6, 7]),
      Estilista(id: 5, nombre: 'Andrea Pons', avatar: 'assets/images/avatars/andrea.jpg', servicioIds: [4, 5, 8, 9, 12]),
    ];

    DateTime reg(int i) => DateTime(hoy.year, hoy.month, hoy.day - (30 + i * 9));
    final clientes = <Cliente>[
      Cliente(id: 1, nombre: 'Laura Gómez', telefono: '52111222', genero: Genero.mujer, fechaRegistro: reg(1)),
      Cliente(id: 2, nombre: 'Carlos Ruiz', telefono: '52345678', genero: Genero.hombre, correo: 'carlos.ruiz@correo.com', fechaRegistro: reg(2)),
      Cliente(id: 3, nombre: 'Ana Martín', telefono: '53220140', genero: Genero.mujer, fechaRegistro: reg(3)),
      Cliente(id: 4, nombre: 'Diego Pérez', telefono: '55908771', genero: Genero.hombre, fechaRegistro: reg(4)),
      Cliente(id: 5, nombre: 'Sofía Díaz', telefono: '54667310', genero: Genero.mujer, fechaRegistro: reg(5)),
      Cliente(id: 6, nombre: 'Javier Soto', telefono: '52774009', genero: Genero.hombre, fechaRegistro: reg(6)), // sin turnos
      Cliente(id: 7, nombre: 'Marta Peña', telefono: '53441902', genero: Genero.mujer, fechaRegistro: reg(7)),
      Cliente(id: 8, nombre: 'Luis Herrera', telefono: '53112233', genero: Genero.hombre, fechaRegistro: reg(8)),
      Cliente(id: 9, nombre: 'Elena Cruz', telefono: '55223344', genero: Genero.mujer, correo: 'elena.cruz@correo.com', fechaRegistro: reg(9)),
      Cliente(id: 10, nombre: 'Pablo Rivas', telefono: '52998877', genero: Genero.hombre, fechaRegistro: reg(10)),
    ];

    // La semana de prueba son los offsets -3..+3; el domingo (cerrado) se
    // reubica en -4 o +4 para no chocar con otros días.
    DateTime dia(int off) {
      final base = DateTime(hoy.year, hoy.month, hoy.day + off);
      final o = base.weekday == DateTime.sunday ? (off < 0 ? -4 : 4) : off;
      return DateTime(hoy.year, hoy.month, hoy.day + o);
    }

    Servicio s(int id) => servicios.firstWhere((x) => x.id == id);
    final turnos = <Turno>[];
    var sig = 1;

    // (offset, hora, min, cliente, estilista, servicios, cancelado, notas)
    void t(int off, int h, int m, int cli, int est, List<int> sv, {bool cancelado = false, String? notas}) {
      final d = dia(off);
      final ini = DateTime(d.year, d.month, d.day, h, m);
      final lista = [for (final id in sv) s(id)];
      final fin = DateTime(d.year, d.month, d.day, h, m + lista.fold<int>(0, (a, e) => a + e.duracionMin));
      final estado = cancelado
          ? EstadoTurno.cancelado
          : (fin.isBefore(now) ? EstadoTurno.completado : EstadoTurno.programado);
      final creado = DateTime(d.year, d.month, d.day - 5, 10);
      turnos.add(Turno(
        id: sig++,
        clienteId: cli,
        estilistaId: est,
        servicios: lista,
        inicio: ini,
        notas: notas,
        estado: estado,
        creadoEn: creado,
        modificadoEn: DateTime(creado.year, creado.month, creado.day + 1, 16),
      ));
    }

    // Días pasados
    t(-3, 9, 0, 1, 1, [1]);
    t(-3, 10, 30, 2, 2, [2, 6]);
    t(-2, 9, 30, 3, 5, [4]);
    t(-2, 12, 0, 4, 4, [3], cancelado: true);
    t(-2, 15, 0, 5, 3, [10, 8]);
    t(-1, 10, 0, 7, 1, [1], cancelado: true);
    t(-1, 11, 0, 8, 2, [2, 7]);
    // Hoy (6 turnos; Rafael no tiene; uno termina a las 19:00; uno con 3 servicios)
    t(0, 9, 0, 1, 1, [1]);
    t(0, 10, 0, 2, 2, [2, 6],
        notas: 'Prefiere la máquina en el número 2 a los lados.\nLlega siempre diez minutos antes y pide agua.');
    t(0, 10, 30, 3, 5, [4, 8]);
    t(0, 12, 0, 4, 2, [7]);
    t(0, 14, 0, 9, 3, [10, 8, 9]);
    t(0, 17, 0, 5, 5, [5]); // 17:00 + 120 min = 19:00
    // Próximos días
    t(1, 9, 30, 1, 1, [4]);
    t(2, 11, 0, 8, 4, [3, 7]);
    t(3, 16, 0, 7, 3, [11], notas: _notaLarga);

    return InMemoryStore(
      servicios: servicios,
      estilistas: estilistas,
      clientes: clientes,
      turnos: turnos,
    );
  }
}
