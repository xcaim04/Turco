import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/app_scope.dart';
import '../../core/utils/fmt.dart';
import '../../models/models.dart';
import '../../viewmodels/estilistas_viewmodel.dart';
import '../../widgets/avatares.dart';

class EstilistasScreen extends StatefulWidget {
  const EstilistasScreen({super.key});

  @override
  State<EstilistasScreen> createState() => _EstilistasScreenState();
}

class _EstilistasScreenState extends State<EstilistasScreen> {
  EstilistasViewModel? _vm;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _vm ??= EstilistasViewModel(AppScope.of(context).store);
  }

  @override
  void dispose() {
    _vm?.dispose();
    super.dispose();
  }

  String _textoTurnos(int n) => n == 0
      ? 'sin turnos programados hoy'
      : n == 1
          ? '1 turno programado hoy'
          : '$n turnos programados hoy';

  @override
  Widget build(BuildContext context) {
    final vm = _vm;
    if (vm == null) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    return ListenableBuilder(
      listenable: vm,
      builder: (context, _) {
        final cs = Theme.of(context).colorScheme;
        final estilistas = vm.estilistas;
        return Scaffold(
          body: CustomScrollView(
            slivers: [
              // Cabecera plegable: al hacer scroll queda fija solo la barra con el título.
              SliverAppBar(
                pinned: true,
                expandedHeight: 168,
                backgroundColor: cs.primary,
                foregroundColor: cs.onPrimary,
                surfaceTintColor: cs.primary,
                flexibleSpace: FlexibleSpaceBar(
                  titlePadding: const EdgeInsetsDirectional.only(start: 20, bottom: 14),
                  title: Text(
                    'Estilistas',
                    style: TextStyle(fontWeight: FontWeight.w600, color: cs.onPrimary),
                  ),
                  background: Padding(
                    padding: EdgeInsets.fromLTRB(20, MediaQuery.paddingOf(context).top + 14, 20, 52),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Icon(Icons.contact_page_outlined, size: 28, color: cs.onPrimary),
                        const SizedBox(height: 8),
                        Text(
                          '${estilistas.length} profesionales · ${_textoTurnos(vm.programadosHoy)}',
                          style: TextStyle(fontSize: 13, color: cs.onPrimary.withValues(alpha: 0.85)),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
                sliver: SliverList.separated(
                  itemCount: estilistas.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, i) {
                    final e = estilistas[i];
                    return _TarjetaEstilista(
                      estilista: e,
                      turnosHoy: vm.turnosHoy(e),
                      servicios: vm.serviciosPorCategoria(e),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _TarjetaEstilista extends StatelessWidget {
  const _TarjetaEstilista({
    required this.estilista,
    required this.turnosHoy,
    required this.servicios,
  });

  final Estilista estilista;
  final int turnosHoy;
  final Map<Categoria, List<Servicio>> servicios;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Material(
      color: cs.surfaceContainer,
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => context.go('/agenda?estilista=${estilista.id}'),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AvatarEstilista(estilista: estilista, size: 56),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(estilista.nombre, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 6),
                    // Servicios agrupados por categoría.
                    for (final MapEntry(key: c, value: lista) in servicios.entries) ...[
                      Text(
                        c.label.toUpperCase(),
                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, letterSpacing: 0.5, color: cs.onSurfaceVariant),
                      ),
                      const SizedBox(height: 4),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: [
                          for (final s in lista)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: cs.outlineVariant),
                              ),
                              child: Text(s.nombre, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: cs.onSurfaceVariant)),
                            ),
                        ],
                      ),
                      const SizedBox(height: 8),
                    ],
                    Text(
                      turnosHoy == 0 ? 'Sin turnos hoy' : '${Fmt.turnos(turnosHoy)} hoy',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: turnosHoy == 0 ? cs.onSurfaceVariant : cs.primary,
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: Icon(Icons.chevron_right, size: 22, color: cs.onSurfaceVariant),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
