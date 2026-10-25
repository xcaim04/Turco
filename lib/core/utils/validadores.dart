/// Validadores de formulario reutilizables (devuelven null si es válido).
class Validadores {
  static final _correo = RegExp(r'^[\w.+-]+@[\w-]+(\.[\w-]+)+$');
  static final _tel = RegExp(r'^\d{8}$');

  static String? nombre(String? v) {
    final t = (v ?? '').trim();
    return (t.length < 3 || t.length > 60) ? 'Escribe entre 3 y 60 caracteres' : null;
  }

  static String? telefono(String? v) =>
      _tel.hasMatch((v ?? '').trim()) ? null : 'Debe tener exactamente 8 dígitos';

  static String? correo(String? v) {
    final t = (v ?? '').trim();
    if (t.isEmpty) return null;
    return _correo.hasMatch(t) ? null : 'Escribe un correo válido';
  }
}
