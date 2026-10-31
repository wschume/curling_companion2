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
  String get tournamentDeleteError =>
      'Could not delete tournament. Please try again.';

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

  @override
  String get verifyEmail => 'Verify email';

  @override
  String get verificationRequired =>
      'Verify your email to post or edit content.';

  @override
  String get verificationInstructions =>
      'Open the verification link in your email, then return here and check your status. You can still browse and manage your account.';

  @override
  String get verificationSent =>
      'Verification email sent. Check your inbox and spam folder.';

  @override
  String get verificationSendError =>
      'Could not send the verification email. Please try resending it. Your account has already been created.';

  @override
  String get verificationRefreshError =>
      'Could not check verification. Please try again.';

  @override
  String get verificationPending =>
      'Your email is not verified yet. Open the email link, then check again.';

  @override
  String get verificationComplete => 'Your email is verified.';

  @override
  String get verificationCheck => 'I\'ve verified my email';

  @override
  String get verificationResend => 'Resend verification email';

  @override
  String get verificationWait =>
      'Please wait 60 seconds before sending another email.';

  @override
  String get verificationSimulate => 'Simulate verification (local demo)';

  @override
  String get emailChangePending =>
      'Check your new email address for a confirmation link. Your current address remains active until confirmed.';

  @override
  String get legalNotice => 'Legal notice';

  @override
  String get legalContact => 'Contact:';

  @override
  String get legalPhone => 'Phone: 0152 2563 5091';

  @override
  String get legalResponsible =>
      'Responsible for content:\nFlorin Zepernick (contact details above)';

  @override
  String get usageTermsTitle => 'Terms of use';

  @override
  String get usageTermsIntro =>
      'Any use of this website that violates one or more laws of the Federal Republic of Germany is prohibited. In particular, the following are prohibited:';

  @override
  String get usageTermsProhibitions =>
      'Obscene, vulgar, or violent posts\nFalse or misleading content\nViolations of the law\nSpamming or scamming the service or other users\nHacking or manipulating the website or app\nCopyright infringement\nHarassment of other users\nStalking other users';

  @override
  String get usageTermsAcceptance =>
      'By using this website, you accept these rules.';

  @override
  String get usageTermsLiability =>
      'The website operator excludes all liability for damage or inconvenience resulting from use of the website. For example, liability for lost data is excluded.';

  @override
  String get termsAcceptLabel => 'I accept the Terms of use.';

  @override
  String get termsRead => 'Read terms';

  @override
  String get termsClose => 'Close';

  @override
  String get termsRequired =>
      'Accept the Terms of use before posting or editing content.';

  @override
  String get termsSaveError =>
      'Your account was created, but your acceptance could not be saved. Please retry saving your acceptance.';

  @override
  String get acceptTermsAction => 'Accept terms';

  @override
  String get tournamentAlreadyExists =>
      'A tournament already exists in this city on this start date.';

  @override
  String get tournamentDuplicateCheckFailed =>
      'Unable to check for an existing tournament. Please try again.';

  @override
  String get privacyTitle => 'Privacy';

  @override
  String get privacyRead => 'Read privacy declaration';

  @override
  String get privacyUnderstood => 'Understood';

  @override
  String get privacyNoticeMessage =>
      'We use Firebase to provide this website and maintain sign-in sessions. Our privacy declaration explains how data is processed. “Understood” only dismisses this notice; it does not grant consent.';

  @override
  String get privacyDraft =>
      'Draft for operator review — not yet approved for publication.';

  @override
  String get privacyVersion => 'Version';

  @override
  String get privacyControllerTitle => 'Controller and contact';

  @override
  String get privacyControllerBody =>
      'Florin Zepernick, Holbeinstr. 17a, 12203 Berlin, Germany. Email: info@curlingcompanion.de. Telephone: 0152 2563 5091. Please use these details for questions about your personal data or to exercise your rights.';

  @override
  String get privacyServicesTitle => 'Website operation and Firebase services';

  @override
  String get privacyServicesBody =>
      'This website uses Google Firebase Hosting to deliver its pages, Firebase Authentication for accounts and sign-in, Cloud Firestore for profiles and community content, Cloud Storage for uploaded marketplace images, and Cloud Functions for image processing and upload management. Requests to these services disclose technical connection information, including IP addresses and request/browser information, to Google. Firebase Hosting and service infrastructure may process logs for operation, security and abuse prevention. Firebase initializes when the website opens; the information notice does not prevent these requests.';

  @override
  String get privacyAuthTitle => 'Registration and account data';

  @override
  String get privacyAuthBody =>
      'For registration and sign-in, Firebase Authentication processes your email address, password, user ID and verification status, together with technical information used to authenticate requests and prevent abuse. Your password is transmitted to Firebase for authentication; the app does not save it as browser session data. Profile settings can include a telephone number and language preference. We also store your acceptance of the current terms of use, including the terms version, server timestamp and selected language. Acknowledging this privacy notice is separate from accepting the terms.';

  @override
  String get privacyPublicTitle => 'Public content and images';

  @override
  String get privacyPublicBody =>
      'Tournament information, marketplace listings, player availability and team/player searches are publicly readable. Depending on what you submit, this includes names, locations, contact information, descriptions and uploaded images. Content records also contain the associated organizer or owner user ID. Marketplace images are accessible using their download links. Do not publish information that you do not want visitors to see. Uploaded image files are stored in Cloud Storage; Cloud Functions receives image data and file information to handle uploads, ownership-related paths and storage quotas.';

  @override
  String get privacyBrowserTitle => 'Storage in your browser';

  @override
  String get privacyBrowserBody =>
      'Firebase Authentication can retain account information such as your email address and user ID, and authentication tokens, in browser storage so that you remain signed in after reloading or returning to the website. Signing out clears the active Firebase sign-in state in this browser. The app stores the acknowledged privacy version under privacy_notice_version using local browser storage, solely to avoid repeating the notice. This value has no user ID and is not sent to our database. It remains until replaced by another acknowledgement or removed through browser settings. A materially updated declaration will show the notice again. If storage is unavailable, dismissal lasts only for the current app session. Clearing browser data may sign you out and will make the notice appear again.';

  @override
  String get privacyHeartbeatTitle => 'SDK heartbeat and technical information';

  @override
  String get privacyHeartbeatBody =>
      'The Firebase web SDK can record technical heartbeat information in IndexedDB, including dates and Firebase SDK/platform version information, and attach it to requests to Google. Authentication requests can also include the Firebase app ID. The app ID identifies this Firebase application, not your personal user account. This technical mechanism is distinct from Google Analytics. This app does not integrate Google Analytics or advertising tracking. The heartbeat mechanism is not controlled by the “Understood” button.';

  @override
  String get privacyTransfersTitle => 'Recipients and international processing';

  @override
  String get privacyTransfersBody =>
      'Google processes information as the provider of the Firebase services used by this website. The website operator controls the data submitted to these services. Processing may involve Google companies and subprocessors outside Germany and the European Economic Area, including in the United States. Google describes its processing terms, subprocessors and international transfer safeguards in its Firebase privacy and security documentation. Public content is also accessible to visitors worldwide. Opening external links connects you to the respective external provider.';

  @override
  String get privacyRetentionTitle => 'Retention and deletion';

  @override
  String get privacyRetentionBody =>
      'Account data is retained in Firebase Authentication until the account is deleted; Google may retain service logs and backup data for additional service-specific periods. The website allows account deletion only after your tournaments and marketplace listings have been removed. Deleting your account removes its Authentication account; it does not automatically delete profile documents, terms-acceptance records, player/team searches or all previously uploaded files. Removing a content record does not by itself guarantee removal of related stored images. Contact the operator about removal of remaining personal data. Browser data can be removed independently through your browser settings.';

  @override
  String get privacyRightsTitle => 'Your rights and complaints';

  @override
  String get privacyRightsBody =>
      'Where the applicable legal conditions are met, you may request access to, correction or erasure of your personal data, restriction of processing and data portability. You may object to processing based on legitimate interests. Where processing is based on consent, you may withdraw that consent for the future without affecting the lawfulness of earlier processing. The “Understood” action on this website is not such consent. Contact the controller using the details above. You may lodge a complaint with a competent data protection supervisory authority, including the Berlin Commissioner for Data Protection and Freedom of Information.';

  @override
  String get dateRange => 'Date range';

  @override
  String get roleAny => 'any';

  @override
  String get countryGermany => 'Germany';
}
