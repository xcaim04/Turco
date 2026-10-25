import 'package:flutter_test/flutter_test.dart';
import 'package:turco/core/rules/reglas.dart';
import 'package:turco/core/utils/fmt.dart';
import 'package:turco/data/seed_data.dart';
import 'package:turco/models/models.dart';
import 'package:turco/viewmodels/turno_form_viewmodel.dart';
import 'package:turco/views/servicios/servicios_screen.dart';

void main() {
  // El ViewModel trabaja con DateTime.now(); se usa un día abierto lejos de
  // los turnos de prueba (que van de -4 a +4 días).
  DateTime diaLibre() {
    final d = Fmt.sumarDias(Fmt.soloFecha(DateTime.now()), 8);
    return Reglas.diaAbierto(d) ? d : Fmt.sumarDias(d, 1);
  }

  test('un formulario vacío no valida y explica cada campo', () {
    final vm = TurnoFormViewModel(SeedData.crear());
    expect(vm.validarCliente(), isNotNull);
    expect(vm.validarServicios(), isNotNull);
    expect(vm.validarEstilista(), 'Primero elige los servicios');
    expect(vm.validarHora(), isNotNull);
    expect(vm.validar(), isFalse);
    expect(vm.intentoGuardar, isTrue);
  });

  test('las notas admiten hasta 500 caracteres', () {
    final vm = TurnoFormViewModel(SeedData.crear());
    expect(vm.validarNotas('a' * 500), isNull);
    expect(vm.validarNotas('a' * 501), isNotNull);
  });

  test('la fecha inicial enviada con extra nunca queda en el pasado', () {
    final hoy = Fmt.soloFecha(DateTime.now());
    final vm = TurnoFormViewModel(
      SeedData.crear(),
      inicial: TurnoFormInicial(fecha: Fmt.sumarDias(hoy, -10)),
    );
    expect(vm.fecha.isBefore(hoy), isFalse);
    expect(Reglas.diaAbierto(vm.fecha), isTrue);
  });

  test('cambiar servicios limpia al estilista que no los realiza y avisa', () {
    final vm = TurnoFormViewModel(SeedData.crear(), inicial: const TurnoFormInicial(servicioId: 6)); // Barba
    vm.cambiarEstilista(2); // Pedro: solo servicios de hombres
    expect(vm.estilistaId, 2);
    vm.alternarServicio(1); // Corte mujer
    expect(vm.estilistaId, isNull);
    expect(vm.avisoEstilista, contains('Pedro'));
    expect(vm.estilistasDisponibles.every((e) => e.realizaTodos(vm.serviciosSeleccionados)), isTrue);
  });

  test('guarda un turno válido y rechaza otro que se solapa', () {
    final store = SeedData.crear();
    final dia = diaLibre();
    final diez = DateTime(dia.year, dia.month, dia.day, 10);

    final vm = TurnoFormViewModel(store, inicial: TurnoFormInicial(clienteId: 6, servicioId: 2, fecha: dia));
    vm.cambiarEstilista(4);
    vm.seleccionarHora(diez);
    final turno = vm.guardar();
    expect(turno, isNotNull);
    expect(store.turnos.length, 17);
    expect(vm.hayCambios, isFalse);

    // Mismo estilista a la misma hora: la franja aparece ocupada y no se guarda.
    final otro = TurnoFormViewModel(store, inicial: TurnoFormInicial(clienteId: 10, servicioId: 2, fecha: dia));
    otro.cambiarEstilista(4);
    expect(otro.estadoFranja(diez), EstadoFranja.ocupada);
    otro.seleccionarHora(diez);
    expect(otro.hora, isNull);
    expect(otro.guardar(), isNull);
  });

  test('al editar, el propio turno no cuenta como solape', () {
    final store = SeedData.crear();
    final programado = store.turnos.firstWhere((t) => t.esProgramado && t.inicio.isAfter(DateTime.now()));
    final vm = TurnoFormViewModel(store, turnoId: programado.id);
    expect(vm.estadoFranja(programado.inicio), EstadoFranja.elegida);
    expect(vm.validar(), isTrue);
  });

  test('columnas del catálogo de servicios según el ancho', () {
    expect(columnasServicios(360), 2);
    expect(columnasServicios(599), 2);
    expect(columnasServicios(600), 3);
    expect(columnasServicios(840), 3);
    expect(columnasServicios(841), 4);
  });
}
