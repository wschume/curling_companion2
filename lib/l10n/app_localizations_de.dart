// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for German (`de`).
class AppLocalizationsDe extends AppLocalizations {
  AppLocalizationsDe([String locale = 'de']) : super(locale);

  @override
  String get appTitle => 'Curling Companion';

  @override
  String get home => 'Startseite';

  @override
  String get marketplace => 'Marktplatz';

  @override
  String get tournaments => 'Turniere';

  @override
  String get players => 'Spieler finden';

  @override
  String get login => 'Anmelden';

  @override
  String get register => 'Registrieren';

  @override
  String get logout => 'Abmelden';

  @override
  String get email => 'E-Mail';

  @override
  String get password => 'Passwort';

  @override
  String get confirmPassword => 'Passwort bestätigen';

  @override
  String get submit => 'Speichern';

  @override
  String get cancel => 'Abbrechen';

  @override
  String get welcome => 'Willkommen bei Curling Companion';

  @override
  String get publicIntro =>
      'Entdecke Curling-Turniere, finde Mitspieler und Ausrüstung.';

  @override
  String signedInAs(String email) {
    return 'Angemeldet als $email';
  }

  @override
  String get marketplaceIntro =>
      'Kaufe und verkaufe Curling-Ausrüstung in der Community.';

  @override
  String get tournamentsIntro =>
      'Entdecke kommende und vergangene Curling-Turniere.';

  @override
  String get playersIntro => 'Finde Mitspieler für ein bestimmtes Turnier.';

  @override
  String get upcoming => 'Kommend';

  @override
  String get past => 'Vergangen';

  @override
  String get noItems => 'Noch keine Einträge vorhanden.';

  @override
  String get loginToEdit => 'Zum Bearbeiten anmelden';

  @override
  String get loginToEditMessage =>
      'Du kannst diese Seite ohne Konto ansehen. Zum Erstellen oder Bearbeiten bitte anmelden.';

  @override
  String get createListing => 'Anzeige erstellen';

  @override
  String get createTournament => 'Turnier erstellen';

  @override
  String get joinEvent => 'Teilnehmen';

  @override
  String get edit => 'Bearbeiten';

  @override
  String get price => 'Preis';

  @override
  String get location => 'Ort';

  @override
  String get date => 'Datum';

  @override
  String get participants => 'Teilnehmer';

  @override
  String get requiredField => 'Dieses Feld ist erforderlich.';

  @override
  String get invalidEmail => 'Gib eine gültige E-Mail-Adresse ein.';

  @override
  String get passwordTooShort =>
      'Das Passwort muss mindestens 6 Zeichen enthalten.';

  @override
  String get passwordMismatch => 'Die Passwörter stimmen nicht überein.';

  @override
  String get authError =>
      'Anmeldung fehlgeschlagen. Bitte prüfe deine Angaben.';

  @override
  String authErrorCode(String code) {
    return 'Anmeldung fehlgeschlagen ($code).';
  }

  @override
  String get language => 'Sprache';

  @override
  String get profile => 'Profil';

  @override
  String get settingsComingSoon => 'Einstellungen folgen später';
}
