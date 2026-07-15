import 'package:flutter_test/flutter_test.dart';

import 'package:curling_companion/main.dart';
import 'package:curling_companion/services/services.dart';

void main() {
  testWidgets('public marketplace is visible without authentication', (
    tester,
  ) async {
    await tester.pumpWidget(
      CurlingCompanionApp(
        auth: LocalAuthService(),
        marketplace: MemoryMarketplaceRepository(),
        tournaments: MemoryTournamentRepository(),
        players: MemoryPlayerRepository(),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Marketplace'), findsOneWidget);
    expect(find.text('Tournaments'), findsOneWidget);
    expect(find.text('Find Players'), findsOneWidget);
  });

  testWidgets('logged out users do not see create listing action', (
    tester,
  ) async {
    await tester.pumpWidget(
      CurlingCompanionApp(
        auth: LocalAuthService(),
        marketplace: MemoryMarketplaceRepository(),
        tournaments: MemoryTournamentRepository(),
        players: MemoryPlayerRepository(),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Create listing'), findsNothing);
    expect(find.text('Log in'), findsOneWidget);
  });
}
