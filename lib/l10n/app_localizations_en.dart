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
  String get name => 'Name';

  @override
  String get location => 'Location';

  @override
  String get currency => 'Currency';

  @override
  String get contactHint => 'Email address or telephone number';

  @override
  String get invalidContact =>
      'Enter a valid email address or telephone number.';

  @override
  String get invalidDateOrder =>
      'Dates must follow signup deadline < start date < end date.';

  @override
  String get durationTooLong => 'A tournament may last at most 5 days.';

  @override
  String get showPastTournaments => 'Show past tournaments';

  @override
  String get hidePastTournaments => 'Hide past tournaments';

  @override
  String get myTournaments => 'My tournaments';

  @override
  String get allTournaments => 'All tournaments';

  @override
  String get futureTournaments => 'Future tournaments';

  @override
  String get pastTournaments => 'Past tournaments';

  @override
  String get startDate => 'Start date';

  @override
  String get endDate => 'End date';

  @override
  String get signupDeadline => 'Signup deadline';

  @override
  String get club => 'Club';

  @override
  String get city => 'City';

  @override
  String get country => 'Country';

  @override
  String get entryFee => 'Entry fee';

  @override
  String get maxTeams => 'Max teams';

  @override
  String get website => 'Website';

  @override
  String get contact => 'Contact';

  @override
  String get filters => 'Filters';

  @override
  String get filterByName => 'Filter by name';

  @override
  String get filterByLocation => 'Filter by location';

  @override
  String get filterStartDate => 'Filter start date';

  @override
  String get filterEndDate => 'Filter end date';

  @override
  String get clearFilters => 'Clear filters';

  @override
  String get createTournament => 'Create tournament';

  @override
  String get editTournament => 'Edit tournament';

  @override
  String get deleteTournament => 'Delete tournament';

  @override
  String get confirmDeleteTournament => 'Delete this tournament?';

  @override
  String get confirmDeleteTournamentMessage => 'This action cannot be undone.';

  @override
  String get saveTournament => 'Save tournament';

  @override
  String get tournamentSaved => 'Tournament saved.';

  @override
  String get tournamentDeleted => 'Tournament deleted.';

  @override
  String get invalidWebsite => 'Enter a valid website URL.';

  @override
  String get invalidNumber => 'Enter a valid number.';

  @override
  String get noFutureTournaments =>
      'No future tournaments match these filters.';

  @override
  String get noPastTournaments => 'No past tournaments match these filters.';

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
  String get joinEvent => 'Join event';

  @override
  String get edit => 'Edit';

  @override
  String get price => 'Price';

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

  @override
  String get profileSettings => 'Profile settings';

  @override
  String get newPassword => 'New password';

  @override
  String get telephone => 'Telephone';

  @override
  String get deleteAccount => 'Delete account';

  @override
  String get confirmDeleteAccount => 'Delete account?';

  @override
  String get accountDeleteBlocked =>
      'Remove all your tournaments and marketplace listings before deleting your account.';

  @override
  String get accountDeletedError => 'Could not delete account.';

  @override
  String get settingsUpdateError => 'Could not update settings.';

  @override
  String get passwordsDoNotMatch => 'Passwords do not match.';

  @override
  String get english => 'English';

  @override
  String get german => 'German';

  @override
  String get teamsLookingForPlayers => 'Teams looking for players.';

  @override
  String get tournamentFilter => 'Tournaments';

  @override
  String get all => 'All';

  @override
  String selectedCount(int count) {
    return '$count selected';
  }

  @override
  String get teamsSearchingForPlayers => 'Teams searching for players';

  @override
  String get playersSearchingForTeams => 'Players searching for teams';

  @override
  String get createPlayerSearch => 'Create player search';

  @override
  String get createTeamSearch => 'Create team search';

  @override
  String get editPlayerSearch => 'Edit player search';

  @override
  String get editTeamSearch => 'Edit team search';

  @override
  String get deletePlayerSearch => 'Delete player search?';

  @override
  String get deleteTeamSearch => 'Delete team search?';

  @override
  String get tournament => 'Tournament';

  @override
  String get role => 'Role';

  @override
  String get tournamentUnavailable => 'Tournament unavailable';

  @override
  String get editSearch => 'Edit search';

  @override
  String get deleteSearch => 'Delete search';

  @override
  String get createSearch => 'Create search';

  @override
  String get saveChanges => 'Save changes';

  @override
  String get unableToLoadData => 'Unable to load data.';

  @override
  String get category => 'Category';

  @override
  String get allCategories => 'All categories';

  @override
  String get shoes => 'Shoes';

  @override
  String get stones => 'Stones';

  @override
  String get brooms => 'Brooms';

  @override
  String get other => 'Other';

  @override
  String get title => 'Title';

  @override
  String get description => 'Description';

  @override
  String get viewDetails => 'View details';

  @override
  String get emailSeller => 'Email seller';

  @override
  String get callSeller => 'Call seller';

  @override
  String get seller => 'Seller';

  @override
  String get close => 'Close';

  @override
  String get editListing => 'Edit listing';

  @override
  String get deleteListing => 'Delete listing?';

  @override
  String get deleteListingMessage => 'This action cannot be undone.';

  @override
  String get sellerEmailOrPhone => 'Seller email or phone';

  @override
  String get addImages => 'Add images';

  @override
  String get optionalMultipleImages =>
      'Optional. You can attach multiple images.';

  @override
  String get image => 'Image';

  @override
  String get uploadingImages => 'Uploading images…';

  @override
  String get enterValidPrice => 'Enter a valid price.';

  @override
  String get imageUploadsRequireFirebase =>
      'Image uploads require Firebase configuration.';

  @override
  String get imageUploadFailed =>
      'Unable to upload one or more images. Please try again.';
}
