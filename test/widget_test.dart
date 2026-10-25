import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:turco/app.dart';

void main() {
  testWidgets('la aplicación abre en la agenda', (tester) async {
    await tester.pumpWidget(const TurcoApp());
    await tester.pumpAndSettle();

    expect(find.text('Agenda'), findsWidgets);
    expect(find.text('Clientes'), findsWidgets);
    expect(find.text('Servicios'), findsWidgets);
    expect(find.text('Estilistas'), findsWidgets);
  });

  testWidgets('el formulario de turno muestra los errores bajo cada campo', (tester) async {
    await tester.pumpWidget(const TurcoApp());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Nuevo turno'));
    await tester.pumpAndSettle();
    expect(find.text('Nuevo turno'), findsOneWidget); // título del formulario

    await tester.tap(find.text('Guardar turno'));
    await tester.pumpAndSettle();
    expect(find.text('Selecciona un cliente'), findsWidgets);
    expect(find.text('Elige al menos un servicio'), findsOneWidget);
    expect(find.text('Primero elige los servicios'), findsOneWidget);
  });

  testWidgets('el formulario de cliente exige el género', (tester) async {
    await tester.pumpWidget(const TurcoApp());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Clientes').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Nuevo cliente'));
    await tester.pumpAndSettle();

    await tester.enterText(find.widgetWithText(TextFormField, 'Nombre completo'), 'Rosa Prieto');
    await tester.enterText(find.widgetWithText(TextFormField, 'Teléfono'), '52111222'); // ya existe
    await tester.tap(find.text('Guardar cliente'));
    await tester.pumpAndSettle();

    expect(find.text('Selecciona el género'), findsOneWidget);
    expect(find.text('Este teléfono ya está registrado'), findsOneWidget);
  });
}
