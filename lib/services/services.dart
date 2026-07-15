import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/models.dart';

abstract interface class AuthService {
  Stream<String?> get authStateChanges;
  String? get currentEmail;
  String? get currentUserId;
  Future<void> signIn(String email, String password);
  Future<void> register(String email, String password);
  Future<void> signOut();
}

class FirebaseAuthService implements AuthService {
  FirebaseAuthService(this._auth);
  final FirebaseAuth _auth;

  @override
  Stream<String?> get authStateChanges =>
      _auth.authStateChanges().map((user) => user?.email);

  @override
  String? get currentEmail => _auth.currentUser?.email;

  @override
  String? get currentUserId => _auth.currentUser?.uid;

  @override
  Future<void> signIn(String email, String password) =>
      _auth.signInWithEmailAndPassword(email: email, password: password);

  @override
  Future<void> register(String email, String password) =>
      _auth.createUserWithEmailAndPassword(email: email, password: password);

  @override
  Future<void> signOut() => _auth.signOut();
}

class LocalAuthService implements AuthService {
  String? _email;
  final _controller = StreamController<String?>.broadcast();

  @override
  Stream<String?> get authStateChanges => _controller.stream;

  @override
  String? get currentEmail => _email;

  @override
  String? get currentUserId => _email;

  @override
  Future<void> signIn(String email, String password) async {
    _email = email;
    _controller.add(_email);
  }

  @override
  Future<void> register(String email, String password) =>
      signIn(email, password);

  @override
  Future<void> signOut() async {
    _email = null;
    _controller.add(null);
  }
}

abstract interface class MarketplaceRepository {
  Stream<List<MarketplaceListing>> watchListings();
  Future<void> save(MarketplaceListing listing);
}

abstract interface class TournamentRepository {
  Stream<List<Tournament>> watchTournaments();
  Future<void> save(Tournament tournament);
  Future<void> delete(String tournamentId);
}

abstract interface class PlayerRepository {
  Stream<List<PlayerAvailability>> watchPlayers(String eventId);
  Future<void> save(PlayerAvailability player);
}

class FirestoreMarketplaceRepository implements MarketplaceRepository {
  FirestoreMarketplaceRepository(this._firestore);
  final FirebaseFirestore _firestore;

  @override
  Stream<List<MarketplaceListing>> watchListings() => _firestore
      .collection('marketplaceListings')
      .snapshots()
      .map(
        (snapshot) => snapshot.docs
            .map((doc) => MarketplaceListingMapper.fromMap(doc.data()))
            .toList(),
      );

  @override
  Future<void> save(MarketplaceListing listing) => _firestore
      .collection('marketplaceListings')
      .doc(listing.id)
      .set(listing.toMap());
}

class FirestoreTournamentRepository implements TournamentRepository {
  FirestoreTournamentRepository(this._firestore);
  final FirebaseFirestore _firestore;

  @override
  Stream<List<Tournament>> watchTournaments() => _firestore
      .collection('tournaments')
      .snapshots()
      .map(
        (snapshot) => snapshot.docs
            .map((doc) => TournamentMapper.fromMap(doc.data()))
            .toList(),
      );

  @override
  Future<void> save(Tournament tournament) => _firestore
      .collection('tournaments')
      .doc(tournament.id)
      .set(tournament.toMap());

  @override
  Future<void> delete(String tournamentId) =>
      _firestore.collection('tournaments').doc(tournamentId).delete();
}

class FirestorePlayerRepository implements PlayerRepository {
  FirestorePlayerRepository(this._firestore);
  final FirebaseFirestore _firestore;

  @override
  Stream<List<PlayerAvailability>> watchPlayers(String eventId) => _firestore
      .collection('playerAvailability')
      .where('eventId', isEqualTo: eventId)
      .snapshots()
      .map(
        (snapshot) => snapshot.docs
            .map((doc) => PlayerAvailabilityMapper.fromMap(doc.data()))
            .toList(),
      );

  @override
  Future<void> save(PlayerAvailability player) => _firestore
      .collection('playerAvailability')
      .doc(player.id)
      .set(player.toMap());
}

class MemoryMarketplaceRepository implements MarketplaceRepository {
  final _items = <MarketplaceListing>[
    const MarketplaceListing(
      id: '1',
      title: 'Junior curling shoes',
      description: 'Placeholder listing',
      price: 45,
      ownerId: 'demo',
    ),
    const MarketplaceListing(
      id: '2',
      title: 'Balanced curling broom',
      description: 'Placeholder listing',
      price: 80,
      ownerId: 'demo',
    ),
  ];
  @override
  Stream<List<MarketplaceListing>> watchListings() =>
      Stream.value(List.unmodifiable(_items));
  @override
  Future<void> save(MarketplaceListing listing) async => _items.add(listing);
}

class MemoryTournamentRepository implements TournamentRepository {
  final _items = <Tournament>[
    Tournament(
      id: 'event-1',
      name: 'Berlin Ice Cup',
      startDate: DateTime.now().add(const Duration(days: 30)),
      endDate: DateTime.now().add(const Duration(days: 32)),
      signupDeadline: DateTime.now().add(const Duration(days: 20)),
      club: 'Berlin Curling Club',
      city: 'Berlin',
      country: 'Germany',
      entryFee: 180,
      currency: 'EUR',
      maxNumberOfTeams: 32,
      websiteUrl: 'https://example.com/berlin-ice-cup',
      contactInformation: 'events@example.com',
      organizerId: 'demo',
    ),
    Tournament(
      id: 'event-2',
      name: 'Alpine Bonspiel',
      startDate: DateTime.now().subtract(const Duration(days: 52)),
      endDate: DateTime.now().subtract(const Duration(days: 50)),
      signupDeadline: DateTime.now().subtract(const Duration(days: 62)),
      club: 'Innsbruck Curling Club',
      city: 'Innsbruck',
      country: 'Austria',
      entryFee: 160,
      currency: 'EUR',
      maxNumberOfTeams: 24,
      websiteUrl: 'https://example.com/alpine-bonspiel',
      contactInformation: 'club@example.com',
      organizerId: 'demo',
    ),
  ];
  @override
  Stream<List<Tournament>> watchTournaments() =>
      Stream.value(List.unmodifiable(_items));
  @override
  Future<void> save(Tournament tournament) async {
    final index = _items.indexWhere((item) => item.id == tournament.id);
    if (index == -1) {
      _items.add(tournament);
    } else {
      _items[index] = tournament;
    }
  }

  @override
  Future<void> delete(String tournamentId) async {
    _items.removeWhere((item) => item.id == tournamentId);
  }
}

class MemoryPlayerRepository implements PlayerRepository {
  final _items = <PlayerAvailability>[
    const PlayerAvailability(
      id: 'player-1',
      eventId: 'event-1',
      userId: 'demo',
      displayName: 'Alex',
      note: 'Looking for a mixed team.',
    ),
    const PlayerAvailability(
      id: 'player-2',
      eventId: 'event-1',
      userId: 'demo-2',
      displayName: 'Sam',
      note: 'Available for any position.',
    ),
  ];
  @override
  Stream<List<PlayerAvailability>> watchPlayers(String eventId) =>
      Stream.value(_items.where((item) => item.eventId == eventId).toList());
  @override
  Future<void> save(PlayerAvailability player) async => _items.add(player);
}
