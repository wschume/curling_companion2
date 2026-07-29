import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:curling_companion/models/models.dart';
import 'package:curling_companion/services/services.dart';
import 'package:curling_companion/main.dart';

void main() {
  test(
    'local authentication provides an identity for tournament ownership',
    () async {
      final auth = LocalAuthService();
      final controller = AuthController(auth);
      await auth.signIn('owner@example.com', 'password');
      expect(controller.isSignedIn, isTrue);
      expect(controller.userId, 'owner@example.com');
      controller.dispose();
    },
  );

  test('marketplace repository reads and writes mapped documents', () async {
    final firestore = FakeFirebaseFirestore();
    final repository = FirestoreMarketplaceRepository(firestore);
    await firestore.collection('marketplaceListings').doc('listing-1').set({
      'id': 'listing-1',
      'title': 'Test broom',
      'description': 'A test item',
      'price': 20.0,
      'ownerId': 'user-1',
    });

    final listing = await repository.watchListings().first;
    expect(listing.single.title, 'Test broom');

    await repository.save(
      const MarketplaceListing(
        id: 'listing-2',
        title: 'Shoes',
        description: 'Test',
        price: 10,
        imageUrls: ['https://example.com/shoes.jpg', 'https://example.com/sole.jpg'],
        ownerId: 'user-2',
      ),
    );
    expect(
      (await firestore.collection('marketplaceListings').doc('listing-2').get())
          .exists,
      isTrue,
    );
    expect(
      (await firestore.collection('marketplaceListings').doc('listing-2').get())
          .data()?['imageUrls'],
      ['https://example.com/shoes.jpg', 'https://example.com/sole.jpg'],
    );
  });

  test(
    'tournament repository persists the full tournament details and deletes',
    () async {
      final firestore = FakeFirebaseFirestore();
      final repository = FirestoreTournamentRepository(firestore);
      final tournament = Tournament(
        id: 'tournament-1',
        name: 'Test Bonspiel',
        startDate: DateTime(2030, 1, 10),
        endDate: DateTime(2030, 1, 12),
        signupDeadline: DateTime(2029, 12, 20),
        club: 'Test Curling Club',
        city: 'Oslo',
        country: 'Norway',
        entryFee: 250,
        maxNumberOfTeams: 16,
        websiteUrl: 'https://example.com',
        contactInformation: 'test@example.com',
        organizerId: 'user-1',
      );

      await repository.save(tournament);
      final tournaments = await repository.watchTournaments().first;
      expect(tournaments.single.name, 'Test Bonspiel');
      expect(tournaments.single.maxNumberOfTeams, 16);
      expect(
        tournaments.single.signupDeadline!.toLocal(),
        DateTime(2029, 12, 20),
      );

      await repository.delete(tournament.id);
      expect((await repository.watchTournaments().first), isEmpty);
    },
  );
}
