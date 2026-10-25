import 'servicio.dart';

class Estilista {
  const Estilista({
    required this.id,
    required this.nombre,
    required this.avatar,
    required this.servicioIds,
  });

  final int id;
  final String nombre;
  final String avatar;
  final List<int> servicioIds;

  String get primerNombre => nombre.split(' ').first;
  bool realiza(Servicio s) => servicioIds.contains(s.id);
  bool realizaTodos(Iterable<Servicio> l) => l.every(realiza);
}
