// ignore_for_file: curly_braces_in_flow_control_structures, unnecessary_underscores, use_null_aware_elements

import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import 'firebase_options.dart';
import 'l10n/app_localizations.dart';
import 'models/models.dart';
import 'services/services.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  AuthService auth;
  MarketplaceRepository marketplace;
  TournamentRepository tournaments;
  PlayerRepository players;
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    auth = FirebaseAuthService(FirebaseAuth.instance);
    marketplace = FirestoreMarketplaceRepository(FirebaseFirestore.instance);
    tournaments = FirestoreTournamentRepository(FirebaseFirestore.instance);
    players = FirestorePlayerRepository(FirebaseFirestore.instance);
  } catch (_) {
    auth = LocalAuthService();
    marketplace = MemoryMarketplaceRepository();
    tournaments = MemoryTournamentRepository();
    players = MemoryPlayerRepository();
  }
  runApp(
    CurlingCompanionApp(
      auth: auth,
      marketplace: marketplace,
      tournaments: tournaments,
      players: players,
    ),
  );
}

class AuthController extends ChangeNotifier {
  AuthController(this.service) {
    _email = service.currentEmail;
    _subscription = service.authStateChanges.listen((email) {
      _email = email;
      notifyListeners();
    });
  }
  final AuthService service;
  String? _email;
  late final StreamSubscription<String?> _subscription;
  String? get email => _email;
  bool get isSignedIn => _email != null;
  // The Firebase implementation uses the stable Firebase UID. The local
  // implementation uses the email as a stable placeholder identity.
  String? get userId => service.currentUserId ?? _email;

  Future<void> signIn(String email, String password) =>
      service.signIn(email, password);
  Future<void> register(String email, String password) =>
      service.register(email, password);
  Future<void> signOut() => service.signOut();

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}

class LocaleController extends ChangeNotifier {
  LocaleController() : _locale = _systemLocale();

  Locale _locale;
  Locale get locale => _locale;

  static Locale _systemLocale() {
    final languageCode =
        WidgetsBinding.instance.platformDispatcher.locale.languageCode;
    return languageCode == 'de' ? const Locale('de') : const Locale('en');
  }

  void select(Locale locale) {
    if (_locale == locale) return;
    _locale = locale;
    notifyListeners();
  }
}

class CurlingCompanionApp extends StatelessWidget {
  CurlingCompanionApp({
    super.key,
    required this.auth,
    required this.marketplace,
    required this.tournaments,
    required this.players,
  }) : _router = GoRouter(routes: _routes),
       super();

  final GoRouter _router;
  final AuthService auth;
  final MarketplaceRepository marketplace;
  final TournamentRepository tournaments;
  final PlayerRepository players;

  static final _routes = <RouteBase>[
    GoRoute(
      path: '/login',
      builder: (_, __) => const AuthPage(register: false),
    ),
    GoRoute(
      path: '/register',
      builder: (_, __) => const AuthPage(register: true),
    ),
    ShellRoute(
      builder: (_, __, child) => AppShell(child: child),
      routes: [
        GoRoute(path: '/', builder: (_, __) => const HomePage()),
        GoRoute(
          path: '/marketplace',
          builder: (_, __) => const MarketplacePage(),
        ),
        GoRoute(
          path: '/tournaments',
          builder: (_, __) => const TournamentsPage(),
        ),
        GoRoute(
          path: '/players',
          builder: (_, __) => const PlayersDirectoryPage(),
        ),
        GoRoute(
          path: '/tournaments/:id/players',
          builder: (_, state) =>
              PlayersPage(eventId: state.pathParameters['id']!),
        ),
      ],
    ),
  ];

  @override
  Widget build(BuildContext context) => MultiProvider(
    providers: [
      ChangeNotifierProvider(create: (_) => AuthController(auth)),
      ChangeNotifierProvider(create: (_) => LocaleController()),
      Provider.value(value: marketplace),
      Provider.value(value: tournaments),
      Provider.value(value: players),
    ],
    child: _AppView(router: _router),
  );
}

class _AppView extends StatelessWidget {
  const _AppView({required this.router});
  final GoRouter router;

