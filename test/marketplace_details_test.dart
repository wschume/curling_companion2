import 'package:curling_companion/main.dart';
import 'package:curling_companion/l10n/app_localizations.dart';
import 'package:curling_companion/models/models.dart';
import 'package:curling_companion/services/services.dart';
import 'package:curling_companion/services/demo/demo_services.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

void main() {
  for (final width in [600.0, 1200.0]) {
    for (final hasImages in [false, true]) {
      testWidgets(
        'image, title and details button open offer at width $width (images: $hasImages)',
        (tester) async {
          tester.view.physicalSize = Size(width, 1800);
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);
          final repository = MemoryMarketplaceRepository();
          for (final item in await repository.watchListings().first) {
            await repository.delete(item.id);
          }
          await repository.save(
            MarketplaceListing(
              id: 'offer',
              title: 'Test offer',
              description: 'Full description',
              imageUrls: hasImages
                  ? [
                      'https://example.com/one.jpg',
                      'https://example.com/two.jpg',
                    ]
                  : const [],
              price: 20,
              city: 'Berlin',
              country: 'Germany',
              ownerId: 'seller',
            ),
          );
          final auth = AuthController(LocalAuthService());
          final router = GoRouter(
            routes: [
              GoRoute(
                path: '/',
                builder: (_, _) => const Scaffold(body: MarketplacePage()),
              ),
            ],
          );
          addTearDown(router.dispose);
          addTearDown(auth.dispose);
          await tester.pumpWidget(
            MultiProvider(
              providers: [
                ChangeNotifierProvider.value(value: auth),
                Provider<MarketplaceRepository>.value(value: repository),
              ],
              child: MaterialApp.router(
                routerConfig: router,
                localizationsDelegates: AppLocalizations.localizationsDelegates,
                supportedLocales: AppLocalizations.supportedLocales,
              ),
            ),
          );
          await tester.pumpAndSettle();
          for (final target in [
            if (hasImages) find.text('1 / 2'),
            find.byKey(const ValueKey('listing-image-offer')),
            find.byKey(const ValueKey('listing-title-offer')),
            find.text('View details'),
          ]) {
            await tester.ensureVisible(target);
            await tester.tap(target);
            await tester.pumpAndSettle();
            expect(find.byType(AlertDialog), findsOneWidget);
            expect(
              find.descendant(
                of: find.byType(AlertDialog),
                matching: find.text('Test offer'),
              ),
              findsOneWidget,
            );
            await tester.tap(find.text('Close'));
            await tester.pumpAndSettle();
            expect(find.byType(AlertDialog), findsNothing);
          }
          for (final key in ['listing-image-offer', 'listing-title-offer']) {
            final ink = find.descendant(
              of: find.byKey(ValueKey(key)),
              matching: find.byType(InkWell),
            );
            await tester.ensureVisible(ink);
            Focus.of(
              tester.element(
                find
                    .descendant(of: ink, matching: find.byType(MouseRegion))
                    .first,
              ),
            ).requestFocus();
            await tester.pump();
            await tester.sendKeyEvent(LogicalKeyboardKey.enter);
            await tester.pumpAndSettle();
            expect(find.byType(AlertDialog), findsOneWidget);
            await tester.tap(find.text('Close'));
            await tester.pumpAndSettle();
          }
        },
      );
    }
  }
}
