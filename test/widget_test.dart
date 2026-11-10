import 'package:flutter_test/flutter_test.dart';

import 'package:astro_vitals/main.dart';

void main() {
  testWidgets('shows sign-in form and switches to registration', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const AstroVitalsApp());

    expect(find.text('Welcome back'), findsOneWidget);
    expect(find.text('Email address'), findsOneWidget);
    expect(find.text('Password'), findsOneWidget);
    expect(find.text('Confirm password'), findsNothing);

    await tester.tap(find.text('Sign up'));
    await tester.pumpAndSettle();

    expect(find.text('Create your account'), findsOneWidget);
    expect(find.text('Full name'), findsOneWidget);
    expect(find.text('Confirm password'), findsOneWidget);
  });

  testWidgets('validates required fields before showing demo response', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const AstroVitalsApp());

    await tester.tap(find.text('Sign in'));
    await tester.pumpAndSettle();

    expect(find.text('Enter your email address'), findsOneWidget);
    expect(find.text('Enter your password'), findsOneWidget);
    expect(
      find.text('Demo only: this form is not connected to an account service.'),
      findsNothing,
    );
  });
}
