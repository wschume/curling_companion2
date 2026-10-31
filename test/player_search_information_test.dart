import 'package:curling_companion/models/models.dart';
import 'package:curling_companion/services/services.dart';
import 'package:curling_companion/services/demo/demo_services.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final legacy = {
    'id': 'search',
    'tournamentId': 'tournament',
    'role': 'any',
    'contact': 'player@example.com',
    'ownerId': 'owner',
  };

  test('older search documents default to empty additional information', () {
    expect(TeamPlayerSearchMapper.fromMap(legacy).additionalInformation, '');
    expect(PlayerTeamSearchMapper.fromMap(legacy).additionalInformation, '');
  });

  for (final firestore in [false, true]) {
    test(
      'both search types persist and clear information ($firestore)',
      () async {
        final PlayerRepository repository = firestore
            ? FirestorePlayerRepository(FakeFirebaseFirestore())
            : MemoryPlayerRepository();
        for (final information in [
          'Friday and Saturday only\nAccommodation booked',
          '',
        ]) {
          await repository.saveTeamSearch(
            TeamPlayerSearchMapper.fromMap({
              ...legacy,
              'additionalInformation': information,
            }),
          );
          await repository.savePlayerTeamSearch(
            PlayerTeamSearchMapper.fromMap({
              ...legacy,
              'additionalInformation': information,
            }),
          );
          expect(
            (await repository.watchTeamSearches().first)
                .single
                .additionalInformation,
            information,
          );
          expect(
            (await repository.watchPlayerTeamSearches().first)
                .single
                .additionalInformation,
            information,
          );
        }
      },
    );
  }
}
