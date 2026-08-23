import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_application/main.dart';

void main() {
  testWidgets('Affiche le formulaire de connexion',
      (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());

    expect(find.text('EMPLACEMENT DU LOGO'), findsOneWidget);
    expect(find.text('Page de connexion'), findsOneWidget);
    expect(find.text('Session-2026'), findsOneWidget);
    expect(find.text('Ajouter produit'), findsOneWidget);
  });
}
