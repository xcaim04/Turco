import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../core/app_scope.dart';
import '../core/utils/fmt.dart';
import '../models/models.dart';
import 'avatares.dart';
import 'controles.dart';
import 'cliente_form_sheet.dart';
import 'dialogos_turno.dart';

enum AccionCliente { nuevoTurno, editar, eliminado }

Future<void> mostrarDetalleCliente(BuildContext context, Cliente cliente) async {
  final accion = await showModalBottomSheet<AccionCliente>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    useSafeArea: true,
    builder: (_) => _DetalleCliente(clienteId: cliente.id),
  );
  if (!context.mounted || accion == null) return;
  switch (accion) {
    case AccionCliente.nuevoTurno:
      final turno = await context.push<Turno>('/turno/nuevo', extra: TurnoFormInicial(clienteId: cliente.id));
      if (turno != null && context.mounted) {
        avisar(context, mensajeTurnoGuardado(turno, edicion: false));
      }
    case AccionCliente.editar:
      final actual = AppScope.of(context).store.clientePorId(cliente.id);
      if (actual == null) return;
      final guardado = await mostrarFormularioCliente(context, cliente: actual);
      if (guardado != null && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Cliente actualizado')));
      }
    case AccionCliente.eliminado:
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${cliente.nombre} fue eliminado')));
      }
  }
}

class _DetalleCliente extends StatelessWidget {
  const _DetalleCliente({required this.clienteId});
  final int clienteId;

  @override
  Widget build(BuildContext context) {
    final store = AppScope.of(context).store;
    return ListenableBuilder(
      listenable: store,
      builder: (context, _) {
        final cliente = store.clientePorId(clienteId);
        if (cliente == null) {
          return const SizedBox(height: 220, child: Center(child: Text('El cliente ya no existe')));
        }
        final cs = Theme.of(context).colorScheme;
        final turnos = store.turnosDeCliente(clienteId);
        return ConstrainedBox(
          constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * 0.78),
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    AvatarCliente(nombre: cliente.nombre, genero: cliente.genero, size: 56),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(cliente.nombre, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                          const SizedBox(height: 3),
                          Row(children: [
                            Icon(Icons.phone_outlined, size: 13, color: cs.onSurfaceVariant),
                            const SizedBox(width: 4),
                            Text(Fmt.telefono(cliente.telefono), style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant)),
                          ]),
                          if (cliente.correo != null) ...[
                            const SizedBox(height: 2),
                            Row(children: [
                              Icon(Icons.mail_outline, size: 13, color: cs.onSurfaceVariant),
                              const SizedBox(width: 4),
                              Flexible(child: Text(cliente.correo!, style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant))),
                            ]),
                          ],
                        ],
                      ),
                    ),
                    EstadoBadge(
                      cliente.genero == Genero.mujer ? EstadoTurno.programado : EstadoTurno.completado,
                      compacto: true,
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: Text('Historial de turnos · ${turnos.length}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                    ),
                    Text('${store.programadosDeCliente(clienteId)} programados', style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant)),
                  ],
                ),
                const SizedBox(height: 8),
                if (turnos.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(color: cs.surfaceContainer, borderRadius: BorderRadius.circular(12)),
                    child: Text('Este cliente todavía no tiene turnos.', style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant)),
                  )
                else
                  for (var i = 0; i < turnos.length; i++) ...[
                    if (i > 0) Divider(color: cs.outlineVariant),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 7),
                      child: Row(
                        children: [
                          SizedBox(
                            width: 42,
                            child: Text(Fmt.ddMM(turnos[i].inicio), style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant)),
                          ),
                          Expanded(
                            child: Text(turnos[i].resumenServicios, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 13)),
                          ),
                          const SizedBox(width: 8),
                          EstadoBadge(turnos[i].estado, compacto: true),
                        ],
                      ),
                    ),
                  ],
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: FilledButton.icon(
                        onPressed: () => Navigator.of(context).pop(AccionCliente.nuevoTurno),
                        icon: const Icon(Icons.add, size: 18),
                        label: const Text('Nuevo turno'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => Navigator.of(context).pop(AccionCliente.editar),
                        icon: const Icon(Icons.edit_outlined, size: 16),
                        label: const Text('Editar'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton.outlined(
                      tooltip: 'Eliminar cliente',
                      onPressed: () => _eliminar(context, cliente),
                      icon: Icon(Icons.delete_outline, color: cs.error),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _eliminar(BuildContext context, Cliente cliente) async {
    final store = AppScope.of(context).store;
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('¿Eliminar cliente?'),
        content: Text(
          store.programadosDeCliente(cliente.id) > 0
              ? '${cliente.nombre} tiene turnos programados. Primero debes cancelarlos o completarlos.'
              : 'Se eliminará ${cliente.nombre} y su historial de turnos. Esta acción no se puede deshacer.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Volver')),
          if (store.programadosDeCliente(cliente.id) == 0)
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.error),
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Eliminar'),
            ),
        ],
      ),
    );
    if (confirmar != true || !context.mounted) return;
    final error = store.eliminarCliente(cliente.id);
    if (error != null) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
      }
      return;
    }
    if (context.mounted) Navigator.of(context).pop(AccionCliente.eliminado);
  }
}
