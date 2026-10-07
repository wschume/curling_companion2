import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:curling_companion/l10n/app_localizations.dart';
import 'package:curling_companion/main.dart';
import 'package:curling_companion/models/models.dart';
import 'package:curling_companion/services/services.dart';

class _FailingDeleteRepository extends MemoryTournamentRepository {
  @override
  Future<void> delete(String tournamentId) async {
    throw StateError('Deletion failed');
  }
}

void main() {
  testWidgets('signed-in user can open the create tournament form', (
    tester,
  ) async {
    final authService = LocalAuthService();
    await authService.signIn('owner@example.com', 'password');
    authService.simulateEmailVerification();
    await authService.acceptTerms('en');
    final auth = AuthController(authService);

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: auth),
          Provider<TournamentRepository>(
            create: (_) => MemoryTournamentRepository(),
          ),
        ],
        child: MaterialApp(
          home: const Scaffold(body: TournamentsPage()),
          supportedLocales: const [Locale('en'), Locale('de')],
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Create tournament'), findsOneWidget);
    await tester.tap(find.text('Create tournament'));
    await tester.pumpAndSettle();

    expect(find.text('Save tournament'), findsOneWidget);
    expect(find.text('Club *'), findsAtLeastNWidgets(1));
  });

  testWidgets('my tournaments toggle filters by the signed-in organizer', (
    tester,
  ) async {
    final authService = LocalAuthService();
    await authService.signIn('owner@example.com', 'password');
    authService.simulateEmailVerification();
    await authService.acceptTerms('en');
    final auth = AuthController(authService);
    final repository = MemoryTournamentRepository();
    await repository.save(
      Tournament(
        id: 'owned-event',
        name: 'Owned Bonspiel',
        startDate: DateTime.now().add(const Duration(days: 10)),
        endDate: DateTime.now().add(const Duration(days: 12)),
        city: 'Berlin',
        organizerId: 'owner@example.com',
      ),
    );
    await repository.save(
      Tournament(
        id: 'other-event',
        name: 'Other Bonspiel',
        startDate: DateTime.now().add(const Duration(days: 20)),
        endDate: DateTime.now().add(const Duration(days: 22)),
        city: 'Oslo',
        organizerId: 'other@example.com',
      ),
    );

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: auth),
          Provider<TournamentRepository>.value(value: repository),
        ],
        child: MaterialApp(
          home: const Scaffold(body: TournamentsPage()),
          supportedLocales: const [Locale('en'), Locale('de')],
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Owned Bonspiel'), findsOneWidget);
    expect(find.text('Other Bonspiel'), findsOneWidget);
    await tester.tap(find.text('My tournaments'));
    await tester.pumpAndSettle();

    expect(find.text('Owned Bonspiel'), findsOneWidget);
    expect(find.text('Other Bonspiel'), findsNothing);
    expect(find.text('All tournaments'), findsOneWidget);
  });
  for (final fails in [false, true]) {
    testWidgets('confirmed tournament deletion (fails: $fails)', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(1200, 1000));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final auth = LocalAuthService();
      await auth.signIn('owner@example.com', 'password');
      final repository = fails
          ? _FailingDeleteRepository()
          : MemoryTournamentRepository();
      await repository.save(
        Tournament(
          id: 'delete-event',
          name: 'Deletion Bonspiel',
          startDate: DateTime.now().add(const Duration(days: 10)),
          endDate: DateTime.now().add(const Duration(days: 12)),
          city: 'Berlin',
          organizerId: 'owner@example.com',
        ),
      );
      await tester.pumpWidget(
        CurlingCompanionApp(
          auth: auth,
          marketplace: MemoryMarketplaceRepository(),
          tournaments: repository,
          players: MemoryPlayerRepository(),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Tournaments').first);
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.byTooltip('Delete tournament'));
      await tester.tap(find.byTooltip('Delete tournament'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(
        (await repository.watchTournaments().first).any(
          (event) => event.id == 'delete-event',
        ),
        isTrue,
      );
      await tester.tap(find.byTooltip('Delete tournament'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Delete tournament'));
      await tester.pumpAndSettle();
      expect(
        (await repository.watchTournaments().first).any(
          (event) => event.id == 'delete-event',
        ),
        fails,
      );
      expect(
        find.text(
          fails
              ? 'Could not delete tournament. Please try again.'
              : 'Tournament deleted.',
        ),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    });
  }
}
