import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../core/app_scope.dart';
import '../core/utils/validadores.dart';
import '../models/models.dart';
import 'controles.dart';

Future<Cliente?> mostrarFormularioCliente(BuildContext context, {Cliente? cliente}) {
  return showModalBottomSheet<Cliente>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    useSafeArea: true,
    builder: (_) => _FormularioCliente(cliente: cliente),
  );
}

class _FormularioCliente extends StatefulWidget {
  const _FormularioCliente({this.cliente});
  final Cliente? cliente;

  @override
  State<_FormularioCliente> createState() => _FormularioClienteState();
}

class _FormularioClienteState extends State<_FormularioCliente> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nombre;
  late final TextEditingController _telefono;
  late final TextEditingController _correo;
  Genero? _genero; // obligatorio: un cliente nuevo empieza sin género
  String? _errorTelefono;
  String? _errorGeneral;
  bool _enviado = false;

  // La acción "siguiente" del teclado recorre nombre → teléfono → correo.
  final _fNombre = FocusNode();
  final _fTelefono = FocusNode();
  final _fCorreo = FocusNode();
  final _fGenero = FocusNode();

  bool get _esEdicion => widget.cliente != null;

  @override
  void initState() {
    super.initState();
    final c = widget.cliente;
    _nombre = TextEditingController(text: c?.nombre ?? '');
    _telefono = TextEditingController(text: c?.telefono ?? '');
    _correo = TextEditingController(text: c?.correo ?? '');
    _genero = c?.genero;
  }

  @override
  void dispose() {
    _nombre.dispose();
    _telefono.dispose();
    _correo.dispose();
    for (final f in [_fNombre, _fTelefono, _fCorreo, _fGenero]) {
      f.dispose();
    }
    super.dispose();
  }

  String? _validarTelefono(String? v) {
    final formato = Validadores.telefono(v);
    if (formato != null) return formato;
    final store = AppScope.of(context).store;
    return store.telefonoDisponible(v!, excluirId: widget.cliente?.id)
        ? null
        : 'Este teléfono ya está registrado';
  }

  String? _validarGenero(Genero? g) => g == null ? 'Selecciona el género' : null;

  /// Lleva el foco al primer campo con error.
  void _enfocarPrimerError() {
    final FocusNode? nodo = Validadores.nombre(_nombre.text) != null
        ? _fNombre
        : _validarTelefono(_telefono.text) != null || _errorTelefono != null
            ? _fTelefono
            : Validadores.correo(_correo.text) != null
                ? _fCorreo
                : _validarGenero(_genero) != null
                    ? _fGenero
                    : null;
    nodo?.requestFocus();
  }

  void _guardar() {
    setState(() {
      _enviado = true;
      _errorTelefono = null;
      _errorGeneral = null;
    });
    if (!_formKey.currentState!.validate()) {
      _enfocarPrimerError();
      return;
    }
    final store = AppScope.of(context).store;
    final resultado = store.guardarCliente(
      id: widget.cliente?.id,
      nombre: _nombre.text,
      telefono: _telefono.text,
      genero: _genero!,
      correo: _correo.text,
    );
    if (resultado.error != null) {
      setState(() => _errorTelefono = resultado.error);
      _fTelefono.requestFocus();
      return;
    }
    Navigator.of(context).pop(resultado.cliente);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        child: Form(
          key: _formKey,
          autovalidateMode: _enviado ? AutovalidateMode.onUserInteraction : AutovalidateMode.disabled,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      _esEdicion ? 'Editar cliente' : 'Nuevo cliente',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                  IconButton(
                    tooltip: 'Cerrar',
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              Text(
                _esEdicion ? 'Actualiza los datos del cliente.' : 'Agrega un cliente para reservar sus turnos.',
                style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant),
              ),
              const SizedBox(height: 18),
              TextFormField(
                controller: _nombre,
                focusNode: _fNombre,
                textCapitalization: TextCapitalization.words,
                textInputAction: TextInputAction.next,
                onFieldSubmitted: (_) => _fTelefono.requestFocus(),
                decoration: const InputDecoration(labelText: 'Nombre completo', hintText: 'Ej. Laura Gómez'),
                validator: Validadores.nombre,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _telefono,
                focusNode: _fTelefono,
                keyboardType: TextInputType.phone,
                textInputAction: TextInputAction.next,
                onFieldSubmitted: (_) => _fCorreo.requestFocus(),
                inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(8)],
                decoration: InputDecoration(
                  labelText: 'Teléfono',
                  hintText: '8 dígitos',
                  errorText: _errorTelefono,
                ),
                onChanged: (_) {
                  if (_errorTelefono != null) setState(() => _errorTelefono = null);
                },
                validator: _validarTelefono,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _correo,
                focusNode: _fCorreo,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.done,
                onFieldSubmitted: (_) => _fCorreo.unfocus(),
                decoration: const InputDecoration(labelText: 'Correo (opcional)', hintText: 'cliente@correo.com'),
                validator: Validadores.correo,
              ),
              const SizedBox(height: 16),
              FormField<Genero>(
                initialValue: _genero,
                validator: _validarGenero,
                builder: (campo) => Focus(
                  focusNode: _fGenero,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'Género',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: campo.hasError ? cs.error : cs.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 6),
                      SelectorSegmentado<Genero?>(
                        opciones: const [
                          OpcionSegmento<Genero?>(Genero.mujer, 'Mujer'),
                          OpcionSegmento<Genero?>(Genero.hombre, 'Hombre'),
                        ],
                        seleccionada: _genero,
                        onChanged: (g) {
                          setState(() => _genero = g);
                          campo.didChange(g);
                        },
                      ),
                      if (campo.hasError) ...[
                        const SizedBox(height: 6),
                        Text(campo.errorText!, style: TextStyle(color: cs.error, fontSize: 12)),
                      ],
                    ],
                  ),
                ),
              ),
              if (_errorGeneral != null) ...[
                const SizedBox(height: 12),
                Text(_errorGeneral!, style: TextStyle(color: cs.error, fontSize: 12)),
              ],
              const SizedBox(height: 22),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Cancelar'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    flex: 2,
                    child: FilledButton.icon(
                      onPressed: _guardar,
                      icon: const Icon(Icons.check, size: 18),
                      label: Text(_esEdicion ? 'Guardar cambios' : 'Guardar cliente'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
