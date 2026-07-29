// ignore_for_file: curly_braces_in_flow_control_structures, unnecessary_underscores, use_null_aware_elements

import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_functions/cloud_functions.dart';
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

const _inkNavy = Color(0xFFF1FAFC);
const _curlingBlue = Color(0xFF168AA4);
const _ice = Color(0xFF0B1F2A);
const _surface = Color(0xFF123542);
const _granite = Color(0xFFB8CAD1);
const _warmAmber = Color(0xFFFFC45B);

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
  Widget build(BuildContext context) {
    final colors = ColorScheme.fromSeed(
      seedColor: _curlingBlue,
      brightness: Brightness.dark,
    ).copyWith(
      primary: _curlingBlue,
      onPrimary: Colors.white,
      secondary: const Color(0xFF74D8EA),
      onSecondary: _ice,
      tertiary: _warmAmber,
      onTertiary: _ice,
      surface: _surface,
      onSurface: _inkNavy,
      outline: const Color(0xFF49636D),
    );
    return MaterialApp.router(
      title: 'Curling Companion',
      routerConfig: router,
      locale: (() {
        final userLanguage = context.watch<AuthController>().language;
        return userLanguage == null
            ? context.watch<LocaleController>().locale
            : Locale(userLanguage);
      })(),
      theme: ThemeData(
        colorScheme: colors,
        useMaterial3: true,
        scaffoldBackgroundColor: _ice,
        cardTheme: CardThemeData(
          color: _surface,
          elevation: 0,
          margin: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: Color(0xFF244B59)),
          ),
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            backgroundColor: _curlingBlue,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            shape: const StadiumBorder(),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: _inkNavy,
            side: const BorderSide(color: Color(0xFF66818B)),
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
            shape: const StadiumBorder(),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: _surface,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFF49636D)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFF49636D)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: _curlingBlue, width: 2),
          ),
        ),
        navigationRailTheme: const NavigationRailThemeData(
          backgroundColor: Color(0xFF0E2834),
          selectedIconTheme: IconThemeData(color: _inkNavy),
          selectedLabelTextStyle: TextStyle(
            color: _inkNavy,
            fontWeight: FontWeight.w700,
          ),
          indicatorColor: Color(0xFF1B4757),
        ),
        dividerTheme: const DividerThemeData(color: Color(0xFF244B59)),
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
}

