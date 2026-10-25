import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:turco/app.dart';

void main() {
  // Recorre las pestañas y abre un turno en tamaño de teléfono, vertical y
  // horizontal. Falla si alguna pantalla desborda o si hay héroes repetidos.
  for (final size in const [Size(375, 812), Size(812, 375)]) {
    testWidgets('se recorren las pantallas sin overflow en $size', (tester) async {
      tester.view.physicalSize = size * 3;
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(const TurcoApp());
      await tester.pumpAndSettle();

      for (final tab in ['Clientes', 'Servicios', 'Estilistas', 'Agenda']) {
        await tester.tap(find.text(tab).last);
        await tester.pumpAndSettle();
      }

      final turnos = find.byWidgetPredicate((w) => w is InkWell && w.onLongPress != null);
      if (turnos.evaluate().isEmpty) return; // el día visible no tiene turnos programados
      await tester.tap(turnos.first, warnIfMissed: false);
      await tester.pumpAndSettle();
      expect(find.text('Detalle del turno'), findsOneWidget);
    });
  }
}
