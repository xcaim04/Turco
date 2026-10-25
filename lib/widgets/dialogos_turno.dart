import 'package:flutter/material.dart';
import '../core/utils/fmt.dart';
import '../models/models.dart';

/// Pide confirmación antes de completar o cancelar un turno.
/// Lo usan la Agenda (acciones rápidas) y el Detalle de turno.
Future<bool> confirmarCambioEstado(BuildContext context, EstadoTurno nuevo) async {
  final cancelar = nuevo == EstadoTurno.cancelado;
  final ok = await showDialog<bool>(
    context: context,
    builder: (context) {
      final cs = Theme.of(context).colorScheme;
      return AlertDialog(
        title: Text(cancelar ? '¿Cancelar turno?' : '¿Completar turno?'),
        content: Text(
          cancelar
              ? 'Esta acción libera el horario y no se puede deshacer.'
              : 'El turno pasará a solo lectura y ya no se podrá editar.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Volver')),
          FilledButton(
            style: cancelar
                ? FilledButton.styleFrom(backgroundColor: cs.error, foregroundColor: cs.onError)
                : null,
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(cancelar ? 'Cancelar turno' : 'Completar'),
          ),
        ],
      );
    },
  );
  return ok == true;
}

/// SnackBar de confirmación o de error para acciones sobre turnos.
void avisar(BuildContext context, String texto, {bool error = false}) {
  final cs = Theme.of(context).colorScheme;
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Text(texto, style: error ? TextStyle(color: cs.onErrorContainer) : null),
        backgroundColor: error ? cs.errorContainer : null,
      ),
    );
}

/// Texto del SnackBar que se muestra al volver del formulario de turno.
String mensajeTurnoGuardado(Turno t, {required bool edicion}) =>
    '${edicion ? 'Turno actualizado' : 'Turno creado'} para el ${Fmt.fechaSnack(t.inicio)} a las ${Fmt.hora(t.inicio)}';
