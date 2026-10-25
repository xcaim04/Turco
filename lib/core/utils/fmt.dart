/// Formateo y utilidades de fecha/texto (sin paquetes externos).
class Fmt {
  static const _dias = ['Lun', 'Mar', 'Mié', 'Jue', 'Vie', 'Sáb', 'Dom'];
  static const _diasLargos = [
    'Lunes', 'Martes', 'Miércoles', 'Jueves', 'Viernes', 'Sábado', 'Domingo'
  ];
  static const _meses = [
    'enero', 'febrero', 'marzo', 'abril', 'mayo', 'junio', 'julio', 'agosto',
    'septiembre', 'octubre', 'noviembre', 'diciembre'
  ];

  static String _dos(int n) => n.toString().padLeft(2, '0');

  static String hora(DateTime d) => '${_dos(d.hour)}:${_dos(d.minute)}';
  static String diaCorto(DateTime d) => _dias[d.weekday - 1];
  static String fechaLarga(DateTime d) =>
      '${_diasLargos[d.weekday - 1]} ${d.day} de ${_meses[d.month - 1]} de ${d.year}';
  static String fechaSnack(DateTime d) =>
      '${_dias[d.weekday - 1].toLowerCase()} ${d.day} de ${_meses[d.month - 1]}';
  static String mesAnio(DateTime d) {
    final m = _meses[d.month - 1];
    return '${m[0].toUpperCase()}${m.substring(1)} ${d.year}';
  }

  static String ddMM(DateTime d) => '${_dos(d.day)}/${_dos(d.month)}';
  static String ddMMyyyy(DateTime d) => '${ddMM(d)}/${d.year}';

  static String duracion(int min) {
    final h = min ~/ 60, m = min % 60;
    if (h == 0) return '$m min';
    if (m == 0) return '$h h';
    return '$h h $m min';
  }

  static String dinero(int v) => '\$ $v';
  static String turnos(int n) => n == 1 ? '1 turno' : '$n turnos';
  static String telefono(String t) => t.length == 8
      ? '${t.substring(0, 2)} ${t.substring(2, 5)} ${t.substring(5)}'
      : t;

  /// Minúsculas y sin acentos, para búsquedas.
  static String normalizar(String s) {
    const from = 'áàäâãéèëêíìïîóòöôõúùüûñç';
    const to = 'aaaaaeeeeiiiiooooouuuunc';
    var r = s.toLowerCase();
    for (var i = 0; i < from.length; i++) {
      r = r.replaceAll(from[i], to[i]);
    }
    return r;
  }

  static DateTime soloFecha(DateTime d) => DateTime(d.year, d.month, d.day);
  static DateTime sumarDias(DateTime d, int n) => DateTime(d.year, d.month, d.day + n);
  static bool mismoDia(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
  static DateTime lunesDe(DateTime d) => DateTime(d.year, d.month, d.day - (d.weekday - 1));
}
