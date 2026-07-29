// ignore_for_file: curly_braces_in_flow_control_structures, unnecessary_underscores, use_null_aware_elements

import 'dart:async';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:file_picker/file_picker.dart';
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
    _subscription = service.authStateChanges.listen((email) async {
      if (_disposed) return;
      _email = email;
      if (email != null) _language = await service.loadLanguage();
      if (_disposed) return;
      notifyListeners();
    });
  }
  final AuthService service;
  String? _email;
  String? _language;
  String? _telephone;
  bool _disposed = false;
  late final StreamSubscription<String?> _subscription;
  String? get email => _email;
  String? get language => _language;
  String? get telephone => _telephone;
  bool get isSignedIn => _email != null;
  // The Firebase implementation uses the stable Firebase UID. The local
  // implementation uses the email as a stable placeholder identity.
  String? get userId => service.currentUserId ?? _email;

  Future<void> signIn(String email, String password) =>
      service.signIn(email, password);
  Future<void> register(String email, String password) =>
      service.register(email, password);
  Future<void> signOut() => service.signOut();
  Future<void> updateEmail(String value) async {
    await service.updateEmail(value);
    _email = value;
    notifyListeners();
  }

  Future<void> updatePassword(String value) => service.updatePassword(value);
  Future<void> updateTelephone(String value) async {
    await service.updateTelephone(value);
    _telephone = value;
    notifyListeners();
  }

  Future<void> updateLanguage(String value) async {
    await service.updateLanguage(value);
    _language = value;
    notifyListeners();
  }

  Future<void> deleteAccount() => service.deleteAccount();

  @override
  void dispose() {
    _disposed = true;
    _subscription.cancel();
    super.dispose();
  }
}

class LocaleController extends ChangeNotifier {
  LocaleController() : _locale = _systemLocale();

