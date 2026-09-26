import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:clarity_mobile/main.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Clarity mobile app fresh launch routes to Welcome/Auth', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});

    await tester.pumpWidget(const ClarityMobileApp());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 1500));
    await tester.pumpAndSettle();

    // Verify Welcome/Auth options appear for fresh install
    expect(find.text('Continue as Private Guest'), findsOneWidget);
    expect(find.text('Continue with Email'), findsOneWidget);
  });

  testWidgets('Clarity mobile app onboarded user routes to main dashboard', (WidgetTester tester) async {
    final profileJson = {
      'id': 'user_test',
      'email': 'test@example.com',
      'name': 'Test User',
      'cigarettesPerDay': 10,
      'targetCigarettesPerDay': 9,
      'packPrice': 200.0,
      'cigarettesPerPack': 20,
      'currency': '₹',
      'currentDelayMinutes': 7,
      'onboardingCompleted': true,
      'isAuthenticated': true,
      'steadyStreak': 1,
      'strategyMode': 'REDUCE',
    };

    SharedPreferences.setMockInitialValues({
      'clarity_user_profile': jsonEncode(profileJson),
    });

    await tester.pumpWidget(const ClarityMobileApp());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 1500));
    await tester.pumpAndSettle();

    // Verify navigation tabs render
    expect(find.text('Home'), findsOneWidget);
    expect(find.text('Progress'), findsOneWidget);
    expect(find.text('Coach'), findsOneWidget);
    expect(find.text('Learn'), findsOneWidget);

    // Verify primary buttons on home dashboard
    expect(find.text('I SMOKED'), findsOneWidget);
    expect(find.text("I'M CRAVING"), findsOneWidget);
  });
}
