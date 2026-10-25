import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/app_scope.dart';
import '../../core/rules/reglas.dart';
import '../../core/utils/fmt.dart';
import '../../data/in_memory_store.dart';
import '../../models/models.dart';
import '../../viewmodels/turno_form_viewmodel.dart';
import '../../widgets/avatares.dart';
import '../../widgets/cliente_form_sheet.dart';
import '../../widgets/controles.dart';
import '../../widgets/dialogos_turno.dart';

class TurnoFormScreen extends StatefulWidget {
  const TurnoFormScreen({super.key, this.turnoId, this.inicial});
  final int? turnoId;
  final TurnoFormInicial? inicial;

  @override
  State<TurnoFormScreen> createState() => _TurnoFormScreenState();
}

class _TurnoFormScreenState extends State<TurnoFormScreen> {
  TurnoFormViewModel? _vm;
  late final TextEditingController _notas;
  bool _permitirSalida = false;
  final _formKey = GlobalKey<FormState>();
  final _scroll = ScrollController();

  // Un FocusNode por campo, en el orden del formulario.
  final _fCliente = FocusNode(debugLabel: 'cliente');
  final _fServicios = FocusNode(debugLabel: 'servicios');
  final _fEstilista = FocusNode(debugLabel: 'estilista');
  final _fFecha = FocusNode(debugLabel: 'fecha');
  final _fHora = FocusNode(debugLabel: 'hora');
  final _fNotas = FocusNode(debugLabel: 'notas');

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_vm == null) {
      _vm = TurnoFormViewModel(
        AppScope.of(context).store,
        inicial: widget.inicial,
        turnoId: widget.turnoId,
      );
      _notas = TextEditingController(text: _vm!.notas);
    }
  }

  @override
  void dispose() {
    _notas.dispose();
    _scroll.dispose();
    for (final f in [_fCliente, _fServicios, _fEstilista, _fFecha, _fHora, _fNotas]) {
      f.dispose();
    }
    _vm?.dispose();
    super.dispose();
  }

  Future<void> _intentarSalir() async {
    final vm = _vm;
    if (vm == null) return;
    if (!vm.hayCambios || _permitirSalida) {
      context.pop();
      return;
    }
    final descartar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('¿Descartar cambios?'),
        content: const Text('Los datos que ingresaste no se guardarán.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Seguir editando')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.error),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Descartar'),
          ),
        ],
      ),
    );
    if (descartar == true && mounted) {
      setState(() => _permitirSalida = true);
      context.pop();
    }
  }

  /// Valida el Form; si todo es correcto guarda y devuelve el turno a la
  /// pantalla anterior con `context.pop(turno)`.
  Future<void> _guardar() async {
    final vm = _vm;
    if (vm == null) return;
    final formOk = _formKey.currentState!.validate();
    final turno = formOk ? vm.guardar() : null;
    if (turno == null) {
      // Marca el intento (los campos pasan a validarse solos) y lleva el foco
      // al primer campo con error cuando el formulario se haya redibujado.
      if (!formOk) vm.validar();
      WidgetsBinding.instance.addPostFrameCallback((_) => _enfocarPrimerError());
      return;
    }
    setState(() => _permitirSalida = true);
    context.pop(turno);
  }

  void _enfocarPrimerError() {
    final vm = _vm;
    if (vm == null || !mounted) return;
    final campos = <(String?, FocusNode)>[
      (vm.validarCliente(), _fCliente),
      (vm.validarServicios(), _fServicios),
      (vm.validarEstilista(), _fEstilista),
      (vm.validarFecha(), _fFecha),
      (vm.validarHora(), _fHora),
      (vm.validarNotas(_notas.text), _fNotas),
    ];
    for (final (error, nodo) in campos) {
      if (error == null) continue;
      nodo.requestFocus();
      final ctx = nodo.context;
      if (ctx != null) {
        Scrollable.ensureVisible(ctx, duration: const Duration(milliseconds: 220), alignment: 0.1);
      }
      return;
    }
  }

  /// Cambios que pueden dejar sin efecto al estilista elegido: se avisa.
  void _conAvisoEstilista(void Function() cambio) {
    final vm = _vm!;
    final antes = vm.estilistaId;
    cambio();
    if (antes != null && vm.estilistaId == null && vm.avisoEstilista != null) {
      avisar(context, vm.avisoEstilista!);
    }
  }

  Future<void> _elegirCliente() async {
    final vm = _vm!;
    final store = AppScope.of(context).store;
    final id = await showModalBottomSheet<int>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (_) => _SelectorCliente(store: store, actual: vm.clienteId),
    );
    if (id != null) _conAvisoEstilista(() => vm.cambiarCliente(id));
  }

  Future<void> _crearCliente() async {
    final c = await mostrarFormularioCliente(context);
    if (c != null) _conAvisoEstilista(() => _vm?.cambiarCliente(c.id));
  }

  Future<void> _elegirEstilista() async {
    final vm = _vm!;
    final id = await showModalBottomSheet<int>(
      context: context,
      useSafeArea: true,
      showDragHandle: true,
      builder: (context) => _SelectorEstilista(
        estilistas: vm.estilistasDisponibles,
        actual: vm.estilistaId,
      ),
    );
    if (id != null) vm.cambiarEstilista(id);
  }

  Future<void> _elegirFecha() async {
    final vm = _vm!;
    final hoy = Fmt.soloFecha(DateTime.now());
    final f = await showDatePicker(
      context: context,
      initialDate: vm.fecha.isBefore(hoy) ? hoy : vm.fecha,
      firstDate: hoy,
      lastDate: Fmt.sumarDias(hoy, 365),
      selectableDayPredicate: Reglas.diaAbierto,
      helpText: 'Elegir fecha',
    );
    if (f != null) vm.cambiarFecha(f);
  }

  @override
  Widget build(BuildContext context) {
    final vm = _vm;
    if (vm == null) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    return ListenableBuilder(
      listenable: vm,
      builder: (context, _) => PopScope(
        canPop: !vm.hayCambios || _permitirSalida,
        onPopInvokedWithResult: (didPop, _) {
          if (!didPop) _intentarSalir();
        },
        child: Scaffold(
          appBar: AppBar(
            toolbarHeight: 58,
            leading: IconButton(
              tooltip: 'Volver',
              onPressed: _intentarSalir,
              icon: const Icon(Icons.chevron_left, size: 26),
            ),
            titleSpacing: 0,
            title: Text(vm.esEdicion ? 'Editar turno' : 'Nuevo turno'),
          ),
          bottomNavigationBar: _BarraGuardar(vm: vm, onGuardar: _guardar, onCancelar: _intentarSalir),
          body: SafeArea(
            top: false,
            child: ContenidoLimitado(
              child: Form(
                key: _formKey,
                // Tras el primer intento de guardar, cada campo se revalida al cambiar.
                autovalidateMode: vm.intentoGuardar ? AutovalidateMode.always : AutovalidateMode.disabled,
                child: ListView(
                  controller: _scroll,
                  keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 20),
                  children: [
                    FormField<int>(
                      validator: (_) => vm.validarCliente(),
                      builder: (campo) => CampoSeleccion(
                        etiqueta: 'Cliente',
                        icono: Icons.person_outline,
                        valor: vm.cliente?.nombre,
                        placeholder: 'Selecciona un cliente',
                        onTap: _elegirCliente,
                        error: campo.errorText,
                        focusNode: _fCliente,
                      ),
                    ),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: TextButton.icon(
                        onPressed: _crearCliente,
                        icon: const Icon(Icons.person_add_alt_1, size: 17),
                        label: const Text('Crear cliente nuevo'),
                        style: TextButton.styleFrom(visualDensity: VisualDensity.compact),
                      ),
                    ),
                    const SizedBox(height: 4),
                    _etiqueta(context, 'Servicios para'),
                    const SizedBox(height: 6),
                    SelectorSegmentado<FiltroPublico>(
                      opciones: const [
                        OpcionSegmento(FiltroPublico.todos, 'Todos'),
                        OpcionSegmento(FiltroPublico.mujeres, 'Mujeres'),
                        OpcionSegmento(FiltroPublico.hombres, 'Hombres'),
                      ],
                      seleccionada: vm.publico,
                      onChanged: (f) => _conAvisoEstilista(() => vm.cambiarPublico(f)),
                    ),
                    const SizedBox(height: 14),
                    FormField<Set<int>>(
                      validator: (_) => vm.validarServicios(),
                      builder: (campo) => Focus(
                        focusNode: _fServicios,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    'Servicios',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: campo.hasError ? Theme.of(context).colorScheme.error : null,
                                    ),
                                  ),
                                ),
                                if (vm.serviciosSeleccionados.isNotEmpty)
                                  Text(
                                    '${vm.serviciosSeleccionados.length} elegidos',
                                    style: TextStyle(fontSize: 11, color: Theme.of(context).colorScheme.onSurfaceVariant),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            for (final categoria in Categoria.values)
                              if (vm.serviciosPorCategoria(categoria).isNotEmpty) ...[
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 6, top: 2),
                                  child: Text(
                                    categoria.label.toUpperCase(),
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      letterSpacing: 0.5,
                                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                ),
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: [
                                    for (final s in vm.serviciosPorCategoria(categoria))
                                      ChipOpcion(
                                        texto: s.nombre,
                                        seleccionado: vm.servicioSeleccionado(s.id),
                                        onTap: () => _conAvisoEstilista(() => vm.alternarServicio(s.id)),
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                              ],
                            if (campo.hasError) _error(context, campo.errorText!),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    FormField<int>(
                      validator: (_) => vm.validarEstilista(),
                      builder: (campo) => CampoSeleccion(
                        etiqueta: 'Estilista',
                        icono: Icons.content_cut,
                        valor: vm.estilista?.nombre,
                        placeholder: vm.estilistasDisponibles.isEmpty
                            ? 'Ningún estilista disponible'
                            : 'Selecciona un estilista',
                        onTap: _elegirEstilista,
                        error: campo.errorText,
                        habilitado: vm.estilistasDisponibles.isNotEmpty,
                        focusNode: _fEstilista,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _info(
                      context,
                      vm.avisoEstilista ?? 'Solo se muestran estilistas que realizan todos los servicios elegidos.',
                      destacado: vm.avisoEstilista != null,
                    ),
                    const SizedBox(height: 16),
                    FormField<DateTime>(
                      validator: (_) => vm.validarFecha(),
                      builder: (campo) => CampoSeleccion(
                        etiqueta: 'Fecha',
                        icono: Icons.calendar_today_outlined,
                        valor: Fmt.fechaLarga(vm.fecha),
                        placeholder: 'Elegir fecha',
                        onTap: _elegirFecha,
                        error: campo.errorText,
                        focusNode: _fFecha,
                      ),
                    ),
                    const SizedBox(height: 16),
                    FormField<DateTime>(
                      validator: (_) => vm.validarHora(),
                      builder: (campo) => Focus(
                        focusNode: _fHora,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              'Hora de inicio',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: campo.hasError ? Theme.of(context).colorScheme.error : null,
                              ),
                            ),
                            const SizedBox(height: 8),
                            _leyenda(context),
                            const SizedBox(height: 10),
                            if (vm.esDomingo)
                              _aviso(context, 'El salón está cerrado los domingos. Elige otra fecha.')
                            else ...[
                              GridView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                padding: EdgeInsets.zero,
                                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 4,
                                  mainAxisSpacing: 8,
                                  crossAxisSpacing: 8,
                                  mainAxisExtent: 40,
                                ),
                                itemCount: vm.franjas.length,
                                itemBuilder: (context, i) {
                                  final f = vm.franjas[i];
                                  return _FranjaBoton(
                                    hora: Fmt.hora(f),
                                    estado: vm.estadoFranja(f),
                                    onTap: () => vm.seleccionarHora(f),
                                  );
                                },
                              ),
                              if (vm.sinFranjasLibres) ...[
                                const SizedBox(height: 10),
                                _aviso(
                                  context,
                                  'No quedan horas libres en esta fecha. Prueba con otra fecha, '
                                  'otro estilista u otros servicios.',
                                ),
                              ],
                            ],
                            if (campo.hasError) ...[
                              const SizedBox(height: 8),
                              _error(context, campo.errorText!),
                            ],
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    _etiqueta(context, 'Notas (opcional)'),
                    const SizedBox(height: 4),
                    TextFormField(
                      controller: _notas,
                      focusNode: _fNotas,
                      onChanged: vm.actualizarNotas,
                      validator: vm.validarNotas,
                      minLines: 3,
                      maxLines: 4,
                      maxLength: TurnoFormViewModel.maxNotas,
                      textCapitalization: TextCapitalization.sentences,
                      // Es el último campo: la acción del teclado cierra el teclado.
                      textInputAction: TextInputAction.done,
                      onFieldSubmitted: (_) => _fNotas.unfocus(),
                      decoration: const InputDecoration(hintText: 'Preferencias, alergias o indicaciones especiales…'),
                    ),
                    if (vm.errorGeneral != null) _error(context, vm.errorGeneral!),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _etiqueta(BuildContext context, String texto) => Text(
        texto,
        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Theme.of(context).colorScheme.onSurfaceVariant),
      );

  Widget _info(BuildContext context, String texto, {bool destacado = false}) {
    final cs = Theme.of(context).colorScheme;
    final color = destacado ? cs.tertiary : cs.onSurfaceVariant;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(destacado ? Icons.warning_amber_rounded : Icons.info_outline, size: 14, color: color),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            texto,
            style: TextStyle(
              fontSize: 11,
              height: 1.35,
              color: color,
              fontWeight: destacado ? FontWeight.w600 : FontWeight.w400,
            ),
          ),
        ),
      ],
    );
  }

  Widget _aviso(BuildContext context, String texto) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: cs.errorContainer, borderRadius: BorderRadius.circular(12)),
      child: Text(texto, style: TextStyle(color: cs.onErrorContainer, fontSize: 13)),
    );
  }

  Widget _error(BuildContext context, String texto) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.error_outline, size: 14, color: cs.error),
          const SizedBox(width: 6),
          Expanded(child: Text(texto, style: TextStyle(fontSize: 12, color: cs.error))),
        ],
      ),
    );
  }

  Widget _leyenda(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    Widget punto(Color color, {bool borde = false}) => Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: borde ? Colors.transparent : color,
            borderRadius: BorderRadius.circular(3),
            border: borde ? Border.all(color: cs.outline) : null,
          ),
        );
    Widget item(Color color, String texto, {bool borde = false}) => Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            punto(color, borde: borde),
            const SizedBox(width: 4),
            Text(texto, style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant)),
          ],
        );
    return Wrap(
      spacing: 14,
      runSpacing: 4,
      children: [
        item(Colors.transparent, 'Libre', borde: true),
        item(cs.surfaceContainer, 'No disponible'),
        item(cs.primary, 'Elegida'),
      ],
    );
  }
}