  Locale _locale;
  Locale get locale => _locale;
  Locale get systemLocale => _systemLocale();

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
      pageBuilder: (_, state) => NoTransitionPage<void>(
        key: state.pageKey,
        child: const AuthPage(register: false),
      ),
    ),
    GoRoute(
      path: '/register',
      pageBuilder: (_, state) => NoTransitionPage<void>(
        key: state.pageKey,
        child: const AuthPage(register: true),
      ),
    ),
    ShellRoute(
      pageBuilder: (_, state, child) => NoTransitionPage<void>(
        key: state.pageKey,
        child: AppShell(child: child),
      ),
      routes: [
        GoRoute(
          path: '/',
          pageBuilder: (_, state) => NoTransitionPage<void>(
            key: state.pageKey,
            child: const HomePage(),
          ),
        ),
        GoRoute(
          path: '/marketplace',
          pageBuilder: (_, state) => NoTransitionPage<void>(
            key: state.pageKey,
            child: const MarketplacePage(),
          ),
        ),
        GoRoute(
          path: '/tournaments',
          pageBuilder: (_, state) => NoTransitionPage<void>(
            key: state.pageKey,
            child: TournamentsPage(
              initialTournamentId: state.extra as String?,
            ),
          ),
        ),
        GoRoute(
          path: '/players',
          pageBuilder: (_, state) => NoTransitionPage<void>(
            key: state.pageKey,
            child: PlayersDirectoryPage(
              initialTournamentId: state.extra as String?,
            ),
          ),
        ),
        GoRoute(
          path: '/tournaments/:id/players',
          pageBuilder: (_, state) => NoTransitionPage<void>(
            key: state.pageKey,
            child: PlayersPage(eventId: state.pathParameters['id']!),
          ),
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
    locale: (() {
      final userLanguage = context.watch<AuthController>().language;
      return userLanguage == null ? const Locale('en') : Locale(userLanguage);
    })(),
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
                if (value == 'settings') _showSettings(context);
                if (value == 'logout') context.read<AuthController>().signOut();
              },
              itemBuilder: (_) => [
                PopupMenuItem(enabled: false, child: Text(auth.email ?? '')),
                PopupMenuItem(
                  value: 'settings',
                  child: Text(
                    auth.language == 'de' ? 'Einstellungen' : 'Settings',
                  ),
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

Future<void> _showSettings(BuildContext context) async {
  final auth = context.read<AuthController>();
  final language = await showDialog<String>(
    context: context,
    builder: (_) => _ProfileSettingsDialog(
      email: auth.email ?? '',
      telephone: auth.telephone ?? '',
      language: auth.language ?? Localizations.localeOf(context).languageCode,
    ),
  );
  if (language != null && context.mounted) {
    await auth.updateLanguage(language);
    context.read<LocaleController>().select(Locale(language));
  }
}

class _ProfileSettingsDialog extends StatefulWidget {
  const _ProfileSettingsDialog({
    required this.email,
    required this.telephone,
    required this.language,
  });
  final String email;
  final String telephone;
  final String language;
  @override
  State<_ProfileSettingsDialog> createState() => _ProfileSettingsDialogState();
}

class _ProfileSettingsDialogState extends State<_ProfileSettingsDialog> {
  late final email = TextEditingController(text: widget.email);
  final password = TextEditingController(), confirm = TextEditingController();
  late final telephone = TextEditingController(text: widget.telephone);
  late String language = widget.language;
  bool busy = false;
  String? error;
  @override
  void dispose() {
    email.dispose();
    password.dispose();
    confirm.dispose();
    telephone.dispose();
    super.dispose();
  }

  Future<void> save() async {
    if (password.text.isNotEmpty && password.text != confirm.text) {
      setState(() => error = AppLocalizations.of(context).passwordsDoNotMatch);
      return;
    }
    setState(() => busy = true);
    final auth = context.read<AuthController>();
    try {
      if (email.text.trim() != widget.email)
        await auth.updateEmail(email.text.trim());
      if (password.text.isNotEmpty) await auth.updatePassword(password.text);
      if (telephone.text.trim().isNotEmpty)
        await auth.updateTelephone(telephone.text.trim());
      if (mounted) Navigator.pop(context, language);
    } catch (_) {
      if (mounted)
        setState(
          () => error = AppLocalizations.of(context).settingsUpdateError,
        );
    }
    if (mounted) setState(() => busy = false);
  }

  Future<void> deleteAccount() async {
    final id = context.read<AuthController>().userId;
    if (id == null) return;
    final tournaments = await context
        .read<TournamentRepository>()
        .watchTournaments()
        .first;
    final listings = await context
        .read<MarketplaceRepository>()
        .watchListings()
        .first;
    final tournamentCount = tournaments
        .where((t) => t.organizerId == id)
        .length;
    final listingCount = listings.where((l) => l.ownerId == id).length;
    if (tournamentCount > 0 || listingCount > 0) {
      if (mounted)
        setState(
          () => error = AppLocalizations.of(context).accountDeleteBlocked,
        );
      return;
    }
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(AppLocalizations.of(context).confirmDeleteAccount),
        content: const Text('This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(AppLocalizations.of(context).cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() => busy = true);
    try {
      await context.read<AuthController>().deleteAccount();
      if (mounted) Navigator.pop(context);
    } catch (_) {
      if (mounted)
        setState(
          () => error = AppLocalizations.of(context).accountDeletedError,
        );
    }
    if (mounted) setState(() => busy = false);
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text(AppLocalizations.of(context).profileSettings),
    content: SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (error != null)
            Text(
              error!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          TextField(
            controller: email,
            decoration: InputDecoration(
              labelText: AppLocalizations.of(context).email,
            ),
          ),
          TextField(
            controller: password,
            obscureText: true,
            decoration: InputDecoration(
              labelText: AppLocalizations.of(context).newPassword,
            ),
          ),
          TextField(
            controller: confirm,
            obscureText: true,
            decoration: InputDecoration(
              labelText: AppLocalizations.of(context).confirmPassword,
            ),
          ),
          TextField(
            controller: telephone,
            keyboardType: TextInputType.phone,
            decoration: InputDecoration(
              labelText: AppLocalizations.of(context).telephone,
            ),
          ),
          DropdownButtonFormField<String>(
            value: language,
            decoration: InputDecoration(
              labelText: AppLocalizations.of(context).language,
            ),
            items: [
              DropdownMenuItem(
                value: 'en',
                child: Text(AppLocalizations.of(context).english),
              ),
              DropdownMenuItem(
                value: 'de',
                child: Text(AppLocalizations.of(context).german),
              ),
            ],
            onChanged: busy ? null : (v) => setState(() => language = v!),
          ),
        ],
      ),
    ),
    actions: [
      TextButton(
        onPressed: busy ? null : deleteAccount,
        child: Text(AppLocalizations.of(context).deleteAccount),
      ),
      TextButton(
        onPressed: busy ? null : () => Navigator.pop(context),
        child: Text(AppLocalizations.of(context).cancel),
      ),
      FilledButton(
        onPressed: busy ? null : save,
        child: Text(AppLocalizations.of(context).submit),
      ),
    ],
  );
}

class _LanguageMenu extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final auth = context.watch<AuthController>();
    final selectedLanguage =
        auth.language ?? Localizations.localeOf(context).languageCode;
    return PopupMenuButton<Locale>(
      tooltip: l10n.language,
      icon: const Icon(Icons.language),
      onSelected: (locale) async {
        context.read<LocaleController>().select(locale);
        if (auth.isSignedIn) await auth.updateLanguage(locale.languageCode);
      },
      itemBuilder: (_) => [
        CheckedPopupMenuItem(
          value: const Locale('en'),
          checked: selectedLanguage == 'en',
          child: const Text('English'),
        ),
        CheckedPopupMenuItem(
          value: const Locale('de'),
          checked: selectedLanguage == 'de',
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
                      textInputAction: widget.register
                          ? TextInputAction.next
                          : TextInputAction.done,
                      onFieldSubmitted: (_) {
                        if (!widget.register && !_busy) _submit();
                      },
                      decoration: InputDecoration(labelText: l10n.password),
                      validator: (value) => value == null || value.length < 6
                          ? l10n.passwordTooShort
                          : null,
                    ),
                    if (widget.register)
                      TextFormField(
                        controller: _confirm,
                        obscureText: true,
                        textInputAction: TextInputAction.done,
                        onFieldSubmitted: (_) {
                          if (!_busy) _submit();
                        },
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
    if (_busy) return;
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

class MarketplacePage extends StatefulWidget {
  const MarketplacePage({super.key});

  @override
  State<MarketplacePage> createState() => _MarketplacePageState();
}

class _MarketplacePageState extends State<MarketplacePage> {
  String _category = 'all';

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final canEdit = context.watch<AuthController>().isSignedIn;
    return PageFrame(
      title: l10n.marketplace,
      intro: l10n.marketplaceIntro,
      action: canEdit
          ? FilledButton.icon(
              onPressed: () => _createListing(context),
              icon: const Icon(Icons.add),
              label: Text(l10n.createListing),
            )
          : null,
      child: StreamBuilder<List<MarketplaceListing>>(
        stream: context.read<MarketplaceRepository>().watchListings(),
        builder: (_, snapshot) {
          final listings = _filtered(snapshot.data ?? const []);
          return Column(
            children: [
              _MarketplaceFilters(
                category: _category,
                onCategoryChanged: (value) => setState(() => _category = value),
              ),
              _listingFeed(snapshot, listings),
            ],
          );
        },
      ),
    );
  }

  List<MarketplaceListing> _filtered(List<MarketplaceListing> items) => items
      .where((item) => _category == 'all' || item.category == _category)
      .toList();

  Widget _listingFeed(
    AsyncSnapshot<List<MarketplaceListing>> snapshot,
    List<MarketplaceListing> listings,
  ) {
    if (snapshot.hasError) return const Text('Unable to load data.');
    if (!snapshot.hasData) {
      return const Center(child: CircularProgressIndicator());
    }
    if (listings.isEmpty) return Text(AppLocalizations.of(context).noItems);

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: listings.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (_, index) => _MarketplaceListingFeedCard(
        listing: listings[index],
        isOwner: context.read<AuthController>().userId == listings[index].ownerId,
        onDetails: () => _showDetails(listings[index]),
        onEdit: () => _editListing(listings[index]),
        onDelete: () => _deleteListing(listings[index]),
      ),
    );
  }

  Future<void> _showDetails(MarketplaceListing listing) => showDialog<void>(
    context: context,
    builder: (_) => _MarketplaceListingDetailsDialog(listing: listing),
  );

  Future<void> _createListing(BuildContext context) async {
    final auth = context.read<AuthController>();
    final userId = auth.userId;
    final email = auth.email;
    if (userId == null || email == null) return;
    final listing = await showDialog<MarketplaceListing>(
      context: context,
      builder: (_) => _MarketplaceListingDialog(ownerId: userId, email: email),
    );
    if (listing == null || !context.mounted) return;
    await context.read<MarketplaceRepository>().save(listing);
  }

  Future<void> _editListing(MarketplaceListing listing) async {
    final edited = await showDialog<MarketplaceListing>(
      context: context,
      builder: (_) => _MarketplaceListingDialog(
        ownerId: listing.ownerId,
        email: listing.sellerContact,
        initial: listing,
      ),
    );
    if (edited == null || !mounted) return;
    await context.read<MarketplaceRepository>().save(edited);
  }

  Future<void> _deleteListing(MarketplaceListing listing) async {
    if (context.read<AuthController>().userId != listing.ownerId) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete listing?'),
        content: const Text('This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => context.pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => context.pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      await context.read<MarketplaceRepository>().delete(listing.id);
    }
  }
}

class _MarketplaceListingFeedCard extends StatelessWidget {
  const _MarketplaceListingFeedCard({
    required this.listing,
    required this.isOwner,
    required this.onDetails,
    required this.onEdit,
    required this.onDelete,
  });

  final MarketplaceListing listing;
  final bool isOwner;
  final VoidCallback onDetails;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) => Card(
    clipBehavior: Clip.antiAlias,
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final image = SizedBox(
            width: constraints.maxWidth >= 700 ? 220 : double.infinity,
            height: 170,
            child: _MarketplaceImagePreview(listing: listing),
          );
          final content = _ListingFeedContent(
            listing: listing,
            isOwner: isOwner,
            onDetails: onDetails,
            onEdit: onEdit,
            onDelete: onDelete,
          );
          if (constraints.maxWidth < 700) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [image, const SizedBox(height: 16), content],
            );
          }
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [image, const SizedBox(width: 20), Expanded(child: content)],
          );
        },
      ),
    ),
  );
}

