import 'package:flutter/material.dart';
import '../core/app_scope.dart';

Future<void> mostrarSelectorTema(BuildContext context) async {
  final vm = AppScope.of(context).themeVm;
  await showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (context) => ListenableBuilder(
      listenable: vm,
      builder: (context, _) {
        final cs = Theme.of(context).colorScheme;
        final opciones = <(ThemeMode, IconData, String, String)>[
          (ThemeMode.system, Icons.brightness_auto_outlined, 'Sistema', 'Sigue la configuración del teléfono'),
          (ThemeMode.light, Icons.light_mode_outlined, 'Claro', 'Siempre con el tema claro'),
          (ThemeMode.dark, Icons.dark_mode_outlined, 'Oscuro', 'Siempre con el tema oscuro'),
        ];
        return SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('Apariencia', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 4),
                Text('Elige cómo se ve Turco.', style: TextStyle(color: cs.onSurfaceVariant, fontSize: 13)),
                const SizedBox(height: 14),
                for (final (modo, icono, titulo, detalle) in opciones)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Material(
                      color: vm.mode == modo ? cs.secondaryContainer : Colors.transparent,
                      borderRadius: BorderRadius.circular(14),
                      child: InkWell(
                        onTap: () => vm.cambiar(modo),
                        borderRadius: BorderRadius.circular(14),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          child: Row(
                            children: [
                              Icon(icono, color: vm.mode == modo ? cs.onSecondaryContainer : cs.onSurfaceVariant),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(titulo, style: TextStyle(fontWeight: FontWeight.w600, color: vm.mode == modo ? cs.onSecondaryContainer : cs.onSurface)),
                                    const SizedBox(height: 2),
                                    Text(detalle, style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant)),
                                  ],
                                ),
                              ),
                              if (vm.mode == modo) Icon(Icons.check_circle, size: 20, color: cs.onSecondaryContainer),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                const SizedBox(height: 6),
                FilledButton.tonal(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Listo'),
                ),
              ],
            ),
          ),
        );
      },
    ),
  );
}
