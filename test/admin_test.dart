import 'dart:async';
import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:curling_companion/main.dart';
import 'package:curling_companion/l10n/app_localizations.dart';
import 'package:curling_companion/models/models.dart';
import 'package:curling_companion/services/services.dart';
import 'package:curling_companion/services/demo/demo_services.dart';

class FailingMarketplace extends MemoryMarketplaceRepository {
  bool fail = false;
  @override
  Future<void> save(MarketplaceListing listing) async {
    if (fail) throw StateError('Permission revoked');
    await super.save(listing);
  }
}

class RoleAuth extends LocalAuthService {
  final roles = <StreamController<bool>>[];
  @override
  Stream<bool> watchAdminRole() {
    final stream = StreamController<bool>.broadcast();
    roles.add(stream);
    return stream.stream;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test(
    'roles fail closed, revoke live, reset on account change and sign-out',
    () async {
      final service = RoleAuth();
      await service.signIn('moderator@example.com', 'password');
      final auth = AuthController(service);
      expect(auth.isAdmin, false);
      service.roles.last.add(true);
      await Future<void>.delayed(Duration.zero);
      expect(auth.canDeleteEntry('other'), true);
      expect(auth.canEditEntry('other'), false);
      service.simulateEmailVerification();
      await service.acceptTerms('en');
      await auth.refreshUser();
      expect(auth.canEditEntry('other'), true);
      service.roles.last.addError(StateError('Role read failed'));
      await Future<void>.delayed(Duration.zero);
      expect(auth.isAdmin, false);
      service.roles.last.add(true);
      await Future<void>.delayed(Duration.zero);
      final previous = service.roles.last;
      await auth.signIn('next@example.com', 'password');
      previous.add(true);
      await Future<void>.delayed(Duration.zero);
      expect(auth.isAdmin, false);
      service.roles.last.add(true);
      await Future<void>.delayed(Duration.zero);
      expect(auth.isAdmin, true);
      await auth.signOut();
      await Future<void>.delayed(Duration.zero);
      expect(auth.isAdmin, false);
      auth.dispose();
      for (final role in service.roles) {
        await role.close();
      }
    },
  );

  for (final page in [
    'marketplace',
    'marketplace-failure',
    'tournaments',
    'players',
  ]) {
    testWidgets('$page moderation controls follow role grant and revocation', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1400, 2000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final service = RoleAuth();
      await service.signIn('moderator@example.com', 'password');
      service.simulateEmailVerification();
      await service.acceptTerms('en');
      final auth = AuthController(service);
      final tournaments = MemoryTournamentRepository();
      await tournaments.save(
        Tournament(
          id: 'admin-event',
          name: 'Admin event',
          city: 'Berlin',
          startDate: DateTime(2099),
          endDate: DateTime(2099, 1, 3),
          organizerId: 'other',
        ),
      );
      final marketplace = FailingMarketplace();
      for (final listing in await marketplace.watchListings().first) {
        await marketplace.delete(listing.id);
      }
      await marketplace.save(
        const MarketplaceListing(
          id: 'admin-listing',
          title: 'Admin listing',
          description: 'Test',
          price: 10,
          location: 'Berlin',
          sellerContact: 'other@example.com',
          ownerId: 'other',
        ),
      );
      final players = MemoryPlayerRepository();
      await players.saveTeamSearch(
        const TeamPlayerSearch(
          id: 'team',
          tournamentId: 'admin-event',
          role: 'any',
          contact: 'other@example.com',
          ownerId: 'other',
        ),
      );
      await players.savePlayerTeamSearch(
        const PlayerTeamSearch(
          id: 'player',
          tournamentId: 'admin-event',
          role: 'any',
          contact: 'other@example.com',
          ownerId: 'other',
        ),
      );
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider.value(value: auth),
            Provider<TournamentRepository>.value(value: tournaments),
            Provider<MarketplaceRepository>.value(value: marketplace),
            Provider<PlayerRepository>.value(value: players),
          ],
          child: MaterialApp.router(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            routerConfig: GoRouter(
              routes: [
                GoRoute(
                  path: '/',
                  builder: (_, _) => Scaffold(
                    body: page.startsWith('marketplace')
                        ? const MarketplacePage()
                        : page == 'tournaments'
                        ? const TournamentsPage()
                        : const PlayersDirectoryPage(),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.delete_outline), findsNothing);
      service.roles.last.add(true);
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.delete_outline), findsWidgets);
      expect(find.byIcon(Icons.edit_outlined), findsWidgets);
      marketplace.fail = page == 'marketplace-failure';
      await tester.ensureVisible(find.byIcon(Icons.edit_outlined).first);
      await tester.tap(find.byIcon(Icons.edit_outlined).first);
      await tester.pumpAndSettle();
      final labels = AppLocalizations.of(
        tester.element(find.byType(AlertDialog)),
      );
      final save = find.text(
        page == 'tournaments' ? labels.saveTournament : labels.saveChanges,
      );
      await tester.ensureVisible(save);
      await tester.tap(save);
      await tester.pumpAndSettle();
      expect(find.byType(AlertDialog), findsNothing);
      if (marketplace.fail) {
        expect(find.text(labels.contentActionFailed), findsOneWidget);
      }
      expect(
        (await tournaments.watchTournaments().first)
            .firstWhere((t) => t.id == 'admin-event')
            .organizerId,
        'other',
      );
      expect(
        (await marketplace.watchListings().first)
            .firstWhere((l) => l.id == 'admin-listing')
            .ownerId,
        'other',
      );
      expect((await players.watchTeamSearches().first).single.ownerId, 'other');
      expect(
        (await players.watchPlayerTeamSearches().first).single.ownerId,
        'other',
      );
      service.roles.last.add(false);
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.delete_outline), findsNothing);
      await tester.pumpWidget(const SizedBox());
      auth.dispose();
      for (final role in service.roles) {
        await role.close();
      }
    });
  }
}
