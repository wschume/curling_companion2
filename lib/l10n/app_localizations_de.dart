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
  String get name => 'Name';

  @override
  String get location => 'Ort';

  @override
  String get currency => 'Währung';

  @override
  String get contactHint => 'E-Mail-Adresse oder Telefonnummer';

  @override
  String get invalidContact =>
      'Gib eine gültige E-Mail-Adresse oder Telefonnummer ein.';

  @override
  String get invalidDateOrder =>
      'Die Reihenfolge muss Anmeldeschluss < Startdatum < Enddatum sein.';

  @override
  String get durationTooLong => 'Ein Turnier darf höchstens 5 Tage dauern.';

  @override
  String get showPastTournaments => 'Vergangene Turniere anzeigen';

  @override
  String get hidePastTournaments => 'Vergangene Turniere ausblenden';

  @override
  String get myTournaments => 'Meine Turniere';

  @override
  String get allTournaments => 'Alle Turniere';

  @override
  String get futureTournaments => 'Kommende Turniere';

  @override
  String get pastTournaments => 'Vergangene Turniere';

  @override
  String get startDate => 'Startdatum';

  @override
  String get endDate => 'Enddatum';

  @override
  String get signupDeadline => 'Anmeldeschluss';

  @override
  String get club => 'Verein';

  @override
  String get city => 'Stadt';

  @override
  String get country => 'Land';

  @override
  String get entryFee => 'Startgebühr';

  @override
  String get maxTeams => 'Max. Teams';

  @override
  String get website => 'Webseite';

  @override
  String get contact => 'Kontakt';

  @override
  String get filters => 'Filter';

  @override
  String get filterByName => 'Nach Name filtern';

  @override
  String get filterByLocation => 'Nach Ort filtern';

  @override
  String get filterStartDate => 'Startdatum filtern';

  @override
  String get filterEndDate => 'Enddatum filtern';

  @override
  String get clearFilters => 'Filter löschen';

  @override
  String get createTournament => 'Turnier erstellen';

  @override
  String get editTournament => 'Turnier bearbeiten';

  @override
  String get deleteTournament => 'Turnier löschen';

  @override
  String get confirmDeleteTournament => 'Dieses Turnier löschen?';

  @override
  String get confirmDeleteTournamentMessage =>
      'Diese Aktion kann nicht rückgängig gemacht werden.';

  @override
  String get saveTournament => 'Turnier speichern';

  @override
  String get tournamentSaved => 'Turnier gespeichert.';

  @override
  String get tournamentDeleted => 'Turnier gelöscht.';

  @override
  String get tournamentDeleteError =>
      'Das Turnier konnte nicht gelöscht werden. Bitte versuche es erneut.';

  @override
  String get invalidWebsite => 'Gib eine gültige Webseiten-URL ein.';

  @override
  String get invalidNumber => 'Gib eine gültige Zahl ein.';

  @override
  String get noFutureTournaments =>
      'Keine kommenden Turniere passen zu den Filtern.';

  @override
  String get noPastTournaments =>
      'Keine vergangenen Turniere passen zu den Filtereinstellungen.';

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
  String get joinEvent => 'Teilnehmen';

  @override
  String get edit => 'Bearbeiten';

  @override
  String get price => 'Preis';

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

  @override
  String get profileSettings => 'Profileinstellungen';

  @override
  String get newPassword => 'Neues Passwort';

  @override
  String get telephone => 'Telefon';

  @override
  String get deleteAccount => 'Konto löschen';

  @override
  String get confirmDeleteAccount => 'Konto löschen?';

  @override
  String get accountDeleteBlocked =>
      'Entferne alle deine Turniere und Marktplatzanzeigen, bevor du dein Konto löschst.';

  @override
  String get accountDeletedError => 'Konto konnte nicht gelöscht werden.';

  @override
  String get settingsUpdateError =>
      'Einstellungen konnten nicht gespeichert werden.';

  @override
  String get passwordsDoNotMatch => 'Die Passwörter stimmen nicht überein.';

  @override
  String get english => 'Englisch';

  @override
  String get german => 'Deutsch';

  @override
  String get teamsLookingForPlayers => 'Teams suchen Spieler.';

  @override
  String get tournamentFilter => 'Turniere';

  @override
  String get all => 'Alle';

  @override
  String selectedCount(int count) {
    return '$count ausgewählt';
  }

  @override
  String get teamsSearchingForPlayers => 'Teams suchen Spieler';

  @override
  String get playersSearchingForTeams => 'Spieler suchen Teams';

  @override
  String get createPlayerSearch => 'Spielersuche erstellen';

  @override
  String get createTeamSearch => 'Teamsuche erstellen';

  @override
  String get editPlayerSearch => 'Spielersuche bearbeiten';

  @override
  String get editTeamSearch => 'Teamsuche bearbeiten';

  @override
  String get deletePlayerSearch => 'Spielersuche löschen?';

  @override
  String get deleteTeamSearch => 'Teamsuche löschen?';

  @override
  String get tournament => 'Turnier';

  @override
  String get role => 'Position';

  @override
  String get tournamentUnavailable => 'Turnier nicht verfügbar';

  @override
  String get editSearch => 'Suche bearbeiten';

  @override
  String get deleteSearch => 'Suche löschen';

  @override
  String get createSearch => 'Suche erstellen';

  @override
  String get saveChanges => 'Änderungen speichern';

  @override
  String get unableToLoadData => 'Daten konnten nicht geladen werden.';

  @override
  String get category => 'Kategorie';

  @override
  String get allCategories => 'Alle Kategorien';

  @override
  String get shoes => 'Schuhe';

  @override
  String get stones => 'Curlingsteine';

  @override
  String get brooms => 'Besen';

  @override
  String get other => 'Sonstiges';

  @override
  String get title => 'Titel';

  @override
  String get description => 'Beschreibung';

  @override
  String get viewDetails => 'Details anzeigen';

  @override
  String get emailSeller => 'Verkäufer kontaktieren';

  @override
  String get callSeller => 'Verkäufer anrufen';

  @override
  String get seller => 'Verkäufer';

  @override
  String get close => 'Schließen';

  @override
  String get editListing => 'Anzeige bearbeiten';

  @override
  String get deleteListing => 'Anzeige löschen?';

  @override
  String get deleteListingMessage =>
      'Diese Aktion kann nicht rückgängig gemacht werden.';

  @override
  String get sellerEmailOrPhone => 'E-Mail oder Telefon des Verkäufers';

  @override
  String get addImages => 'Bilder hinzufügen';

  @override
  String get optionalMultipleImages =>
      'Optional. Du kannst mehrere Bilder anhängen.';

  @override
  String get image => 'Bild';

  @override
  String get uploadingImages => 'Bilder werden hochgeladen…';

  @override
  String get enterValidPrice => 'Gib einen gültigen Preis ein.';

  @override
  String get imageUploadsRequireFirebase =>
      'Für Bilduploads ist eine Firebase-Konfiguration erforderlich.';

  @override
  String get imageUploadFailed =>
      'Ein oder mehrere Bilder konnten nicht hochgeladen werden. Bitte versuche es erneut.';

  @override
  String get verifyEmail => 'E-Mail bestätigen';

  @override
  String get verificationRequired =>
      'Bestätige deine E-Mail-Adresse, um Inhalte zu erstellen oder zu bearbeiten.';

  @override
  String get verificationInstructions =>
      'Öffne den Bestätigungslink in deiner E-Mail und prüfe danach hier deinen Status. Du kannst weiterhin Inhalte ansehen und dein Konto verwalten.';

  @override
  String get verificationSent =>
      'Bestätigungs-E-Mail gesendet. Prüfe deinen Posteingang und Spam-Ordner.';

  @override
  String get verificationSendError =>
      'Die Bestätigungs-E-Mail konnte nicht gesendet werden. Versuche es erneut. Dein Konto wurde bereits erstellt.';

  @override
  String get verificationRefreshError =>
      'Der Bestätigungsstatus konnte nicht geprüft werden. Versuche es erneut.';

  @override
  String get verificationPending =>
      'Deine E-Mail-Adresse ist noch nicht bestätigt. Öffne den Link in der E-Mail und prüfe erneut.';

  @override
  String get verificationComplete => 'Deine E-Mail-Adresse ist bestätigt.';

  @override
  String get verificationCheck => 'Ich habe meine E-Mail bestätigt';

  @override
  String get verificationResend => 'Bestätigungs-E-Mail erneut senden';

  @override
  String get verificationWait =>
      'Bitte warte 60 Sekunden, bevor du eine weitere E-Mail sendest.';

  @override
  String get verificationSimulate => 'Bestätigung simulieren (lokale Demo)';

  @override
  String get emailChangePending =>
      'Prüfe deine neue E-Mail-Adresse auf einen Bestätigungslink. Bis zur Bestätigung bleibt deine bisherige Adresse aktiv.';

  @override
  String get legalNotice => 'Impressum';

  @override
  String get legalContact => 'Kontakt:';

  @override
  String get legalPhone => 'Telefon: 0152 2563 5091';

  @override
  String get legalResponsible =>
      'Inhaltlich Verantwortlicher:\nFlorin Zepernick (Kontakt s. o.)';

  @override
  String get usageTermsTitle => 'Nutzungsbedingungen';

  @override
  String get usageTermsIntro =>
      'Jede Nutzung der Webseite in einer Weise, die gegen ein oder mehrere Gesetze der Bundesrepublik Deutschland verstößt, ist untersagt. Insbesondere sind verboten:';

  @override
  String get usageTermsProhibitions =>
      'Obszöne, grobe oder gewalttätige Beiträge\nFalsche oder irreführende Inhalte\nVerstöße gegen das Gesetz\nSpamming oder Scamming des Dienstes oder anderer Nutzer\nHacking oder Manipulation Ihrer Website oder App\nVerstöße gegen das Urheberrecht\nBelästigung anderer Nutzer\nStalking anderer Nutzer';

  @override
  String get usageTermsAcceptance =>
      'Mit der Nutzung der Webseite erkennen Sie diese Regeln an.';

  @override
  String get usageTermsLiability =>
      'Der Betreiber der Webseite schließt jede Haftung für durch die Nutzung der Seite entstandene Schäden oder Unannehmlichkeiten aus. Beispielsweise ist die Haftung für verloren gegangene Daten ausgeschlossen.';

  @override
  String get termsAcceptLabel => 'Ich akzeptiere die Nutzungsbedingungen.';

  @override
  String get termsRead => 'Nutzungsbedingungen lesen';

  @override
  String get termsClose => 'Schließen';

  @override
  String get termsRequired =>
      'Akzeptiere die Nutzungsbedingungen, bevor du Inhalte erstellst oder bearbeitest.';

  @override
  String get termsSaveError =>
      'Dein Konto wurde erstellt, aber deine Zustimmung konnte nicht gespeichert werden. Versuche erneut, deine Zustimmung zu speichern.';

  @override
  String get acceptTermsAction => 'Nutzungsbedingungen akzeptieren';

  @override
  String get tournamentAlreadyExists =>
      'In dieser Stadt existiert bereits ein Turnier mit diesem Startdatum.';

  @override
  String get tournamentDuplicateCheckFailed =>
      'Vorhandene Turniere konnten nicht geprüft werden. Bitte versuche es erneut.';

  @override
  String get privacyTitle => 'Datenschutz';

  @override
  String get privacyRead => 'Datenschutzerklärung lesen';

  @override
  String get privacyUnderstood => 'Verstanden';

  @override
  String get privacyNoticeMessage =>
      'Wir verwenden Firebase, um diese Webseite bereitzustellen und Anmeldesitzungen aufrechtzuerhalten. Unsere Datenschutzerklärung erläutert die Datenverarbeitung. „Verstanden“ blendet nur diesen Hinweis aus und erteilt keine Einwilligung.';

  @override
  String get privacyVersion => 'Version';

  @override
  String get privacyControllerTitle => 'Verantwortlicher und Kontakt';

  @override
  String get privacyControllerBody =>
      'Florin Zepernick, Holbeinstr. 17a, 12203 Berlin, Deutschland. E-Mail: webmaster@curlingcompanion.org. Telefon: 0152 2563 5091. Bitte nutze diese Kontaktdaten bei Fragen zu deinen personenbezogenen Daten oder zur Ausübung deiner Rechte.';

  @override
  String get privacyServicesTitle =>
      'Betrieb der Webseite und Firebase-Dienste';

  @override
  String get privacyServicesBody =>
      'Diese Webseite verwendet Google Firebase Hosting zur Auslieferung der Seiten, Firebase Authentication für Konten und Anmeldung, Cloud Firestore für Profile und gemeinschaftliche Inhalte, Cloud Storage für hochgeladene Marktplatzbilder sowie Cloud Functions zur Verarbeitung und Verwaltung von Bilduploads. Bei Anfragen an diese Dienste erhält Google technische Verbindungsinformationen, einschließlich IP-Adressen und Anfrage-/Browserinformationen. Firebase Hosting und die Dienstinfrastruktur können Protokolldaten für Betrieb, Sicherheit und Missbrauchsprävention verarbeiten. Firebase wird beim Öffnen der Webseite initialisiert; der Informationshinweis verhindert diese Anfragen nicht.';

  @override
  String get privacyAuthTitle => 'Registrierung und Kontodaten';

  @override
  String get privacyAuthBody =>
      'Für Registrierung und Anmeldung verarbeitet Firebase Authentication deine E-Mail-Adresse, dein Passwort, deine Nutzer-ID und deinen Verifizierungsstatus sowie technische Informationen zur Authentifizierung von Anfragen und zur Missbrauchsprävention. Dein Passwort wird zur Authentifizierung an Firebase übertragen; die App speichert es nicht als Sitzungsdatum im Browser. Profileinstellungen können eine Telefonnummer und die bevorzugte Sprache enthalten. Außerdem speichern wir deine Zustimmung zu den aktuellen Nutzungsbedingungen mit deren Version, Serverzeitstempel und gewählter Sprache. Die Kenntnisnahme dieses Datenschutzhinweises ist von der Zustimmung zu den Nutzungsbedingungen getrennt.';

  @override
  String get privacyPublicTitle => 'Öffentliche Inhalte und Bilder';

  @override
  String get privacyPublicBody =>
      'Turnierinformationen, Marktplatzangebote, Spielerverfügbarkeiten und Team-/Spielergesuche sind öffentlich lesbar. Je nach deinen Angaben gehören dazu Namen, Orte, Kontaktdaten, Beschreibungen und hochgeladene Bilder. Inhaltsdatensätze enthalten auch die zugehörige Veranstalter- oder Eigentümer-Nutzer-ID. Marktplatzbilder sind über ihre Downloadlinks zugänglich. Veröffentliche keine Informationen, die Besucher nicht sehen sollen. Hochgeladene Bilddateien werden in Cloud Storage gespeichert; Cloud Functions erhält Bilddaten und Dateiinformationen zur Verarbeitung von Uploads, nutzerbezogenen Speicherpfaden und Speicherquoten.';

  @override
  String get privacyBrowserTitle => 'Speicherung in deinem Browser';

  @override
  String get privacyBrowserBody =>
      'Firebase Authentication kann Kontoinformationen wie E-Mail-Adresse und Nutzer-ID sowie Authentifizierungstoken im Browserspeicher aufbewahren, damit du nach dem Neuladen oder bei einem späteren Besuch angemeldet bleibst. Die Abmeldung entfernt den aktiven Firebase-Anmeldestatus in diesem Browser. Die App speichert die zur Kenntnis genommene Datenschutzversion unter privacy_notice_version lokal im Browser, ausschließlich um den Hinweis nicht wiederholt anzuzeigen. Dieser Wert enthält keine Nutzer-ID und wird nicht an unsere Datenbank gesendet. Er bleibt bestehen, bis er durch eine weitere Kenntnisnahme ersetzt oder über die Browsereinstellungen entfernt wird. Bei einer wesentlichen Aktualisierung der Erklärung erscheint der Hinweis erneut. Ist der Speicher nicht verfügbar, gilt das Ausblenden nur für die aktuelle App-Sitzung. Das Löschen von Browserdaten kann dich abmelden und lässt den Hinweis erneut erscheinen.';

  @override
  String get privacyHeartbeatTitle =>
      'SDK-Heartbeat und technische Informationen';

  @override
  String get privacyHeartbeatBody =>
      'Das Firebase-Web-SDK kann technische Heartbeat-Informationen in IndexedDB speichern, darunter Datumsangaben und Firebase-SDK-/Plattformversionen, und sie an Anfragen an Google anhängen. Authentifizierungsanfragen können zusätzlich die Firebase-App-ID enthalten. Diese App-ID bezeichnet die Firebase-Anwendung, nicht dein persönliches Nutzerkonto. Dieser technische Mechanismus ist von Google Analytics zu unterscheiden. Die App bindet weder Google Analytics noch Werbetracking ein. Der Heartbeat-Mechanismus wird nicht durch den Button „Verstanden“ gesteuert.';

  @override
  String get privacyTransfersTitle =>
      'Empfänger und internationale Verarbeitung';

  @override
  String get privacyTransfersBody =>
      'Google verarbeitet Informationen als Anbieter der von dieser Webseite genutzten Firebase-Dienste. Der Webseitenbetreiber bestimmt über die an diese Dienste übermittelten Daten. Die Verarbeitung kann Google-Unternehmen und Unterauftragsverarbeiter außerhalb Deutschlands und des Europäischen Wirtschaftsraums einbeziehen, einschließlich in den USA. Google erläutert seine Verarbeitungsbedingungen, Unterauftragsverarbeiter und Schutzmechanismen für internationale Übermittlungen in seiner Firebase-Datenschutz- und Sicherheitsdokumentation. Öffentliche Inhalte sind außerdem für Besucher weltweit zugänglich. Beim Öffnen externer Links wird eine Verbindung zum jeweiligen externen Anbieter hergestellt.';

  @override
  String get privacyRetentionTitle => 'Speicherdauer und Löschung';

  @override
  String get privacyRetentionBody =>
      'Kontodaten bleiben bis zur Kontolöschung in Firebase Authentication gespeichert; Google kann Dienstprotokolle und Sicherungsdaten für zusätzliche dienstspezifische Zeiträume aufbewahren. Die Webseite erlaubt die Kontolöschung erst, nachdem deine Turniere und Marktplatzangebote entfernt wurden. Die Kontolöschung entfernt das Authentication-Konto; sie löscht nicht automatisch Profildokumente, Zustimmungsnachweise zu Nutzungsbedingungen, Spieler-/Teamgesuche oder sämtliche zuvor hochgeladenen Dateien. Das Entfernen eines Inhaltsdatensatzes garantiert allein keine Löschung zugehöriger gespeicherter Bilder. Wende dich wegen der Entfernung verbleibender personenbezogener Daten an den Betreiber. Browserdaten kannst du unabhängig davon über deine Browsereinstellungen entfernen.';

  @override
  String get privacyRightsTitle => 'Deine Rechte und Beschwerden';

  @override
  String get privacyRightsBody =>
      'Unter den jeweils geltenden gesetzlichen Voraussetzungen kannst du Auskunft, Berichtigung oder Löschung deiner personenbezogenen Daten, Einschränkung der Verarbeitung sowie Datenübertragbarkeit verlangen. Gegen eine auf berechtigte Interessen gestützte Verarbeitung kannst du Widerspruch einlegen. Beruht eine Verarbeitung auf Einwilligung, kannst du diese für die Zukunft widerrufen, ohne dass die Rechtmäßigkeit der bisherigen Verarbeitung berührt wird. Der Button „Verstanden“ auf dieser Webseite erteilt keine solche Einwilligung. Wende dich über die oben genannten Kontaktdaten an den Verantwortlichen. Du kannst dich bei einer zuständigen Datenschutzaufsichtsbehörde beschweren, einschließlich der Berliner Beauftragten für Datenschutz und Informationsfreiheit.';

  @override
  String get dateRange => 'Zeitraum';

  @override
  String get roleAny => 'beliebig';

  @override
  String get countryGermany => 'Deutschland';

  @override
  String get forgotPassword => 'Passwort vergessen?';

  @override
  String get sendResetLink => 'Link senden';

  @override
  String get resetSent =>
      'Falls ein Konto mit dieser E-Mail-Adresse existiert, erhältst du einen Link zum Zurücksetzen des Passworts.';

  @override
  String get resetNetworkError =>
      'Prüfe deine Verbindung und versuche es erneut.';

  @override
  String get resetRateError =>
      'Zu viele Anfragen. Bitte versuche es später erneut.';

  @override
  String get resetError =>
      'Der Link konnte nicht angefordert werden. Bitte versuche es erneut.';

  @override
  String get resetClose => 'Schließen';

  @override
  String get resetCancel => 'Abbrechen';

  @override
  String get additionalInformationOptional =>
      'Zusätzliche Informationen (optional)';

  @override
  String get contentActionFailed =>
      'Der Eintrag konnte nicht gespeichert oder gelöscht werden. Bitte versuche es erneut.';

  @override
  String get buyMeACoffee => 'Spendiere mir einen Kaffee';

  @override
  String get donationLinkFailed =>
      'Die Spendenseite konnte nicht geöffnet werden. Bitte versuche es erneut.';
}
