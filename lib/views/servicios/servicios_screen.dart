import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/app_scope.dart';
import '../../core/utils/fmt.dart';
import '../../models/models.dart';
import '../../viewmodels/servicios_viewmodel.dart';
import '../../widgets/controles.dart';
import '../../widgets/dialogos_turno.dart';

class ServiciosScreen extends StatefulWidget {
  const ServiciosScreen({super.key});

  @override
  State<ServiciosScreen> createState() => _ServiciosScreenState();
}

class _ServiciosScreenState extends State<ServiciosScreen> {
  ServiciosViewModel? _vm;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _vm ??= ServiciosViewModel(AppScope.of(context).store);
  }

  @override
  void dispose() {
    _vm?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final vm = _vm;
    if (vm == null) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    return ListenableBuilder(
      listenable: vm,
      builder: (context, _) {
        final cs = Theme.of(context).colorScheme;
        final servicios = vm.servicios;
        return Scaffold(
          appBar: AppBar(
            toolbarHeight: 60,
            titleSpacing: 16,
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Servicios', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600)),
                Text('Toca un servicio para reservar', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w400, color: cs.onSurfaceVariant)),
              ],
            ),
          ),
          body: SafeArea(
            top: false,
            child: ContenidoLimitado(
              maxWidth: 1200,
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SizedBox(
                      height: 32,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        children: [
                          ChipOpcion(
                            texto: 'Todas',
                            seleccionado: vm.categoria == null,
                            onTap: () => vm.filtrarCategoria(null),
                          ),
                          for (final c in Categoria.values) ...[
                            const SizedBox(width: 8),
                            ChipOpcion(
                              texto: c.label,
                              seleccionado: vm.categoria == c,
                              onTap: () => vm.filtrarCategoria(c),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    SelectorSegmentado<FiltroPublico>(
                      opciones: const [
                        OpcionSegmento(FiltroPublico.todos, 'Todos'),
                        OpcionSegmento(FiltroPublico.mujeres, 'Mujeres'),
                        OpcionSegmento(FiltroPublico.hombres, 'Hombres'),
                      ],
                      seleccionada: vm.publico,
                      onChanged: vm.filtrarPublico,
                    ),
                    const SizedBox(height: 12),
                    if (servicios.isEmpty)
                      EstadoVacio(
                        icono: Icons.search_off,
                        titulo: 'No hay servicios con estos filtros',
                        mensaje: 'Prueba con otra categoría o público.',
                        accion: TextButton.icon(
                          onPressed: vm.limpiar,
                          icon: const Icon(Icons.filter_alt_off_outlined, size: 18),
                          label: const Text('Limpiar filtros'),
                        ),
                      )
                    else
                      LayoutBuilder(
                        builder: (context, constraints) => GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          padding: EdgeInsets.zero,
                          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: columnasServicios(constraints.maxWidth),
                            mainAxisSpacing: 12,
                            crossAxisSpacing: 12,
                            mainAxisExtent: 206,
                          ),
                          itemCount: servicios.length,
                          itemBuilder: (context, i) => _TarjetaServicio(servicio: servicios[i]),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// 2 columnas en menos de 600 dp, 3 entre 600 y 840 dp y 4 en más de 840 dp.
int columnasServicios(double ancho) => ancho < 600 ? 2 : (ancho <= 840 ? 3 : 4);

class _TarjetaServicio extends StatelessWidget {
  const _TarjetaServicio({required this.servicio});
  final Servicio servicio;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Material(
      color: cs.surfaceContainer,
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () async {
          final turno = await context.push<Turno>('/turno/nuevo', extra: TurnoFormInicial(servicioId: servicio.id));
          if (turno != null && context.mounted) {
            avisar(context, mensajeTurnoGuardado(turno, edicion: false));
          }
        },
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ImagenCategoria(categoria: servicio.categoria, height: 84),
              const SizedBox(height: 7),
              Text(
                servicio.nombre,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(Icons.schedule, size: 12, color: cs.onSurfaceVariant),
                  const SizedBox(width: 3),
                  Text(Fmt.duracion(servicio.duracionMin), style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant)),
                  const Spacer(),
                  Text(Fmt.dinero(servicio.precio), style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: cs.primary)),
                ],
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(color: cs.secondaryContainer, borderRadius: BorderRadius.circular(8)),
                child: Text(
                  servicio.publico.label,
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: cs.onSecondaryContainer),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