class _ListingFeedContent extends StatelessWidget {
  const _ListingFeedContent({
    required this.listing,
    required this.isOwner,
    required this.onDetails,
    required this.onEdit,
    required this.onDelete,
  });

  final MarketplaceListing listing;
  final bool isOwner;
  final VoidCallback onDetails;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        children: [
          Chip(label: Text(listing.category)),
          const Spacer(),
          Text(
            '${listing.price.toStringAsFixed(2)} ${listing.currency}',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
      Text(listing.title, style: Theme.of(context).textTheme.titleLarge),
      const SizedBox(height: 6),
      Text(listing.description, maxLines: 4, overflow: TextOverflow.ellipsis),
      const SizedBox(height: 12),
      Wrap(
        spacing: 12,
        runSpacing: 6,
        children: [
          if (listing.location.isNotEmpty)
            _ListingMeta(icon: Icons.location_on_outlined, text: listing.location),
          if (listing.listedAt != null)
            _ListingMeta(
              icon: Icons.calendar_today_outlined,
              text: DateFormat.yMMMd().format(listing.listedAt!),
            ),
          if (listing.sellerName.isNotEmpty)
            _ListingMeta(icon: Icons.person_outline, text: listing.sellerName),
        ],
      ),
      const SizedBox(height: 16),
      Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          FilledButton.tonalIcon(
            onPressed: onDetails,
            icon: const Icon(Icons.open_in_new),
            label: const Text('View details'),
          ),
          _MarketplaceContactButton(contact: listing.sellerContact),
          if (isOwner) ...[
            IconButton(
              tooltip: 'Edit listing',
              onPressed: onEdit,
              icon: const Icon(Icons.edit_outlined),
            ),
            IconButton(
              tooltip: 'Delete listing',
              onPressed: onDelete,
              icon: const Icon(Icons.delete_outline),
            ),
          ],
        ],
      ),
    ],
  );
}

class _ListingMeta extends StatelessWidget {
  const _ListingMeta({required this.icon, required this.text});
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [Icon(icon, size: 16), const SizedBox(width: 4), Text(text)],
  );
}

class _MarketplaceImagePreview extends StatelessWidget {
  const _MarketplaceImagePreview({required this.listing});
  final MarketplaceListing listing;

  @override
  Widget build(BuildContext context) => Stack(
    fit: StackFit.expand,
    children: [
      _MarketplaceImage(url: listing.imageUrls.firstOrNull, category: listing.category),
      if (listing.imageUrls.length > 1)
        Positioned(
          right: 8,
          bottom: 8,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: Colors.black87,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Text(
                '1 / ${listing.imageUrls.length}',
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ),
        ),
    ],
  );
}

class _MarketplaceImage extends StatelessWidget {
  const _MarketplaceImage({required this.url, required this.category});
  final String? url;
  final String category;

  @override
  Widget build(BuildContext context) {
    final imageUrl = url;
    if (imageUrl == null || imageUrl.isEmpty) {
      return ColoredBox(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        child: Center(
          child: Icon(_categoryIcon(category), size: 52, color: Theme.of(context).colorScheme.primary),
        ),
      );
    }
    return Image.network(
      imageUrl,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => ColoredBox(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        child: const Center(child: Icon(Icons.broken_image_outlined, size: 44)),
      ),
    );
  }
}

IconData _categoryIcon(String category) => switch (category) {
  'shoes' => Icons.ice_skating_outlined,
  'brooms' => Icons.cleaning_services_outlined,
  'stones' => Icons.sports_baseball_outlined,
  _ => Icons.inventory_2_outlined,
};

class _MarketplaceContactButton extends StatelessWidget {
  const _MarketplaceContactButton({required this.contact});
  final String contact;

  @override
  Widget build(BuildContext context) {
    final isEmail = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(contact);
    if (contact.trim().isEmpty) return const SizedBox.shrink();
    return OutlinedButton.icon(
      onPressed: () => launchUrl(
        Uri(scheme: isEmail ? 'mailto' : 'tel', path: contact.trim()),
      ),
      icon: Icon(isEmail ? Icons.email_outlined : Icons.phone_outlined),
      label: Text(isEmail ? 'Email seller' : 'Call seller'),
    );
  }
}

class _MarketplaceListingDetailsDialog extends StatelessWidget {
  const _MarketplaceListingDetailsDialog({required this.listing});
  final MarketplaceListing listing;

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text(listing.title),
    content: SizedBox(
      width: 760,
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 360, child: _MarketplaceImageGallery(listing: listing)),
            const SizedBox(height: 20),
            Text(
              '${listing.price.toStringAsFixed(2)} ${listing.currency}',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 12),
            Text(listing.description),
            const SizedBox(height: 20),
            if (listing.location.isNotEmpty) Text('Location: ${listing.location}'),
            if (listing.sellerName.isNotEmpty) Text('Seller: ${listing.sellerName}'),
          ],
        ),
      ),
    ),
    actions: [
      _MarketplaceContactButton(contact: listing.sellerContact),
      TextButton(onPressed: () => context.pop(), child: const Text('Close')),
    ],
  );
}

class _MarketplaceImageGallery extends StatefulWidget {
  const _MarketplaceImageGallery({required this.listing});
  final MarketplaceListing listing;

  @override
  State<_MarketplaceImageGallery> createState() => _MarketplaceImageGalleryState();
}

class _MarketplaceImageGalleryState extends State<_MarketplaceImageGallery> {
  var _selectedImage = 0;

