import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/models.dart';
import '../terms.dart';

abstract interface class AuthService {
  Stream<String?> get authStateChanges;
  String? get currentEmail;
  String? get currentUserId;
  bool get isEmailVerified;
  Future<bool> loadTermsAcceptance();
  Future<void> acceptTerms(String languageCode);
  Future<void> sendEmailVerification(String languageCode);
  Future<void> refreshUser();
  Future<void> signIn(String email, String password);
  Future<void> register(String email, String password);
  Future<void> updateEmail(String email);
  Future<void> updatePassword(String password);
  Future<void> updateTelephone(String telephone);
  Future<void> deleteAccount();
  Future<String?> loadLanguage();
  Future<String?> loadTelephone();
  Future<void> updateLanguage(String languageCode);
  Future<void> signOut();
}

class FirebaseAuthService implements AuthService {
  FirebaseAuthService(this._auth);
  final FirebaseAuth _auth;

  @override
  Stream<String?> get authStateChanges =>
      _auth.userChanges().map((user) => user?.email);

  @override
  String? get currentEmail => _auth.currentUser?.email;

  @override
  String? get currentUserId => _auth.currentUser?.uid;

  @override
  bool get isEmailVerified => _auth.currentUser?.emailVerified ?? false;

  DocumentReference<Map<String, dynamic>> get _termsRecord => FirebaseFirestore.instance
      .collection('users').doc(_auth.currentUser!.uid)
      .collection('termsAcceptances').doc(currentTermsVersion);

  @override
  Future<bool> loadTermsAcceptance() async {
    if (_auth.currentUser == null) return false;
    final data = (await _termsRecord.get()).data();
    return data?['accepted'] == true && data?['version'] == currentTermsVersion;
  }

  @override
  Future<void> acceptTerms(String languageCode) async {
    final record = _termsRecord;
    await FirebaseFirestore.instance.runTransaction((transaction) async {
      if ((await transaction.get(record)).exists) return;
      transaction.set(record, {
        'version': currentTermsVersion,
        'accepted': true,
        'acceptedAt': FieldValue.serverTimestamp(),
        'language': languageCode,
      });
    });
  }

  @override
  Future<void> sendEmailVerification(String languageCode) async {
    await _auth.setLanguageCode(languageCode);
    const returnUrl = String.fromEnvironment('EMAIL_VERIFICATION_RETURN_URL');
    await _auth.currentUser!.sendEmailVerification(
      returnUrl.isEmpty ? null : ActionCodeSettings(url: returnUrl),
    );
  }

  @override
  Future<void> refreshUser() async {
    final user = _auth.currentUser;
    if (user == null) return;
    await user.reload();
    await _auth.currentUser?.getIdToken(true);
  }

  @override
  Future<void> signIn(String email, String password) =>
      _auth.signInWithEmailAndPassword(email: email, password: password);

  @override
  Future<void> register(String email, String password) =>
      _auth.createUserWithEmailAndPassword(email: email, password: password);

  @override
  Future<void> updateEmail(String email) => _auth.currentUser!.verifyBeforeUpdateEmail(email);

  @override
  Future<void> updatePassword(String password) =>
      _auth.currentUser!.updatePassword(password);

  @override
  Future<void> updateTelephone(String telephone) => FirebaseFirestore.instance
      .collection('users').doc(_auth.currentUser!.uid).set(
        {'telephone': telephone}, SetOptions(merge: true));

  @override
  Future<void> deleteAccount() => _auth.currentUser!.delete();

  @override
  Future<String?> loadLanguage() async => (await FirebaseFirestore.instance
      .collection('users').doc(_auth.currentUser!.uid).get()).data()?['language'] as String?;

  @override
  Future<void> updateLanguage(String languageCode) => FirebaseFirestore.instance
      .collection('users').doc(_auth.currentUser!.uid).set(
        {'language': languageCode}, SetOptions(merge: true));

  @override
  Future<String?> loadTelephone() async => (await FirebaseFirestore.instance
      .collection('users').doc(_auth.currentUser!.uid).get()).data()?['telephone'] as String?;

