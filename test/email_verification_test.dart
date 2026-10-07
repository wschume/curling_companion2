import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:curling_companion/main.dart';
import 'package:curling_companion/models/models.dart';
import 'package:curling_companion/services/services.dart';

class TestAuthService extends LocalAuthService {
  bool failSend = false;
  bool failRefresh = false;
  bool verified = false;
  int sends = 0;
  int registrations = 0;
  bool failTerms = false;
  int termsSaves = 0;
  String? termsLanguage;
  @override
  Future<void> acceptTerms(String languageCode) async {
    termsSaves++;
    termsLanguage = languageCode;
    if (failTerms) throw StateError("Consent save failed");
    await super.acceptTerms(languageCode);
  }

  String? sentLanguage;
  @override
  bool get isEmailVerified => verified && currentEmail != null;
  @override
  Future<void> register(String email, String password) async {
    registrations++;
    await super.register(email, password);
  }

  @override
  Future<void> sendEmailVerification(String languageCode) async {
    sends++;
    sentLanguage = languageCode;
    if (failSend) throw StateError('Send failed');
  }

  @override
  Future<void> refreshUser() async {
    if (failRefresh) throw StateError('Refresh failed');
    await super.refreshUser();
  }
}

Widget app(AuthService auth) => CurlingCompanionApp(
  auth: auth,
  marketplace: MemoryMarketplaceRepository(),
  tournaments: MemoryTournamentRepository(),
  players: MemoryPlayerRepository(),
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test(
    'registration sends localized verification and remains restricted',
    () async {
      final service = TestAuthService();
      final auth = AuthController(service);
      await auth.register(
        'new@example.com',
        'password',
        languageCode: 'de',
        acceptedTerms: true,
      );
      expect(service.sentLanguage, 'de');
      expect(auth.isSignedIn, isTrue);
      expect(auth.canManageContent, isFalse);
      service.verified = true;
      await auth.refreshUser();
      expect(auth.canManageContent, isTrue);
      await auth.signOut();
      await Future<void>.delayed(Duration.zero);
      expect(auth.canManageContent, isFalse);
      auth.dispose();
    },
  );

  for (final failSend in [false, true]) {
    testWidgets(
      'registration blocks tournament creation (send fails: $failSend)',
      (tester) async {
        await tester.binding.setSurfaceSize(const Size(800, 1000));
        addTearDown(() => tester.binding.setSurfaceSize(null));
        final service = TestAuthService()..failSend = failSend;
        await tester.pumpWidget(app(service));
        await tester.pumpAndSettle();
        await tester.tap(find.widgetWithText(FilledButton, 'Register'));
        await tester.pumpAndSettle();
        final fields = find.byType(TextFormField);
        await tester.enterText(fields.at(0), 'new@example.com');
        await tester.enterText(fields.at(1), 'password123');
        await tester.enterText(fields.at(2), 'password123');
        await tester.tap(find.byType(Checkbox));
        await tester.pumpAndSettle();
        await tester.tap(find.widgetWithText(FilledButton, 'Register'));
        await tester.pumpAndSettle();
        expect(service.registrations, 1);
        expect(service.sends, 1);
        expect(service.isEmailVerified, isFalse);
        expect(find.byType(EmailVerificationPage), findsOneWidget);
        if (failSend) {
          expect(
            find.textContaining('Could not send the verification email.'),
            findsOneWidget,
          );
        }
        GoRouter.of(
          tester.element(find.byType(EmailVerificationPage)),
        ).go('/tournaments');
        await tester.pumpAndSettle();
        expect(find.text('Create tournament'), findsNothing);
        expect(find.text('Verify email'), findsOneWidget);
      },
    );
  }

  test('failed send allows resend without creating another account', () async {
    final service = TestAuthService()..failSend = true;
    final auth = AuthController(service);
    await auth.register('new@example.com', 'password', acceptedTerms: true);
    expect(auth.isSignedIn, isTrue);
    expect(auth.verificationError, isNotNull);
    service.failSend = false;
    await auth.sendVerification('en');
    expect(service.sends, 2);
    expect(service.registrations, 1);
    auth.dispose();
  });

  test('refresh failure fails closed and retry restores access', () async {
    final service = TestAuthService()..verified = true;
    await service.signIn('user@example.com', 'password');
    await service.acceptTerms('en');
    final auth = AuthController(service);
    await auth.refreshUser();
    expect(auth.canManageContent, isTrue);
    service.failRefresh = true;
    await expectLater(auth.refreshUser(), throwsStateError);
    expect(auth.canManageContent, isFalse);
    service.failRefresh = false;
    await auth.refreshUser();
    expect(auth.canManageContent, isTrue);
    auth.dispose();
  });

  test('returning to app refreshes verification status', () async {
    final service = TestAuthService();
    await service.signIn('user@example.com', 'password');
    await service.acceptTerms('en');
    final auth = AuthController(service);
    service.verified = true;
    auth.didChangeAppLifecycleState(AppLifecycleState.resumed);
    await Future<void>.delayed(Duration.zero);
    expect(auth.canManageContent, isTrue);
    auth.dispose();
  });

  test('local email change stays pending until confirmation', () async {
    final service = LocalAuthService();
    await service.register('old@example.com', 'password');
    await service.acceptTerms('en');
    service.simulateEmailVerification();
    final auth = AuthController(service);
    await auth.updateEmail('new@example.com');
    expect(auth.email, 'old@example.com');
    service.simulateEmailVerification();
    await auth.refreshUser();
    expect(auth.email, 'new@example.com');
    expect(auth.canManageContent, isTrue);
    auth.dispose();
  });

  testWidgets('unverified user can browse and sees verification prompt', (
    tester,
  ) async {
    final service = LocalAuthService();
    await service.register('new@example.com', 'password');
    await service.acceptTerms('en');
    await tester.pumpWidget(app(service));
    await tester.pumpAndSettle();
    expect(find.text('Marketplace'), findsOneWidget);
    expect(find.text('Verify email'), findsOneWidget);
    expect(find.text('Create listing'), findsNothing);
    await tester.tap(find.text('Verify email'));
    await tester.pumpAndSettle();
    expect(find.text("I've verified my email"), findsOneWidget);
    await tester.tap(find.text("I've verified my email"));
    await tester.pumpAndSettle();
    expect(
      find.textContaining('Your email is not verified yet.'),
      findsOneWidget,
    );
    await tester.tap(find.text('Simulate verification (local demo)'));
    await tester.pumpAndSettle();
    expect(find.text('Verify email'), findsNothing);
  });

  testWidgets('verification screen reports send and refresh errors', (
    tester,
  ) async {
    final service = TestAuthService()..failSend = true;
    await service.register('new@example.com', 'password');
    await service.acceptTerms('en');
    await tester.pumpWidget(app(service));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Verify email'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Resend verification email'));
    await tester.pumpAndSettle();
    expect(
      find.textContaining('Could not send the verification email.'),
      findsOneWidget,
    );
    service.failSend = false;
    await tester.tap(find.text('Resend verification email'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Verification email sent.'), findsOneWidget);
    service.failRefresh = true;
    await tester.tap(find.text("I've verified my email"));
    await tester.pumpAndSettle();
    expect(
      find.textContaining('Could not check verification.'),
      findsOneWidget,
    );
  });
  testWidgets('unverified owners retain deletion and account settings', (
    tester,
  ) async {
    final service = LocalAuthService();
    await service.register('owner@example.com', 'password');
    final marketplace = MemoryMarketplaceRepository();
    await marketplace.save(
      const MarketplaceListing(
        id: 'owned',
        title: 'Owned broom',
        description: 'Test',
        price: 10,
        ownerId: 'owner@example.com',
      ),
    );
    await tester.pumpWidget(
      CurlingCompanionApp(
        auth: service,
        marketplace: marketplace,
        tournaments: MemoryTournamentRepository(),
        players: MemoryPlayerRepository(),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Profile'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Settings'));
    await tester.pumpAndSettle();
    expect(find.text('Delete account'), findsOneWidget);
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Marketplace'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Marketplace'));
    await tester.pumpAndSettle();
    expect(find.text('Create listing'), findsNothing);
    final edit = tester.widget<IconButton>(
      find.widgetWithIcon(IconButton, Icons.edit_outlined),
    );
    expect(edit.onPressed, isNull);
    final delete = tester.widget<IconButton>(
      find.widgetWithIcon(IconButton, Icons.delete_outline),
    );
    expect(delete.onPressed, isNotNull);
    await tester.ensureVisible(find.byTooltip('Delete listing?'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Delete listing?'));
    await tester.pumpAndSettle();
    expect(find.text('This action cannot be undone.'), findsOneWidget);
    await tester.tap(find.widgetWithText(FilledButton, 'Delete listing?'));
    await tester.pumpAndSettle();
    expect(
      (await marketplace.watchListings().first).any(
        (listing) => listing.id == 'owned',
      ),
      isFalse,
    );
  });
  test('registration without explicit acceptance creates no account', () async {
    final service = TestAuthService();
    final auth = AuthController(service);
    await expectLater(
      auth.register('new@example.com', 'password', acceptedTerms: false),
      throwsStateError,
    );
    expect(service.registrations, 0);
    expect(service.sends, 0);
    expect(service.termsSaves, 0);
    auth.dispose();
  });

  test(
    'failed consent save stays restricted and can retry without another registration',
    () async {
      final service = TestAuthService()..failTerms = true;
      final auth = AuthController(service);
      await auth.register(
        'new@example.com',
        'password',
        acceptedTerms: true,
        languageCode: 'de',
      );
      expect(service.registrations, 1);
      expect(service.sends, 1);
      expect(service.termsLanguage, 'de');
      expect(auth.termsError, isTrue);
      service.verified = true;
      await auth.refreshUser();
      expect(auth.canManageContent, isFalse);
      service.failTerms = false;
      await auth.acceptTerms('de');
      expect(auth.canManageContent, isTrue);
      await auth.signOut();
      await Future<void>.delayed(Duration.zero);
      expect(auth.hasAcceptedTerms, isFalse);
      await auth.signIn('new@example.com', 'password');
      expect(auth.hasAcceptedTerms, isTrue);
      expect(service.registrations, 1);
      auth.dispose();
    },
  );

  testWidgets('unchecked registration and reading terms preserve user input', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(800, 1000));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final service = TestAuthService();
    await tester.pumpWidget(app(service));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Register'));
    await tester.pumpAndSettle();
    expect(tester.widget<Checkbox>(find.byType(Checkbox)).value, isFalse);
    expect(
      tester
          .widget<FilledButton>(find.widgetWithText(FilledButton, 'Register'))
          .onPressed,
      isNull,
    );
    final fields = find.byType(TextFormField);
    await tester.enterText(fields.at(0), 'new@example.com');
    await tester.enterText(fields.at(1), 'password123');
    await tester.enterText(fields.at(2), 'password123');
    await tester.tap(find.text('Read terms'));
    await tester.pumpAndSettle();
    expect(find.text('Terms of use'), findsOneWidget);
    expect(find.text('Copyright infringement'), findsOneWidget);
    await tester.tap(find.text('Close'));
    await tester.pumpAndSettle();
    expect(find.text('new@example.com'), findsOneWidget);
    expect(tester.widget<Checkbox>(find.byType(Checkbox)).value, isFalse);
    expect(service.registrations, 0);
    await tester.tap(find.byType(Checkbox));
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<FilledButton>(find.widgetWithText(FilledButton, 'Register'))
          .onPressed,
      isNotNull,
    );
  });

  testWidgets(
    'failed terms save retries on registration without creating another account',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 1000));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final service = TestAuthService()..failTerms = true;
      await tester.pumpWidget(app(service));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Register'));
      await tester.pumpAndSettle();
      final fields = find.byType(TextFormField);
      await tester.enterText(fields.at(0), 'new@example.com');
      await tester.enterText(fields.at(1), 'password123');
      await tester.enterText(fields.at(2), 'password123');
      await tester.tap(find.byType(Checkbox));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Register'));
      await tester.pumpAndSettle();
      expect(tester.widget<Checkbox>(find.byType(Checkbox)).value, isTrue);
      expect(find.byType(TextFormField), findsNothing);
      expect(find.textContaining('Please retry saving'), findsOneWidget);
      service.failTerms = false;
      await tester.tap(find.widgetWithText(FilledButton, 'Accept terms'));
      await tester.pumpAndSettle();
      expect(find.byType(Checkbox), findsNothing);
      expect(find.text('Read terms'), findsNothing);
      expect(find.text('Accept terms'), findsNothing);
      expect(service.registrations, 1);
      expect(service.sends, 1);
    },
  );

  testWidgets('terms checkbox and dialog use the selected German locale', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(800, 1000));
    tester.binding.platformDispatcher.localeTestValue = const Locale('de');
    addTearDown(() {
      tester.binding.setSurfaceSize(null);
      tester.binding.platformDispatcher.clearLocaleTestValue();
    });
    await tester.pumpWidget(app(LocalAuthService()));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Registrieren'));
    await tester.pumpAndSettle();
    expect(
      find.text('Ich akzeptiere die Nutzungsbedingungen.'),
      findsOneWidget,
    );
    expect(tester.widget<Checkbox>(find.byType(Checkbox)).value, isFalse);
    await tester.tap(find.text('Nutzungsbedingungen lesen'));
    await tester.pumpAndSettle();
    expect(find.text('Nutzungsbedingungen'), findsOneWidget);
    expect(find.text('Verstöße gegen das Urheberrecht'), findsOneWidget);
  });
}
