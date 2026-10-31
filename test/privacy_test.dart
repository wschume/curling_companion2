import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:curling_companion/l10n/app_localizations.dart';
import 'package:curling_companion/main.dart';
import 'package:curling_companion/privacy.dart';
import 'package:curling_companion/services/services.dart';

class TestPrivacyStore implements PrivacyAcknowledgementStore {
  TestPrivacyStore({
    this.version,
    this.failRead = false,
    this.failWrite = false,
  });
  String? version;
  bool failRead;
  bool failWrite;
  int writes = 0;

  @override
  Future<String?> readVersion() async {
    if (failRead) throw StateError('Storage unavailable');
    return version;
  }

  @override
  Future<void> writeVersion(String value) async {
    writes++;
    if (failWrite) throw StateError('Storage full');
    version = value;
  }
}

Widget privacyApp(TestPrivacyStore store, {String route = '/'}) =>
    CurlingCompanionApp(
      auth: LocalAuthService(),
      marketplace: MemoryMarketplaceRepository(),
      tournaments: MemoryTournamentRepository(),
      players: MemoryPlayerRepository(),
      privacyStore: store,
      initialLocation: route,
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'acknowledgement persists only the current version and reloads',
    () async {
      SharedPreferences.setMockInitialValues({});
      final store = SharedPreferencesPrivacyStore();
      final controller = PrivacyNoticeController(store);
      await controller.ready;
      expect(controller.visible, isTrue);
      await controller.acknowledge();
      expect(controller.visible, isFalse);
      expect((await SharedPreferences.getInstance()).getKeys(), {
        privacyAcknowledgementKey,
      });
      final reloaded = PrivacyNoticeController(store);
      await reloaded.ready;
      expect(reloaded.visible, isFalse);
      final changed = PrivacyNoticeController(store, version: 'next-version');
      await changed.ready;
      expect(changed.visible, isTrue);
      await (await SharedPreferences.getInstance()).clear();
      final cleared = PrivacyNoticeController(store);
      await cleared.ready;
      expect(cleared.visible, isTrue);
      for (final value in [controller, reloaded, changed, cleared]) {
        value.dispose();
      }
    },
  );

  test(
    'failed storage permits session dismissal and redisplays next visit',
    () async {
      final store = TestPrivacyStore(failRead: true, failWrite: true);
      final controller = PrivacyNoticeController(store);
      await controller.ready;
      expect(controller.visible, isTrue);
      await controller.acknowledge();
      expect(controller.visible, isFalse);
      final next = PrivacyNoticeController(store);
      await next.ready;
      expect(next.visible, isTrue);
      controller.dispose();
      next.dispose();
    },
  );

  test(
    'late storage load cannot undo dismissal or notify after disposal',
    () async {
      final store = _DelayedPrivacyStore();
      final controller = PrivacyNoticeController(store);
      await controller.acknowledge();
      controller.dispose();
      store.result.complete(null);
      await controller.ready;
      expect(controller.visible, isFalse);
    },
  );

  for (final route in ['/', '/login', '/register', '/verify-email']) {
    testWidgets('notice is informational on $route', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1100, 1000));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final store = TestPrivacyStore();
      await tester.pumpWidget(privacyApp(store, route: route));
      await tester.pumpAndSettle();
      expect(find.text('Understood'), findsOneWidget);
      expect(find.byType(AlertDialog), findsNothing);
      await tester.tap(find.text('Understood'));
      await tester.pumpAndSettle();
      expect(find.byType(PrivacyNotice), findsNothing);
      expect(store.version, currentPrivacyVersion);
      expect(store.writes, 1);
    });
  }

  for (final language in ['en', 'de']) {
    testWidgets('public privacy page, mobile links and text in $language', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(390, 844));
      tester.binding.platformDispatcher.localeTestValue = Locale(language);
      addTearDown(() {
        tester.binding.setSurfaceSize(null);
        tester.binding.platformDispatcher.clearLocaleTestValue();
      });
      final store = TestPrivacyStore();
      await tester.pumpWidget(privacyApp(store, route: '/privacy'));
      await tester.pumpAndSettle();
      expect(find.byType(PrivacyDeclarationContent), findsOneWidget);
      expect(find.byType(PrivacyNotice), findsNothing);
      expect(
        find.text(
          language == 'en'
              ? 'Controller and contact'
              : 'Verantwortlicher und Kontakt',
        ),
        findsOneWidget,
      );
      expect(
        find.widgetWithText(
          TextButton,
          language == 'en' ? 'Privacy' : 'Datenschutz',
        ),
        findsOneWidget,
      );
      expect(
        find.widgetWithText(
          TextButton,
          language == 'en' ? 'Legal notice' : 'Impressum',
        ),
        findsOneWidget,
      );
      expect(find.byType(Checkbox), findsNothing);
      expect(store.writes, 0);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('switching locale translates the page without acknowledgement', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final store = TestPrivacyStore();
    await tester.pumpWidget(privacyApp(store, route: '/privacy'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Language'));
    await tester.pumpAndSettle();
    await tester.tap(
      find.widgetWithText(CheckedPopupMenuItem<Locale>, 'Deutsch'),
    );
    await tester.pumpAndSettle();
    expect(find.text('Verantwortlicher und Kontakt'), findsOneWidget);
    expect(store.writes, 0);
    expect(tester.takeException(), isNull);
  });

  for (final language in ['en', 'de']) {
    testWidgets('narrow first-visit notice fits enlarged text in $language', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(320, 700));
      tester.binding.platformDispatcher.localeTestValue = Locale(language);
      addTearDown(() {
        tester.binding.setSurfaceSize(null);
        tester.binding.platformDispatcher.clearLocaleTestValue();
      });
      final store = TestPrivacyStore();
      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(
            size: Size(320, 700),
            textScaler: TextScaler.linear(2),
          ),
          child: privacyApp(store),
        ),
      );
      await tester.pumpAndSettle();
      final button = find.widgetWithText(
        FilledButton,
        language == 'en' ? 'Understood' : 'Verstanden',
      );
      await tester.ensureVisible(button);
      await tester.tap(button);
      await tester.pumpAndSettle();
      expect(store.version, currentPrivacyVersion);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('reading notice preserves form input and does not acknowledge', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(800, 1100));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final store = TestPrivacyStore();
    await tester.pumpWidget(privacyApp(store, route: '/register'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byType(TextFormField).first,
      'user@example.com',
    );
    await tester.tap(find.text('Read privacy declaration'));
    await tester.pumpAndSettle();
    expect(find.byType(PrivacyDeclarationContent), findsOneWidget);
    expect(find.byType(PrivacyNotice), findsNothing);
    expect(store.writes, 0);
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    expect(find.text('user@example.com'), findsOneWidget);
    expect(find.byType(PrivacyNotice), findsOneWidget);
    expect(tester.widget<Checkbox>(find.byType(Checkbox)).value, isFalse);
    expect(store.writes, 0);
  });

  testWidgets('desktop privacy link is immediately above Impressum', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1200, 1000));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      privacyApp(TestPrivacyStore(version: currentPrivacyVersion)),
    );
    await tester.pumpAndSettle();
    final privacy = find.descendant(
      of: find.byType(NavigationRail),
      matching: find.widgetWithText(TextButton, 'Privacy'),
    );
    final legal = find.descendant(
      of: find.byType(NavigationRail),
      matching: find.widgetWithText(TextButton, 'Legal notice'),
    );
    expect(privacy, findsOneWidget);
    expect(legal, findsOneWidget);
    expect(tester.getCenter(privacy).dy, lessThan(tester.getCenter(legal).dy));
    await tester.tap(privacy);
    await tester.pumpAndSettle();
    expect(find.byType(PrivacyDeclarationContent), findsOneWidget);
  });

  for (final route in ['/login', '/register', '/verify-email']) {
    testWidgets('permanent privacy link is available on $route', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(800, 1000));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final store = TestPrivacyStore(version: currentPrivacyVersion);
      await tester.pumpWidget(privacyApp(store, route: route));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(TextButton, 'Privacy'));
      await tester.pumpAndSettle();
      expect(find.byType(PrivacyDeclarationContent), findsOneWidget);
      expect(store.writes, 0);
    });
  }

  testWidgets('notice actions support keyboard and screen-reader labels', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();

    var reads = 0;
    var dismissals = 0;
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: Scaffold(
          body: PrivacyNotice(
            onRead: () => reads++,
            onUnderstood: () => dismissals++,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.bySemanticsLabel('Read privacy declaration'), findsOneWidget);
    expect(find.bySemanticsLabel('Understood'), findsOneWidget);
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pump();
    expect(reads, 1);
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pump();
    expect(dismissals, 1);
    semantics.dispose();
  });

  test('review snapshots match the localized declaration', () {
    for (final language in ['en', 'de']) {
      final arb =
          jsonDecode(File('lib/l10n/app_$language.arb').readAsStringSync())
              as Map<String, dynamic>;
      final snapshot = File(
        'docs/privacy/$currentPrivacyVersion.$language.md',
      ).readAsStringSync();
      expect(snapshot, contains(arb['privacyDraft']));
      for (final entry in arb.entries.where(
        (entry) =>
            entry.key.startsWith('privacy') && entry.key.endsWith('Body'),
      )) {
        expect(snapshot, contains(entry.value));
      }
    }
  });
}

class _DelayedPrivacyStore extends TestPrivacyStore {
  final result = Completer<String?>();
  @override
  Future<String?> readVersion() => result.future;
}
