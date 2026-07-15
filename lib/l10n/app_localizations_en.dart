// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Curling Companion';

  @override
  String get home => 'Home';

  @override
  String get marketplace => 'Marketplace';

  @override
  String get tournaments => 'Tournaments';

  @override
  String get players => 'Find Players';

  @override
  String get login => 'Log in';

  @override
  String get register => 'Register';

  @override
  String get logout => 'Log out';

  @override
  String get email => 'Email';

  @override
  String get password => 'Password';

  @override
  String get confirmPassword => 'Confirm password';

  @override
  String get submit => 'Submit';

  @override
  String get cancel => 'Cancel';

  @override
  String get welcome => 'Welcome to Curling Companion';

  @override
  String get publicIntro =>
      'Browse curling events, find teammates, and discover useful gear.';

  @override
  String signedInAs(String email) {
    return 'Signed in as $email';
  }

  @override
  String get marketplaceIntro =>
      'Buy and sell curling equipment with the community.';

  @override
  String get tournamentsIntro =>
      'Explore upcoming and past curling tournaments.';

  @override
  String get playersIntro => 'Find fellow players for a specific event.';

  @override
  String get upcoming => 'Upcoming';

  @override
  String get past => 'Past';

  @override
  String get noItems => 'Nothing to show yet.';

  @override
  String get loginToEdit => 'Log in to make changes';

  @override
  String get loginToEditMessage =>
      'You can browse this page without an account. Please log in to create or edit content.';

  @override
  String get createListing => 'Create listing';

  @override
  String get createTournament => 'Create tournament';

  @override
  String get joinEvent => 'Join event';

  @override
  String get edit => 'Edit';

  @override
  String get price => 'Price';

  @override
  String get location => 'Location';

  @override
  String get date => 'Date';

  @override
  String get participants => 'Participants';

  @override
  String get requiredField => 'This field is required.';

  @override
  String get invalidEmail => 'Enter a valid email address.';

  @override
  String get passwordTooShort => 'Password must contain at least 6 characters.';

  @override
  String get passwordMismatch => 'Passwords do not match.';

  @override
  String get authError => 'Authentication failed. Please check your details.';

  @override
  String authErrorCode(String code) {
    return 'Authentication failed ($code).';
  }

  @override
  String get language => 'Language';

  @override
  String get profile => 'Profile';

  @override
  String get settingsComingSoon => 'Settings coming soon';
}
