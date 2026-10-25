import 'package:flutter/material.dart';
import '../../core/app_scope.dart';
import '../../core/utils/fmt.dart';
import '../../models/models.dart';
import '../../viewmodels/clientes_viewmodel.dart';
import '../../widgets/avatares.dart';
import '../../widgets/cliente_detalle_sheet.dart';
import '../../widgets/cliente_form_sheet.dart';
import '../../widgets/controles.dart';

class ClientesScreen extends StatefulWidget {
  const ClientesScreen({super.key});

  @override
  State<ClientesScreen> createState() => _ClientesScreenState();
}

class _ClientesScreenState extends State<ClientesScreen> {
  ClientesViewModel? _vm;
  final _busqueda = TextEditingController();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _vm ??= ClientesViewModel(AppScope.of(context).store);
  }

  @override
  void dispose() {
    _busqueda.dispose();
    _vm?.dispose();
    super.dispose();
  }

  Future<void> _nuevo() async {
    final c = await mostrarFormularioCliente(context);
    if (c != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${c.nombre} fue agregado')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final vm = _vm;
    if (vm == null) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    return ListenableBuilder(
      listenable: vm,
      builder: (context, _) {
        final cs = Theme.of(context).colorScheme;
        final clientes = vm.clientes;
        return Scaffold(
          appBar: AppBar(
            toolbarHeight: 60,
            titleSpacing: 16,
            title: const Text('Clientes', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600)),
            actions: [
              IconButton(
                tooltip: 'Nuevo cliente',
                onPressed: _nuevo,
                icon: const Icon(Icons.person_add_alt_1_outlined),
              ),
              const SizedBox(width: 6),
            ],
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: _nuevo,
            icon: const Icon(Icons.person_add_alt_1),
            label: const Text('Nuevo cliente'),
          ),
          body: SafeArea(
            top: false,
            child: ContenidoLimitado(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 6),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                    TextField(
                      controller: _busqueda,
                      onChanged: vm.buscar,
                      textInputAction: TextInputAction.search,
                      decoration: InputDecoration(
                        hintText: 'Buscar por nombre o teléfono',
                        prefixIcon: const Icon(Icons.search, size: 20),
                        suffixIcon: vm.busqueda.isEmpty
                            ? null
                            : IconButton(
                                tooltip: 'Limpiar búsqueda',
                                onPressed: () {
                                  _busqueda.clear();
                                  vm.buscar('');
                                },
                                icon: const Icon(Icons.close, size: 18),
                              ),
                        filled: true,
                        fillColor: cs.surfaceContainer,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide(color: cs.primary, width: 1.5),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SelectorSegmentado<FiltroPublico>(
                      opciones: const [
                        OpcionSegmento(FiltroPublico.todos, 'Todos'),
                        OpcionSegmento(FiltroPublico.mujeres, 'Mujeres'),
                        OpcionSegmento(FiltroPublico.hombres, 'Hombres'),
                      ],
                      seleccionada: vm.filtro,
                      onChanged: vm.filtrar,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      '${vm.total} ${vm.total == 1 ? 'cliente' : 'clientes'} · ${vm.mujeres} mujeres · ${vm.hombres} hombres',
                      style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
                    ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: clientes.isEmpty
                        ? SingleChildScrollView(
                            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                            child: EstadoVacio(
                        icono: Icons.person_search_outlined,
                        titulo: 'No encontramos clientes',
                        mensaje: vm.hayBusquedaOFiltro
                            ? 'Prueba con otro nombre, teléfono o filtro.'
                            : 'Agrega el primer cliente para empezar a reservar turnos.',
                        accion: vm.hayBusquedaOFiltro
                            ? TextButton.icon(
                                onPressed: () {
                                  _busqueda.clear();
                                  vm.limpiar();
                                },
                                icon: const Icon(Icons.filter_alt_off_outlined, size: 18),
                                label: const Text('Limpiar filtros'),
                              )
                            : FilledButton.tonalIcon(
                                onPressed: _nuevo,
                                icon: const Icon(Icons.person_add_alt_1, size: 18),
                                label: const Text('Nuevo cliente'),
                              ),
                            ),
                          )
                        : ListView.separated(
                            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                            padding: const EdgeInsets.fromLTRB(16, 0, 16, 96),
                            itemCount: clientes.length,
                            separatorBuilder: (_, __) => Divider(color: cs.outlineVariant),
                            itemBuilder: (context, i) => _FilaCliente(cliente: clientes[i]),
                          ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _FilaCliente extends StatelessWidget {
  const _FilaCliente({required this.cliente});
  final Cliente cliente;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final store = AppScope.of(context).store;
    final turnos = store.turnosDeCliente(cliente.id).length;
    return InkWell(
      onTap: () => mostrarDetalleCliente(context, cliente),
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 10),
        child: Row(
          children: [
            AvatarCliente(nombre: cliente.nombre, genero: cliente.genero, size: 44),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(cliente.nombre, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 1),
                  Text(
                    '${Fmt.telefono(cliente.telefono)} · ${cliente.genero.label}',
                    style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
                  ),
                ],
              ),
            ),
            Text(
              Fmt.turnos(turnos),
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: cs.onSurfaceVariant),
            ),
            const SizedBox(width: 4),
            Icon(Icons.chevron_right, size: 18, color: cs.outline),
          ],
        ),
      ),
    );
  }
}