class AppShell extends StatelessWidget {
  const AppShell({super.key, required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final path = GoRouterState.of(context).uri.path;
    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth < 1000) return child;
          final destinations = [
            (l10n.home, Icons.home_outlined, Icons.home, '/'),
            (l10n.tournaments, Icons.emoji_events_outlined, Icons.emoji_events, '/tournaments'),
            (l10n.players, Icons.group_outlined, Icons.group, '/players'),
            (l10n.marketplace, Icons.storefront_outlined, Icons.storefront, '/marketplace'),
          ];
          final selectedIndex = destinations.indexWhere(
            (destination) => destination.$4 == '/'
                ? path == '/'
                : path.startsWith(destination.$4),
          );
          return Row(
            children: [
              NavigationRail(
                selectedIndex: selectedIndex < 0 ? 0 : selectedIndex,
                labelType: NavigationRailLabelType.all,
                minWidth: 104,
                leading: const Padding(
                  padding: EdgeInsets.only(top: 12, bottom: 20),
                  child: Icon(Icons.sports_score, color: _curlingBlue, size: 30),
                ),
                destinations: [
                  for (final destination in destinations)
                    NavigationRailDestination(
                      icon: Icon(destination.$2),
                      selectedIcon: Icon(destination.$3),
                      label: Text(destination.$1),
                    ),
                ],
                onDestinationSelected: (index) => context.go(destinations[index].$4),
              ),
              const VerticalDivider(width: 1),
              Expanded(child: child),
            ],
          );
        },
      ),
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
    return LayoutBuilder(
      builder: (context, constraints) => ListView(
        padding: EdgeInsets.all(constraints.maxWidth < 600 ? 16 : 32),
        children: [
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1200),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: double.infinity,
                    child: Wrap(
                      alignment: WrapAlignment.spaceBetween,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      runSpacing: 12,
                      children: [
                        Text(
                          'CURLING COMPANION',
                          style: Theme.of(context).textTheme.labelMedium?.copyWith(
                            color: _curlingBlue,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.2,
                          ),
                        ),
                        const _PageHeaderControls(),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    l10n.welcome,
                    style: Theme.of(
                      context,
                    ).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    l10n.publicIntro,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: _granite,
                    ),
                  ),
                  const SizedBox(height: 32),
                  LayoutBuilder(
                    builder: (context, cardConstraints) => Wrap(
                      spacing: 20,
                      runSpacing: 20,
                      children: [
                        _FeatureCard(
                          title: l10n.tournaments,
                          description: l10n.tournamentsIntro,
                          imageAsset: 'assets/tournaments.png',
                          route: '/tournaments',
                          width: cardConstraints.maxWidth > 900
                              ? (cardConstraints.maxWidth - 40) / 3
                              : cardConstraints.maxWidth,
                        ),
                        _FeatureCard(
                          title: l10n.players,
                          description: l10n.playersIntro,
                          imageAsset: 'assets/player_search.png',
                          route: '/players',
                          width: cardConstraints.maxWidth > 900
                              ? (cardConstraints.maxWidth - 40) / 3
                              : cardConstraints.maxWidth,
                        ),
                        _FeatureCard(
                          title: l10n.marketplace,
                          description: l10n.marketplaceIntro,
                          imageAsset: 'assets/marketplace.png',
                          route: '/marketplace',
                          width: cardConstraints.maxWidth > 900
                              ? (cardConstraints.maxWidth - 40) / 3
                              : cardConstraints.maxWidth,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
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
      child: StreamBuilder<List<MarketplaceListing>>(
        stream: context.read<MarketplaceRepository>().watchListings(),
        builder: (_, snapshot) {
          final listings = _filtered(snapshot.data ?? const []);
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _MarketplaceFilters(
                category: _category,
                onCategoryChanged: (value) => setState(() => _category = value),
                action: canEdit
                    ? FilledButton.icon(
                        onPressed: () => _createListing(context),
                        icon: const Icon(Icons.add),
                        label: Text(l10n.createListing),
                      )
                    : null,
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
    if (snapshot.hasError) {
      return Text(AppLocalizations.of(context).unableToLoadData);
    }
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
        title: Text(AppLocalizations.of(context).deleteListing),
        content: Text(AppLocalizations.of(context).deleteListingMessage),
        actions: [
          TextButton(
            onPressed: () => context.pop(false),
            child: Text(AppLocalizations.of(context).cancel),
          ),
          FilledButton(
            onPressed: () => context.pop(true),
            child: Text(AppLocalizations.of(context).deleteListing),
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
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        children: [
          Chip(label: Text(_localizedMarketplaceCategory(l10n, listing.category))),
          const Spacer(),
          Text(
            '${listing.price.toStringAsFixed(2)} ${listing.currency}',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: _warmAmber,
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
              text: _formatDate(context, listing.listedAt!),
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
            label: Text(l10n.viewDetails),
          ),
          _MarketplaceContactButton(contact: listing.sellerContact),
          if (isOwner) ...[
            IconButton(
              tooltip: l10n.editListing,
              onPressed: onEdit,
              icon: const Icon(Icons.edit_outlined),
            ),
            IconButton(
              tooltip: l10n.deleteListing,
              onPressed: onDelete,
              icon: const Icon(Icons.delete_outline),
            ),
          ],
        ],
      ),
    ],
  );
  }
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

String _localizedMarketplaceCategory(
  AppLocalizations l10n,
  String category,
) => switch (category) {
  'shoes' => l10n.shoes,
  'stones' => l10n.stones,
  'brooms' => l10n.brooms,
  _ => l10n.other,
};

class _MarketplaceContactButton extends StatelessWidget {
  const _MarketplaceContactButton({required this.contact});
  final String contact;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isEmail = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(contact);
    if (contact.trim().isEmpty) return const SizedBox.shrink();
    return OutlinedButton.icon(
      onPressed: () => launchUrl(
        Uri(scheme: isEmail ? 'mailto' : 'tel', path: contact.trim()),
      ),
      icon: Icon(isEmail ? Icons.email_outlined : Icons.phone_outlined),
      label: Text(isEmail ? l10n.emailSeller : l10n.callSeller),
    );
  }
}

class _MarketplaceListingDetailsDialog extends StatelessWidget {
  const _MarketplaceListingDetailsDialog({required this.listing});
  final MarketplaceListing listing;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AlertDialog(
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
            if (listing.location.isNotEmpty)
              Text('${l10n.location}: ${listing.location}'),
            if (listing.sellerName.isNotEmpty)
              Text('${l10n.seller}: ${listing.sellerName}'),
          ],
        ),
      ),
    ),
    actions: [
      _MarketplaceContactButton(contact: listing.sellerContact),
      TextButton(onPressed: () => context.pop(), child: Text(l10n.close)),
    ],
  );
  }
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
    this.action,
  });
  final String category;
  final ValueChanged<String> onCategoryChanged;
  final Widget? action;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Wrap(
      spacing: 12,
      runSpacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        SizedBox(
          width: 180,
          child: DropdownButtonFormField<String>(
            initialValue: category,
            decoration: InputDecoration(
              labelText: AppLocalizations.of(context).category,
            ),
            items: [
              DropdownMenuItem(
                value: 'all',
                child: Text(AppLocalizations.of(context).allCategories),
              ),
              DropdownMenuItem(
                value: 'shoes',
                child: Text(AppLocalizations.of(context).shoes),
              ),
              DropdownMenuItem(
                value: 'stones',
                child: Text(AppLocalizations.of(context).stones),
              ),
              DropdownMenuItem(
                value: 'brooms',
                child: Text(AppLocalizations.of(context).brooms),
              ),
              DropdownMenuItem(
                value: 'other',
                child: Text(AppLocalizations.of(context).other),
              ),
            ],
            onChanged: (value) => onCategoryChanged(value!),
          ),
        ),
        if (action != null) action!,
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
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AlertDialog(
    title: Text(widget.initial == null ? l10n.createListing : l10n.editListing),
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
                decoration: InputDecoration(labelText: l10n.title),
                validator: _required,
              ),
              TextFormField(
                controller: _description,
                decoration: InputDecoration(labelText: l10n.description),
                maxLines: 3,
                validator: _required,
              ),
              DropdownButtonFormField<String>(
                initialValue: _category,
                decoration: InputDecoration(labelText: l10n.category),
                items: ['shoes', 'stones', 'brooms', 'other']
                    .map(
                      (category) => DropdownMenuItem(
                        value: category,
                        child: Text(_localizedMarketplaceCategory(l10n, category)),
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
                      decoration: InputDecoration(labelText: l10n.price),
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      validator: (value) =>
                          double.tryParse(value?.replaceAll(',', '.') ?? '') ==
                              null
                          ? l10n.enterValidPrice
                          : null,
                    ),
                  ),
                  const SizedBox(width: 12),
                  SizedBox(
                    width: 100,
                    child: TextFormField(
                      controller: _currency,
                      decoration: InputDecoration(labelText: l10n.currency),
                      textCapitalization: TextCapitalization.characters,
                      validator: _required,
                    ),
                  ),
                ],
              ),
              TextFormField(
                controller: _location,
                decoration: InputDecoration(labelText: l10n.location),
                validator: _required,
              ),
              TextFormField(
                controller: _contact,
                decoration: InputDecoration(
                  labelText: l10n.sellerEmailOrPhone,
                ),
                validator: _required,
              ),
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerLeft,
                child: OutlinedButton.icon(
                  onPressed: _isUploading ? null : _pickImages,
                  icon: const Icon(Icons.add_photo_alternate_outlined),
                  label: Text(l10n.addImages),
                ),
              ),
              if (_imageUrls.isEmpty && _newImages.isEmpty)
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(l10n.optionalMultipleImages),
                )
              else
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (var index = 0; index < _imageUrls.length; index++)
                      InputChip(
                        label: Text('${l10n.image} ${index + 1}'),
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
      TextButton(onPressed: () => context.pop(), child: Text(l10n.cancel)),
      FilledButton(
        onPressed: _isUploading ? null : _submit,
        child: Text(
          _isUploading
              ? l10n.uploadingImages
              : widget.initial == null
              ? l10n.createListing
              : l10n.saveChanges,
        ),
      ),
    ],
  );
  }

  String? _required(String? value) => value == null || value.trim().isEmpty
      ? AppLocalizations.of(context).requiredField
      : null;

  Future<void> _pickImages() async {
    if (Firebase.apps.isEmpty) {
      setState(() => _uploadError = AppLocalizations.of(context).imageUploadsRequireFirebase);
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
        final result = await FirebaseFunctions.instance
            .httpsCallable("uploadMarketplaceImage")
            .call({
              "listingId": id,
              "fileName": _safeFileName(image.name),
              "contentType": _imageContentType(image.extension),
              "dataBase64": base64Encode(data),
            });
        imageUrls.add((result.data as Map)["downloadUrl"] as String);
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
          _uploadError = AppLocalizations.of(context).imageUploadFailed;
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
  final _selectedLocations = <String>{};
  final _selectedTournamentIds = <String>{};
  DateTimeRange? _filterDateRange;
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
    final organizerId = _showMyTournaments ? auth.userId : null;
    final futureCandidates = snapshot.data!.where((item) => !item.endDate.isBefore(now) && (organizerId == null || item.organizerId == organizerId)).toList();
    final future = _filtered(futureCandidates)
        .where((item) => _selectedTournamentIds.isEmpty || _selectedTournamentIds.contains(item.id))
        .toList()
      ..sort((a, b) => a.startDate.compareTo(b.startDate));
    final past = snapshot.data!
        .where((item) => item.endDate.isBefore(now) && (organizerId == null || item.organizerId == organizerId))
        .toList()
      ..sort((a, b) => b.startDate.compareTo(a.startDate));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _TournamentFilters(
          tournaments: futureCandidates,
          selectedTournamentIds: _selectedTournamentIds,
          selectedLocations: _selectedLocations,
          filterDateRange: _filterDateRange,
          onTournamentToggled: (id) => setState(() {
            if (!_selectedTournamentIds.add(id)) _selectedTournamentIds.remove(id);
          }),
          onLocationToggled: (location) => setState(() {
            if (!_selectedLocations.add(location)) _selectedLocations.remove(location);
          }),
          onDateRangeChanged: (range) => setState(() => _filterDateRange = range),
          onClear: () => setState(() {
            _selectedTournamentIds.clear();
            _selectedLocations.clear();
            _filterDateRange = null;
          }),
        ),
        if (auth.isSignedIn) ...[
          const SizedBox(height: 12),
          FilterChip(
            selected: _showMyTournaments,
            avatar: const Icon(Icons.person_outline),
            label: Text(_showMyTournaments ? l10n.allTournaments : l10n.myTournaments),
            onSelected: (selected) => setState(() => _showMyTournaments = selected),
          ),
        ],
        const SizedBox(height: 24),
        Text(
          l10n.futureTournaments,
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 8),
        _TournamentFeed(
          tournaments: future,
          emptyText: l10n.noFutureTournaments,
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
          _TournamentFeed(
            tournaments: past,
            emptyText: l10n.noPastTournaments,
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
    return source.where((tournament) {
      final matchesLocation = _selectedLocations.isEmpty || _selectedLocations.contains(_tournamentLocation(tournament));
      final matchesDateRange = _filterDateRange == null || (!tournament.startDate.isBefore(_filterDateRange!.start) && !tournament.endDate.isAfter(_filterDateRange!.end));
      final matchesOrganizer = organizerId == null || tournament.organizerId == organizerId;
      return matchesLocation && matchesDateRange && matchesOrganizer;
    }).toList();
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

String _tournamentLocation(Tournament tournament) =>
    "${tournament.city}${tournament.country?.isNotEmpty ?? false ? ", ${tournament.country}" : ""}";

class _TournamentFilters extends StatelessWidget {
  const _TournamentFilters({
    required this.tournaments,
    required this.selectedTournamentIds,
    required this.selectedLocations,
    required this.filterDateRange,
    required this.onTournamentToggled,
    required this.onLocationToggled,
    required this.onDateRangeChanged,
    required this.onClear,
  });

  final List<Tournament> tournaments;
  final Set<String> selectedTournamentIds;
  final Set<String> selectedLocations;
  final DateTimeRange? filterDateRange;
  final ValueChanged<String> onTournamentToggled;
  final ValueChanged<String> onLocationToggled;
  final ValueChanged<DateTimeRange?> onDateRangeChanged;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final tournamentItems = selectedLocations.isEmpty
        ? tournaments
        : tournaments.where((tournament) => selectedLocations.contains(_tournamentLocation(tournament))).toList();
    final locationItems = selectedTournamentIds.isEmpty
        ? tournaments
        : tournaments.where((tournament) => selectedTournamentIds.contains(tournament.id)).toList();
    final locations = locationItems.map(_tournamentLocation).toSet().toList()..sort();
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Wrap(
          spacing: 16,
          runSpacing: 12,
          crossAxisAlignment: WrapCrossAlignment.start,
          children: [
            _SearchableMultiSelectFilter<Tournament>(
              label: l10n.tournamentFilter,
              items: tournamentItems,
              selectedItems: selectedTournamentIds,
              itemValue: (tournament) => tournament.id,
              itemLabel: (tournament) => tournament.name,
              onToggle: onTournamentToggled,
            ),
            _SearchableMultiSelectFilter<String>(
              label: "Location",
              items: locations,
              selectedItems: selectedLocations,
              itemValue: (location) => location,
              itemLabel: (location) => location,
              onToggle: onLocationToggled,
            ),
            _FilterDateRangeButton(
              value: filterDateRange,
              onChanged: onDateRangeChanged,
            ),
            SizedBox(
              width: 140,
              height: 56,
              child: Center(
                child: TextButton.icon(
                  onPressed: onClear,
                  icon: const Icon(Icons.clear),
                  label: Text(l10n.clearFilters),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SearchableMultiSelectFilter<T> extends StatefulWidget {
  const _SearchableMultiSelectFilter({
    required this.label,
    required this.items,
    required this.selectedItems,
    required this.itemValue,
    required this.itemLabel,
    required this.onToggle,
  });

  final String label;
  final List<T> items;
  final Set<String> selectedItems;
  final String Function(T) itemValue;
  final String Function(T) itemLabel;
  final ValueChanged<String> onToggle;

  @override
  State<_SearchableMultiSelectFilter<T>> createState() =>
      _SearchableMultiSelectFilterState<T>();
}

class _SearchableMultiSelectFilterState<T>
    extends State<_SearchableMultiSelectFilter<T>> {
  final _link = LayerLink();
  OverlayEntry? _overlay;
  String _query = "";

  @override
  void dispose() {
    _close();
    super.dispose();
  }

  void _toggle() => _overlay == null ? _open() : _close();
  void _close() { _overlay?.remove(); _overlay = null; }

  void _open() {
    _query = "";
    _overlay = OverlayEntry(
      builder: (context) {
        final items = widget.items.where((item) => widget.itemLabel(item).toLowerCase().contains(_query.toLowerCase())).toList();
        return Stack(children: [
          Positioned.fill(child: GestureDetector(behavior: HitTestBehavior.translucent, onTap: _close)),
          CompositedTransformFollower(
            link: _link,
            targetAnchor: Alignment.bottomLeft,
            followerAnchor: Alignment.topLeft,
            offset: const Offset(0, 4),
            child: Material(
              elevation: 6,
              child: SizedBox(
                width: 280,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 340),
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    Padding(
                      padding: const EdgeInsets.all(8),
                      child: TextField(
                        autofocus: true,
                        onChanged: (value) { _query = value; _overlay?.markNeedsBuild(); },
                        decoration: InputDecoration(prefixIcon: const Icon(Icons.search), hintText: widget.label),
                      ),
                    ),
                    Flexible(
                      child: ListView(
                        shrinkWrap: true,
                        children: items.map((item) {
                          final value = widget.itemValue(item);
                          return CheckboxListTile(
                            dense: true,
                            controlAffinity: ListTileControlAffinity.leading,
                            value: widget.selectedItems.contains(value),
                            title: Text(widget.itemLabel(item), maxLines: 1, overflow: TextOverflow.ellipsis),
                            onChanged: (_) { widget.onToggle(value); _overlay?.markNeedsBuild(); },
                          );
                        }).toList(),
                      ),
                    ),
                  ]),
                ),
              ),
            ),
          ),
        ]);
      },
    );
    Overlay.of(context, rootOverlay: true).insert(_overlay!);
  }

  @override
  Widget build(BuildContext context) => SizedBox(
    width: 220,
    child: CompositedTransformTarget(
      link: _link,
      child: InkWell(
        onTap: _toggle,
        child: InputDecorator(
          decoration: InputDecoration(labelText: widget.label, border: const OutlineInputBorder(), suffixIcon: const Icon(Icons.arrow_drop_down)),
          child: Text(widget.selectedItems.isEmpty ? AppLocalizations.of(context).all : AppLocalizations.of(context).selectedCount(widget.selectedItems.length)),
        ),
      ),
    ),
  );
}

class _FilterDateRangeButton extends StatelessWidget {
  const _FilterDateRangeButton({required this.value, required this.onChanged});
  final DateTimeRange? value;
  final ValueChanged<DateTimeRange?> onChanged;

  @override
  Widget build(BuildContext context) {
    final label = value == null
        ? "Date range"
        : "${_formatDate(context, value!.start)} – ${_formatDate(context, value!.end)}";
    return SizedBox(
      width: 220,
      height: 56,
      child: InkWell(
        onTap: () async {
          final range = await showDateRangePicker(
            context: context,
            firstDate: DateTime(2000),
            lastDate: DateTime(2100),
            initialDateRange: value,
            builder: (context, child) => Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 640, maxHeight: 720),
                child: child!,
              ),
            ),
          );
          if (range != null) onChanged(range);
        },
        child: InputDecorator(
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            suffixIcon: Icon(Icons.date_range_outlined),
          ),
          child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
        ),
      ),
    );
  }
}

class _TournamentFeed extends StatelessWidget {
  const _TournamentFeed({required this.tournaments, required this.emptyText, required this.canEdit, required this.onEdit, required this.tournamentsWithPlayerSearches, required this.tournamentsWithTeamSearches, this.onDelete});
  final List<Tournament> tournaments;
  final String emptyText;
  final bool canEdit;
  final ValueChanged<Tournament> onEdit;
  final Set<String> tournamentsWithPlayerSearches;
  final Set<String> tournamentsWithTeamSearches;
  final ValueChanged<Tournament>? onDelete;

  @override
  Widget build(BuildContext context) {
    if (tournaments.isEmpty) return Text(emptyText);
    final l10n = AppLocalizations.of(context);
    final auth = context.read<AuthController>();
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: tournaments.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final tournament = tournaments[index];
        final owner = canEdit && auth.userId == tournament.organizerId;
        final website = tournament.websiteUrl;
        final location = "${tournament.city}${tournament.country?.isNotEmpty ?? false ? ", ${tournament.country}" : ""}";
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final date = _TournamentDateBlock(date: tournament.startDate);
                final content = Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(tournament.name, style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 4),
                    Text([if (tournament.club?.isNotEmpty ?? false) tournament.club!, location].join(" · ")),
                    const SizedBox(height: 14),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _TournamentChip(icon: Icons.date_range_outlined, label: "${_formatDate(context, tournament.startDate)} – ${_formatDate(context, tournament.endDate)}"),
                        if (tournament.signupDeadline != null) _TournamentChip(icon: Icons.how_to_reg_outlined, label: "${l10n.signupDeadline}: ${_formatDate(context, tournament.signupDeadline!)}"),
                        if (tournament.entryFee != null) _TournamentChip(icon: Icons.payments_outlined, label: "${tournament.entryFee!.toStringAsFixed(2)} ${tournament.currency ?? ""}"),
                        if (tournament.maxNumberOfTeams != null) _TournamentChip(icon: Icons.groups_outlined, label: "${tournament.maxNumberOfTeams} ${l10n.maxTeams}"),
                        if (tournament.contactInformation?.isNotEmpty ?? false) _TournamentChip(icon: Icons.contact_mail_outlined, label: tournament.contactInformation!),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        if (website != null && website.isNotEmpty) OutlinedButton.icon(onPressed: () => launchUrl(_websiteUri(website)), icon: const Icon(Icons.language_outlined), label: Text(website)),
                        if (tournamentsWithPlayerSearches.contains(tournament.id)) IconButton(tooltip: l10n.playersSearchingForTeams, onPressed: () => context.go("/players", extra: tournament.id), icon: const Icon(Icons.person_search_outlined)),
                        if (tournamentsWithTeamSearches.contains(tournament.id)) IconButton(tooltip: l10n.teamsSearchingForPlayers, onPressed: () => context.go("/players", extra: tournament.id), icon: const Icon(Icons.groups_outlined)),
                        if (owner) IconButton(tooltip: l10n.editTournament, onPressed: () => onEdit(tournament), icon: const Icon(Icons.edit_outlined)),
                        if (owner && onDelete != null) IconButton(tooltip: l10n.deleteTournament, onPressed: () => onDelete!(tournament), icon: const Icon(Icons.delete_outline)),
                      ],
                    ),
                  ],
                );
                return constraints.maxWidth < 620
                    ? Column(crossAxisAlignment: CrossAxisAlignment.start, children: [date, const SizedBox(height: 16), content])
                    : Row(crossAxisAlignment: CrossAxisAlignment.start, children: [date, const SizedBox(width: 20), Expanded(child: content)]);
              },
            ),
          ),
        );
      },
    );
  }
}

