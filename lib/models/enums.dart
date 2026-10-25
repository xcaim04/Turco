enum Categoria {
  corte('Corte'),
  color('Color'),
  barba('Barba'),
  peinado('Peinado'),
  tratamiento('Tratamiento');

  const Categoria(this.label);
  final String label;
  String get imagen => 'assets/images/categorias/$name.png';
}

enum Publico {
  mujeres('Mujeres'),
  hombres('Hombres'),
  unisex('Unisex');

  const Publico(this.label);
  final String label;
}

enum Genero {
  mujer('Mujer'),
  hombre('Hombre');

  const Genero(this.label);
  final String label;
}

/// Filtro "Todos / Mujeres / Hombres" para servicios y clientes.
enum FiltroPublico {
  todos('Todos'),
  mujeres('Mujeres'),
  hombres('Hombres');

  const FiltroPublico(this.label);
  final String label;

  bool aceptaPublico(Publico p) => switch (this) {
        FiltroPublico.todos => true,
        FiltroPublico.mujeres => p != Publico.hombres,
        FiltroPublico.hombres => p != Publico.mujeres,
      };

  bool aceptaGenero(Genero g) => switch (this) {
        FiltroPublico.todos => true,
        FiltroPublico.mujeres => g == Genero.mujer,
        FiltroPublico.hombres => g == Genero.hombre,
      };

  static FiltroPublico deGenero(Genero g) =>
      g == Genero.mujer ? FiltroPublico.mujeres : FiltroPublico.hombres;
}

enum EstadoTurno {
  programado('Programado'),
  completado('Completado'),
  cancelado('Cancelado');

  const EstadoTurno(this.label);
  final String label;
}