class _FranjaBoton extends StatelessWidget {
  const _FranjaBoton({required this.hora, required this.estado, required this.onTap});
  final String hora;
  final EstadoFranja estado;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final elegida = estado == EstadoFranja.elegida;
    final ocupada = estado == EstadoFranja.ocupada;
    return Semantics(
      button: true,
      selected: elegida,
      enabled: !ocupada,
      label: ocupada ? '$hora no disponible' : 'Hora $hora',
      child: Material(
        color: elegida ? cs.primary : (ocupada ? cs.surfaceContainer : Colors.transparent),
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          onTap: ocupada ? null : onTap,
          borderRadius: BorderRadius.circular(10),
          child: Container(
            alignment: Alignment.center,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              border: elegida ? null : Border.all(color: ocupada ? Colors.transparent : cs.outline),
            ),
            child: Text(
              hora,
              style: TextStyle(
                fontSize: 13,
                fontWeight: elegida ? FontWeight.w600 : FontWeight.w500,
                color: elegida ? cs.onPrimary : (ocupada ? cs.outline : cs.onSurface),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _BarraGuardar extends StatelessWidget {
  const _BarraGuardar({required this.vm, required this.onGuardar, required this.onCancelar});
  final TurnoFormViewModel vm;
  final VoidCallback onGuardar;
  final VoidCallback onCancelar;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final fin = vm.fin;
    return SafeArea(
      top: false,
      child: Container(
        color: cs.surfaceContainer,
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Resumen siempre visible: duración, hora de fin y precio total.
            Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                decoration: BoxDecoration(color: cs.primaryContainer, borderRadius: BorderRadius.circular(12)),
                child: Wrap(
                  alignment: WrapAlignment.spaceBetween,
                  spacing: 12,
                  runSpacing: 4,
                  children: [
                    _dato(cs, Icons.schedule, Fmt.duracion(vm.duracion), color: cs.onPrimaryContainer),
                    _dato(cs, Icons.flag_outlined, 'Fin ${fin == null ? '--:--' : Fmt.hora(fin)}', color: cs.onPrimaryContainer),
                    _dato(cs, Icons.payments_outlined, Fmt.dinero(vm.total), color: cs.onPrimaryContainer, negrita: true),
                  ],
                ),
              ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: onCancelar,
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(0, 46),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(23)),
                    ),
                    child: const Text('Cancelar'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  flex: 2,
                  child: FilledButton.icon(
                    onPressed: onGuardar,
                    style: FilledButton.styleFrom(
                      minimumSize: const Size(0, 46),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(23)),
                    ),
                    icon: const Icon(Icons.check, size: 18),
                    label: Text(vm.esEdicion ? 'Guardar cambios' : 'Guardar turno'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _dato(ColorScheme cs, IconData icono, String texto, {required Color color, bool negrita = false}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icono, size: 14, color: color),
        const SizedBox(width: 4),
        Text(texto, style: TextStyle(fontSize: 12.5, fontWeight: negrita ? FontWeight.w700 : FontWeight.w600, color: color)),
      ],
    );
  }
}

class _SelectorCliente extends StatefulWidget {
  const _SelectorCliente({required this.store, this.actual});
  final InMemoryStore store;
  final int? actual;

  @override
  State<_SelectorCliente> createState() => _SelectorClienteState();
}

class _SelectorClienteState extends State<_SelectorCliente> {
  final _busqueda = TextEditingController();

  @override
  void dispose() {
    _busqueda.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final q = Fmt.normalizar(_busqueda.text.trim());
    final clientes = widget.store.clientes.where((Cliente c) {
      if (q.isEmpty) return true;
      return Fmt.normalizar(c.nombre).contains(q) || c.telefono.contains(q);
    }).toList()
      ..sort((Cliente a, Cliente b) => a.nombre.compareTo(b.nombre));

    return SizedBox(
      height: MediaQuery.sizeOf(context).height * 0.72,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Expanded(child: Text('Seleccionar cliente', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600))),
                IconButton(
                  tooltip: 'Cerrar',
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            TextField(
              controller: _busqueda,
              onChanged: (_) => setState(() {}),
              decoration: const InputDecoration(
                hintText: 'Buscar por nombre o teléfono',
                prefixIcon: Icon(Icons.search, size: 20),
              ),
            ),
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: () async {
                final c = await mostrarFormularioCliente(context);
                if (c != null && context.mounted) Navigator.of(context).pop(c.id);
              },
              icon: const Icon(Icons.person_add_alt_1, size: 18),
              label: const Text('Crear cliente nuevo'),
              style: OutlinedButton.styleFrom(minimumSize: const Size(0, 44)),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: clientes.isEmpty
                  ? Center(child: Text('No se encontraron clientes', style: TextStyle(color: cs.onSurfaceVariant)))
                  : ListView.separated(
                      itemCount: clientes.length,
                      separatorBuilder: (_, __) => Divider(color: cs.outlineVariant),
                      itemBuilder: (context, i) {
                        final c = clientes[i];
                        final sel = c.id == widget.actual;
                        return ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 4),
                          onTap: () => Navigator.of(context).pop(c.id),
                          leading: AvatarCliente(nombre: c.nombre, genero: c.genero, size: 40),
                          title: Text(c.nombre, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                          subtitle: Text('${Fmt.telefono(c.telefono)} · ${c.genero.label}', style: const TextStyle(fontSize: 12)),
                          trailing: sel ? Icon(Icons.check_circle, color: cs.primary) : null,
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SelectorEstilista extends StatelessWidget {
  const _SelectorEstilista({required this.estilistas, this.actual});
  final List<Estilista> estilistas;
  final int? actual;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final store = AppScope.of(context).store;
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Expanded(child: Text('Seleccionar estilista', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600))),
                IconButton(
                  tooltip: 'Cerrar',
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            if (estilistas.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 30),
                child: Text(
                  'Ningún estilista realiza todos los servicios elegidos.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant),
                ),
              )
            else
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: estilistas.length,
                  separatorBuilder: (_, __) => Divider(color: cs.outlineVariant),
                  itemBuilder: (context, i) {
                    final e = estilistas[i];
                    final sel = e.id == actual;
                    final servicios = e.servicioIds.map(store.servicioPorId).whereType<Servicio>();
                    final categorias = <Categoria>[];
                    for (final s in servicios) {
                      if (!categorias.contains(s.categoria)) categorias.add(s.categoria);
                    }
                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 4),
                      onTap: () => Navigator.of(context).pop(e.id),
                      leading: AvatarEstilista(estilista: e, size: 44),
                      title: Text(e.nombre, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                      subtitle: Text(categorias.map((c) => c.label).join(' · '), style: const TextStyle(fontSize: 12)),
                      trailing: sel ? Icon(Icons.check_circle, color: cs.primary) : null,
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}
