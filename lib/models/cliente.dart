import 'enums.dart';

class Cliente {
  const Cliente({
    required this.id,
    required this.nombre,
    required this.telefono,
    required this.genero,
    this.correo,
    required this.fechaRegistro,
  });

  final int id;
  final String nombre;
  final String telefono;
  final Genero genero;
  final String? correo;
  final DateTime fechaRegistro;

  String get inicial => nombre.isEmpty ? '?' : nombre[0].toUpperCase();

  Cliente copyWith({
    String? nombre,
    String? telefono,
    Genero? genero,
    String? correo,
    bool sinCorreo = false,
  }) =>
      Cliente(
        id: id,
        nombre: nombre ?? this.nombre,
        telefono: telefono ?? this.telefono,
        genero: genero ?? this.genero,
        correo: sinCorreo ? null : (correo ?? this.correo),
        fechaRegistro: fechaRegistro,
      );
}
