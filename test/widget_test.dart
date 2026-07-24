import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:propkart/main.dart';
import 'package:propkart/features/auth/repository/auth_repository.dart';

class MockAuthRepository extends AuthRepository {
  @override
  Future<bool> isAuthenticated() async => false;

  @override
  Future<String?> getSavedToken() async => null;
}

void main() {
  testWidgets('Login screen loads correctly test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    final authRepository = MockAuthRepository();
    await tester.pumpWidget(MyApp(authRepository: authRepository));
    
    // Wait for the BLoC status check to resolve and transition to Unauthenticated
    await tester.pump(const Duration(milliseconds: 100));

    // Tap "Get Started" on splash screen to navigate to Login Screen
    await tester.tap(find.text('Get Started'));
    await tester.pumpAndSettle();

    // Verify that our app title is shown.
    expect(find.text('Go ahead to your account'), findsOneWidget);

    // Verify that the form elements exist on the screen.
    expect(find.text('Email Address'), findsOneWidget);
    expect(find.text('Password'), findsOneWidget);
    expect(find.text('Remember me'), findsOneWidget);
  });
}
