import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:curling_companion/l10n/app_localizations.dart';
import 'package:curling_companion/main.dart';
import 'package:curling_companion/models/models.dart';
import 'package:curling_companion/services/services.dart';

void main() {
  testWidgets('signed-in user can open the create tournament form', (
    tester,
  ) async {
    final authService = LocalAuthService();
    await authService.signIn('owner@example.com', 'password');
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
    expect(find.text('Club'), findsAtLeastNWidgets(1));
  });

  testWidgets('my tournaments toggle filters by the signed-in organizer', (
    tester,
  ) async {
    final authService = LocalAuthService();
    await authService.signIn('owner@example.com', 'password');
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
