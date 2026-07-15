import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:curling_companion/models/models.dart';
import 'package:curling_companion/services/services.dart';

void main() {
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
        ownerId: 'user-2',
      ),
    );
    expect(
      (await firestore.collection('marketplaceListings').doc('listing-2').get())
          .exists,
      isTrue,
    );
  });
}