class _TournamentDateBlock extends StatelessWidget {
  const _TournamentDateBlock({required this.date});
  final DateTime date;
  @override
  Widget build(BuildContext context) => Container(
    width: 92,
    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
    decoration: BoxDecoration(color: Theme.of(context).colorScheme.primaryContainer, borderRadius: BorderRadius.circular(12)),
    child: Column(mainAxisSize: MainAxisSize.min, children: [
      Text(DateFormat("MMM", Localizations.localeOf(context).languageCode).format(date.toLocal()).toUpperCase()),
      Text(DateFormat("d", Localizations.localeOf(context).languageCode).format(date.toLocal()), style: Theme.of(context).textTheme.headlineMedium),
      Text(DateFormat("y", Localizations.localeOf(context).languageCode).format(date.toLocal())),
    ]),
  );
}

class _TournamentChip extends StatelessWidget {
  const _TournamentChip({required this.icon, required this.label});
  final IconData icon;
  final String label;
  @override
  Widget build(BuildContext context) => Chip(avatar: Icon(icon, size: 18), label: Text(label));
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
  final _selectedRoles = <String>{};
  static const _roles = ["lead", "second", "third", "skip", "any"];

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
                Wrap(
                  spacing: 16,
                  runSpacing: 12,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    _SearchableMultiSelectFilter<Tournament>(
                      label: l10n.tournamentFilter,
                      items: (tournaments.data ?? const <Tournament>[]).where((tournament) => !tournament.endDate.isBefore(DateTime.now())).toList(),
                      selectedItems: _selectedTournamentIds,
                      itemValue: (tournament) => tournament.id,
                      itemLabel: (tournament) => tournament.name,
                      onToggle: (id) => setState(() {
                        if (!_selectedTournamentIds.add(id)) _selectedTournamentIds.remove(id);
                      }),
                    ),
                    _SearchableMultiSelectFilter<String>(
                      label: l10n.role,
                      items: _roles,
                      selectedItems: _selectedRoles,
                      itemValue: (role) => role,
                      itemLabel: (role) => role,
                      onToggle: (role) => setState(() {
                        if (!_selectedRoles.add(role)) _selectedRoles.remove(role);
                      }),
                    ),
                  ],
                ),
                if (_selectedTournamentIds.isNotEmpty || _selectedRoles.isNotEmpty)
                  TextButton.icon(
                    onPressed: () => setState(() { _selectedTournamentIds.clear(); _selectedRoles.clear(); }),
                    icon: const Icon(Icons.clear),
                    label: Text(l10n.clearFilters),
                  ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 12,
                  runSpacing: 8,
                  crossAxisAlignment: WrapCrossAlignment.center,
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
                Wrap(
                  spacing: 12,
                  runSpacing: 8,
                  crossAxisAlignment: WrapCrossAlignment.center,
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
    if (snapshot.hasError) return Text(AppLocalizations.of(context).unableToLoadData);
    if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
    final byId = {for (final tournament in tournaments) tournament.id: tournament};
    final now = DateTime.now();
    final searches = snapshot.data!.where((search) {
      final tournament = byId[search.tournamentId];
      return tournament != null && !tournament.endDate.isBefore(now) && (_selectedTournamentIds.isEmpty || _selectedTournamentIds.contains(search.tournamentId)) && (_selectedRoles.isEmpty || _selectedRoles.contains(search.role));
    }).toList();

    if (searches.isEmpty) return Text(AppLocalizations.of(context).noItems);
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: searches.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (_, index) {
        final search = searches[index];
        return _PlayerSearchCard(
          tournament: byId[search.tournamentId],
          role: search.role,
          contact: search.contact,
          isOwner: context.read<AuthController>().userId == search.ownerId,
          onEdit: () => _editTeamSearch(search),
          onDelete: () => _deleteTeamSearch(search),
        );
      },
    );
  }

  Future<void> _createTeamSearch() async {
    final auth = context.read<AuthController>();
    if (auth.userId == null || auth.email == null) return;
    final tournaments = await context
        .read<TournamentRepository>()
        .watchTournaments()
        .first;
    final upcomingTournaments = tournaments.where((tournament) => !tournament.endDate.isBefore(DateTime.now())).toList();
    if (!mounted) return;
    final result = await showDialog<PlayerTeamSearch>(
      context: context,
      builder: (_) => _PlayerTeamSearchDialog(
        ownerId: auth.userId!,
        contact: auth.email!,
        tournaments: upcomingTournaments,
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
    if (snapshot.hasError) return Text(AppLocalizations.of(context).unableToLoadData);
    if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
    final byId = {for (final tournament in tournaments) tournament.id: tournament};
    final now = DateTime.now();
    final searches = snapshot.data!.where((search) {
      final tournament = byId[search.tournamentId];
      return tournament != null && !tournament.endDate.isBefore(now) && (_selectedTournamentIds.isEmpty || _selectedTournamentIds.contains(search.tournamentId)) && (_selectedRoles.isEmpty || _selectedRoles.contains(search.role));
    }).toList();

    if (searches.isEmpty) return Text(AppLocalizations.of(context).noItems);
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: searches.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (_, index) {
        final search = searches[index];
        return _PlayerSearchCard(
          tournament: byId[search.tournamentId],
          role: search.role,
          contact: search.contact,
          isOwner: context.read<AuthController>().userId == search.ownerId,
          onEdit: () => _editSearch(search),
          onDelete: () => _deleteSearch(search),
        );
      },
    );
  }

  Future<void> _createSearch() async {
    final auth = context.read<AuthController>();
    if (auth.userId == null || auth.email == null) return;
    final tournaments = await context
        .read<TournamentRepository>()
        .watchTournaments()
        .first;
    final upcomingTournaments = tournaments.where((tournament) => !tournament.endDate.isBefore(DateTime.now())).toList();
    if (!mounted) return;
    final result = await showDialog<TeamPlayerSearch>(
      context: context,
      builder: (_) => _TeamSearchDialog(
        ownerId: auth.userId!,
        contact: auth.email!,
        tournaments: upcomingTournaments,
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

class _PlayerSearchCard extends StatelessWidget {
  const _PlayerSearchCard({
    required this.tournament,
    required this.role,
    required this.contact,
    required this.isOwner,
    required this.onEdit,
    required this.onDelete,
  });

  final Tournament? tournament;
  final String role;
  final String contact;
  final bool isOwner;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final event = tournament;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.groups_outlined),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: event == null
                      ? Text(l10n.tournamentUnavailable, style: Theme.of(context).textTheme.titleMedium)
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            TextButton(
                              onPressed: () => context.go("/tournaments", extra: event.id),
                              style: TextButton.styleFrom(
                                padding: EdgeInsets.zero,
                                minimumSize: Size.zero,
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                              child: Text(event.name, style: Theme.of(context).textTheme.titleLarge),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              "${event.city}${event.country?.isNotEmpty ?? false ? ", ${event.country}" : ""} · ${_formatDate(context, event.startDate)} – ${_formatDate(context, event.endDate)}",
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ],
                        ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Chip(avatar: const Icon(Icons.sports_outlined, size: 18), label: Text(role)),
                Chip(avatar: const Icon(Icons.contact_mail_outlined, size: 18), label: SelectableText(contact)),
                if (isOwner) IconButton(tooltip: l10n.editSearch, onPressed: onEdit, icon: const Icon(Icons.edit_outlined)),
                if (isOwner) IconButton(tooltip: l10n.deleteSearch, onPressed: onDelete, icon: const Icon(Icons.delete_outline)),
              ],
            ),
          ],
        ),
      ),
    );
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
    child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
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
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final padding = constraints.maxWidth < 600 ? 16.0 : 32.0;
      final pageAction = titleAction ?? action;
      return ListView(
        padding: EdgeInsets.all(padding),
        children: [
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1200),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: double.infinity,
                    child: Wrap(
                      alignment: WrapAlignment.spaceBetween,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      runSpacing: 16,
                      children: [
                        ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 760),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                            Tooltip(
                              message: AppLocalizations.of(context).home,
                              child: InkWell(
                                onTap: () => context.go('/'),
                                borderRadius: BorderRadius.circular(6),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 4,
                                    vertical: 2,
                                  ),
                                  child: Text(
                                    'CURLING COMPANION',
                                    style: Theme.of(context).textTheme.labelMedium
                                        ?.copyWith(
                                          color: _curlingBlue,
                                          fontWeight: FontWeight.w800,
                                          letterSpacing: 1.2,
                                        ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              title,
                              style: Theme.of(context).textTheme.headlineMedium
                                  ?.copyWith(fontWeight: FontWeight.w700),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              intro,
                              style: Theme.of(context).textTheme.bodyLarge
                                  ?.copyWith(color: _granite),
                            ),
                            ],
                          ),
                        ),
                        _PageHeaderControls(pageAction: pageAction),
                      ],
                    ),
                  ),
                  const SizedBox(height: 28),
                  child,
                ],
              ),
            ),
          ),
        ],
      );
    },
  );
}

