import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';

import 'package:curling_companion/l10n/app_localizations.dart';
import 'package:curling_companion/main.dart';
import 'package:curling_companion/models/models.dart';
import 'package:curling_companion/services/services.dart';

void main() {
  for (final fails in [false, true]) {
    testWidgets(
      fails
          ? 'lookup failure preserves form and allows retry'
          : 'duplicate preserves form and corrected city can be saved',
      (tester) async {
        final service = LocalAuthService();
        await service.signIn('owner@example.com', 'password');
        service.simulateEmailVerification();
        await service.acceptTerms('en');
        final auth = AuthController(service);
        final repository = _ControlledTournamentRepository();
        final router = GoRouter(
          routes: [
            GoRoute(
              path: '/',
              builder: (_, _) => const Scaffold(body: TournamentsPage()),
            ),
          ],
        );
        await tester.pumpWidget(
          MultiProvider(
            providers: [
              ChangeNotifierProvider.value(value: auth),
              Provider<TournamentRepository>.value(value: repository),
            ],
            child: MaterialApp.router(
              routerConfig: router,
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
        await tester.tap(find.text('Create tournament'));
        await tester.pumpAndSettle();
        final fields = find.byType(TextFormField);
        await tester.enterText(fields.at(0), 'New bonspiel');
        await tester.enterText(fields.at(1), 'Berlin');
        await tester.enterText(fields.at(2), 'Germany');
        await tester.enterText(fields.at(3), 'Test club');
        await tester.enterText(fields.at(6), 'test@example.com');
        await tester.tap(find.text('Save tournament'));
        await tester.pump();
        expect(
          tester
              .widget<FilledButton>(
                find.widgetWithText(FilledButton, 'Save tournament'),
              )
              .onPressed,
          isNull,
        );
        expect(repository.checkedCity, 'Berlin');
        if (fails) {
          repository.pending.completeError(StateError('offline'));
        } else {
          repository.pending.complete(true);
        }
        await tester.pumpAndSettle();
        final message = fails
            ? 'Unable to check for an existing tournament. Please try again.'
            : 'A tournament already exists in this city on this start date.';
        expect(find.text(message), findsOneWidget);
        expect(find.text('New bonspiel'), findsOneWidget);
        expect(repository.saves, 0);
        expect(find.text('Save tournament'), findsOneWidget);
        await tester.enterText(fields.at(1), 'Oslo');
        repository.pending = Completer<bool>();
        await tester.tap(find.text('Save tournament'));
        await tester.pump();
        repository.pending.complete(false);
        await tester.pumpAndSettle();
        expect(repository.checkedCity, 'Oslo');
        expect(repository.saves, 1);
        expect(find.text('Save tournament'), findsNothing);
        await tester.pumpWidget(const SizedBox.shrink());
        router.dispose();
        auth.dispose();
      },
    );
  }

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
}

class _ControlledTournamentRepository extends MemoryTournamentRepository {
  Completer<bool> pending = Completer<bool>();
  String? checkedCity;
  int saves = 0;

  @override
  Future<bool> hasDuplicate({
    required String city,
    required DateTime startDate,
  }) {
    checkedCity = city;
    return pending.future;
  }

  @override
  Future<void> save(Tournament tournament) async {
    saves++;
    await super.save(tournament);
  }
}