  @override
  Widget build(BuildContext context) => MaterialApp.router(
    title: 'Curling Companion',
    routerConfig: router,
    locale: context.watch<LocaleController>().locale,
    theme: ThemeData(
      colorScheme: ColorScheme.fromSeed(seedColor: Colors.blueGrey),
      useMaterial3: true,
    ),
    supportedLocales: const [Locale('en'), Locale('de')],
    localizationsDelegates: const [
      AppLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
  );
}

class AppShell extends StatelessWidget {
  const AppShell({super.key, required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final auth = context.watch<AuthController>();
    return Scaffold(
      appBar: AppBar(
        title: InkWell(
          onTap: () => context.go('/'),
          child: Text(l10n.appTitle),
        ),
        actions: [
          _LanguageMenu(),
          if (auth.isSignedIn)
            PopupMenuButton<String>(
              tooltip: l10n.profile,
              icon: CircleAvatar(
                child: Text((auth.email ?? '?').substring(0, 1).toUpperCase()),
              ),
              onSelected: (value) {
                if (value == 'logout') context.read<AuthController>().signOut();
              },
              itemBuilder: (_) => [
                PopupMenuItem(enabled: false, child: Text(auth.email ?? '')),
                PopupMenuItem(
                  enabled: false,
                  value: 'settings',
                  child: Text(l10n.settingsComingSoon),
                ),
                PopupMenuItem(value: 'logout', child: Text(l10n.logout)),
              ],
            )
          else ...[
            TextButton(
              onPressed: () => context.go('/login'),
              child: Text(l10n.login),
            ),
            FilledButton(
              onPressed: () => context.go('/register'),
              child: Text(l10n.register),
            ),
          ],
        ],
      ),
      body: child,
    );
  }
}

class _LanguageMenu extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return PopupMenuButton<Locale>(
      tooltip: l10n.language,
      icon: const Icon(Icons.language),
      onSelected: context.read<LocaleController>().select,
      itemBuilder: (_) => [
        CheckedPopupMenuItem(
          value: const Locale('en'),
          checked: context.read<LocaleController>().locale.languageCode == 'en',
          child: const Text('English'),
        ),
        CheckedPopupMenuItem(
          value: const Locale('de'),
          checked: context.read<LocaleController>().locale.languageCode == 'de',
          child: const Text('Deutsch'),
        ),
      ],
    );
  }
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Text(l10n.welcome, style: Theme.of(context).textTheme.headlineMedium),
        const SizedBox(height: 8),
        Text(l10n.publicIntro),
        const SizedBox(height: 28),
        LayoutBuilder(
          builder: (context, constraints) => Wrap(
            spacing: 20,
            runSpacing: 20,
            children: [
              _FeatureCard(
                title: l10n.tournaments,
                description: l10n.tournamentsIntro,
                imageAsset: 'assets/tournaments.png',
                route: '/tournaments',
                width: constraints.maxWidth > 900
                    ? (constraints.maxWidth - 40) / 3
                    : 360,
              ),
              _FeatureCard(
                title: l10n.players,
                description: l10n.playersIntro,
                imageAsset: 'assets/player_search.png',
                route: '/players',
                width: constraints.maxWidth > 900
                    ? (constraints.maxWidth - 40) / 3
                    : 360,
              ),
              _FeatureCard(
                title: l10n.marketplace,
                description: l10n.marketplaceIntro,
                imageAsset: 'assets/marketplace.png',
                route: '/marketplace',
                width: constraints.maxWidth > 900
                    ? (constraints.maxWidth - 40) / 3
                    : 360,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _FeatureCard extends StatelessWidget {
  const _FeatureCard({
    required this.title,
    required this.description,
    required this.imageAsset,
    required this.route,
    required this.width,
  });
  final String title;
  final String description;
  final String imageAsset;
  final String route;
  final double width;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: width,
    child: Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => context.go(route),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: 180,
              width: double.infinity,
              child: ColoredBox(
                color: Theme.of(context).colorScheme.secondaryContainer,
                child: Image.asset(imageAsset, fit: BoxFit.contain),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 6),
                  Text(description),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class AuthPage extends StatefulWidget {
  const AuthPage({super.key, required this.register});
  final bool register;
  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  bool _busy = false;
  String? _error;
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Card(
            margin: const EdgeInsets.all(24),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      l10n.appTitle,
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    TextButton(
                      onPressed: () => context.go('/'),
                      child: Text(l10n.home),
                    ),
                    const SizedBox(height: 8),
                    Text(widget.register ? l10n.register : l10n.login),
                    const SizedBox(height: 24),
                    TextFormField(
                      controller: _email,
                      decoration: InputDecoration(labelText: l10n.email),
                      validator: (value) =>
                          value == null || !value.contains('@')
                          ? l10n.invalidEmail
                          : null,
                    ),
                    TextFormField(
                      controller: _password,
                      obscureText: true,
                      decoration: InputDecoration(labelText: l10n.password),
                      validator: (value) => value == null || value.length < 6
                          ? l10n.passwordTooShort
                          : null,
                    ),
                    if (widget.register)
                      TextFormField(
                        controller: _confirm,
                        obscureText: true,
                        decoration: InputDecoration(
                          labelText: l10n.confirmPassword,
                        ),
                        validator: (value) => value != _password.text
                            ? l10n.passwordMismatch
                            : null,
                      ),
                    if (_error != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 12),
                        child: Text(
                          _error!,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.error,
                          ),
                        ),
                      ),
                    const SizedBox(height: 20),
                    FilledButton(
                      onPressed: _busy ? null : _submit,
                      child: Text(widget.register ? l10n.register : l10n.login),
                    ),
                    TextButton(
                      onPressed: () =>
                          context.go(widget.register ? '/login' : '/register'),
                      child: Text(widget.register ? l10n.login : l10n.register),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final auth = context.read<AuthController>();
      if (widget.register)
        await auth.register(_email.text.trim(), _password.text);
      else
        await auth.signIn(_email.text.trim(), _password.text);
      if (mounted) context.go('/');
    } on FirebaseAuthException catch (error) {
      if (mounted) {
        setState(
          () => _error = AppLocalizations.of(context).authErrorCode(error.code),
        );
      }
    } on FirebaseException catch (error) {
      if (mounted) {
        setState(
          () => _error = AppLocalizations.of(
            context,
          ).authErrorCode('${error.plugin}:${error.code}'),
        );
      }
    } catch (_) {
      if (mounted) {
        setState(() => _error = AppLocalizations.of(context).authError);
      }
    }
    if (mounted) setState(() => _busy = false);
  }
}

class MarketplacePage extends StatelessWidget {
  const MarketplacePage({super.key});
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final canEdit = context.watch<AuthController>().isSignedIn;
    return PageFrame(
      title: l10n.marketplace,
      intro: l10n.marketplaceIntro,
      action: canEdit ? _WriteButton(label: l10n.createListing) : null,
      child: StreamBuilder<List<MarketplaceListing>>(
        stream: context.read<MarketplaceRepository>().watchListings(),
        builder: (_, snapshot) => _ListState<MarketplaceListing>(
          snapshot: snapshot,
          itemBuilder: (item) => Card(
            child: ListTile(
              leading: const Icon(Icons.sports_hockey),
              title: Text(item.title),
              subtitle: Text(item.description),
              trailing: Text('${item.price.toStringAsFixed(0)} €'),
            ),
          ),
        ),
      ),
    );
  }
}

class TournamentsPage extends StatefulWidget {
  const TournamentsPage({super.key});

  @override
  State<TournamentsPage> createState() => _TournamentsPageState();
}

class _TournamentsPageState extends State<TournamentsPage> {
  final _nameController = TextEditingController();
  final _locationController = TextEditingController();
  DateTime? _filterStartDate;
  DateTime? _filterEndDate;
  String _sortField = 'startDate';
  bool _sortAscending = true;
  bool _showPastTournaments = false;
  bool _showMyTournaments = false;

  @override
  void dispose() {
    _nameController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final canEdit = context.watch<AuthController>().isSignedIn;
    return PageFrame(
      title: l10n.tournaments,
      intro: l10n.tournamentsIntro,
      action: canEdit
          ? FilledButton.icon(
              onPressed: _createTournament,
              icon: const Icon(Icons.add),
              label: Text(l10n.createTournament),
            )
          : null,
      child: StreamBuilder<List<Tournament>>(
        stream: context.read<TournamentRepository>().watchTournaments(),
        builder: (_, snapshot) => _buildContent(context, snapshot),
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    AsyncSnapshot<List<Tournament>> snapshot,
  ) {
    final l10n = AppLocalizations.of(context);
    if (snapshot.hasError) return const Text('Unable to load tournaments.');
    if (!snapshot.hasData) {
      return const Center(child: CircularProgressIndicator());
    }

    final now = DateTime.now();
    final auth = context.read<AuthController>();
    final all = _filtered(
      snapshot.data!,
      organizerId: _showMyTournaments ? auth.userId : null,
    );
    final future = all.where((item) => !item.endDate.isBefore(now)).toList();
    final past = all.where((item) => item.endDate.isBefore(now)).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _TournamentFilters(
          nameController: _nameController,
          locationController: _locationController,
          filterStartDate: _filterStartDate,
          filterEndDate: _filterEndDate,
          onNameChanged: (_) => setState(() {}),
          onLocationChanged: (_) => setState(() {}),
          onStartDateChanged: (date) => setState(() => _filterStartDate = date),
          onEndDateChanged: (date) => setState(() => _filterEndDate = date),
          onClear: () {
            _nameController.clear();
            _locationController.clear();
            setState(() {
              _filterStartDate = null;
              _filterEndDate = null;
            });
          },
        ),
        if (auth.isSignedIn) ...[
          const SizedBox(height: 12),
          FilterChip(
            selected: _showMyTournaments,
            avatar: const Icon(Icons.person_outline),
            label: Text(
              _showMyTournaments ? l10n.allTournaments : l10n.myTournaments,
            ),
            onSelected: (selected) =>
                setState(() => _showMyTournaments = selected),
          ),
        ],
        const SizedBox(height: 24),
        Text(
          l10n.futureTournaments,
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 8),
        _TournamentTable(
          tournaments: future,
          emptyText: l10n.noFutureTournaments,
          sortField: _sortField,
          sortAscending: _sortAscending,
          onSort: _sort,
          canEdit: context.read<AuthController>().isSignedIn,
          onEdit: _editTournament,
          onDelete: _deleteTournament,
        ),
        const SizedBox(height: 24),
        TextButton.icon(
          onPressed: () =>
              setState(() => _showPastTournaments = !_showPastTournaments),
          icon: Icon(
            _showPastTournaments ? Icons.expand_less : Icons.expand_more,
          ),
          label: Text(
            _showPastTournaments
                ? l10n.hidePastTournaments
                : l10n.showPastTournaments,
          ),
        ),
        if (_showPastTournaments) ...[
          const SizedBox(height: 12),
          Text(
            l10n.pastTournaments,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          _TournamentTable(
            tournaments: past,
            emptyText: l10n.noPastTournaments,
            sortField: _sortField,
            sortAscending: _sortAscending,
            onSort: _sort,
            canEdit: context.read<AuthController>().isSignedIn,
            onEdit: _editTournament,
          ),
        ],
      ],
    );
  }

  List<Tournament> _filtered(List<Tournament> source, {String? organizerId}) {
    final name = _nameController.text.trim().toLowerCase();
    final location = _locationController.text.trim().toLowerCase();
    final result = source.where((tournament) {
      final matchesName =
          name.isEmpty || tournament.name.toLowerCase().contains(name);
      final searchableLocation =
          '${tournament.club ?? ''} ${tournament.city} ${tournament.country ?? ''}'
              .toLowerCase();
      final matchesLocation =
          location.isEmpty || searchableLocation.contains(location);
      final matchesStart =
          _filterStartDate == null ||
          !tournament.startDate.isBefore(_filterStartDate!);
      final matchesEnd =
          _filterEndDate == null ||
          !tournament.endDate.isAfter(_filterEndDate!);
      final matchesOrganizer =
          organizerId == null || tournament.organizerId == organizerId;
      return matchesName &&
          matchesLocation &&
          matchesStart &&
          matchesEnd &&
          matchesOrganizer;
    }).toList();
    result.sort((a, b) {
      final left = _sortValue(a);
      final right = _sortValue(b);
      final comparison = left.compareTo(right);
      return _sortAscending ? comparison : -comparison;
    });
    return result;
  }

  String _sortValue(Tournament tournament) => switch (_sortField) {
    'endDate' => tournament.endDate.toIso8601String(),
    'signupDeadline' => tournament.signupDeadline?.toIso8601String() ?? '',
    'name' => tournament.name.toLowerCase(),
    _ => tournament.startDate.toIso8601String(),
  };

  void _sort(String field) {
    setState(() {
      if (_sortField == field) {
        _sortAscending = !_sortAscending;
      } else {
        _sortField = field;
        _sortAscending = true;
      }
    });
  }

  Future<void> _createTournament() async {
    final auth = context.read<AuthController>();
    final userId = auth.userId;
    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context).loginToEdit)),
      );
      return;
    }
    final tournament = await showDialog<Tournament>(
      context: context,
      builder: (_) => _TournamentFormDialog(
        title: AppLocalizations.of(context).createTournament,
        organizerId: userId,
      ),
    );
    if (tournament != null && mounted) {
      try {
        await context.read<TournamentRepository>().save(tournament);
        if (mounted)
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(AppLocalizations.of(context).tournamentSaved),
            ),
          );
      } catch (error) {
        if (mounted)
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Unable to save tournament: $error')),
          );
      }
    }
  }

  Future<void> _editTournament(Tournament tournament) async {
    final auth = context.read<AuthController>();
    if (auth.userId != tournament.organizerId) return;
    final edited = await showDialog<Tournament>(
      context: context,
      builder: (_) => _TournamentFormDialog(
        title: AppLocalizations.of(context).editTournament,
        initial: tournament,
        organizerId: tournament.organizerId,
      ),
    );
    if (edited != null && mounted) {
      await context.read<TournamentRepository>().save(edited);
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context).tournamentSaved)),
        );
    }
  }

  Future<void> _deleteTournament(Tournament tournament) async {
    final auth = context.read<AuthController>();
    if (auth.userId != tournament.organizerId ||
        tournament.endDate.isBefore(DateTime.now()))
      return;
    final l10n = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(l10n.confirmDeleteTournament),
        content: Text(l10n.confirmDeleteTournamentMessage),
        actions: [
          TextButton(
            onPressed: () => context.pop(false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => context.pop(true),
            child: Text(l10n.deleteTournament),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      await context.read<TournamentRepository>().delete(tournament.id);
      if (mounted)
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l10n.tournamentDeleted)));
    }
  }
}

