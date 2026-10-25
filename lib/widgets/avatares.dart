import 'package:flutter/material.dart';
import '../models/models.dart';

class AvatarCliente extends StatelessWidget {
  const AvatarCliente({
    super.key,
    required this.nombre,
    required this.genero,
    this.size = 44,
  });

  final String nombre;
  final Genero genero;
  final double size;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final esMujer = genero == Genero.mujer;
    final fondo = esMujer ? cs.primaryContainer : cs.tertiaryContainer;
    final texto = esMujer ? cs.onPrimaryContainer : cs.onTertiaryContainer;
    final inicial = nombre.trim().isEmpty ? '?' : nombre.trim()[0].toUpperCase();
    return Semantics(
      label: 'Avatar de $nombre',
      child: Container(
        width: size,
        height: size,
        alignment: Alignment.center,
        decoration: BoxDecoration(color: fondo, shape: BoxShape.circle),
        child: Text(
          inicial,
          style: TextStyle(
            color: texto,
            fontSize: size * 0.4,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

class AvatarEstilista extends StatelessWidget {
  const AvatarEstilista({
    super.key,
    required this.estilista,
    this.size = 56,
  });

  final Estilista estilista;
  final double size;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final inicial = estilista.nombre.trim().isEmpty
        ? '?'
        : estilista.nombre.trim()[0].toUpperCase();
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: cs.primaryContainer,
        shape: BoxShape.circle,
        border: Border.all(color: cs.surface, width: 2),
      ),
      clipBehavior: Clip.antiAlias,
      child: Image.asset(
        estilista.avatar,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => Center(
          child: Text(
            inicial,
            style: TextStyle(
              color: cs.onPrimaryContainer,
              fontSize: size * 0.4,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}
