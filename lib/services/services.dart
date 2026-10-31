import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/models.dart';
import '../terms.dart';
import 'tournament_matching.dart';

abstract interface class AuthService {
  Stream<String?> get authStateChanges;
  Stream<bool> watchAdminRole();
  String? get currentEmail;
  String? get currentUserId;
  bool get isEmailVerified;
  Future<bool> loadTermsAcceptance();
  Future<void> acceptTerms(String languageCode);
  Future<void> sendEmailVerification(String languageCode);
  Future<void> refreshUser();
  Future<void> sendPasswordResetEmail(String email, String languageCode);
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
  Stream<bool> watchAdminRole() {
    final uid = currentUserId;
    if (uid == null) return Stream.value(false);
    return FirebaseFirestore.instance.collection('adminRoles').doc(uid)
        .snapshots().map((doc) => doc.data()?['role'] == 'admin');
  }

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
  Future<void> sendPasswordResetEmail(String email, String languageCode) async {
    await _auth.setLanguageCode(languageCode);
    await _auth.sendPasswordResetEmail(email: email);
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

abstract interface class MarketplaceRepository {
  Stream<List<MarketplaceListing>> watchListings();
  Future<void> save(MarketplaceListing listing);
  Future<void> delete(String listingId);
}

abstract interface class TournamentRepository {
  Stream<List<Tournament>> watchTournaments();
  Future<bool> hasDuplicate({required String city, required DateTime startDate});
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
  Future<bool> hasDuplicate({
    required String city,
    required DateTime startDate,
  }) async {
    final snapshot = await _firestore
        .collection('tournaments')
        .get(const GetOptions(source: Source.server));
    return snapshot.docs.any(
      (doc) => matchesTournamentLocationAndDate(
        TournamentMapper.fromMap(doc.data()),
        city,
        startDate,
      ),
    );
  }

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

