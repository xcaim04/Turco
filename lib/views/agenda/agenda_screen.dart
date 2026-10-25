import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/app_scope.dart';
import '../../core/rules/reglas.dart';
import '../../core/utils/fmt.dart';
import '../../models/models.dart';
import '../../viewmodels/agenda_viewmodel.dart';
import '../../widgets/controles.dart';
import '../../widgets/theme_sheet.dart';

class AgendaScreen extends StatefulWidget {
  const AgendaScreen({super.key, this.estilistaId});
  final int? estilistaId;

  @override
  State<AgendaScreen> createState() => _AgendaScreenState();
}

class _AgendaScreenState extends State<AgendaScreen> {
  AgendaViewModel? _vm;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _vm ??= AgendaViewModel(AppScope.of(context).store, estilistaId: widget.estilistaId);
  }

  @override
  void didUpdateWidget(covariant AgendaScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.estilistaId != widget.estilistaId) {
      _vm?.seleccionarEstilista(widget.estilistaId);
    }
  }

  @override
  void dispose() {
    _vm?.dispose();
    super.dispose();
  }

  Future<void> _elegirFecha(AgendaViewModel vm) async {
    final hoy = Fmt.soloFecha(DateTime.now());
    final f = await showDatePicker(
      context: context,
      initialDate: vm.diaSeleccionado,
      firstDate: Fmt.sumarDias(hoy, -365),
      lastDate: Fmt.sumarDias(hoy, 730),
      selectableDayPredicate: Reglas.diaAbierto,
      helpText: 'Elegir fecha',
    );
    if (f != null) vm.seleccionarDia(f);
  }

  @override
  Widget build(BuildContext context) {
    final vm = _vm;
    if (vm == null) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    return ListenableBuilder(
      listenable: vm,
      builder: (context, _) {
        final cs = Theme.of(context).colorScheme;
        final turnos = vm.turnosDelDia;
        final visibles = vm.turnosVisibles;
        return Scaffold(
          appBar: AppBar(
            toolbarHeight: 60,
            titleSpacing: 16,
            title: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(color: cs.primary, borderRadius: BorderRadius.circular(10)),
                  child: Icon(Icons.content_cut, size: 18, color: cs.onPrimary),
                ),
                const SizedBox(width: 12),
                const Text('Turco', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w600)),
              ],
            ),
            actions: [
              IconButton(
                tooltip: 'Apariencia',
                onPressed: () => mostrarSelectorTema(context),
                icon: const Icon(Icons.brightness_6_outlined),
              ),
              const SizedBox(width: 6),
            ],
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () => context.push('/turno/nuevo'),
            icon: const Icon(Icons.add),
            label: const Text('Nuevo turno'),
          ),
          body: SafeArea(
            top: false,
            child: ContenidoLimitado(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 96),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _cabeceraSemana(context, vm),
                    const SizedBox(height: 8),
                    _tiraDias(vm),
                    const SizedBox(height: 6),
                    Text(
                      'Domingo: salón cerrado',
                      style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant),
                    ),
                    if (turnos.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      _resumen(vm),
                    ],
                    const SizedBox(height: 12),
                    _filtrosEstilista(vm),
                    const SizedBox(height: 10),
                    SelectorSegmentado<EstadoTurno?>(
                      opciones: const [
                        OpcionSegmento<EstadoTurno?>(null, 'Todos'),
                        OpcionSegmento<EstadoTurno?>(EstadoTurno.programado, 'Program.'),
                        OpcionSegmento<EstadoTurno?>(EstadoTurno.completado, 'Complet.'),
                        OpcionSegmento<EstadoTurno?>(EstadoTurno.cancelado, 'Cancel.'),
                      ],
                      seleccionada: vm.filtroEstado,
                      onChanged: vm.seleccionarEstado,
                    ),
                    const SizedBox(height: 12),
                    if (visibles.isEmpty)
                      EstadoVacio(
                        icono: vm.esDomingo ? Icons.lock_clock_outlined : Icons.event_busy_outlined,
                        titulo: vm.esDomingo ? 'El salón está cerrado' : 'No hay turnos para este día',
                        mensaje: vm.esDomingo
                            ? 'Abre otro día de la semana para ver o crear turnos.'
                            : turnos.isEmpty
                                ? 'Crea el primer turno con el botón de abajo.'
                                : 'No hay turnos que coincidan con los filtros elegidos.',
                        accion: vm.sinFiltros
                            ? null
                            : TextButton.icon(
                                onPressed: vm.limpiarFiltros,
                                icon: const Icon(Icons.filter_alt_off_outlined, size: 18),
                                label: const Text('Limpiar filtros'),
                              ),
                      )
                    else
                      for (final t in visibles) ...[
                        _TarjetaTurno(turno: t),
                        const SizedBox(height: 8),
                      ],
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _cabeceraSemana(BuildContext context, AgendaViewModel vm) {
    final cs = Theme.of(context).colorScheme;
    return Row(
      children: [
        IconButton(
          tooltip: 'Semana anterior',
          visualDensity: VisualDensity.compact,
          onPressed: () => vm.cambiarSemana(-1),
          icon: const Icon(Icons.chevron_left, size: 22),
        ),
        Text(vm.mesSemana, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
        IconButton(
          tooltip: 'Semana siguiente',
          visualDensity: VisualDensity.compact,
          onPressed: () => vm.cambiarSemana(1),
          icon: const Icon(Icons.chevron_right, size: 22),
        ),
        const Spacer(),
        TextButton.icon(
          onPressed: () => _elegirFecha(vm),
          icon: const Icon(Icons.calendar_today_outlined, size: 17),
          label: const Text('Elegir fecha', style: TextStyle(fontSize: 13)),
          style: TextButton.styleFrom(foregroundColor: cs.primary, visualDensity: VisualDensity.compact),
        ),
      ],
    );
  }

  Widget _tiraDias(AgendaViewModel vm) {
    final cs = Theme.of(context).colorScheme;
    final hoy = Fmt.soloFecha(DateTime.now());
    return Row(
      children: [
        for (final d in vm.diasSemana) ...[
          Expanded(
            child: Builder(builder: (context) {
              final seleccionado = Fmt.mismoDia(d, vm.diaSeleccionado);
              final domingo = d.weekday == DateTime.sunday;
              final esHoy = Fmt.mismoDia(d, hoy);
              return Opacity(
                opacity: domingo ? 0.4 : 1,
                child: Semantics(
                  button: true,
                  selected: seleccionado,
                  label: '${Fmt.diaCorto(d)} ${d.day}',
                  child: InkWell(
                    onTap: () => vm.seleccionarDia(d),
                    borderRadius: BorderRadius.circular(18),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      height: 60,
                      margin: const EdgeInsets.symmetric(horizontal: 2),
                      decoration: BoxDecoration(
                        color: seleccionado ? cs.primary : Colors.transparent,
                        borderRadius: BorderRadius.circular(18),
                        border: esHoy && !seleccionado ? Border.all(color: cs.outlineVariant) : null,
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            Fmt.diaCorto(d),
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: seleccionado ? cs.onPrimary : cs.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${d.day}',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: seleccionado ? cs.onPrimary : cs.onSurface,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
        ],
      ],
    );
  }

  Widget _resumen(AgendaViewModel vm) {
    final cs = Theme.of(context).colorScheme;
    Widget tarjeta(String valor, String etiqueta, Color color) => Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(color: cs.surfaceContainer, borderRadius: BorderRadius.circular(14)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(valor, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: color)),
                ),
                Text(etiqueta, style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant)),
              ],
            ),
          ),
        );
    return Row(
      children: [
        tarjeta('${vm.programados}', 'Programados', cs.primary),
        const SizedBox(width: 8),
        tarjeta('${vm.completados}', 'Completados', cs.tertiary),
        const SizedBox(width: 8),
        tarjeta(Fmt.dinero(vm.ingresoEstimado), 'Ingreso est.', cs.onSurface),
      ],
    );
  }

  Widget _filtrosEstilista(AgendaViewModel vm) {
    return SizedBox(
      height: 32,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          ChipOpcion(
            texto: 'Todos',
            seleccionado: vm.estilistaId == null,
            onTap: () => vm.seleccionarEstilista(null),
          ),
          for (final e in vm.estilistas) ...[
            const SizedBox(width: 8),
            ChipOpcion(
              texto: e.primerNombre,
              seleccionado: vm.estilistaId == e.id,
              onTap: () => vm.seleccionarEstilista(e.id),
            ),
          ],
        ],
      ),
    );
  }
}

