import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pawtrack/main.dart';

void main() {
  testWidgets('login screen renders before authentication', (tester) async {
    await tester.pumpWidget(
      PawTrackApp(authService: FakeAuthService()),
    );
    await tester.pumpAndSettle();

    expect(find.text('Sign in to PawTrack'), findsOneWidget);
    expect(find.byKey(const Key('login-email')), findsOneWidget);
    expect(find.byKey(const Key('login-password')), findsOneWidget);
  });

  testWidgets('bottom navigation switches app sections', (tester) async {
    await tester.pumpWidget(
      PawTrackApp(authService: FakeAuthService(initiallySignedIn: true)),
    );
    await tester.pumpAndSettle();

    expect(find.text('Pet profiles'), findsOneWidget);

    await tester.tap(find.text('Logs'));
    await tester.pumpAndSettle();
    expect(find.text('Health logs'), findsOneWidget);

    await tester.tap(find.text('Insights'));
    await tester.pumpAndSettle();
    expect(find.text('Pattern flags'), findsOneWidget);
  });

  testWidgets('add pet form inserts a pet into local state', (tester) async {
    await tester.pumpWidget(
      PawTrackApp(authService: FakeAuthService(initiallySignedIn: true)),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Add pet'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byKey(const Key('pet-name-field')), 'Buddy');
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Breed'),
      'Beagle',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Notes'),
      'Loves walks and evening snacks.',
    );
    await tester.tap(find.byKey(const Key('save-pet')));
    await tester.pumpAndSettle();

    expect(find.text('Buddy'), findsOneWidget);
    expect(find.text('Dog • Beagle'), findsOneWidget);
  });

  testWidgets('add log form inserts a log into local state', (tester) async {
    await tester.pumpWidget(
      PawTrackApp(authService: FakeAuthService(initiallySignedIn: true)),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Logs'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Add log'));
    await tester.pumpAndSettle();

    // Add a weight log (default type)
    await tester.enterText(
      find.byKey(const Key('log-weight-field')),
      '25.5',
    );
    await tester.tap(find.byKey(const Key('save-log')));
    await tester.pumpAndSettle();

    expect(find.textContaining('25.5'), findsOneWidget);
  });

  testWidgets('logout returns to login', (tester) async {
    final authService = FakeAuthService(initiallySignedIn: true);
    await tester.pumpWidget(PawTrackApp(authService: authService));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Sign out'));
    await tester.pumpAndSettle();

    expect(find.text('Sign in to PawTrack'), findsOneWidget);
  });

  testWidgets('add pet shows error snackbar when DB save fails', (tester) async {
    await tester.pumpWidget(
      PawTrackApp(
        authService: FakeAuthService(initiallySignedIn: true),
        db: FailingFakePawTrackDatabase(),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Add pet'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byKey(const Key('pet-name-field')), 'Buddy');
    await tester.enterText(find.widgetWithText(TextFormField, 'Breed'), 'Beagle');
    await tester.tap(find.byKey(const Key('save-pet')));
    await tester.pumpAndSettle();

    expect(find.text('Failed to save pet. Please try again.'), findsOneWidget);
    expect(find.text('Buddy'), findsNothing);
  });

  testWidgets('dismissing add pet form does not add a pet', (tester) async {
    await tester.pumpWidget(
      PawTrackApp(authService: FakeAuthService(initiallySignedIn: true)),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Add pet'));
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.close));
    await tester.pumpAndSettle();

    expect(find.text('No pets yet'), findsOneWidget);
  });


  // B — Add Pet form tests
  testWidgets('B1: add pet with name and breed only (notes optional)', (tester) async {
    await tester.pumpWidget(
      PawTrackApp(authService: FakeAuthService(initiallySignedIn: true)),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Add pet'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byKey(const Key('pet-name-field')), 'Max');
    await tester.enterText(find.widgetWithText(TextFormField, 'Breed'), 'Golden Retriever');
    await tester.tap(find.byKey(const Key('save-pet')));
    await tester.pumpAndSettle();

    expect(find.text('Max'), findsOneWidget);
    expect(find.text('Dog • Golden Retriever'), findsOneWidget);
  });

  testWidgets('B2: saving without a name shows validation error', (tester) async {
    await tester.pumpWidget(
      PawTrackApp(authService: FakeAuthService(initiallySignedIn: true)),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Add pet'));
    await tester.pumpAndSettle();

    await tester.enterText(find.widgetWithText(TextFormField, 'Breed'), 'Poodle');
    await tester.tap(find.byKey(const Key('save-pet')));
    await tester.pump();

    expect(find.text('Required.'), findsWidgets);
  });

  testWidgets('B3: saving without a breed shows validation error', (tester) async {
    await tester.pumpWidget(
      PawTrackApp(authService: FakeAuthService(initiallySignedIn: true)),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Add pet'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byKey(const Key('pet-name-field')), 'Fluffy');
    await tester.tap(find.byKey(const Key('save-pet')));
    await tester.pump();

    expect(find.text('Required.'), findsWidgets);
  });

  testWidgets('B4: species dropdown defaults to Dog', (tester) async {
    await tester.pumpWidget(
      PawTrackApp(authService: FakeAuthService(initiallySignedIn: true)),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Add pet'));
    await tester.pumpAndSettle();

    expect(find.text('Dog'), findsOneWidget);
  });

  testWidgets('B5: species can be changed to Cat', (tester) async {
    await tester.pumpWidget(
      PawTrackApp(authService: FakeAuthService(initiallySignedIn: true)),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Add pet'));
    await tester.pumpAndSettle();

    await tester.tap(find.byType(DropdownButtonFormField<String>).first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cat').last);
    await tester.pumpAndSettle();

    await tester.enterText(find.byKey(const Key('pet-name-field')), 'Whiskers');
    await tester.enterText(find.widgetWithText(TextFormField, 'Breed'), 'Siamese');
    await tester.tap(find.byKey(const Key('save-pet')));
    await tester.pumpAndSettle();

    expect(find.text('Cat • Siamese'), findsOneWidget);
  });

  // C — Add Log form tests
  testWidgets('C2: weight log missing weight shows validation error', (tester) async {
    await tester.pumpWidget(
      PawTrackApp(authService: FakeAuthService(initiallySignedIn: true)),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Logs'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Add log'));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('save-log')));
    await tester.pump();

    expect(find.text('Required.'), findsWidgets);
  });




  testWidgets('C17: dismissing add log form does not add a log', (tester) async {
    await tester.pumpWidget(
      PawTrackApp(authService: FakeAuthService(initiallySignedIn: true)),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Logs'));
    await tester.pumpAndSettle();

    expect(find.text('No logs yet'), findsOneWidget);

    await tester.tap(find.byTooltip('Add log'));
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.close));
    await tester.pumpAndSettle();

    expect(find.text('No logs yet'), findsOneWidget);
  });

  testWidgets('C18: add log DB failure shows snackbar', (tester) async {
    await tester.pumpWidget(
      PawTrackApp(
        authService: FakeAuthService(initiallySignedIn: true),
        db: FailingFakeLogDatabase(),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Logs'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Add log'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byKey(const Key('log-weight-field')), '20');
    await tester.tap(find.byKey(const Key('save-log')));
    await tester.pumpAndSettle();

    expect(find.text('Failed to save log. Please try again.'), findsOneWidget);
  });
}

class FailingFakePawTrackDatabase implements PawTrackDatabaseI {
  @override
  Future<List<Pet>> fetchPets() async => [];
  @override
  Future<Pet> insertPet(Pet pet) async => throw Exception('DB error');
  @override
  Future<List<HealthLog>> fetchLogs(List<Pet> pets) async => [];
  @override
  Future<void> insertLog(HealthLog log) async {}
}

class FailingFakeLogDatabase implements PawTrackDatabaseI {
  @override
  Future<List<Pet>> fetchPets() async => [];
  @override
  Future<Pet> insertPet(Pet pet) async => pet;
  @override
  Future<List<HealthLog>> fetchLogs(List<Pet> pets) async => [];
  @override
  Future<void> insertLog(HealthLog log) async => throw Exception('DB error');
}

class FakeAuthService implements PawTrackAuth {
  FakeAuthService({bool initiallySignedIn = false})
    : _isSignedIn = initiallySignedIn;

  final _controller = StreamController<bool>.broadcast();
  bool _isSignedIn;

  @override
  bool get isConfigured => true;

  @override
  String? get currentEmail => _isSignedIn ? 'demo@pawtrack.app' : null;

  @override
  Stream<bool> authChanges() => _controller.stream;

  @override
  Future<bool> hasSession() async => _isSignedIn;

  @override
  Future<bool> signIn(String email, String password) async {
    _isSignedIn = true;
    _controller.add(true);
    return true;
  }

  @override
  Future<bool> signUp(String email, String password) async {
    _isSignedIn = true;
    _controller.add(true);
    return true;
  }

  @override
  Future<void> signOut() async {
    _isSignedIn = false;
    _controller.add(false);
  }
}
