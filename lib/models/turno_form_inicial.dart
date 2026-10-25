/// Datos iniciales que otras pantallas envían al formulario con `extra`.
class TurnoFormInicial {
  const TurnoFormInicial({this.clienteId, this.servicioId, this.fecha});
  final int? clienteId;
  final int? servicioId;
  final DateTime? fecha;
}
