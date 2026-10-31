import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'l10n/app_localizations.dart';

/// Bump when the reviewed declaration changes materially.
const currentPrivacyVersion = '2026-10-31';
const privacyAcknowledgementKey = 'privacy_notice_version';

abstract interface class PrivacyAcknowledgementStore {
  Future<String?> readVersion();
  Future<void> writeVersion(String version);
}

class SharedPreferencesPrivacyStore implements PrivacyAcknowledgementStore {
  @override
  Future<String?> readVersion() async => (await SharedPreferences.getInstance())
      .getString(privacyAcknowledgementKey);

  @override
  Future<void> writeVersion(String version) async {
    final saved = await (await SharedPreferences.getInstance()).setString(
      privacyAcknowledgementKey,
      version,
    );
    if (!saved) throw StateError('Could not save privacy acknowledgement');
  }
}

/// Information acknowledgement only: never grants consent or content access.
class PrivacyNoticeController extends ChangeNotifier {
  PrivacyNoticeController(this.store, {this.version = currentPrivacyVersion}) {
    ready = _load();
  }

  final PrivacyAcknowledgementStore store;
  final String version;
  late final Future<void> ready;
  bool _visible = false;
  bool _dismissed = false;
  bool _disposed = false;
  bool get visible => _visible;

  Future<void> _load() async {
    String? stored;
    try {
      stored = await store.readVersion();
    } catch (_) {
      // Unavailable browser storage must not prevent using the app.
    }
    if (_disposed || _dismissed) return;
    _visible = stored != version;
    notifyListeners();
  }

  Future<void> acknowledge() async {
    if (_disposed || _dismissed) return;
    _dismissed = true;
    _visible = false;
    notifyListeners();
    try {
      await store.writeVersion(version);
    } catch (_) {
      // Dismissed for this session; a later visit can show the notice again.
    }
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}

class PrivacyNotice extends StatelessWidget {
  const PrivacyNotice({
    super.key,
    required this.onRead,
    required this.onUnderstood,
  });
  final VoidCallback onRead;
  final VoidCallback onUnderstood;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Material(
      elevation: 4,
      color: Theme.of(context).colorScheme.surfaceContainerHigh,
      child: SafeArea(
        top: false,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.sizeOf(context).height * .35,
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Semantics(
                  header: true,
                  child: Text(
                    l10n.privacyTitle,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                const SizedBox(height: 4),
                Text(l10n.privacyNoticeMessage),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 12,
                  runSpacing: 8,
                  children: [
                    TextButton(
                      onPressed: onRead,
                      child: Text(l10n.privacyRead),
                    ),
                    FilledButton(
                      onPressed: onUnderstood,
                      child: Text(l10n.privacyUnderstood),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class PrivacyDeclarationContent extends StatelessWidget {
  const PrivacyDeclarationContent({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final sections = [
      (l10n.privacyControllerTitle, l10n.privacyControllerBody),
      (l10n.privacyServicesTitle, l10n.privacyServicesBody),
      (l10n.privacyAuthTitle, l10n.privacyAuthBody),
      (l10n.privacyPublicTitle, l10n.privacyPublicBody),
      (l10n.privacyBrowserTitle, l10n.privacyBrowserBody),
      (l10n.privacyHeartbeatTitle, l10n.privacyHeartbeatBody),
      (l10n.privacyTransfersTitle, l10n.privacyTransfersBody),
      (l10n.privacyRetentionTitle, l10n.privacyRetentionBody),
      (l10n.privacyRightsTitle, l10n.privacyRightsBody),
    ];
    return SelectionArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.privacyDraft,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 12),
          Text('${l10n.privacyVersion}: $currentPrivacyVersion'),
          for (final (title, body) in sections) ...[
            const SizedBox(height: 24),
            Text(title, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(body),
          ],
        ],
      ),
    );
  }
}
