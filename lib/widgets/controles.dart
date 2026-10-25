import 'package:flutter/material.dart';
import '../models/models.dart';

class OpcionSegmento<T> {
  const OpcionSegmento(this.valor, this.texto);
  final T valor;
  final String texto;
}

class SelectorSegmentado<T> extends StatelessWidget {
  const SelectorSegmentado({
    super.key,
    required this.opciones,
    required this.seleccionada,
    required this.onChanged,
    this.mostrarIcono = true,
  });

  final List<OpcionSegmento<T>> opciones;
  final T seleccionada;
  final ValueChanged<T> onChanged;
  final bool mostrarIcono;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      height: 40,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: cs.outline),
      ),
      clipBehavior: Clip.antiAlias,
      child: Row(
        children: [
          for (final op in opciones)
            Expanded(
              child: Semantics(
                selected: op.valor == seleccionada,
                button: true,
                child: InkWell(
                  onTap: () => onChanged(op.valor),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    alignment: Alignment.center,
                    color: op.valor == seleccionada
                        ? cs.secondaryContainer
                        : Colors.transparent,
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (mostrarIcono && op.valor == seleccionada) ...[
                          Icon(Icons.check, size: 14, color: cs.onSecondaryContainer),
                          const SizedBox(width: 5),
                        ],
                        Flexible(
                          child: Text(
                            op.texto,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: op.valor == seleccionada
                                  ? cs.onSecondaryContainer
                                  : cs.onSurface,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class ChipOpcion extends StatelessWidget {
  const ChipOpcion({
    super.key,
    required this.texto,
    required this.seleccionado,
    required this.onTap,
    this.icono,
  });

  final String texto;
  final bool seleccionado;
  final VoidCallback onTap;
  final IconData? icono;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Material(
      color: seleccionado ? cs.secondaryContainer : Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(
          color: seleccionado ? Colors.transparent : cs.outlineVariant,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: SizedBox(
            height: 32,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (seleccionado) ...[
                  Icon(Icons.check, size: 14, color: cs.onSecondaryContainer),
                  const SizedBox(width: 6),
                ] else if (icono != null) ...[
                  Icon(icono, size: 14, color: cs.onSurfaceVariant),
                  const SizedBox(width: 6),
                ],
                Text(
                  texto,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: seleccionado ? cs.onSecondaryContainer : cs.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class EstadoBadge extends StatelessWidget {
  const EstadoBadge(this.estado, {super.key, this.compacto = false});

  final EstadoTurno estado;
  final bool compacto;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final (fondo, color) = switch (estado) {
      EstadoTurno.programado => (cs.primaryContainer, cs.onPrimaryContainer),
      EstadoTurno.completado => (cs.tertiaryContainer, cs.onTertiaryContainer),
      EstadoTurno.cancelado => (cs.errorContainer, cs.onErrorContainer),
    };
    return Container(
      padding: EdgeInsets.symmetric(horizontal: compacto ? 8 : 9, vertical: compacto ? 2 : 3),
      decoration: BoxDecoration(color: fondo, borderRadius: BorderRadius.circular(8)),
      child: Text(
        estado.label,
        style: TextStyle(fontSize: compacto ? 10 : 11, fontWeight: FontWeight.w600, color: color),
      ),
    );
  }
}

class ImagenCategoria extends StatelessWidget {
  const ImagenCategoria({
    super.key,
    required this.categoria,
    this.height = 84,
    this.radio = 12,
  });

  final Categoria categoria;
  final double height;
  final double radio;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return ClipRRect(
      borderRadius: BorderRadius.circular(radio),
      child: Container(
        height: height,
        width: double.infinity,
        color: cs.primaryContainer,
        child: Image.asset(
          categoria.imagen,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => Center(
            child: Icon(_iconoCategoria(categoria), size: 36, color: cs.primary),
          ),
        ),
      ),
    );
  }
}

IconData iconoCategoria(Categoria c) => switch (c) {
      Categoria.corte => Icons.content_cut,
      Categoria.color => Icons.palette_outlined,
      Categoria.barba => Icons.face_retouching_natural,
      Categoria.peinado => Icons.auto_awesome,
      Categoria.tratamiento => Icons.water_drop_outlined,
    };

IconData _iconoCategoria(Categoria c) => iconoCategoria(c);

class CampoSeleccion extends StatelessWidget {
  const CampoSeleccion({
    super.key,
    required this.etiqueta,
    required this.icono,
    required this.valor,
    required this.placeholder,
    this.onTap,
    this.error,
    this.habilitado = true,
  });

  final String etiqueta;
  final IconData icono;
  final String? valor;
  final String placeholder;
  final VoidCallback? onTap;
  final String? error;
  final bool habilitado;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tieneError = error != null;
    final colorBorde = tieneError ? cs.error : cs.outline;
    final texto = valor?.isNotEmpty == true ? valor! : placeholder;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          etiqueta,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: tieneError ? cs.error : cs.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 4),
        Semantics(
          button: true,
          enabled: habilitado,
          label: '$etiqueta: $texto',
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: habilitado ? onTap : null,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                height: 52,
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: colorBorde, width: tieneError ? 2 : 1),
                ),
                child: Row(
                  children: [
                    Icon(icono, size: 18, color: cs.onSurfaceVariant),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        texto,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 14,
                          color: valor?.isNotEmpty == true ? cs.onSurface : cs.outline,
                        ),
                      ),
                    ),
                    Icon(Icons.keyboard_arrow_down, size: 18, color: cs.onSurfaceVariant),
                  ],
                ),
              ),
            ),
          ),
        ),
        if (tieneError) ...[
          const SizedBox(height: 5),
          Row(
            children: [
              Icon(Icons.error_outline, size: 13, color: cs.error),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  error!,
                  style: TextStyle(fontSize: 12, color: cs.error),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

class SeccionTarjeta extends StatelessWidget {
  const SeccionTarjeta({super.key, required this.child, this.padding = 16});
  final Widget child;
  final double padding;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(padding),
      decoration: BoxDecoration(
        color: cs.surfaceContainer,
        borderRadius: BorderRadius.circular(16),
      ),
      child: child,
    );
  }
}

class EstadoVacio extends StatelessWidget {
  const EstadoVacio({
    super.key,
    required this.titulo,
    required this.mensaje,
    this.icono = Icons.event_busy_outlined,
    this.accion,
  });

  final String titulo;
  final String mensaje;
  final IconData icono;
  final Widget? accion;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 36),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 88,
            height: 88,
            decoration: BoxDecoration(color: cs.secondaryContainer, shape: BoxShape.circle),
            child: Icon(icono, size: 40, color: cs.onSecondaryContainer),
          ),
          const SizedBox(height: 18),
          Text(titulo, textAlign: TextAlign.center, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          Text(mensaje, textAlign: TextAlign.center, style: TextStyle(fontSize: 13, height: 1.45, color: cs.onSurfaceVariant)),
          if (accion != null) ...[const SizedBox(height: 18), accion!],
        ],
      ),
    );
  }
}

class EncabezadoSeccion extends StatelessWidget {
  const EncabezadoSeccion({super.key, required this.titulo, this.accion, this.subtitulo});
  final String titulo;
  final String? subtitulo;
  final Widget? accion;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(titulo, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
              if (subtitulo != null) ...[
                const SizedBox(height: 2),
                Text(subtitulo!, style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant)),
              ],
            ],
          ),
        ),
        if (accion != null) accion!,
      ],
    );
  }
}

class ContenidoLimitado extends StatelessWidget {
  const ContenidoLimitado({super.key, required this.child, this.maxWidth = 720});
  final Widget child;
  final double maxWidth;

  @override
  Widget build(BuildContext context) => Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxWidth),
          child: child,
        ),
      );
}
