// In-memory services used when Firebase is unavailable and by tests.
import 'dart:async';

import '../../models/models.dart';
import '../services.dart';
import '../tournament_matching.dart';

class LocalAuthService implements AuthService {
  String? _email;
  String? _pendingEmail;
  final _verifiedEmails = <String>{};
  final _termsAcceptedEmails = <String>{};
  final _controller = StreamController<String?>.broadcast();

  @override
  Stream<bool> watchAdminRole() => Stream.value(false);

  @override
  Stream<String?> get authStateChanges => _controller.stream;

  @override
  String? get currentEmail => _email;

  @override
  String? get currentUserId => _email;

  @override
  Future<void> sendPasswordResetEmail(
    String email,
    String languageCode,
  ) async {}

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
      city: 'Berlin',
      country: 'Germany',
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
      city: 'Berlin',
      country: 'Germany',
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
  Future<bool> hasDuplicate({
    required String city,
    required DateTime startDate,
  }) async => _items.any(
    (item) => matchesTournamentLocationAndDate(item, city, startDate),
  );

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

