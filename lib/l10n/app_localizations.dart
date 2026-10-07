import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_de.dart';
import 'app_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('de'),
    Locale('en'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'Curling Companion'**
  String get appTitle;

  /// No description provided for @home.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get home;

  /// No description provided for @name.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get name;

  /// No description provided for @location.
  ///
  /// In en, this message translates to:
  /// **'Location'**
  String get location;

  /// No description provided for @currency.
  ///
  /// In en, this message translates to:
  /// **'Currency'**
  String get currency;

  /// No description provided for @contactHint.
  ///
  /// In en, this message translates to:
  /// **'Email address or telephone number'**
  String get contactHint;

  /// No description provided for @invalidContact.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid email address or telephone number.'**
  String get invalidContact;

  /// No description provided for @invalidDateOrder.
  ///
  /// In en, this message translates to:
  /// **'Dates must follow signup deadline < start date < end date.'**
  String get invalidDateOrder;

  /// No description provided for @durationTooLong.
  ///
  /// In en, this message translates to:
  /// **'A tournament may last at most 5 days.'**
  String get durationTooLong;

  /// No description provided for @showPastTournaments.
  ///
  /// In en, this message translates to:
  /// **'Show past tournaments'**
  String get showPastTournaments;

  /// No description provided for @hidePastTournaments.
  ///
  /// In en, this message translates to:
  /// **'Hide past tournaments'**
  String get hidePastTournaments;

  /// No description provided for @myTournaments.
  ///
  /// In en, this message translates to:
  /// **'My tournaments'**
  String get myTournaments;

  /// No description provided for @allTournaments.
  ///
  /// In en, this message translates to:
  /// **'All tournaments'**
  String get allTournaments;

  /// No description provided for @futureTournaments.
  ///
  /// In en, this message translates to:
  /// **'Future tournaments'**
  String get futureTournaments;

  /// No description provided for @pastTournaments.
  ///
  /// In en, this message translates to:
  /// **'Past tournaments'**
  String get pastTournaments;

  /// No description provided for @startDate.
  ///
  /// In en, this message translates to:
  /// **'Start date'**
  String get startDate;

  /// No description provided for @endDate.
  ///
  /// In en, this message translates to:
  /// **'End date'**
  String get endDate;

  /// No description provided for @signupDeadline.
  ///
  /// In en, this message translates to:
  /// **'Signup deadline'**
  String get signupDeadline;

  /// No description provided for @club.
  ///
  /// In en, this message translates to:
  /// **'Club'**
  String get club;

  /// No description provided for @city.
  ///
  /// In en, this message translates to:
  /// **'City'**
  String get city;

  /// No description provided for @country.
  ///
  /// In en, this message translates to:
  /// **'Country'**
  String get country;

  /// No description provided for @entryFee.
  ///
  /// In en, this message translates to:
  /// **'Entry fee'**
  String get entryFee;

  /// No description provided for @maxTeams.
  ///
  /// In en, this message translates to:
  /// **'Max teams'**
  String get maxTeams;

  /// No description provided for @website.
  ///
  /// In en, this message translates to:
  /// **'Website'**
  String get website;

  /// No description provided for @contact.
  ///
  /// In en, this message translates to:
  /// **'Contact'**
  String get contact;

  /// No description provided for @filters.
  ///
  /// In en, this message translates to:
  /// **'Filters'**
  String get filters;

  /// No description provided for @filterByName.
  ///
  /// In en, this message translates to:
  /// **'Filter by name'**
  String get filterByName;

  /// No description provided for @filterByLocation.
  ///
  /// In en, this message translates to:
  /// **'Filter by location'**
  String get filterByLocation;

  /// No description provided for @filterStartDate.
  ///
  /// In en, this message translates to:
  /// **'Filter start date'**
  String get filterStartDate;

  /// No description provided for @filterEndDate.
  ///
  /// In en, this message translates to:
  /// **'Filter end date'**
  String get filterEndDate;

  /// No description provided for @clearFilters.
  ///
  /// In en, this message translates to:
  /// **'Clear filters'**
  String get clearFilters;

  /// No description provided for @createTournament.
  ///
  /// In en, this message translates to:
  /// **'Create tournament'**
  String get createTournament;

  /// No description provided for @editTournament.
  ///
  /// In en, this message translates to:
  /// **'Edit tournament'**
  String get editTournament;

  /// No description provided for @deleteTournament.
  ///
  /// In en, this message translates to:
  /// **'Delete tournament'**
  String get deleteTournament;

  /// No description provided for @confirmDeleteTournament.
  ///
  /// In en, this message translates to:
  /// **'Delete this tournament?'**
  String get confirmDeleteTournament;

  /// No description provided for @confirmDeleteTournamentMessage.
  ///
  /// In en, this message translates to:
  /// **'This action cannot be undone.'**
  String get confirmDeleteTournamentMessage;

  /// No description provided for @saveTournament.
  ///
  /// In en, this message translates to:
  /// **'Save tournament'**
  String get saveTournament;

  /// No description provided for @tournamentSaved.
  ///
  /// In en, this message translates to:
  /// **'Tournament saved.'**
  String get tournamentSaved;

  /// No description provided for @tournamentDeleted.
  ///
  /// In en, this message translates to:
  /// **'Tournament deleted.'**
  String get tournamentDeleted;

  /// No description provided for @invalidWebsite.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid website URL.'**
  String get invalidWebsite;

  /// No description provided for @invalidNumber.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid number.'**
  String get invalidNumber;

  /// No description provided for @noFutureTournaments.
  ///
  /// In en, this message translates to:
  /// **'No future tournaments match these filters.'**
  String get noFutureTournaments;

  /// No description provided for @noPastTournaments.
  ///
  /// In en, this message translates to:
  /// **'No past tournaments match these filters.'**
  String get noPastTournaments;

  /// No description provided for @marketplace.
  ///
  /// In en, this message translates to:
  /// **'Marketplace'**
  String get marketplace;

  /// No description provided for @tournaments.
  ///
  /// In en, this message translates to:
  /// **'Tournaments'**
  String get tournaments;

  /// No description provided for @players.
  ///
  /// In en, this message translates to:
  /// **'Find Players'**
  String get players;

  /// No description provided for @login.
  ///
  /// In en, this message translates to:
  /// **'Log in'**
  String get login;

  /// No description provided for @register.
  ///
  /// In en, this message translates to:
  /// **'Register'**
  String get register;

  /// No description provided for @logout.
  ///
  /// In en, this message translates to:
  /// **'Log out'**
  String get logout;

  /// No description provided for @email.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get email;

  /// No description provided for @password.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password;

  /// No description provided for @confirmPassword.
  ///
  /// In en, this message translates to:
  /// **'Confirm password'**
  String get confirmPassword;

  /// No description provided for @submit.
  ///
  /// In en, this message translates to:
  /// **'Submit'**
  String get submit;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @welcome.
  ///
  /// In en, this message translates to:
  /// **'Welcome to Curling Companion'**
  String get welcome;

  /// No description provided for @publicIntro.
  ///
  /// In en, this message translates to:
  /// **'Browse curling events, find teammates, and discover useful gear.'**
  String get publicIntro;

  /// No description provided for @signedInAs.
  ///
  /// In en, this message translates to:
  /// **'Signed in as {email}'**
  String signedInAs(String email);

  /// No description provided for @marketplaceIntro.
  ///
  /// In en, this message translates to:
  /// **'Buy and sell curling equipment with the community.'**
  String get marketplaceIntro;

  /// No description provided for @tournamentsIntro.
  ///
  /// In en, this message translates to:
  /// **'Explore upcoming and past curling tournaments.'**
  String get tournamentsIntro;

  /// No description provided for @playersIntro.
  ///
  /// In en, this message translates to:
  /// **'Find fellow players for a specific event.'**
  String get playersIntro;

  /// No description provided for @upcoming.
  ///
  /// In en, this message translates to:
  /// **'Upcoming'**
  String get upcoming;

  /// No description provided for @past.
  ///
  /// In en, this message translates to:
  /// **'Past'**
  String get past;

  /// No description provided for @noItems.
  ///
  /// In en, this message translates to:
  /// **'Nothing to show yet.'**
  String get noItems;

  /// No description provided for @loginToEdit.
  ///
  /// In en, this message translates to:
  /// **'Log in to make changes'**
  String get loginToEdit;

  /// No description provided for @loginToEditMessage.
  ///
  /// In en, this message translates to:
  /// **'You can browse this page without an account. Please log in to create or edit content.'**
  String get loginToEditMessage;

  /// No description provided for @createListing.
  ///
  /// In en, this message translates to:
  /// **'Create listing'**
  String get createListing;

  /// No description provided for @joinEvent.
  ///
  /// In en, this message translates to:
  /// **'Join event'**
  String get joinEvent;

  /// No description provided for @edit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get edit;

  /// No description provided for @price.
  ///
  /// In en, this message translates to:
  /// **'Price'**
  String get price;

  /// No description provided for @date.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get date;

  /// No description provided for @participants.
  ///
  /// In en, this message translates to:
  /// **'Participants'**
  String get participants;

  /// No description provided for @requiredField.
  ///
  /// In en, this message translates to:
  /// **'This field is required.'**
  String get requiredField;

  /// No description provided for @invalidEmail.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid email address.'**
  String get invalidEmail;

  /// No description provided for @passwordTooShort.
  ///
  /// In en, this message translates to:
  /// **'Password must contain at least 6 characters.'**
  String get passwordTooShort;

  /// No description provided for @passwordMismatch.
  ///
  /// In en, this message translates to:
  /// **'Passwords do not match.'**
  String get passwordMismatch;

  /// No description provided for @authError.
  ///
  /// In en, this message translates to:
  /// **'Authentication failed. Please check your details.'**
  String get authError;

  /// No description provided for @authErrorCode.
  ///
  /// In en, this message translates to:
  /// **'Authentication failed ({code}).'**
  String authErrorCode(String code);

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @profile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profile;

  /// No description provided for @settingsComingSoon.
  ///
  /// In en, this message translates to:
  /// **'Settings coming soon'**
  String get settingsComingSoon;

  /// No description provided for @profileSettings.
  ///
  /// In en, this message translates to:
  /// **'Profile settings'**
  String get profileSettings;

  /// No description provided for @newPassword.
  ///
  /// In en, this message translates to:
  /// **'New password'**
  String get newPassword;

  /// No description provided for @telephone.
  ///
  /// In en, this message translates to:
  /// **'Telephone'**
  String get telephone;

  /// No description provided for @deleteAccount.
  ///
  /// In en, this message translates to:
  /// **'Delete account'**
  String get deleteAccount;

  /// No description provided for @confirmDeleteAccount.
  ///
  /// In en, this message translates to:
  /// **'Delete account?'**
  String get confirmDeleteAccount;

  /// No description provided for @accountDeleteBlocked.
  ///
  /// In en, this message translates to:
  /// **'Remove all your tournaments and marketplace listings before deleting your account.'**
  String get accountDeleteBlocked;

  /// No description provided for @accountDeletedError.
  ///
  /// In en, this message translates to:
  /// **'Could not delete account.'**
  String get accountDeletedError;

  /// No description provided for @settingsUpdateError.
  ///
  /// In en, this message translates to:
  /// **'Could not update settings.'**
  String get settingsUpdateError;

  /// No description provided for @passwordsDoNotMatch.
  ///
  /// In en, this message translates to:
  /// **'Passwords do not match.'**
  String get passwordsDoNotMatch;

  /// No description provided for @english.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get english;

  /// No description provided for @german.
  ///
  /// In en, this message translates to:
  /// **'German'**
  String get german;

  /// No description provided for @teamsLookingForPlayers.
  ///
  /// In en, this message translates to:
  /// **'Teams looking for players.'**
  String get teamsLookingForPlayers;

  /// No description provided for @tournamentFilter.
  ///
  /// In en, this message translates to:
  /// **'Tournaments'**
  String get tournamentFilter;

  /// No description provided for @all.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get all;

  /// No description provided for @selectedCount.
  ///
  /// In en, this message translates to:
  /// **'{count} selected'**
  String selectedCount(int count);

  /// No description provided for @teamsSearchingForPlayers.
  ///
  /// In en, this message translates to:
  /// **'Teams searching for players'**
  String get teamsSearchingForPlayers;

  /// No description provided for @playersSearchingForTeams.
  ///
  /// In en, this message translates to:
  /// **'Players searching for teams'**
  String get playersSearchingForTeams;

  /// No description provided for @createPlayerSearch.
  ///
  /// In en, this message translates to:
  /// **'Create player search'**
  String get createPlayerSearch;

  /// No description provided for @createTeamSearch.
  ///
  /// In en, this message translates to:
  /// **'Create team search'**
  String get createTeamSearch;

  /// No description provided for @editPlayerSearch.
  ///
  /// In en, this message translates to:
  /// **'Edit player search'**
  String get editPlayerSearch;

  /// No description provided for @editTeamSearch.
  ///
  /// In en, this message translates to:
  /// **'Edit team search'**
  String get editTeamSearch;

  /// No description provided for @deletePlayerSearch.
  ///
  /// In en, this message translates to:
  /// **'Delete player search?'**
  String get deletePlayerSearch;

  /// No description provided for @deleteTeamSearch.
  ///
  /// In en, this message translates to:
  /// **'Delete team search?'**
  String get deleteTeamSearch;

  /// No description provided for @tournament.
  ///
  /// In en, this message translates to:
  /// **'Tournament'**
  String get tournament;

  /// No description provided for @role.
  ///
  /// In en, this message translates to:
  /// **'Role'**
  String get role;

  /// No description provided for @tournamentUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Tournament unavailable'**
  String get tournamentUnavailable;

  /// No description provided for @editSearch.
  ///
  /// In en, this message translates to:
  /// **'Edit search'**
  String get editSearch;

  /// No description provided for @deleteSearch.
  ///
  /// In en, this message translates to:
  /// **'Delete search'**
  String get deleteSearch;

  /// No description provided for @createSearch.
  ///
  /// In en, this message translates to:
  /// **'Create search'**
  String get createSearch;

  /// No description provided for @saveChanges.
  ///
  /// In en, this message translates to:
  /// **'Save changes'**
  String get saveChanges;

  /// No description provided for @unableToLoadData.
  ///
  /// In en, this message translates to:
  /// **'Unable to load data.'**
  String get unableToLoadData;

  /// No description provided for @category.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get category;

  /// No description provided for @allCategories.
  ///
  /// In en, this message translates to:
  /// **'All categories'**
  String get allCategories;

  /// No description provided for @shoes.
  ///
  /// In en, this message translates to:
  /// **'Shoes'**
  String get shoes;

  /// No description provided for @stones.
  ///
  /// In en, this message translates to:
  /// **'Stones'**
  String get stones;

  /// No description provided for @brooms.
  ///
  /// In en, this message translates to:
  /// **'Brooms'**
  String get brooms;

  /// No description provided for @other.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get other;

  /// No description provided for @title.
  ///
  /// In en, this message translates to:
  /// **'Title'**
  String get title;

  /// No description provided for @description.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get description;

  /// No description provided for @viewDetails.
  ///
  /// In en, this message translates to:
  /// **'View details'**
  String get viewDetails;

  /// No description provided for @emailSeller.
  ///
  /// In en, this message translates to:
  /// **'Email seller'**
  String get emailSeller;

  /// No description provided for @callSeller.
  ///
  /// In en, this message translates to:
  /// **'Call seller'**
  String get callSeller;

  /// No description provided for @seller.
  ///
  /// In en, this message translates to:
  /// **'Seller'**
  String get seller;

  /// No description provided for @close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// No description provided for @editListing.
  ///
  /// In en, this message translates to:
  /// **'Edit listing'**
  String get editListing;

  /// No description provided for @deleteListing.
  ///
  /// In en, this message translates to:
  /// **'Delete listing?'**
  String get deleteListing;

  /// No description provided for @deleteListingMessage.
  ///
  /// In en, this message translates to:
  /// **'This action cannot be undone.'**
  String get deleteListingMessage;

  /// No description provided for @sellerEmailOrPhone.
  ///
  /// In en, this message translates to:
  /// **'Seller email or phone'**
  String get sellerEmailOrPhone;

  /// No description provided for @addImages.
  ///
  /// In en, this message translates to:
  /// **'Add images'**
  String get addImages;

  /// No description provided for @optionalMultipleImages.
  ///
  /// In en, this message translates to:
  /// **'Optional. You can attach multiple images.'**
  String get optionalMultipleImages;

  /// No description provided for @image.
  ///
  /// In en, this message translates to:
  /// **'Image'**
  String get image;

  /// No description provided for @uploadingImages.
  ///
  /// In en, this message translates to:
  /// **'Uploading images…'**
  String get uploadingImages;

  /// No description provided for @enterValidPrice.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid price.'**
  String get enterValidPrice;

  /// No description provided for @imageUploadsRequireFirebase.
  ///
  /// In en, this message translates to:
  /// **'Image uploads require Firebase configuration.'**
  String get imageUploadsRequireFirebase;

  /// No description provided for @imageUploadFailed.
  ///
  /// In en, this message translates to:
  /// **'Unable to upload one or more images. Please try again.'**
  String get imageUploadFailed;

  /// No description provided for @verifyEmail.
  ///
  /// In en, this message translates to:
  /// **'Verify email'**
  String get verifyEmail;

  /// No description provided for @verificationRequired.
  ///
  /// In en, this message translates to:
  /// **'Verify your email to post or edit content.'**
  String get verificationRequired;

  /// No description provided for @verificationInstructions.
  ///
  /// In en, this message translates to:
  /// **'Open the verification link in your email, then return here and check your status. You can still browse and manage your account.'**
  String get verificationInstructions;

  /// No description provided for @verificationSent.
  ///
  /// In en, this message translates to:
  /// **'Verification email sent. Check your inbox and spam folder.'**
  String get verificationSent;

  /// No description provided for @verificationSendError.
  ///
  /// In en, this message translates to:
  /// **'Could not send the verification email. Please try resending it. Your account has already been created.'**
  String get verificationSendError;

  /// No description provided for @verificationRefreshError.
  ///
  /// In en, this message translates to:
  /// **'Could not check verification. Please try again.'**
  String get verificationRefreshError;

  /// No description provided for @verificationPending.
  ///
  /// In en, this message translates to:
  /// **'Your email is not verified yet. Open the email link, then check again.'**
  String get verificationPending;

  /// No description provided for @verificationComplete.
  ///
  /// In en, this message translates to:
  /// **'Your email is verified. You can now post and edit content.'**
  String get verificationComplete;

  /// No description provided for @verificationCheck.
  ///
  /// In en, this message translates to:
  /// **'I\'ve verified my email'**
  String get verificationCheck;

  /// No description provided for @verificationResend.
  ///
  /// In en, this message translates to:
  /// **'Resend verification email'**
  String get verificationResend;

  /// No description provided for @verificationWait.
  ///
  /// In en, this message translates to:
  /// **'Please wait 60 seconds before sending another email.'**
  String get verificationWait;

  /// No description provided for @verificationSimulate.
  ///
  /// In en, this message translates to:
  /// **'Simulate verification (local demo)'**
  String get verificationSimulate;

  /// No description provided for @emailChangePending.
  ///
  /// In en, this message translates to:
  /// **'Check your new email address for a confirmation link. Your current address remains active until confirmed.'**
  String get emailChangePending;

  /// No description provided for @legalNotice.
  ///
  /// In en, this message translates to:
  /// **'Legal notice'**
  String get legalNotice;

  /// No description provided for @legalContact.
  ///
  /// In en, this message translates to:
  /// **'Contact:'**
  String get legalContact;

  /// No description provided for @legalPhone.
  ///
  /// In en, this message translates to:
  /// **'Phone: 0152 2563 5091'**
  String get legalPhone;

  /// No description provided for @legalResponsible.
  ///
  /// In en, this message translates to:
  /// **'Responsible for content:\nFlorin Zepernick (contact details above)'**
  String get legalResponsible;

  /// No description provided for @usageTermsTitle.
  ///
  /// In en, this message translates to:
  /// **'Terms of use'**
  String get usageTermsTitle;

  /// No description provided for @usageTermsIntro.
  ///
  /// In en, this message translates to:
  /// **'Any use of this website that violates one or more laws of the Federal Republic of Germany is prohibited. In particular, the following are prohibited:'**
  String get usageTermsIntro;

  /// No description provided for @usageTermsProhibitions.
  ///
  /// In en, this message translates to:
  /// **'Obscene, vulgar, or violent posts\nFalse or misleading content\nViolations of the law\nSpamming or scamming the service or other users\nHacking or manipulating the website or app\nCopyright infringement\nHarassment of other users\nStalking other users'**
  String get usageTermsProhibitions;

  /// No description provided for @usageTermsAcceptance.
  ///
  /// In en, this message translates to:
  /// **'By using this website, you accept these rules.'**
  String get usageTermsAcceptance;

  /// No description provided for @usageTermsLiability.
  ///
  /// In en, this message translates to:
  /// **'The website operator excludes all liability for damage or inconvenience resulting from use of the website. For example, liability for lost data is excluded.'**
  String get usageTermsLiability;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['de', 'en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'de':
      return AppLocalizationsDe();
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