class _PageHeaderControls extends StatelessWidget {
  const _PageHeaderControls({this.pageAction});
  final Widget? pageAction;

  @override
  Widget build(BuildContext context) => Wrap(
    spacing: 8,
    runSpacing: 8,
    crossAxisAlignment: WrapCrossAlignment.center,
    children: [
      if (pageAction != null) pageAction!,
      _LanguageMenu(),
      _PageAccountMenu(),
    ],
  );
}

class _PageAccountMenu extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final auth = context.watch<AuthController>();
    if (!auth.isSignedIn) {
      return Wrap(
        spacing: 8,
        children: [
          TextButton(
            onPressed: () => context.go('/login'),
            child: Text(l10n.login),
          ),
          FilledButton(
            onPressed: () => context.go('/register'),
            child: Text(l10n.register),
          ),
        ],
      );
    }
    return PopupMenuButton<String>(
      tooltip: l10n.profile,
      icon: CircleAvatar(
        backgroundColor: Theme.of(context).colorScheme.secondary,
        foregroundColor: Theme.of(context).colorScheme.onSecondary,
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
          child: Text(auth.language == 'de' ? 'Einstellungen' : 'Settings'),
        ),
        PopupMenuItem(value: 'logout', child: Text(l10n.logout)),
      ],
    );
  }
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
