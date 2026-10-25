import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../models/models.dart';
import '../../views/agenda/agenda_screen.dart';
import '../../views/clientes/clientes_screen.dart';
import '../../views/detalle/turno_detalle_screen.dart';
import '../../views/estilistas/estilistas_screen.dart';
import '../../views/servicios/servicios_screen.dart';
import '../../views/shell/home_shell.dart';
import '../../views/turno_form/turno_form_screen.dart';

final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'root');

GoRouter construirRouter() => GoRouter(
      navigatorKey: rootNavigatorKey,
      initialLocation: '/agenda',
      routes: [
        StatefulShellRoute.indexedStack(
          builder: (context, state, shell) => HomeShell(shell: shell),
          branches: [
            StatefulShellBranch(routes: [
              GoRoute(
                path: '/agenda',
                builder: (context, state) => AgendaScreen(
                  estilistaId: int.tryParse(state.uri.queryParameters['estilista'] ?? ''),
                ),
              ),
            ]),
            StatefulShellBranch(routes: [
              GoRoute(path: '/clientes', builder: (context, state) => const ClientesScreen()),
            ]),
            StatefulShellBranch(routes: [
              GoRoute(path: '/servicios', builder: (context, state) => const ServiciosScreen()),
            ]),
            StatefulShellBranch(routes: [
              GoRoute(path: '/estilistas', builder: (context, state) => const EstilistasScreen()),
            ]),
          ],
        ),
        // Por encima de la barra inferior. 'nuevo' va antes que ':id'.
        GoRoute(
          path: '/turno/nuevo',
          parentNavigatorKey: rootNavigatorKey,
          builder: (context, state) => TurnoFormScreen(inicial: state.extra as TurnoFormInicial?),
        ),
        GoRoute(
          path: '/turno/:id',
          parentNavigatorKey: rootNavigatorKey,
          builder: (context, state) =>
              TurnoDetalleScreen(turnoId: int.tryParse(state.pathParameters['id'] ?? '')),
        ),
        GoRoute(
          path: '/turno/:id/editar',
          parentNavigatorKey: rootNavigatorKey,
          builder: (context, state) =>
              TurnoFormScreen(turnoId: int.tryParse(state.pathParameters['id'] ?? '')),
        ),
      ],
    );
