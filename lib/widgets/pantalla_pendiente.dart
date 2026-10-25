import 'package:flutter/material.dart';

/// Marcador temporal; se reemplaza en las siguientes entregas.
class PantallaPendiente extends StatelessWidget {
  const PantallaPendiente(this.titulo, {super.key});
  final String titulo;

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: Text(titulo)),
        body: Center(
          child: Text('Pendiente: $titulo', style: Theme.of(context).textTheme.titleMedium),
        ),
      );
}
