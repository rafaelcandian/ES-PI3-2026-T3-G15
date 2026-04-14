import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:mesclainvest/main.dart';

void main() {
  testWidgets('Login screen loads correctly', (WidgetTester tester) async {
    // Build do app
    await tester.pumpWidget(const MesclaInvestApp());

    // Verifica se o título aparece
    expect(find.text('MesclaInvest'), findsOneWidget);

    // Verifica campos
    expect(find.byType(TextFormField), findsNWidgets(2));

    // Verifica botão
    expect(find.text('Entrar'), findsOneWidget);
  });
}