  @override
  Future<void> signOut() => _auth.signOut();
}

class LocalAuthService implements AuthService {
  String? _email;
  String? _pendingEmail;
  final _verifiedEmails = <String>{};
  final _termsAcceptedEmails = <String>{};
  final _controller = StreamController<String?>.broadcast();

  @override
  Stream<String?> get authStateChanges => _controller.stream;

  @override
  String? get currentEmail => _email;

  @override
  String? get currentUserId => _email;

  @override
  Future<void> signIn(String email, String password) async {
    if (_email != email) _pendingEmail = null;
    _email = email;
    _controller.add(_email);
  }

  @override
  Future<void> register(String email, String password) =>
      signIn(email, password);

  @override
  Future<void> updateEmail(String email) async {
    _pendingEmail = email;
  }

  @override
  bool get isEmailVerified => _verifiedEmails.contains(_email);

  @override
  Future<bool> loadTermsAcceptance() async => _termsAcceptedEmails.contains(_email);

  @override
  Future<void> acceptTerms(String languageCode) async {
    if (_email == null) throw StateError('Sign in before accepting terms.');
    _termsAcceptedEmails.add(_email!);
  }

  @override
  Future<void> sendEmailVerification(String languageCode) async {}

  @override
  Future<void> refreshUser() async {
    _controller.add(_email);
  }

  /// Simulates clicking a verification link when running without Firebase.
  void simulateEmailVerification() {
    if (_email == null) return;
    final acceptedTerms = _termsAcceptedEmails.contains(_email);
    _email = _pendingEmail ?? _email;
    if (acceptedTerms) _termsAcceptedEmails.add(_email!);
    _pendingEmail = null;
    _verifiedEmails.add(_email!);
    _controller.add(_email);
  }

  @override
  Future<void> updatePassword(String password) async {}

  @override
  Future<void> updateTelephone(String telephone) async {}

  @override
  Future<void> deleteAccount() => signOut();

  @override
  Future<String?> loadLanguage() async => null;

  @override
  Future<void> updateLanguage(String languageCode) async {}
  @override
  Future<String?> loadTelephone() async => null;

  @override
  Future<void> signOut() async {
    _email = null;
    _pendingEmail = null;
    _controller.add(null);
  }
}

abstract interface class MarketplaceRepository {
  Stream<List<MarketplaceListing>> watchListings();
  Future<void> save(MarketplaceListing listing);
  Future<void> delete(String listingId);
}

abstract interface class TournamentRepository {
  Stream<List<Tournament>> watchTournaments();
  Future<void> save(Tournament tournament);
  Future<void> delete(String tournamentId);
}

abstract interface class PlayerRepository {
  Stream<List<PlayerAvailability>> watchPlayers(String eventId);
  Future<void> save(PlayerAvailability player);
  Stream<List<TeamPlayerSearch>> watchTeamSearches();
  Future<void> saveTeamSearch(TeamPlayerSearch search);
  Future<void> deleteTeamSearch(String searchId);
  Stream<List<PlayerTeamSearch>> watchPlayerTeamSearches();
  Future<void> savePlayerTeamSearch(PlayerTeamSearch search);
  Future<void> deletePlayerTeamSearch(String searchId);
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

  @override
  Future<void> delete(String listingId) =>
      _firestore.collection('marketplaceListings').doc(listingId).delete();
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

  @override
  Stream<List<TeamPlayerSearch>> watchTeamSearches() => _firestore
      .collection('teamPlayerSearches')
      .snapshots()
      .map(
        (snapshot) => snapshot.docs
            .map((doc) => TeamPlayerSearchMapper.fromMap(doc.data()))
            .toList(),
      );

  @override
  Future<void> saveTeamSearch(TeamPlayerSearch search) => _firestore
      .collection('teamPlayerSearches')
      .doc(search.id)
      .set(search.toMap());

  @override
  Future<void> deleteTeamSearch(String searchId) =>
      _firestore.collection('teamPlayerSearches').doc(searchId).delete();