class _TournamentFilters extends StatelessWidget {
  const _TournamentFilters({
    required this.nameController,
    required this.locationController,
    required this.filterStartDate,
    required this.filterEndDate,
    required this.onNameChanged,
    required this.onLocationChanged,
    required this.onStartDateChanged,
    required this.onEndDateChanged,
    required this.onClear,
  });

  final TextEditingController nameController;
  final TextEditingController locationController;
  final DateTime? filterStartDate;
  final DateTime? filterEndDate;
  final ValueChanged<String> onNameChanged;
  final ValueChanged<String> onLocationChanged;
  final ValueChanged<DateTime?> onStartDateChanged;
  final ValueChanged<DateTime?> onEndDateChanged;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Wrap(
          spacing: 16,
          runSpacing: 12,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            SizedBox(
              width: 220,
              child: TextField(
                controller: nameController,
                onChanged: onNameChanged,
                decoration: InputDecoration(
                  labelText: l10n.filterByName,
                  prefixIcon: const Icon(Icons.search),
                ),
              ),
            ),
            SizedBox(
              width: 220,
              child: TextField(
                controller: locationController,
                onChanged: onLocationChanged,
                decoration: InputDecoration(
                  labelText: l10n.filterByLocation,
                  prefixIcon: const Icon(Icons.location_on_outlined),
                ),
              ),
            ),
            _FilterDateButton(
              label: l10n.filterStartDate,
              value: filterStartDate,
              onChanged: onStartDateChanged,
            ),
            _FilterDateButton(
              label: l10n.filterEndDate,
              value: filterEndDate,
              onChanged: onEndDateChanged,
            ),
            TextButton.icon(
              onPressed: onClear,
              icon: const Icon(Icons.clear),
              label: Text(l10n.clearFilters),
            ),
          ],
        ),
      ),
    );
  }
}