  @override
  Widget build(BuildContext context) {
    final images = widget.listing.imageUrls;
    if (images.isEmpty) {
      return _MarketplaceImage(url: null, category: widget.listing.category);
    }
    return Column(
      children: [
        Expanded(
          child: _MarketplaceImage(
            url: images[_selectedImage],
            category: widget.listing.category,
          ),
        ),
        if (images.length > 1) ...[
          const SizedBox(height: 8),
          SizedBox(
            height: 64,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: images.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (_, index) => InkWell(
                onTap: () => setState(() => _selectedImage = index),
                child: SizedBox(
                  width: 80,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: index == _selectedImage
                            ? Theme.of(context).colorScheme.primary
                            : Colors.transparent,
                        width: 2,
                      ),
                    ),
                    child: _MarketplaceImage(
                      url: images[index],
                      category: widget.listing.category,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _MarketplaceFilters extends StatelessWidget {
  const _MarketplaceFilters({
    required this.category,
    required this.onCategoryChanged,
  });
  final String category;
  final ValueChanged<String> onCategoryChanged;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Wrap(
      spacing: 12,
      runSpacing: 8,
      children: [
        SizedBox(
          width: 180,
          child: DropdownButtonFormField<String>(
            initialValue: category,
            decoration: const InputDecoration(labelText: 'Category'),
            items: const [
              DropdownMenuItem(value: 'all', child: Text('All categories')),
              DropdownMenuItem(value: 'shoes', child: Text('Shoes')),
              DropdownMenuItem(value: 'stones', child: Text('Stones')),
              DropdownMenuItem(value: 'brooms', child: Text('Brooms')),
              DropdownMenuItem(value: 'other', child: Text('Other')),
            ],
            onChanged: (value) => onCategoryChanged(value!),
          ),
        ),
      ],
    ),
  );
}

class _MarketplaceListingDialog extends StatefulWidget {
  const _MarketplaceListingDialog({
    required this.ownerId,
    required this.email,
    this.initial,
  });
  final String ownerId;
  final String email;
  final MarketplaceListing? initial;

  @override
  State<_MarketplaceListingDialog> createState() =>
      _MarketplaceListingDialogState();
}

class _MarketplaceListingDialogState extends State<_MarketplaceListingDialog> {
  final _formKey = GlobalKey<FormState>();
  late final _title = TextEditingController(text: widget.initial?.title);
  late final _description = TextEditingController(
    text: widget.initial?.description,
  );
  late final _price = TextEditingController(
    text: widget.initial?.price.toString(),
  );
  late final _currency = TextEditingController(
    text: widget.initial?.currency ?? 'EUR',
  );
  late final _location = TextEditingController(text: widget.initial?.location);
  late final _contact = TextEditingController(
    text: widget.initial?.sellerContact ?? widget.email,
  );
  late final _imageUrls = List<String>.of(widget.initial?.imageUrls ?? const []);
  final _newImages = <PlatformFile>[];
  final _removedImageUrls = <String>[];
  late String _category = widget.initial?.category ?? 'other';
  bool _isUploading = false;
  String? _uploadError;

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    _price.dispose();
    _currency.dispose();
    _location.dispose();
    _contact.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text(widget.initial == null ? 'Create listing' : 'Edit listing'),
    content: SizedBox(
      width: 460,
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _title,
                decoration: const InputDecoration(labelText: 'Title'),
                validator: _required,
              ),
              TextFormField(
                controller: _description,
                decoration: const InputDecoration(labelText: 'Description'),
                maxLines: 3,
                validator: _required,
              ),
              DropdownButtonFormField<String>(
                initialValue: _category,
                decoration: const InputDecoration(labelText: 'Category'),
                items: const ['shoes', 'stones', 'brooms', 'other']
                    .map(
                      (category) => DropdownMenuItem(
                        value: category,
                        child: Text(category),
                      ),
                    )
                    .toList(),
                onChanged: (category) => setState(() => _category = category!),
              ),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _price,
                      decoration: const InputDecoration(labelText: 'Price'),
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      validator: (value) =>
                          double.tryParse(value?.replaceAll(',', '.') ?? '') ==
                              null
                          ? 'Enter a valid price.'
                          : null,
                    ),
                  ),
                  const SizedBox(width: 12),
                  SizedBox(
                    width: 100,
                    child: TextFormField(
                      controller: _currency,
                      decoration: const InputDecoration(labelText: 'Currency'),
                      textCapitalization: TextCapitalization.characters,
                      validator: _required,
                    ),
                  ),
                ],
              ),
              TextFormField(
                controller: _location,
                decoration: const InputDecoration(labelText: 'Location'),
                validator: _required,
              ),
              TextFormField(
                controller: _contact,
                decoration: const InputDecoration(
                  labelText: 'Seller email or phone',
                ),
                validator: _required,
              ),
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerLeft,
                child: OutlinedButton.icon(
                  onPressed: _isUploading ? null : _pickImages,
                  icon: const Icon(Icons.add_photo_alternate_outlined),
                  label: const Text('Add images'),
                ),
              ),
              if (_imageUrls.isEmpty && _newImages.isEmpty)
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text('Optional. You can attach multiple images.'),
                )
              else
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (var index = 0; index < _imageUrls.length; index++)
                      InputChip(
                        label: Text('Image ${index + 1}'),
                        onDeleted: _isUploading
                            ? null
                            : () => setState(() {
                                _removedImageUrls.add(_imageUrls.removeAt(index));
                              }),
                      ),
                    for (final image in _newImages)
                      InputChip(
                        avatar: const Icon(Icons.image_outlined),
                        label: Text(image.name),
                        onDeleted: _isUploading
                            ? null
                            : () => setState(() => _newImages.remove(image)),
                      ),
                  ],
                ),
              if (_uploadError != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    _uploadError!,
                    style: TextStyle(color: Theme.of(context).colorScheme.error),
                  ),
                ),
            ],
          ),
        ),
      ),
    ),
    actions: [
      TextButton(onPressed: () => context.pop(), child: const Text('Cancel')),
      FilledButton(
        onPressed: _isUploading ? null : _submit,
        child: Text(
          _isUploading
              ? 'Uploading images…'
              : widget.initial == null
              ? 'Create listing'
              : 'Save changes',
        ),
      ),
    ],
  );

  String? _required(String? value) =>
      value == null || value.trim().isEmpty ? 'This field is required.' : null;

  Future<void> _pickImages() async {
    if (Firebase.apps.isEmpty) {
      setState(() => _uploadError = 'Image uploads require Firebase configuration.');
      return;
    }
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      allowMultiple: true,
      withData: true,
    );
    if (result == null || !mounted) return;
    setState(() {
      _newImages.addAll(result.files.where((file) => file.bytes != null));
      _uploadError = null;
    });
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final id = widget.initial?.id ?? DateTime.now().microsecondsSinceEpoch.toString();
    setState(() {
      _isUploading = true;
      _uploadError = null;
    });
    try {
      final imageUrls = List<String>.of(_imageUrls);
      for (final image in _newImages) {
        final Uint8List? data = image.bytes;
        if (data == null) continue;
        final path = 'marketplaceListings/${widget.ownerId}/$id/${DateTime.now().microsecondsSinceEpoch}_${_safeFileName(image.name)}';
        final reference = FirebaseStorage.instance.ref(path);
        await reference.putData(
          data,
          SettableMetadata(contentType: _imageContentType(image.extension)),
        );
        imageUrls.add(await reference.getDownloadURL());
      }
      for (final url in _removedImageUrls) {
        try {
          await FirebaseStorage.instance.refFromURL(url).delete();
        } on FirebaseException {
          // A legacy URL may not point to an object owned by this app.
        }
      }
      if (!mounted) return;
      context.pop(
        MarketplaceListing(
          id: id,
        title: _title.text.trim(),
        description: _description.text.trim(),
        price: double.parse(_price.text.replaceAll(',', '.')),
        currency: _currency.text.trim().toUpperCase(),
        category: _category,
        location: _location.text.trim(),
        sellerName: widget.initial?.sellerName ?? widget.email,
        sellerContact: _contact.text.trim(),
        listedAt: widget.initial?.listedAt ?? DateTime.now(),
        imageUrls: imageUrls,
        ownerId: widget.ownerId,
      ),
      );
    } catch (_) {
      if (mounted) {
        setState(() {
          _isUploading = false;
          _uploadError = 'Unable to upload one or more images. Please try again.';
        });
      }
    }
  }

  String _safeFileName(String name) => name.replaceAll(RegExp(r'[^A-Za-z0-9._-]'), '_');

  String _imageContentType(String? extension) => switch (extension?.toLowerCase()) {
    'jpg' || 'jpeg' => 'image/jpeg',
    'png' => 'image/png',
    'gif' => 'image/gif',
    'webp' => 'image/webp',
    _ => 'application/octet-stream',
  };
}