  @override
  Stream<List<PlayerTeamSearch>> watchPlayerTeamSearches() => _firestore
      .collection('playerTeamSearches')
      .snapshots()
      .map((snapshot) => snapshot.docs
          .map((doc) => PlayerTeamSearchMapper.fromMap(doc.data()))
          .toList());

  @override
  Future<void> savePlayerTeamSearch(PlayerTeamSearch search) => _firestore
      .collection('playerTeamSearches')
      .doc(search.id)
      .set(search.toMap());

  @override
  Future<void> deletePlayerTeamSearch(String searchId) =>
      _firestore.collection('playerTeamSearches').doc(searchId).delete();
}

class MemoryMarketplaceRepository implements MarketplaceRepository {
  final _changes = StreamController<List<MarketplaceListing>>.broadcast();
  final _items = <MarketplaceListing>[
    MarketplaceListing(
      id: '1',
      title: 'Junior curling shoes',
      description: 'Placeholder listing',
      price: 45,
      currency: 'EUR',
      category: 'shoes',
      location: 'Berlin',
      sellerName: 'demo@example.com',
      sellerContact: 'demo@example.com',
      listedAt: _demoDate,
      ownerId: 'demo',
    ),
    MarketplaceListing(
      id: '2',
      title: 'Balanced curling broom',
      description: 'Placeholder listing',
      price: 80,
      currency: 'EUR',
      category: 'brooms',
      location: 'Berlin',
      sellerName: 'demo@example.com',
      sellerContact: 'demo@example.com',
      listedAt: _demoDate,
      ownerId: 'demo',
    ),
  ];
  @override
  Stream<List<MarketplaceListing>> watchListings() async* {
    yield List.unmodifiable(_items);
    yield* _changes.stream;
  }

  @override
  Future<void> save(MarketplaceListing listing) async {
    final index = _items.indexWhere((item) => item.id == listing.id);
    if (index == -1) {
      _items.add(listing);
    } else {
      _items[index] = listing;
    }
    _changes.add(List.unmodifiable(_items));
  }

  @override
  Future<void> delete(String listingId) async {
    _items.removeWhere((item) => item.id == listingId);
    _changes.add(List.unmodifiable(_items));
  }
}

final _demoDate = DateTime(2025, 1, 1);

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
  final _teamSearchChanges =
      StreamController<List<TeamPlayerSearch>>.broadcast();
  final _teamSearches = <TeamPlayerSearch>[];
  final _playerTeamSearchChanges =
      StreamController<List<PlayerTeamSearch>>.broadcast();
  final _playerTeamSearches = <PlayerTeamSearch>[];
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

  @override
  Stream<List<TeamPlayerSearch>> watchTeamSearches() async* {
    yield List.unmodifiable(_teamSearches);
    yield* _teamSearchChanges.stream;
  }

  @override
  Future<void> saveTeamSearch(TeamPlayerSearch search) async {
    final index = _teamSearches.indexWhere((item) => item.id == search.id);
    if (index == -1) {
      _teamSearches.add(search);
    } else {
      _teamSearches[index] = search;
    }
    _teamSearchChanges.add(List.unmodifiable(_teamSearches));
  }

  @override
  Future<void> deleteTeamSearch(String searchId) async {
    _teamSearches.removeWhere((item) => item.id == searchId);
    _teamSearchChanges.add(List.unmodifiable(_teamSearches));
  }

  @override
  Stream<List<PlayerTeamSearch>> watchPlayerTeamSearches() async* {
    yield List.unmodifiable(_playerTeamSearches);
    yield* _playerTeamSearchChanges.stream;
  }

  @override
  Future<void> savePlayerTeamSearch(PlayerTeamSearch search) async {
    final index = _playerTeamSearches.indexWhere((item) => item.id == search.id);
    if (index == -1) {
      _playerTeamSearches.add(search);
    } else {
      _playerTeamSearches[index] = search;
    }
    _playerTeamSearchChanges.add(List.unmodifiable(_playerTeamSearches));
  }

  @override
  Future<void> deletePlayerTeamSearch(String searchId) async {
    _playerTeamSearches.removeWhere((item) => item.id == searchId);
    _playerTeamSearchChanges.add(List.unmodifiable(_playerTeamSearches));
  }
}