class _FilterDateButton extends StatelessWidget {
  const _FilterDateButton({
    required this.label,
    required this.value,
    required this.onChanged,
  });
  final String label;
  final DateTime? value;
  final ValueChanged<DateTime?> onChanged;

  @override
  Widget build(BuildContext context) => OutlinedButton.icon(
    onPressed: () async {
      final selected = await showDatePicker(
        context: context,
        firstDate: DateTime(2000),
        lastDate: DateTime(2100),
        initialDate: value ?? DateTime.now(),
      );
      if (selected != null) onChanged(selected);
    },
    icon: const Icon(Icons.calendar_today_outlined),
    label: Text(
      value == null ? label : '$label: ${_formatDate(context, value!)}',
    ),
  );
}

class _TournamentTable extends StatefulWidget {
  const _TournamentTable({
    required this.tournaments,
    required this.emptyText,
    required this.sortField,
    required this.sortAscending,
    required this.onSort,
    required this.canEdit,
    required this.onEdit,
    this.onDelete,
  });

  final List<Tournament> tournaments;
  final String emptyText;
  final String sortField;
  final bool sortAscending;
  final ValueChanged<String> onSort;
  final bool canEdit;
  final ValueChanged<Tournament> onEdit;
  final ValueChanged<Tournament>? onDelete;

