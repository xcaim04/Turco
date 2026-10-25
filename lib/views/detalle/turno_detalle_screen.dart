import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/app_scope.dart';
import '../../core/utils/fmt.dart';
import '../../models/models.dart';
import '../../viewmodels/turno_detalle_viewmodel.dart';
import '../../widgets/avatares.dart';
import '../../widgets/controles.dart';
import '../../widgets/dialogos_turno.dart';

class TurnoDetalleScreen extends StatefulWidget {
  const TurnoDetalleScreen({super.key, required this.turnoId});
  final int? turnoId;

  @override
  State<TurnoDetalleScreen> createState() => _TurnoDetalleScreenState();
}

class _TurnoDetalleScreenState extends State<TurnoDetalleScreen> {
  TurnoDetalleViewModel? _vm;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_vm == null && widget.turnoId != null) {
      _vm = TurnoDetalleViewModel(AppScope.of(context).store, widget.turnoId!);
    }
  }

  @override
  void dispose() {
    _vm?.dispose();
    super.dispose();
  }

  void _volver() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/agenda');
    }
  }

  Future<void> _cambiarEstado(TurnoDetalleViewModel vm, EstadoTurno nuevo) async {
    if (!await confirmarCambioEstado(context, nuevo) || !mounted) return;
    final error = nuevo == EstadoTurno.completado ? vm.completar() : vm.cancelar();
    if (!mounted) return;
    avisar(
      context,
      error ?? (nuevo == EstadoTurno.completado ? 'Turno completado' : 'Turno cancelado'),
      error: error != null,
    );
  }

  Future<void> _editar(Turno turno) async {
    final guardado = await context.push<Turno>('/turno/${turno.id}/editar');
    if (guardado != null && mounted) {
      avisar(context, mensajeTurnoGuardado(guardado, edicion: true));
    }
  }

  @override
  Widget build(BuildContext context) {
    final vm = _vm;
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 58,
        leading: IconButton(
          tooltip: 'Volver',
          onPressed: _volver,
          icon: const Icon(Icons.chevron_left, size: 26),
        ),
        titleSpacing: 0,
        title: const Text('Detalle del turno'),
      ),
      body: vm == null
          ? _NoEncontrado(onVolver: _volver)
          : ListenableBuilder(
              listenable: vm,
              builder: (context, _) {
                final turno = vm.turno;
                if (turno == null) return _NoEncontrado(onVolver: _volver);
                return SafeArea(
                  top: false,
                  child: Column(
                    children: [
                      Expanded(
                        child: ContenidoLimitado(
                          child: ListView(
                            padding: const EdgeInsets.fromLTRB(16, 4, 16, 20),
                            children: [
                              _TarjetaHorario(turno: turno, cliente: vm.cliente, estilista: vm.estilista),
                              const SizedBox(height: 12),
                              _TarjetaServicios(turno: turno),
                              if (turno.notas?.trim().isNotEmpty == true) ...[
                                const SizedBox(height: 12),
                                _TarjetaNotas(notas: turno.notas!),
                              ],
                              const SizedBox(height: 10),
                              Text(
                                'Creado el ${Fmt.ddMMyyyy(turno.creadoEn)} ${Fmt.hora(turno.creadoEn)} · '
                                'Modificado el ${Fmt.ddMMyyyy(turno.modificadoEn)} ${Fmt.hora(turno.modificadoEn)}',
                                style: TextStyle(fontSize: 11, color: Theme.of(context).colorScheme.onSurfaceVariant),
                              ),
                            ],
                          ),
                        ),
                      ),
                      _Acciones(
                        turno: turno,
                        onEditar: () => _editar(turno),
                        onCompletar: () => _cambiarEstado(vm, EstadoTurno.completado),
                        onCancelar: () => _cambiarEstado(vm, EstadoTurno.cancelado),
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}

class _TarjetaHorario extends StatelessWidget {
  const _TarjetaHorario({required this.turno, this.cliente, this.estilista});
  final Turno turno;
  final Cliente? cliente;
  final Estilista? estilista;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final c = cliente;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: cs.surfaceContainer, borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (c != null) ...[
                AvatarCliente(nombre: c.nombre, genero: c.genero, size: 48),
                const SizedBox(width: 12),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      c?.nombre ?? 'Cliente no disponible',
                      style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
                    ),
                    if (c != null) ...[
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Icon(Icons.phone, size: 13, color: cs.onSurfaceVariant),
                          const SizedBox(width: 4),
                          Text(Fmt.telefono(c.telefono), style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant)),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              EstadoBadge(turno.estado),
            ],
          ),
          const SizedBox(height: 14),
          _dato(context, Icons.calendar_today_outlined, 'Fecha', Fmt.fechaLarga(turno.inicio)),
          const SizedBox(height: 10),
          _dato(
            context,
            Icons.schedule,
            'Hora',
            '${Fmt.hora(turno.inicio)} a ${Fmt.hora(turno.fin)} (${Fmt.duracion(turno.duracionMin)})',
          ),
          const SizedBox(height: 10),
          _dato(context, Icons.person_outline, 'Estilista', estilista?.nombre ?? 'No disponible'),
        ],
      ),
    );
  }

  Widget _dato(BuildContext context, IconData icono, String etiqueta, String valor) {
    final cs = Theme.of(context).colorScheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 2),
          child: Icon(icono, size: 18, color: cs.primary),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(etiqueta, style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant)),
              Text(valor, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
            ],
          ),
        ),
      ],
    );
  }
}

