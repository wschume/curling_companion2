// ignore_for_file: curly_braces_in_flow_control_structures, unnecessary_underscores, use_null_aware_elements

import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

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
                icon: Icons.emoji_events,
                route: '/tournaments',
                width: constraints.maxWidth > 900
                    ? (constraints.maxWidth - 40) / 3
                    : 360,
              ),
              _FeatureCard(
                title: l10n.players,
                description: l10n.playersIntro,
                icon: Icons.groups,
                route: '/players',
                width: constraints.maxWidth > 900
                    ? (constraints.maxWidth - 40) / 3
                    : 360,
              ),
              _FeatureCard(
                title: l10n.marketplace,
                description: l10n.marketplaceIntro,
                icon: Icons.storefront,
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
    required this.icon,
    required this.route,
    required this.width,
  });
  final String title;
  final String description;
  final IconData icon;
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
            Container(
              height: 180,
              width: double.infinity,
              color: Theme.of(context).colorScheme.secondaryContainer,
              child: Icon(
                icon,
                size: 76,
                color: Theme.of(context).colorScheme.onSecondaryContainer,
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
      if (mounted) context.go('/marketplace');
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

class TournamentsPage extends StatelessWidget {
  const TournamentsPage({super.key});
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final canEdit = context.watch<AuthController>().isSignedIn;
    return PageFrame(
      title: l10n.tournaments,
      intro: l10n.tournamentsIntro,
      action: canEdit ? _WriteButton(label: l10n.createTournament) : null,
      child: StreamBuilder<List<Tournament>>(
        stream: context.read<TournamentRepository>().watchTournaments(),
        builder: (_, snapshot) => _ListState<Tournament>(
          snapshot: snapshot,
          itemBuilder: (item) => Card(
            child: ListTile(
              title: Text(item.name),
              subtitle: Text(
                '${item.location} · ${item.date.toLocal().toString().split(' ').first}',
              ),
              trailing: TextButton(
                onPressed: () => context.go('/tournaments/${item.id}/players'),
                child: Text(l10n.players),
              ),
            ),
          ),
        ),
      ),
    );
  }
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
                '${tournament.location} · ${tournament.date.toLocal().toString().split(' ').first}',
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
