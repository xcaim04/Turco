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
}
