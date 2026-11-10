import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:astro_vitals/main.dart';

void main() {
  testWidgets('registration fields validate required profile details', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const AstroVitalsApp());

    await tester.tap(find.text('Sign up'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Create account'));
    await tester.tap(find.text('Create account'));
    await tester.pumpAndSettle();

    expect(find.text('Enter your astronaut ID'), findsNWidgets(2));
    expect(find.text('Enter your full name'), findsOneWidget);
    expect(find.text('Select your date of birth'), findsOneWidget);
    expect(find.text('Enter your height'), findsOneWidget);
    expect(find.text('Enter your weight'), findsOneWidget);
  });

  testWidgets('registers, signs out, and signs back in during the session', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const AstroVitalsApp());

    await tester.tap(find.text('Sign up'));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const ValueKey('astronaut-id')),
      'AV-1001',
    );
    await tester.enterText(
      find.byKey(const ValueKey('full-name')),
      'Alex Morgan',
    );
    await tester.enterText(
      find.byKey(const ValueKey('email')),
      'alex@example.com',
    );
    await tester.enterText(find.byKey(const ValueKey('password')), 'secure123');
    await tester.enterText(
      find.byKey(const ValueKey('confirm-password')),
      'secure123',
    );
    await tester.ensureVisible(find.text('Select date'));
    await tester.tap(find.text('Select date'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const ValueKey('height')), '172.5');
    await tester.enterText(find.byKey(const ValueKey('weight')), '68.5');

    await tester.ensureVisible(find.text('Create account'));
    await tester.tap(find.text('Create account'));
    await tester.pumpAndSettle();

    expect(find.text('Welcome, Alex Morgan'), findsOneWidget);
    expect(find.text('Astronaut ID: AV-1001'), findsOneWidget);

    await tester.tap(find.text('Sign out'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('email')),
      'alex@example.com',
    );
    await tester.enterText(find.byKey(const ValueKey('password')), 'secure123');
    await tester.tap(find.text('Sign in'));
    await tester.pumpAndSettle();

    expect(find.text('Welcome, Alex Morgan'), findsOneWidget);
  });

  testWidgets('rejects incorrect credentials', (WidgetTester tester) async {
    await tester.pumpWidget(const AstroVitalsApp());

    await tester.enterText(
      find.byKey(const ValueKey('email')),
      'nobody@example.com',
    );
    await tester.enterText(find.byKey(const ValueKey('password')), 'secure123');
    await tester.tap(find.text('Sign in'));
    await tester.pumpAndSettle();

    expect(find.text('Email or password is incorrect.'), findsOneWidget);
  });
}