class TournamentsPage extends StatefulWidget {
  const TournamentsPage({super.key, this.initialTournamentId});
  final String? initialTournamentId;

  @override
  State<TournamentsPage> createState() => _TournamentsPageState();
}

class _TournamentsPageState extends State<TournamentsPage> {
  final _locationController = TextEditingController();
  final _selectedTournamentIds = <String>{};
  DateTime? _filterStartDate;
  DateTime? _filterEndDate;
  String _futureSortField = 'startDate';
  bool _futureSortAscending = true;
  String _pastSortField = 'startDate';
  bool _pastSortAscending = true;
  bool _showPastTournaments = false;
  bool _showMyTournaments = false;

  @override
  void initState() {
    super.initState();
    if (widget.initialTournamentId != null) {
      _selectedTournamentIds.add(widget.initialTournamentId!);
    }
  }

  @override
  void dispose() {
    _locationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final canEdit = context.watch<AuthController>().isSignedIn;
    final playerRepository = Provider.of<PlayerRepository?>(
      context,
      listen: false,
    );
    return PageFrame(
      title: l10n.tournaments,
      intro: l10n.tournamentsIntro,
      titleAction: canEdit
          ? FilledButton.icon(
              onPressed: _createTournament,
              icon: const Icon(Icons.add),
              label: Text(l10n.createTournament),
            )
          : null,
      child: StreamBuilder<List<Tournament>>(
        stream: context.read<TournamentRepository>().watchTournaments(),
        builder: (_, snapshot) => StreamBuilder<List<TeamPlayerSearch>>(
          stream: playerRepository?.watchTeamSearches(),
          builder: (_, searches) => StreamBuilder<List<PlayerTeamSearch>>(
            stream: playerRepository?.watchPlayerTeamSearches(),
            builder: (_, teamSearches) => _buildContent(
              context,
              snapshot,
              searches.data?.map((search) => search.tournamentId).toSet() ?? {},
              teamSearches.data?.map((search) => search.tournamentId).toSet() ??
                  {},
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    AsyncSnapshot<List<Tournament>> snapshot,
    Set<String> tournamentsWithPlayerSearches,
    Set<String> tournamentsWithTeamSearches,
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
    final focused = all
        .where(
          (item) =>
              _selectedTournamentIds.isEmpty ||
              _selectedTournamentIds.contains(item.id),
        )
        .toList();
    final future = _sorted(
      focused.where((item) => !item.endDate.isBefore(now)),
      field: _futureSortField,
      ascending: _futureSortAscending,
    );
    final past = _sorted(
      focused.where((item) => item.endDate.isBefore(now)),
      field: _pastSortField,
      ascending: _pastSortAscending,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _TournamentFilters(
          tournaments: snapshot.data!,
          selectedTournamentIds: _selectedTournamentIds,
          locationController: _locationController,
          filterStartDate: _filterStartDate,
          filterEndDate: _filterEndDate,
          onTournamentToggled: (id) => setState(() {
            if (!_selectedTournamentIds.add(id))
              _selectedTournamentIds.remove(id);
          }),
          onLocationChanged: (_) => setState(() {}),
          onStartDateChanged: (date) => setState(() => _filterStartDate = date),
          onEndDateChanged: (date) => setState(() => _filterEndDate = date),
          onClear: () {
            _locationController.clear();
            setState(() {
              _selectedTournamentIds.clear();
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
          sortField: _futureSortField,
          sortAscending: _futureSortAscending,
          onSort: _sortFuture,
          canEdit: context.read<AuthController>().isSignedIn,
          onEdit: _editTournament,
          onDelete: _deleteTournament,
          tournamentsWithPlayerSearches: tournamentsWithPlayerSearches,
          tournamentsWithTeamSearches: tournamentsWithTeamSearches,
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
            sortField: _pastSortField,
            sortAscending: _pastSortAscending,
            onSort: _sortPast,
            canEdit: context.read<AuthController>().isSignedIn,
            onEdit: _editTournament,
            tournamentsWithPlayerSearches: tournamentsWithPlayerSearches,
            tournamentsWithTeamSearches: tournamentsWithTeamSearches,
          ),
        ],
      ],
    );
  }

  List<Tournament> _filtered(List<Tournament> source, {String? organizerId}) {
    final location = _locationController.text.trim().toLowerCase();
    final result = source.where((tournament) {
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
      return matchesLocation && matchesStart && matchesEnd && matchesOrganizer;
    }).toList();
    return result;
  }

  List<Tournament> _sorted(
    Iterable<Tournament> source, {
    required String field,
    required bool ascending,
  }) {
    final result = source.toList();
    result.sort((a, b) {
      final left = _sortValue(a, field);
      final right = _sortValue(b, field);
      final comparison = left.compareTo(right);
      return ascending ? comparison : -comparison;
    });
    return result;
  }

  String _sortValue(Tournament tournament, String field) => switch (field) {
    'endDate' => tournament.endDate.toIso8601String(),
    'signupDeadline' => tournament.signupDeadline?.toIso8601String() ?? '',
    'name' => tournament.name.toLowerCase(),
    _ => tournament.startDate.toIso8601String(),
  };

  void _sortFuture(String field) {
    setState(() {
      if (_futureSortField == field) {
        _futureSortAscending = !_futureSortAscending;
      } else {
        _futureSortField = field;
        _futureSortAscending = true;
      }
    });
  }

  void _sortPast(String field) {
    setState(() {
      if (_pastSortField == field) {
        _pastSortAscending = !_pastSortAscending;
      } else {
        _pastSortField = field;
        _pastSortAscending = true;
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
    required this.tournaments,
    required this.selectedTournamentIds,
    required this.locationController,
    required this.filterStartDate,
    required this.filterEndDate,
    required this.onTournamentToggled,
    required this.onLocationChanged,
    required this.onStartDateChanged,
    required this.onEndDateChanged,
    required this.onClear,
  });

  final List<Tournament> tournaments;
  final Set<String> selectedTournamentIds;
  final TextEditingController locationController;
  final DateTime? filterStartDate;
  final DateTime? filterEndDate;
  final ValueChanged<String> onTournamentToggled;
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
            _TournamentMultiSelectFilter(
              tournaments: tournaments,
              selectedIds: selectedTournamentIds,
              onToggle: onTournamentToggled,
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

class _TournamentMultiSelectFilter extends StatefulWidget {
  const _TournamentMultiSelectFilter({
    required this.tournaments,
    required this.selectedIds,
    required this.onToggle,
  });

  final List<Tournament> tournaments;
  final Set<String> selectedIds;
  final ValueChanged<String> onToggle;

  @override
  State<_TournamentMultiSelectFilter> createState() =>
      _TournamentMultiSelectFilterState();
}

class _TournamentMultiSelectFilterState
    extends State<_TournamentMultiSelectFilter> {
  final _link = LayerLink();
  OverlayEntry? _overlay;

  @override
  void dispose() {
    _close();
    super.dispose();
  }

  void _toggle() => _overlay == null ? _open() : _close();

  void _open() {
    _overlay = OverlayEntry(
      builder: (context) => Stack(
        children: [
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.translucent,
              onTap: _close,
            ),
          ),
          CompositedTransformFollower(
            link: _link,
            targetAnchor: Alignment.bottomLeft,
            followerAnchor: Alignment.topLeft,
            offset: const Offset(0, 4),
            child: Material(
              elevation: 6,
              child: SizedBox(
                width: 220,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 260),
                  child: ListView(
                    shrinkWrap: true,
                    children: widget.tournaments
                        .map(
                          (tournament) => CheckboxListTile(
                            dense: true,
                            controlAffinity: ListTileControlAffinity.leading,
                            value: widget.selectedIds.contains(tournament.id),
                            title: Text(
                              tournament.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            onChanged: (_) {
                              widget.onToggle(tournament.id);
                              _overlay?.markNeedsBuild();
                            },
                          ),
                        )
                        .toList(),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
    Overlay.of(context, rootOverlay: true).insert(_overlay!);
  }

  void _close() {
    _overlay?.remove();
    _overlay = null;
  }

  @override
  Widget build(BuildContext context) => SizedBox(
    width: 220,
    child: CompositedTransformTarget(
      link: _link,
      child: InkWell(
        onTap: _toggle,
        child: InputDecorator(
          decoration: InputDecoration(
            labelText: AppLocalizations.of(context).tournamentFilter,
            border: OutlineInputBorder(),
            suffixIcon: Icon(Icons.arrow_drop_down),
          ),
          child: Text(
            widget.selectedIds.isEmpty
                ? AppLocalizations.of(context).all
                : AppLocalizations.of(
                    context,
                  ).selectedCount(widget.selectedIds.length),
          ),
        ),
      ),
    ),
  );
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
    required this.tournamentsWithPlayerSearches,
    required this.tournamentsWithTeamSearches,
    this.onDelete,
  });

  final List<Tournament> tournaments;
  final String emptyText;
  final String sortField;
  final bool sortAscending;
  final ValueChanged<String> onSort;
  final bool canEdit;
  final ValueChanged<Tournament> onEdit;
  final Set<String> tournamentsWithPlayerSearches;
  final Set<String> tournamentsWithTeamSearches;
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
      'startDate': 3,
      'endDate': 4,
      'signupDeadline': 5,
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
            const DataColumn(
              label: Tooltip(
                message: 'Player search available',
                child: Icon(Icons.person_outline),
              ),
            ),
            const DataColumn(
              label: Tooltip(
                message: 'Team search available',
                child: Icon(Icons.groups_outlined),
              ),
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
                DataCell(
                  TextButton(
                    onPressed: () =>
                        context.go('/tournaments', extra: tournament.id),
                    child: Text(tournament.name),
                  ),
                ),
                DataCell(
                  IconButton(
                    tooltip: 'View player search',
                    onPressed:
                        widget.tournamentsWithPlayerSearches.contains(
                          tournament.id,
                        )
                        ? () => context.go('/players', extra: tournament.id)
                        : null,
                    icon: Icon(
                      Icons.person,
                      color:
                          widget.tournamentsWithPlayerSearches.contains(
                            tournament.id,
                          )
                          ? Theme.of(context).colorScheme.primary
                          : Theme.of(context).colorScheme.outlineVariant,
                    ),
                  ),
                ),
                DataCell(
                  IconButton(
                    tooltip: 'View team search',
                    onPressed:
                        widget.tournamentsWithTeamSearches.contains(
                          tournament.id,
                        )
                        ? () => context.go('/players', extra: tournament.id)
                        : null,
                    icon: Icon(
                      Icons.groups,
                      color:
                          widget.tournamentsWithTeamSearches.contains(
                            tournament.id,
                          )
                          ? Theme.of(context).colorScheme.primary
                          : Theme.of(context).colorScheme.outlineVariant,
                    ),
                  ),
                ),
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
                          onPressed: () => launchUrl(
                            _websiteUri(tournament.websiteUrl!),
                          ),
                          child: Text(tournament.websiteUrl!),
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

Uri _websiteUri(String website) {
  final parsed = Uri.parse(website);
  return parsed.hasScheme ? parsed : Uri.parse('https://$website');
}

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
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('* ${l10n.requiredField}'),
                const SizedBox(height: 12),
                _requiredField(_name, l10n.name),
                _requiredField(_city, l10n.city),
                Row(
                  children: [
                    Expanded(
                      child: _requiredField(_country, l10n.country),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _requiredField(_club, l10n.club),
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
                    labelText: _requiredLabel(l10n.contact),
                    hintText: l10n.contactHint,
                  ),
                  validator: _contactValidator,
                ),
                TextFormField(
                  controller: _website,
                  decoration: InputDecoration(labelText: l10n.website),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    _FormDateButton(
                      label: _requiredLabel(l10n.startDate),
                      value: _startDate,
                      onChanged: (value) => setState(() => _startDate = value!),
                      referenceDate: _endDate,
                      initialDate: _dateInRelatedMonth(
                        _endDate.subtract(const Duration(days: 1)),
                      ),
                    ),
                    _FormDateButton(
                      label: _requiredLabel(l10n.endDate),
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
        decoration: InputDecoration(labelText: _requiredLabel(label)),
        validator: (value) => value == null || value.trim().isEmpty
            ? AppLocalizations.of(context).requiredField
            : null,
      );

  String _requiredLabel(String label) => '$label *';

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
    if (value == null || value.trim().isEmpty) {
      return AppLocalizations.of(context).requiredField;
    }
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

class PlayersDirectoryPage extends StatefulWidget {
  const PlayersDirectoryPage({super.key, this.initialTournamentId});
  final String? initialTournamentId;

  @override
  State<PlayersDirectoryPage> createState() => _PlayersDirectoryPageState();
}

class _PlayersDirectoryPageState extends State<PlayersDirectoryPage> {
  final _selectedTournamentIds = <String>{};

  @override
  void initState() {
    super.initState();
    if (widget.initialTournamentId != null) {
      _selectedTournamentIds.add(widget.initialTournamentId!);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return PageFrame(
      title: l10n.players,
      intro: l10n.teamsLookingForPlayers,
      child: StreamBuilder<List<Tournament>>(
        stream: context.read<TournamentRepository>().watchTournaments(),
        builder: (_, tournaments) => StreamBuilder<List<TeamPlayerSearch>>(
          stream: context.read<PlayerRepository>().watchTeamSearches(),
          builder: (_, searches) => StreamBuilder<List<PlayerTeamSearch>>(
            stream: context.read<PlayerRepository>().watchPlayerTeamSearches(),
            builder: (_, teamSearches) => Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _TournamentMultiSelectFilter(
                  tournaments: tournaments.data ?? const [],
                  selectedIds: _selectedTournamentIds,
                  onToggle: (id) => setState(() {
                    if (!_selectedTournamentIds.add(id)) {
                      _selectedTournamentIds.remove(id);
                    }
                  }),
                ),
                if (_selectedTournamentIds.isNotEmpty)
                  TextButton.icon(
                    onPressed: () => setState(_selectedTournamentIds.clear),
                    icon: const Icon(Icons.clear),
                    label: Text(l10n.clearFilters),
                  ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Text(
                      l10n.teamsSearchingForPlayers,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(width: 12),
                    if (context.watch<AuthController>().isSignedIn)
                      FilledButton.icon(
                        onPressed: _createSearch,
                        icon: const Icon(Icons.add),
                        label: Text(l10n.createPlayerSearch),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                _searchTable(tournaments.data ?? const [], searches),
                const SizedBox(height: 32),
                Row(
                  children: [
                    Text(
                      l10n.playersSearchingForTeams,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(width: 12),
                    if (context.watch<AuthController>().isSignedIn)
                      FilledButton.icon(
                        onPressed: _createTeamSearch,
                        icon: const Icon(Icons.add),
                        label: Text(l10n.createTeamSearch),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                _teamSearchTable(tournaments.data ?? const [], teamSearches),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _teamSearchTable(
    List<Tournament> tournaments,
    AsyncSnapshot<List<PlayerTeamSearch>> snapshot,
  ) {
    if (snapshot.hasError)
      return Text(AppLocalizations.of(context).unableToLoadData);
    if (!snapshot.hasData)
      return const Center(child: CircularProgressIndicator());
    final byId = {
      for (final tournament in tournaments) tournament.id: tournament,
    };
    final searches = snapshot.data!
        .where(
          (search) =>
              _selectedTournamentIds.isEmpty ||
              _selectedTournamentIds.contains(search.tournamentId),
        )
        .toList();
    if (searches.isEmpty) return Text(AppLocalizations.of(context).noItems);
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columns: [
          DataColumn(label: Text(AppLocalizations.of(context).tournament)),
          DataColumn(label: Text(AppLocalizations.of(context).role)),
          DataColumn(label: Text(AppLocalizations.of(context).contact)),
          DataColumn(label: Text('')),
        ],
        rows: searches.map((search) {
          final owner = context.read<AuthController>().userId == search.ownerId;
          return DataRow(
            cells: [
              DataCell(
                SizedBox(
                  width: 300,
                  child: byId[search.tournamentId] == null
                      ? Text(AppLocalizations.of(context).tournamentUnavailable)
                      : Builder(
                          builder: (context) {
                            final tournament = byId[search.tournamentId]!;
                            return Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                TextButton(
                                  onPressed: () => context.go(
                                    '/tournaments',
                                    extra: tournament.id,
                                  ),
                                  style: TextButton.styleFrom(
                                    padding: EdgeInsets.zero,
                                    minimumSize: Size.zero,
                                    tapTargetSize:
                                        MaterialTapTargetSize.shrinkWrap,
                                  ),
                                  child: Align(
                                    alignment: Alignment.centerLeft,
                                    child: Text(
                                      tournament.name,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ),
                                Text(
                                  '${tournament.city}${tournament.country == null ? '' : ', ${tournament.country}'} · ${DateFormat.yMMMd().format(tournament.startDate)} – ${DateFormat.yMMMd().format(tournament.endDate)}',
                                  style: Theme.of(context).textTheme.bodySmall,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            );
                          },
                        ),
                ),
              ),
              DataCell(Text(search.role)),
              DataCell(Text(search.contact)),
              DataCell(
                owner
                    ? Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit),
                            tooltip: AppLocalizations.of(context).editSearch,
                            onPressed: () => _editTeamSearch(search),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete),
                            tooltip: AppLocalizations.of(context).deleteSearch,
                            onPressed: () => _deleteTeamSearch(search),
                          ),
                        ],
                      )
                    : const SizedBox.shrink(),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }

  Future<void> _createTeamSearch() async {
    final auth = context.read<AuthController>();
    if (auth.userId == null || auth.email == null) return;
    final tournaments = await context
        .read<TournamentRepository>()
        .watchTournaments()
        .first;
    if (!mounted) return;
    final result = await showDialog<PlayerTeamSearch>(
      context: context,
      builder: (_) => _PlayerTeamSearchDialog(
        ownerId: auth.userId!,
        contact: auth.email!,
        tournaments: tournaments,
      ),
    );
    if (result != null && mounted)
      await context.read<PlayerRepository>().savePlayerTeamSearch(result);
  }

  Future<void> _editTeamSearch(PlayerTeamSearch search) async {
    if (context.read<AuthController>().userId != search.ownerId) return;
    final tournaments = await context
        .read<TournamentRepository>()
        .watchTournaments()
        .first;
    if (!mounted) return;
    final result = await showDialog<PlayerTeamSearch>(
      context: context,
      builder: (_) => _PlayerTeamSearchDialog(
        ownerId: search.ownerId,
        contact: search.contact,
        tournaments: tournaments,
        initial: search,
      ),
    );
    if (result != null && mounted)
      await context.read<PlayerRepository>().savePlayerTeamSearch(result);
  }

  Future<void> _deleteTeamSearch(PlayerTeamSearch search) async {
    if (context.read<AuthController>().userId != search.ownerId) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(AppLocalizations.of(context).deleteTeamSearch),
        content: Text(
          AppLocalizations.of(context).confirmDeleteTournamentMessage,
        ),
        actions: [
          TextButton(
            onPressed: () => context.pop(false),
            child: Text(AppLocalizations.of(context).cancel),
          ),
          FilledButton(
            onPressed: () => context.pop(true),
            child: Text(AppLocalizations.of(context).deleteSearch),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted)
      await context.read<PlayerRepository>().deletePlayerTeamSearch(search.id);
  }

  Widget _searchTable(
    List<Tournament> tournaments,
    AsyncSnapshot<List<TeamPlayerSearch>> snapshot,
  ) {
    if (snapshot.hasError)
      return Text(AppLocalizations.of(context).unableToLoadData);
    if (!snapshot.hasData)
      return const Center(child: CircularProgressIndicator());
    final byId = {
      for (final tournament in tournaments) tournament.id: tournament,
    };
    final searches = snapshot.data!
        .where(
          (search) =>
              _selectedTournamentIds.isEmpty ||
              _selectedTournamentIds.contains(search.tournamentId),
        )
        .toList();
    if (searches.isEmpty) return Text(AppLocalizations.of(context).noItems);
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columns: [
          DataColumn(label: Text(AppLocalizations.of(context).tournament)),
          DataColumn(label: Text(AppLocalizations.of(context).role)),
          DataColumn(label: Text(AppLocalizations.of(context).contact)),
          DataColumn(label: Text('')),
        ],
        rows: searches.map((search) {
          final tournament = byId[search.tournamentId];
          final owner = context.read<AuthController>().userId == search.ownerId;
          return DataRow(
            cells: [
              DataCell(
                SizedBox(
                  width: 300,
                  child: tournament == null
                      ? Text(AppLocalizations.of(context).tournamentUnavailable)
                      : Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            TextButton(
                              onPressed: () => context.go(
                                '/tournaments',
                                extra: tournament.id,
                              ),
                              style: TextButton.styleFrom(
                                padding: EdgeInsets.zero,
                                minimumSize: Size.zero,
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                              child: Align(
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  tournament.name,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ),
                            Text(
                              '${tournament.city}${tournament.country == null ? '' : ', ${tournament.country}'} · ${DateFormat.yMMMd().format(tournament.startDate)} – ${DateFormat.yMMMd().format(tournament.endDate)}',
                              style: Theme.of(context).textTheme.bodySmall,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                ),
              ),
              DataCell(Text(search.role)),
              DataCell(Text(search.contact)),
              DataCell(
                owner
                    ? Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit),
                            tooltip: AppLocalizations.of(context).editSearch,
                            onPressed: () => _editSearch(search),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete),
                            tooltip: AppLocalizations.of(context).deleteSearch,
                            onPressed: () => _deleteSearch(search),
                          ),
                        ],
                      )
                    : const SizedBox.shrink(),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }

  Future<void> _createSearch() async {
    final auth = context.read<AuthController>();
    if (auth.userId == null || auth.email == null) return;
    final tournaments = await context
        .read<TournamentRepository>()
        .watchTournaments()
        .first;
    if (!mounted) return;
    final result = await showDialog<TeamPlayerSearch>(
      context: context,
      builder: (_) => _TeamSearchDialog(
        ownerId: auth.userId!,
        contact: auth.email!,
        tournaments: tournaments,
      ),
    );
    if (result != null && mounted)
      await context.read<PlayerRepository>().saveTeamSearch(result);
  }

  Future<void> _editSearch(TeamPlayerSearch search) async {
    if (context.read<AuthController>().userId != search.ownerId) return;
    final tournaments = await context
        .read<TournamentRepository>()
        .watchTournaments()
        .first;
    if (!mounted) return;
    final result = await showDialog<TeamPlayerSearch>(
      context: context,
      builder: (_) => _TeamSearchDialog(
        ownerId: search.ownerId,
        contact: search.contact,
        tournaments: tournaments,
        initial: search,
      ),
    );
    if (result != null && mounted)
      await context.read<PlayerRepository>().saveTeamSearch(result);
  }

  Future<void> _deleteSearch(TeamPlayerSearch search) async {
    if (context.read<AuthController>().userId != search.ownerId) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(AppLocalizations.of(context).deletePlayerSearch),
        content: Text(
          AppLocalizations.of(context).confirmDeleteTournamentMessage,
        ),
        actions: [
          TextButton(
            onPressed: () => context.pop(false),
            child: Text(AppLocalizations.of(context).cancel),
          ),
          FilledButton(
            onPressed: () => context.pop(true),
            child: Text(AppLocalizations.of(context).deleteSearch),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted)
      await context.read<PlayerRepository>().deleteTeamSearch(search.id);
  }
}

class _TeamSearchDialog extends StatefulWidget {
  const _TeamSearchDialog({
    required this.ownerId,
    required this.contact,
    required this.tournaments,
    this.initial,
  });
  final String ownerId, contact;
  final List<Tournament> tournaments;
  final TeamPlayerSearch? initial;
  @override
  State<_TeamSearchDialog> createState() => _TeamSearchDialogState();
}

class _TeamSearchDialogState extends State<_TeamSearchDialog> {
  String? _tournamentId;
  String _role = 'any';
  @override
  void initState() {
    super.initState();
    _tournamentId = widget.initial?.tournamentId;
    _role = widget.initial?.role ?? 'any';
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text(
      widget.initial == null
          ? AppLocalizations.of(context).createPlayerSearch
          : AppLocalizations.of(context).editPlayerSearch,
    ),
    content: SizedBox(
      width: 420,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          DropdownButtonFormField<String>(
            initialValue: _tournamentId,
            decoration: InputDecoration(
              labelText: AppLocalizations.of(context).tournament,
            ),
            items: widget.tournaments
                .map((t) => DropdownMenuItem(value: t.id, child: Text(t.name)))
                .toList(),
            onChanged: (value) => setState(() => _tournamentId = value),
          ),
          DropdownButtonFormField<String>(
            initialValue: _role,
            decoration: InputDecoration(
              labelText: AppLocalizations.of(context).role,
            ),
            items: const ['lead', 'second', 'third', 'skip', 'any']
                .map((role) => DropdownMenuItem(value: role, child: Text(role)))
                .toList(),
            onChanged: (value) => setState(() => _role = value!),
          ),
        ],
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => context.pop(),
        child: Text(AppLocalizations.of(context).cancel),
      ),
      FilledButton(
        onPressed: _tournamentId == null
            ? null
            : () => context.pop(
                TeamPlayerSearch(
                  id:
                      widget.initial?.id ??
                      DateTime.now().microsecondsSinceEpoch.toString(),
                  tournamentId: _tournamentId!,
                  role: _role,
                  contact: widget.contact,
                  ownerId: widget.ownerId,
                ),
              ),
        child: Text(
          widget.initial == null
              ? AppLocalizations.of(context).createSearch
              : AppLocalizations.of(context).saveChanges,
        ),
      ),
    ],
  );
}

class _PlayerTeamSearchDialog extends StatefulWidget {
  const _PlayerTeamSearchDialog({
    required this.ownerId,
    required this.contact,
    required this.tournaments,
    this.initial,
  });
  final String ownerId, contact;
  final List<Tournament> tournaments;
  final PlayerTeamSearch? initial;
  @override
  State<_PlayerTeamSearchDialog> createState() =>
      _PlayerTeamSearchDialogState();
}

class _PlayerTeamSearchDialogState extends State<_PlayerTeamSearchDialog> {
  String? _tournamentId;
  String _role = 'any';
  @override
  void initState() {
    super.initState();
    _tournamentId = widget.initial?.tournamentId;
    _role = widget.initial?.role ?? 'any';
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text(
      widget.initial == null
          ? AppLocalizations.of(context).createTeamSearch
          : AppLocalizations.of(context).editTeamSearch,
    ),
    content: SizedBox(
      width: 420,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          DropdownButtonFormField<String>(
            initialValue: _tournamentId,
            decoration: InputDecoration(
              labelText: AppLocalizations.of(context).tournament,
            ),
            items: widget.tournaments
                .map((t) => DropdownMenuItem(value: t.id, child: Text(t.name)))
                .toList(),
            onChanged: (value) => setState(() => _tournamentId = value),
          ),
          DropdownButtonFormField<String>(
            initialValue: _role,
            decoration: InputDecoration(
              labelText: AppLocalizations.of(context).role,
            ),
            items: const ['lead', 'second', 'third', 'skip', 'any']
                .map((role) => DropdownMenuItem(value: role, child: Text(role)))
                .toList(),
            onChanged: (value) => setState(() => _role = value!),
          ),
        ],
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => context.pop(),
        child: Text(AppLocalizations.of(context).cancel),
      ),
      FilledButton(
        onPressed: _tournamentId == null
            ? null
            : () => context.pop(
                PlayerTeamSearch(
                  id:
                      widget.initial?.id ??
                      DateTime.now().microsecondsSinceEpoch.toString(),
                  tournamentId: _tournamentId!,
                  role: _role,
                  contact: widget.contact,
                  ownerId: widget.ownerId,
                ),
              ),
        child: Text(
          widget.initial == null
              ? AppLocalizations.of(context).createTeamSearch
              : AppLocalizations.of(context).saveChanges,
        ),
      ),
    ],
  );
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
    this.titleAction,
  });
  final String title, intro;
  final Widget child;
  final Widget? action;
  final Widget? titleAction;
  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.all(24),
    children: [
      if (titleAction != null)
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(title, style: Theme.of(context).textTheme.headlineMedium),
                const SizedBox(width: 12),
                titleAction!,
              ],
            ),
            Text(intro),
          ],
        )
      else
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
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