  @override
  State<_TournamentTable> createState() => _TournamentTableState();
}

class _TournamentTableState extends State<_TournamentTable> {
  final _horizontalController = ScrollController();

  @override
  void dispose() {
    _horizontalController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.tournaments.isEmpty) return Text(widget.emptyText);
    final l10n = AppLocalizations.of(context);
    final auth = context.read<AuthController>();
    final sortIndex = {
      'name': 0,
      'startDate': 1,
      'endDate': 2,
      'signupDeadline': 3,
    }[widget.sortField];
    return Scrollbar(
      controller: _horizontalController,
      thumbVisibility: true,
      trackVisibility: true,
      interactive: true,
      notificationPredicate: (notification) =>
          notification.metrics.axis == Axis.horizontal,
      child: SingleChildScrollView(
        controller: _horizontalController,
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.only(bottom: 12),
        child: DataTable(
          sortColumnIndex: sortIndex,
          sortAscending: widget.sortAscending,
          columns: [
            DataColumn(
              label: Text(l10n.name),
              onSort: (_, __) => widget.onSort('name'),
            ),
            DataColumn(
              label: Text(l10n.startDate),
              onSort: (_, __) => widget.onSort('startDate'),
            ),
            DataColumn(
              label: Text(l10n.endDate),
              onSort: (_, __) => widget.onSort('endDate'),
            ),
            DataColumn(
              label: Text(l10n.signupDeadline),
              onSort: (_, __) => widget.onSort('signupDeadline'),
            ),
            DataColumn(label: Text(l10n.club)),
            DataColumn(label: Text('${l10n.city}/${l10n.country}')),
            DataColumn(label: Text(l10n.entryFee)),
            DataColumn(label: Text(l10n.maxTeams)),
            DataColumn(label: Text(l10n.website)),
            DataColumn(label: Text(l10n.contact)),
            const DataColumn(label: Text('')),
          ],
          rows: widget.tournaments.map((tournament) {
            final isOwner =
                widget.canEdit && auth.userId == tournament.organizerId;
            return DataRow(
              cells: [
                DataCell(Text(tournament.name)),
                DataCell(Text(_formatDate(context, tournament.startDate))),
                DataCell(Text(_formatDate(context, tournament.endDate))),
                DataCell(
                  Text(
                    tournament.signupDeadline == null
                        ? '-'
                        : _formatDate(context, tournament.signupDeadline!),
                  ),
                ),
                DataCell(Text(tournament.club ?? '-')),
                DataCell(
                  Text(
                    '${tournament.city}${tournament.country == null ? '' : ', ${tournament.country}'}',
                  ),
                ),
                DataCell(
                  Text(
                    tournament.entryFee == null
                        ? '-'
                        : '${tournament.entryFee!.toStringAsFixed(2)} ${tournament.currency ?? ''}',
                  ),
                ),
                DataCell(Text(tournament.maxNumberOfTeams?.toString() ?? '-')),
                DataCell(
                  tournament.websiteUrl == null ||
                          tournament.websiteUrl!.isEmpty
                      ? const Text('-')
                      : TextButton(
                          onPressed: () =>
                              launchUrl(Uri.parse(tournament.websiteUrl!)),
                          child: Text(l10n.website),
                        ),
                ),
                DataCell(SelectableText(tournament.contactInformation ?? '-')),
                DataCell(
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (isOwner)
                        IconButton(
                          tooltip: l10n.editTournament,
                          onPressed: () => widget.onEdit(tournament),
                          icon: const Icon(Icons.edit_outlined),
                        ),
                      if (isOwner && widget.onDelete != null)
                        IconButton(
                          tooltip: l10n.deleteTournament,
                          onPressed: () => widget.onDelete!(tournament),
                          icon: const Icon(Icons.delete_outline),
                        ),
                      IconButton(
                        tooltip: l10n.players,
                        onPressed: () =>
                            context.go('/tournaments/${tournament.id}/players'),
                        icon: const Icon(Icons.groups_outlined),
                      ),
                    ],
                  ),
                ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }
}

String _formatDate(BuildContext context, DateTime date) => DateFormat(
  'dd-MMM-yyyy',
  Localizations.localeOf(context).languageCode,
).format(date.toLocal());

class _TournamentFormDialog extends StatefulWidget {
  const _TournamentFormDialog({
    required this.title,
    required this.organizerId,
    this.initial,
  });
  final String title;
  final String organizerId;
  final Tournament? initial;

  @override
  State<_TournamentFormDialog> createState() => _TournamentFormDialogState();
}

class _TournamentFormDialogState extends State<_TournamentFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _club;
  late final TextEditingController _city;
  late final TextEditingController _country;
  late final TextEditingController _fee;
  late final TextEditingController _maxTeams;
  late final TextEditingController _website;
  late final TextEditingController _contact;
  late DateTime _startDate;
  late DateTime _endDate;
  DateTime? _signupDeadline;
  String _currency = 'EUR';
  String? _dateError;

  @override
  void initState() {
    super.initState();
    final tournament = widget.initial;
    _name = TextEditingController(text: tournament?.name);
    _club = TextEditingController(text: tournament?.club);
    _city = TextEditingController(text: tournament?.city);
    _country = TextEditingController(text: tournament?.country);
    _fee = TextEditingController(text: tournament?.entryFee?.toString() ?? '');
    _maxTeams = TextEditingController(
      text: tournament?.maxNumberOfTeams?.toString() ?? '',
    );
    _website = TextEditingController(text: tournament?.websiteUrl);
    _contact = TextEditingController(text: tournament?.contactInformation);
    _startDate =
        tournament?.startDate ?? DateTime.now().add(const Duration(days: 30));
    _endDate = tournament?.endDate ?? _startDate.add(const Duration(days: 2));
    _signupDeadline = tournament?.signupDeadline;
    _currency = tournament?.currency ?? 'EUR';
  }

  @override
  void dispose() {
    for (final controller in [
      _name,
      _club,
      _city,
      _country,
      _fee,
      _maxTeams,
      _website,
      _contact,
    ])
      controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AlertDialog(
      title: Text(widget.title),
      content: SizedBox(
        width: 720,
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                _requiredField(_name, l10n.name),
                _requiredField(_city, l10n.location),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _country,
                        decoration: InputDecoration(labelText: l10n.country),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _club,
                        decoration: InputDecoration(labelText: l10n.club),
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    Expanded(child: _numberField(_fee, l10n.entryFee)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _numberField(
                        _maxTeams,
                        l10n.maxTeams,
                        integer: true,
                      ),
                    ),
                  ],
                ),
                DropdownButtonFormField<String>(
                  initialValue: _currency,
                  decoration: InputDecoration(labelText: l10n.currency),
                  items: const [
                    DropdownMenuItem(value: 'EUR', child: Text('EUR (€)')),
                    DropdownMenuItem(value: 'USD', child: Text('USD (\$)')),
                    DropdownMenuItem(value: 'GBP', child: Text('GBP (£)')),
                    DropdownMenuItem(value: 'CHF', child: Text('CHF')),
                    DropdownMenuItem(value: 'NOK', child: Text('NOK')),
                  ],
                  onChanged: (value) =>
                      setState(() => _currency = value ?? 'EUR'),
                ),
                TextFormField(
                  controller: _contact,
                  decoration: InputDecoration(
                    labelText: l10n.contact,
                    hintText: l10n.contactHint,
                  ),
                  validator: _contactValidator,
                ),
                TextFormField(
                  controller: _website,
                  decoration: InputDecoration(labelText: l10n.website),
                  validator: (value) {
                    if (value == null || value.isEmpty) return null;
                    final uri = Uri.tryParse(value);
                    return uri == null ||
                            !(uri.scheme == 'http' || uri.scheme == 'https')
                        ? l10n.invalidWebsite
                        : null;
                  },
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    _FormDateButton(
                      label: l10n.startDate,
                      value: _startDate,
                      onChanged: (value) => setState(() => _startDate = value!),
                      referenceDate: _endDate,
                      initialDate: _dateInRelatedMonth(
                        _endDate.subtract(const Duration(days: 1)),
                      ),
                    ),
                    _FormDateButton(
                      label: l10n.endDate,
                      value: _endDate,
                      onChanged: (value) => setState(() => _endDate = value!),
                      referenceDate: _startDate,
                      initialDate: _dateInRelatedMonth(
                        _startDate.add(const Duration(days: 1)),
                      ),
                    ),
                    _FormDateButton(
                      label: l10n.signupDeadline,
                      value: _signupDeadline,
                      onChanged: (value) =>
                          setState(() => _signupDeadline = value),
                      canClear: true,
                      referenceDate: _startDate,
                      initialDate: _dateInRelatedMonth(
                        _startDate.subtract(const Duration(days: 1)),
                      ),
                    ),
                  ],
                ),
                if (_dateError != null)
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        _dateError!,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => context.pop(), child: Text(l10n.cancel)),
        FilledButton(onPressed: _save, child: Text(l10n.saveTournament)),
      ],
    );
  }

