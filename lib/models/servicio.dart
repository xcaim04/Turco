import 'enums.dart';

class Servicio {
  const Servicio({
    required this.id,
    required this.nombre,
    required this.categoria,
    required this.duracionMin,
    required this.precio,
    required this.publico,
  });

  final int id;
  final String nombre;
  final Categoria categoria;
  final int duracionMin;
  final int precio;
  final Publico publico;
}