class _TarjetaServicios extends StatelessWidget {
  const _TarjetaServicios({required this.turno});
  final Turno turno;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: cs.surfaceContainer, borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Servicios', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
          const SizedBox(height: 10),
          for (var i = 0; i < turno.servicios.length; i++) ...[
            if (i > 0) Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Divider(height: 1, color: cs.outlineVariant),
            ),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(turno.servicios[i].nombre, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                      Text(
                        Fmt.duracion(turno.servicios[i].duracionMin),
                        style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Text(Fmt.dinero(turno.servicios[i].precio), style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
              ],
            ),
          ],
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Divider(height: 1, color: cs.outlineVariant),
          ),
          Row(
            children: [
              const Expanded(child: Text('Total', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600))),
              Text(Fmt.dinero(turno.total), style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: cs.primary)),
            ],
          ),
        ],
      ),
    );
  }
}

class _TarjetaNotas extends StatefulWidget {
  const _TarjetaNotas({required this.notas});
  final String notas;

  @override
  State<_TarjetaNotas> createState() => _TarjetaNotasState();
}

class _TarjetaNotasState extends State<_TarjetaNotas> {
  final _scroll = ScrollController();

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final notas = widget.notas;
    final cs = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: cs.surfaceContainer, borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Notas', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          // Área con scroll propio: una nota larga no estira la pantalla.
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 140),
            child: Scrollbar(
              controller: _scroll,
              thumbVisibility: true,
              child: SingleChildScrollView(
                controller: _scroll,
                padding: const EdgeInsets.only(right: 10),
                child: Text(notas, style: TextStyle(fontSize: 13, height: 1.45, color: cs.onSurfaceVariant)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Acciones extends StatelessWidget {
  const _Acciones({
    required this.turno,
    required this.onEditar,
    required this.onCompletar,
    required this.onCancelar,
  });
  final Turno turno;
  final VoidCallback onEditar;
  final VoidCallback onCompletar;
  final VoidCallback onCancelar;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return SafeArea(
      top: false,
      child: Container(
        width: double.infinity,
        color: cs.surfaceContainer,
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
        child: turno.estado == EstadoTurno.programado
            ? Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: double.infinity,
                    height: 44,
                    child: OutlinedButton.icon(
                      onPressed: onEditar,
                      style: _forma(cs.outline),
                      icon: Icon(Icons.edit_outlined, size: 18, color: cs.primary),
                      label: Text('Editar', style: TextStyle(color: cs.primary)),
                    ),
                  ),
                  const SizedBox(height: 6),
                  SizedBox(
                    width: double.infinity,
                    height: 44,
                    child: FilledButton.icon(
                      onPressed: onCompletar,
                      style: FilledButton.styleFrom(
                        backgroundColor: cs.secondaryContainer,
                        foregroundColor: cs.onSecondaryContainer,
                        shape: const StadiumBorder(),
                        textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                      ),
                      icon: const Icon(Icons.check, size: 18),
                      label: const Text('Completar'),
                    ),
                  ),
                  const SizedBox(height: 6),
                  SizedBox(
                    width: double.infinity,
                    height: 44,
                    child: OutlinedButton.icon(
                      onPressed: onCancelar,
                      style: _forma(cs.outline, color: cs.error),
                      icon: const Icon(Icons.block, size: 18),
                      label: const Text('Cancelar'),
                    ),
                  ),
                ],
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.lock_outline, size: 16, color: cs.onSurfaceVariant),
                  const SizedBox(width: 8),
                  Text(
                    turno.estado == EstadoTurno.completado
                        ? 'Turno completado: solo lectura'
                        : 'Turno cancelado: solo lectura',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: cs.onSurfaceVariant),
                  ),
                ],
              ),
      ),
    );
  }

  ButtonStyle _forma(Color borde, {Color? color}) => OutlinedButton.styleFrom(
        side: BorderSide(color: borde),
        foregroundColor: color,
        shape: const StadiumBorder(),
        textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
      );
}

class _NoEncontrado extends StatelessWidget {
  const _NoEncontrado({required this.onVolver});
  final VoidCallback onVolver;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 112,
              height: 112,
              decoration: BoxDecoration(color: cs.errorContainer, shape: BoxShape.circle),
              child: Icon(Icons.search_off, size: 52, color: cs.error),
            ),
            const SizedBox(height: 18),
            const Text('No encontramos este turno', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Text(
              'El turno no existe o ya no está disponible.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant),
            ),
            const SizedBox(height: 18),
            FilledButton.icon(
              onPressed: onVolver,
              style: FilledButton.styleFrom(shape: const StadiumBorder(), minimumSize: const Size(0, 44)),
              icon: const Icon(Icons.arrow_back, size: 18),
              label: const Text('Volver a la agenda'),
            ),
          ],
        ),
      ),
    );
  }
}