  Widget _requiredField(TextEditingController controller, String label) =>
      TextFormField(
        controller: controller,
        decoration: InputDecoration(labelText: label),
        validator: (value) => value == null || value.trim().isEmpty
            ? AppLocalizations.of(context).requiredField
            : null,
      );

  Widget _numberField(
    TextEditingController controller,
    String label, {
    bool integer = false,
  }) => TextFormField(
    controller: controller,
    keyboardType: const TextInputType.numberWithOptions(decimal: true),
    decoration: InputDecoration(labelText: label),
    validator: (value) {
      final parsed = integer
          ? int.tryParse(value ?? '')
          : double.tryParse(value ?? '');
      if ((value ?? '').trim().isEmpty) return null;
      return parsed == null || parsed < 0
          ? AppLocalizations.of(context).invalidNumber
          : null;
    },
  );

  String? _contactValidator(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    final text = value.trim();
    final email = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(text);
    final phoneDigits = text.replaceAll(RegExp(r'[^0-9]'), '');
    return email || phoneDigits.length >= 7
        ? null
        : AppLocalizations.of(context).invalidContact;
  }

  Future<void> _save() async {
    final dateError = validateTournamentDateOrder(
      signupDeadline: _signupDeadline,
      startDate: _startDate,
      endDate: _endDate,
    );
    if (dateError != null) {
      final l10n = AppLocalizations.of(context);
      final message = dateError == 'durationTooLong'
          ? l10n.durationTooLong
          : l10n.invalidDateOrder;
      setState(() => _dateError = message);
      if (mounted) {
        await showDialog<void>(
          context: context,
          builder: (_) => AlertDialog(
            title: Text(l10n.invalidDateOrder),
            content: Text(message),
            actions: [
              TextButton(
                onPressed: () => context.pop(),
                child: Text(l10n.cancel),
              ),
            ],
          ),
        );
      }
      return;
    }
    setState(() => _dateError = null);
    if (!_formKey.currentState!.validate()) return;
    final fee = _fee.text.trim().isEmpty ? null : double.parse(_fee.text);
    final maxTeams = _maxTeams.text.trim().isEmpty
        ? null
        : int.parse(_maxTeams.text);
    final tournament = Tournament(
      id:
          widget.initial?.id ??
          DateTime.now().microsecondsSinceEpoch.toString(),
      name: _name.text.trim(),
      startDate: _startDate,
      endDate: _endDate,
      signupDeadline: _signupDeadline,
      club: _club.text.trim().isEmpty ? null : _club.text.trim(),
      city: _city.text.trim(),
      country: _country.text.trim().isEmpty ? null : _country.text.trim(),
      entryFee: fee,
      currency: fee == null ? null : _currency,
      maxNumberOfTeams: maxTeams,
      websiteUrl: _website.text.trim().isEmpty ? null : _website.text.trim(),
      contactInformation: _contact.text.trim().isEmpty
          ? null
          : _contact.text.trim(),
      organizerId: widget.organizerId,
    );
    if (mounted) context.pop(tournament);
  }
}

