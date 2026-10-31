import 'package:curling_companion/main.dart';
import 'package:curling_companion/l10n/app_localizations.dart';
import 'package:curling_companion/services/services.dart';
import 'package:curling_companion/services/demo/demo_services.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

void main() {
  for (final language in ['en', 'de']) {
    testWidgets('Alternate can be created in both search forms ($language)', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1400, 2000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final service = LocalAuthService();
      await service.signIn('player@example.com', 'password');
      service.simulateEmailVerification();
      await service.acceptTerms(language);
      final auth = AuthController(service);
      final players = MemoryPlayerRepository();
      final router = GoRouter(
        routes: [
          GoRoute(
            path: '/',
            builder: (_, _) => const Scaffold(body: PlayersDirectoryPage()),
          ),
        ],
      );
      addTearDown(router.dispose);
      addTearDown(auth.dispose);
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider.value(value: auth),
            Provider<PlayerRepository>.value(value: players),
            Provider<TournamentRepository>.value(
              value: MemoryTournamentRepository(),
            ),
          ],
          child: MaterialApp.router(
            routerConfig: router,
            locale: Locale(language),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
          ),
        ),
      );
      await tester.pumpAndSettle();
      final l10n = AppLocalizations.of(
        tester.element(find.byType(PlayersDirectoryPage)),
      );
      for (final button in [l10n.createPlayerSearch, l10n.createTeamSearch]) {
        await tester.tap(find.text(button));
        await tester.pumpAndSettle();
        final dropdowns = find.descendant(
          of: find.byType(AlertDialog),
          matching: find.byType(DropdownButtonFormField<String>),
        );
        await tester.tap(dropdowns.first);
        await tester.pumpAndSettle();
        await tester.tap(find.text('Berlin Ice Cup').last);
        await tester.pumpAndSettle();
        await tester.tap(dropdowns.last);
        await tester.pumpAndSettle();
        await tester.tap(find.text('alternate').last);
        await tester.pumpAndSettle();
        await tester.tap(
          find.descendant(
            of: find.byType(AlertDialog),
            matching: find.byType(FilledButton),
          ),
        );
        await tester.pumpAndSettle();
      }
      expect(
        (await players.watchTeamSearches().first).single.role,
        'alternate',
      );
      expect(
        (await players.watchPlayerTeamSearches().first).single.role,
        'alternate',
      );
      expect(find.text('alternate'), findsNWidgets(2));
    });
  }
}
