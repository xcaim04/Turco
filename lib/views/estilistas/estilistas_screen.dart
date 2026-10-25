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
              SliverToBoxAdapter(
                child: Container(
                  width: double.infinity,
                  color: cs.primary,
                  padding: EdgeInsets.fromLTRB(20, MediaQuery.paddingOf(context).top + 14, 20, 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.contact_page_outlined, size: 28, color: cs.onPrimary),
                      const SizedBox(height: 8),
                      Text('Estilistas', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w600, color: cs.onPrimary)),
                      const SizedBox(height: 4),
                      Text(
                        '${estilistas.length} profesionales · ${_textoTurnos(vm.programadosHoy)}',
                        style: TextStyle(fontSize: 13, color: cs.onPrimary.withValues(alpha: 0.85)),
                      ),
                    ],
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
                      categorias: vm.categoriasDe(e),
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
    required this.categorias,
  });

  final Estilista estilista;
  final int turnosHoy;
  final List<Categoria> categorias;

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
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        for (final c in categorias.take(2))
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: cs.outlineVariant),
                            ),
                            child: Text(c.label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: cs.onSurfaceVariant)),
                          ),
                        if (categorias.length > 2)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: cs.secondaryContainer,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text('+${categorias.length - 2}', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: cs.onSecondaryContainer)),
                          ),
                      ],
                    ),
                    const SizedBox(height: 6),
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