class _TarjetaTurno extends StatelessWidget {
  const _TarjetaTurno({required this.turno});
  final Turno turno;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final store = AppScope.of(context).store;
    final cliente = store.clientePorId(turno.clienteId);
    final estilista = store.estilistaPorId(turno.estilistaId);
    final colorBarra = switch (turno.estado) {
      EstadoTurno.programado => cs.primary,
      EstadoTurno.completado => cs.tertiary,
      EstadoTurno.cancelado => cs.error,
    };
    return Opacity(
      opacity: turno.estado == EstadoTurno.cancelado ? 0.72 : 1,
      child: Material(
        color: cs.surfaceContainer,
        borderRadius: BorderRadius.circular(16),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => context.push('/turno/${turno.id}'),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                Container(
                  width: 4,
                  decoration: BoxDecoration(color: colorBarra, borderRadius: BorderRadius.circular(2)),
                ),
                const SizedBox(width: 10),
                SizedBox(
                  width: 48,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(Fmt.hora(turno.inicio), style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                      Text(Fmt.hora(turno.fin), style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant)),
                    ],
                  ),
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        cliente?.nombre ?? 'Cliente eliminado',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        turno.resumenServicios,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Icon(Icons.person_outline, size: 13, color: cs.onSurfaceVariant),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              estilista?.primerNombre ?? 'Sin estilista',
                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: cs.onSurfaceVariant),
                            ),
                          ),
                          EstadoBadge(turno.estado),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
