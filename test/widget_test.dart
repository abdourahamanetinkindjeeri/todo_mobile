import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:recipe_clean_app/core/widgets/error_view.dart';

void main() {
  testWidgets('ErrorView affiche le message et le bouton de retry', (
    tester,
  ) async {
    var retryCalled = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ErrorView(
            error: 'Erreur de chargement',
            onRetry: () => retryCalled = true,
          ),
        ),
      ),
    );

    expect(find.text('Erreur de chargement'), findsOneWidget);
    expect(find.text('Réessayer'), findsOneWidget);

    await tester.tap(find.text('Réessayer'));
    await tester.pump();

    expect(retryCalled, isTrue);
  });
}