String? validateTournamentDateOrder({
  DateTime? signupDeadline,
  required DateTime? startDate,
  required DateTime? endDate,
}) {
  if (startDate == null || endDate == null) return 'required';
  if (!startDate.isBefore(endDate)) return 'startBeforeEnd';
  if (endDate.difference(startDate).inDays > 5) return 'durationTooLong';
  if (signupDeadline != null && !signupDeadline.isBefore(startDate))
    return 'signupBeforeStart';
  return null;
}

class _FormDateButton extends StatelessWidget {
  const _FormDateButton({
    required this.label,
    required this.value,
    required this.onChanged,
    this.canClear = false,
    this.referenceDate,
    this.initialDate,
  });
  final String label;
  final DateTime? value;
  final ValueChanged<DateTime?> onChanged;
  final bool canClear;
  final DateTime? referenceDate;
  final DateTime? initialDate;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      OutlinedButton.icon(
        onPressed: () async {
          final date = await showDatePicker(
            context: context,
            firstDate: DateTime(2000),
            lastDate: DateTime(2100),
            initialDate: initialDate ?? value ?? DateTime.now(),
            currentDate: referenceDate,
          );
          if (date != null) onChanged(date);
        },
        icon: const Icon(Icons.calendar_today_outlined),
        label: Text(
          value == null
              ? '$label (optional)'
              : '$label: ${_formatDate(context, value!)}',
        ),
      ),
      if (canClear && value != null)
        IconButton(
          tooltip: AppLocalizations.of(context).clearFilters,
          onPressed: () => onChanged(null),
          icon: const Icon(Icons.clear),
        ),
    ],
  );
}

