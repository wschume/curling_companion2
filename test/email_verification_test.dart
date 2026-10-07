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
      await auth.register('new@example.com', 'password', languageCode: 'de');
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
    await auth.register('new@example.com', 'password');
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
    final auth = AuthController(service);
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
}