DateTime _dateInRelatedMonth(DateTime preferred) {
  final daysInMonth = DateUtils.getDaysInMonth(preferred.year, preferred.month);
  final preferredDate = DateTime(
    preferred.year,
    preferred.month,
    preferred.day.clamp(1, daysInMonth),
  );
  return preferredDate;
}

class PlayersPage extends StatelessWidget {
  const PlayersPage({super.key, required this.eventId});
  final String eventId;
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return PageFrame(
      title: l10n.players,
      intro: l10n.playersIntro,
      action: _WriteButton(label: l10n.joinEvent),
      child: StreamBuilder<List<PlayerAvailability>>(
        stream: context.read<PlayerRepository>().watchPlayers(eventId),
        builder: (_, snapshot) => _ListState<PlayerAvailability>(
          snapshot: snapshot,
          itemBuilder: (item) => Card(
            child: ListTile(
              leading: const CircleAvatar(child: Icon(Icons.person)),
              title: Text(item.displayName),
              subtitle: Text(item.note),
            ),
          ),
        ),
      ),
    );
  }
}

class PlayersDirectoryPage extends StatelessWidget {
  const PlayersDirectoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return PageFrame(
      title: l10n.players,
      intro: l10n.playersIntro,
      child: StreamBuilder<List<Tournament>>(
        stream: context.read<TournamentRepository>().watchTournaments(),
        builder: (_, snapshot) => _ListState<Tournament>(
          snapshot: snapshot,
          itemBuilder: (tournament) => Card(
            child: ListTile(
              leading: const Icon(Icons.groups),
              title: Text(tournament.name),
              subtitle: Text(
                '${tournament.city}, ${tournament.country} · ${tournament.startDate.toLocal().toString().split(' ').first}',
              ),
              trailing: FilledButton.tonal(
                onPressed: () =>
                    context.go('/tournaments/${tournament.id}/players'),
                child: Text(l10n.players),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _WriteButton extends StatelessWidget {
  const _WriteButton({required this.label});
  final String label;
  @override
  Widget build(BuildContext context) => FilledButton(
    onPressed: () {
      if (!context.read<AuthController>().isSignedIn) {
        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: Text(AppLocalizations.of(context).loginToEdit),
            content: Text(AppLocalizations.of(context).loginToEditMessage),
            actions: [
              TextButton(
                onPressed: () => context.pop(),
                child: Text(AppLocalizations.of(context).cancel),
              ),
              FilledButton(
                onPressed: () {
                  context.pop();
                  context.go('/login');
                },
                child: Text(AppLocalizations.of(context).login),
              ),
            ],
          ),
        );
      }
    },
    child: Text(label),
  );
}

class PageFrame extends StatelessWidget {
  const PageFrame({
    super.key,
    required this.title,
    required this.intro,
    required this.child,
    this.action,
  });
  final String title, intro;
  final Widget child;
  final Widget? action;
  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.all(24),
    children: [
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: Theme.of(context).textTheme.headlineMedium),
                Text(intro),
              ],
            ),
          ),
          if (action != null) action!,
        ],
      ),
      const SizedBox(height: 20),
      child,
    ],
  );
}

class _ListState<T> extends StatelessWidget {
  const _ListState({required this.snapshot, required this.itemBuilder});
  final AsyncSnapshot<List<T>> snapshot;
  final Widget Function(T) itemBuilder;
  @override
  Widget build(BuildContext context) {
    if (snapshot.hasError) return Text('Unable to load data.');
    if (!snapshot.hasData)
      return const Center(child: CircularProgressIndicator());
    if (snapshot.data!.isEmpty)
      return Text(AppLocalizations.of(context).noItems);
    return Column(children: snapshot.data!.map(itemBuilder).toList());
  }
}
