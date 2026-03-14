import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
import 'app_localizations_en.dart';
import 'app_localizations_fr.dart';
import 'app_localizations_he.dart';
import 'app_localizations_ru.dart';

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
    Locale('ar'),
    Locale('en'),
    Locale('fr'),
    Locale('he'),
    Locale('ru')
  ];

  /// The application name
  ///
  /// In en, this message translates to:
  /// **'SuperNanny'**
  String get appTitle;

  /// Greeting on login screen
  ///
  /// In en, this message translates to:
  /// **'Welcome back'**
  String get welcomeBack;

  /// Sign in button
  ///
  /// In en, this message translates to:
  /// **'Sign In'**
  String get signIn;

  /// Sign up button
  ///
  /// In en, this message translates to:
  /// **'Sign Up'**
  String get signUp;

  /// Email field label
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get email;

  /// Password field label
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password;

  /// Confirm password field label
  ///
  /// In en, this message translates to:
  /// **'Confirm Password'**
  String get confirmPassword;

  /// Forgot password link
  ///
  /// In en, this message translates to:
  /// **'Forgot Password?'**
  String get forgotPassword;

  /// Google sign-in button
  ///
  /// In en, this message translates to:
  /// **'Continue with Google'**
  String get continueWithGoogle;

  /// Biometric sign-in button
  ///
  /// In en, this message translates to:
  /// **'Sign in with Biometric'**
  String get signInWithBiometric;

  /// Fingerprint sign-in button
  ///
  /// In en, this message translates to:
  /// **'Sign in with Fingerprint'**
  String get signInWithFingerprint;

  /// Face ID sign-in button
  ///
  /// In en, this message translates to:
  /// **'Sign in with Face ID'**
  String get signInWithFaceId;

  /// Sign up prompt
  ///
  /// In en, this message translates to:
  /// **'Don\'t have an account?'**
  String get dontHaveAccount;

  /// Sign in prompt
  ///
  /// In en, this message translates to:
  /// **'Already have an account?'**
  String get alreadyHaveAccount;

  /// Full name field label
  ///
  /// In en, this message translates to:
  /// **'Full Name'**
  String get fullName;

  /// Phone number field label
  ///
  /// In en, this message translates to:
  /// **'Phone Number'**
  String get phoneNumber;

  /// Create account button
  ///
  /// In en, this message translates to:
  /// **'Create Account'**
  String get createAccount;

  /// Social login separator text
  ///
  /// In en, this message translates to:
  /// **'Or continue with'**
  String get orContinueWith;

  /// Home search placeholder
  ///
  /// In en, this message translates to:
  /// **'Search nannies, cities...'**
  String get searchNanniesCities;

  /// Current location label
  ///
  /// In en, this message translates to:
  /// **'My Location'**
  String get myLocation;

  /// Top rated section title
  ///
  /// In en, this message translates to:
  /// **'Top Rated'**
  String get topRated;

  /// Available now section title
  ///
  /// In en, this message translates to:
  /// **'Available Now'**
  String get availableNow;

  /// New nannies section title
  ///
  /// In en, this message translates to:
  /// **'New on SuperNanny'**
  String get newOnSuperNanny;

  /// All nannies section title
  ///
  /// In en, this message translates to:
  /// **'All Nannies'**
  String get allNannies;

  /// Filter button
  ///
  /// In en, this message translates to:
  /// **'Filter'**
  String get filter;

  /// Filters title
  ///
  /// In en, this message translates to:
  /// **'Filters'**
  String get filters;

  /// Sort by label
  ///
  /// In en, this message translates to:
  /// **'Sort By'**
  String get sortBy;

  /// Rating label
  ///
  /// In en, this message translates to:
  /// **'Rating'**
  String get rating;

  /// Price label
  ///
  /// In en, this message translates to:
  /// **'Price'**
  String get price;

  /// Distance label
  ///
  /// In en, this message translates to:
  /// **'Distance'**
  String get distance;

  /// Experience label
  ///
  /// In en, this message translates to:
  /// **'Experience'**
  String get experience;

  /// Skills label
  ///
  /// In en, this message translates to:
  /// **'Skills'**
  String get skills;

  /// Reviews label
  ///
  /// In en, this message translates to:
  /// **'Reviews'**
  String get reviews;

  /// See all link
  ///
  /// In en, this message translates to:
  /// **'See All'**
  String get seeAll;

  /// Book now button
  ///
  /// In en, this message translates to:
  /// **'Book Now'**
  String get bookNow;

  /// One-time booking type
  ///
  /// In en, this message translates to:
  /// **'One-time'**
  String get oneTime;

  /// Recurring booking type
  ///
  /// In en, this message translates to:
  /// **'Recurring'**
  String get recurring;

  /// Date picker label
  ///
  /// In en, this message translates to:
  /// **'Select Date'**
  String get selectDate;

  /// Start time label
  ///
  /// In en, this message translates to:
  /// **'Start'**
  String get startTime;

  /// End time label
  ///
  /// In en, this message translates to:
  /// **'End'**
  String get endTime;

  /// Children count field
  ///
  /// In en, this message translates to:
  /// **'Number of Children'**
  String get numberOfChildren;

  /// Address field label
  ///
  /// In en, this message translates to:
  /// **'Address'**
  String get address;

  /// Notes field label
  ///
  /// In en, this message translates to:
  /// **'Notes'**
  String get notes;

  /// Request booking button
  ///
  /// In en, this message translates to:
  /// **'Request Booking'**
  String get requestBooking;

  /// Booking summary title
  ///
  /// In en, this message translates to:
  /// **'Booking Summary'**
  String get bookingSummary;

  /// Payment info text
  ///
  /// In en, this message translates to:
  /// **'Payment after session'**
  String get paymentAfterSession;

  /// Hourly rate label
  ///
  /// In en, this message translates to:
  /// **'Hourly Rate'**
  String get hourlyRate;

  /// Estimated total label
  ///
  /// In en, this message translates to:
  /// **'Estimated Total'**
  String get estimatedTotal;

  /// Booking confirmation title
  ///
  /// In en, this message translates to:
  /// **'Booking Confirmed'**
  String get bookingConfirmed;

  /// Booking pending status
  ///
  /// In en, this message translates to:
  /// **'Booking Pending'**
  String get bookingPending;

  /// Booking cancelled status
  ///
  /// In en, this message translates to:
  /// **'Booking Cancelled'**
  String get bookingCancelled;

  /// Booking completed status
  ///
  /// In en, this message translates to:
  /// **'Booking Completed'**
  String get bookingCompleted;

  /// Upcoming bookings section
  ///
  /// In en, this message translates to:
  /// **'Upcoming Bookings'**
  String get upcomingBookings;

  /// Past bookings section
  ///
  /// In en, this message translates to:
  /// **'Past Bookings'**
  String get pastBookings;

  /// Empty bookings message
  ///
  /// In en, this message translates to:
  /// **'No bookings yet'**
  String get noBookingsYet;

  /// Chat input placeholder
  ///
  /// In en, this message translates to:
  /// **'Type a message...'**
  String get typeAMessage;

  /// Empty chat message
  ///
  /// In en, this message translates to:
  /// **'Start the conversation!'**
  String get startTheConversation;

  /// Chat typing indicator
  ///
  /// In en, this message translates to:
  /// **'typing...'**
  String get typing;

  /// Online status
  ///
  /// In en, this message translates to:
  /// **'Online'**
  String get online;

  /// Offline status
  ///
  /// In en, this message translates to:
  /// **'Offline'**
  String get offline;

  /// Messages tab title
  ///
  /// In en, this message translates to:
  /// **'Messages'**
  String get messages;

  /// Empty messages state
  ///
  /// In en, this message translates to:
  /// **'No messages yet'**
  String get noMessages;

  /// Edit profile button
  ///
  /// In en, this message translates to:
  /// **'Edit Profile'**
  String get editProfile;

  /// Privacy settings
  ///
  /// In en, this message translates to:
  /// **'Privacy & Security'**
  String get privacyAndSecurity;

  /// About section
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get about;

  /// Help section
  ///
  /// In en, this message translates to:
  /// **'Help'**
  String get help;

  /// Notifications settings
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notifications;

  /// Logout button
  ///
  /// In en, this message translates to:
  /// **'Logout'**
  String get logout;

  /// Delete account button
  ///
  /// In en, this message translates to:
  /// **'Delete Account'**
  String get deleteAccount;

  /// Delete account confirmation message
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete your account? This action cannot be undone.'**
  String get deleteAccountConfirmation;

  /// Nanny dashboard pending requests
  ///
  /// In en, this message translates to:
  /// **'Pending Requests'**
  String get pendingRequests;

  /// Nanny dashboard total earned
  ///
  /// In en, this message translates to:
  /// **'Total Earned'**
  String get totalEarned;

  /// Nanny dashboard total jobs
  ///
  /// In en, this message translates to:
  /// **'Total Jobs'**
  String get totalJobs;

  /// Nanny dashboard quick actions
  ///
  /// In en, this message translates to:
  /// **'Quick Actions'**
  String get quickActions;

  /// Nanny availability section
  ///
  /// In en, this message translates to:
  /// **'Availability'**
  String get availability;

  /// Nanny earnings section
  ///
  /// In en, this message translates to:
  /// **'Earnings'**
  String get earnings;

  /// Profile tab
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profile;

  /// Home tab
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get home;

  /// Bookings tab
  ///
  /// In en, this message translates to:
  /// **'Bookings'**
  String get bookings;

  /// Chat tab
  ///
  /// In en, this message translates to:
  /// **'Chat'**
  String get chat;

  /// Settings page title
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// Terms of service link
  ///
  /// In en, this message translates to:
  /// **'Terms of Service'**
  String get termsOfService;

  /// Privacy policy link
  ///
  /// In en, this message translates to:
  /// **'Privacy Policy'**
  String get privacyPolicy;

  /// Open source licenses link
  ///
  /// In en, this message translates to:
  /// **'Open Source Licenses'**
  String get openSourceLicenses;

  /// Cancel button
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// Confirm button
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get confirm;

  /// Save button
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// Loading indicator text
  ///
  /// In en, this message translates to:
  /// **'Loading...'**
  String get loading;

  /// Error title
  ///
  /// In en, this message translates to:
  /// **'Error'**
  String get error;

  /// Success title
  ///
  /// In en, this message translates to:
  /// **'Success'**
  String get success;

  /// Empty results message
  ///
  /// In en, this message translates to:
  /// **'No results'**
  String get noResults;

  /// Retry button
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// OK button
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get ok;

  /// Yes button
  ///
  /// In en, this message translates to:
  /// **'Yes'**
  String get yes;

  /// No button
  ///
  /// In en, this message translates to:
  /// **'No'**
  String get no;

  /// Close button
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// Done button
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get done;

  /// Next button
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get next;

  /// Back button
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get back;

  /// Skip button
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get skip;

  /// Apply button
  ///
  /// In en, this message translates to:
  /// **'Apply'**
  String get apply;

  /// Reset button
  ///
  /// In en, this message translates to:
  /// **'Reset'**
  String get reset;

  /// Delete button
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// Edit button
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get edit;

  /// Add button
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get add;

  /// Remove button
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get remove;

  /// Search button/label
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get search;

  /// Share button
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get share;

  /// Favorites section
  ///
  /// In en, this message translates to:
  /// **'Favorites'**
  String get favorites;

  /// Add to favorites action
  ///
  /// In en, this message translates to:
  /// **'Add to Favorites'**
  String get addToFavorites;

  /// Remove from favorites action
  ///
  /// In en, this message translates to:
  /// **'Remove from Favorites'**
  String get removeFromFavorites;

  /// Empty favorites message
  ///
  /// In en, this message translates to:
  /// **'No favorites yet'**
  String get noFavoritesYet;

  /// Per hour abbreviation
  ///
  /// In en, this message translates to:
  /// **'/hr'**
  String get perHour;

  /// Years of experience
  ///
  /// In en, this message translates to:
  /// **'{count} years experience'**
  String yearsExperience(int count);

  /// Number of children
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 child} other{{count} children}}'**
  String childrenCount(int count);

  /// Number of reviews
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{No reviews} =1{1 review} other{{count} reviews}}'**
  String reviewsCount(int count);

  /// Kilometers abbreviation
  ///
  /// In en, this message translates to:
  /// **'km'**
  String get km;

  /// Today label
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get today;

  /// Tomorrow label
  ///
  /// In en, this message translates to:
  /// **'Tomorrow'**
  String get tomorrow;

  /// Yesterday label
  ///
  /// In en, this message translates to:
  /// **'Yesterday'**
  String get yesterday;

  /// Language setting label
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// Language selection title
  ///
  /// In en, this message translates to:
  /// **'Select Language'**
  String get selectLanguage;

  /// Dark mode setting
  ///
  /// In en, this message translates to:
  /// **'Dark Mode'**
  String get darkMode;

  /// Location permission label
  ///
  /// In en, this message translates to:
  /// **'Location Permission'**
  String get locationPermission;

  /// Location permission explanation
  ///
  /// In en, this message translates to:
  /// **'We need your location to find nannies near you'**
  String get locationPermissionDescription;

  /// Notification permission label
  ///
  /// In en, this message translates to:
  /// **'Notification Permission'**
  String get notificationPermission;

  /// Notification permission explanation
  ///
  /// In en, this message translates to:
  /// **'Get notified about bookings and messages'**
  String get notificationPermissionDescription;

  /// Allow button
  ///
  /// In en, this message translates to:
  /// **'Allow'**
  String get allow;

  /// Deny button
  ///
  /// In en, this message translates to:
  /// **'Deny'**
  String get deny;

  /// Connection error message
  ///
  /// In en, this message translates to:
  /// **'Connection error. Please check your internet.'**
  String get connectionError;

  /// Generic error message
  ///
  /// In en, this message translates to:
  /// **'Something went wrong. Please try again.'**
  String get somethingWentWrong;

  /// Session expired message
  ///
  /// In en, this message translates to:
  /// **'Session expired. Please sign in again.'**
  String get sessionExpired;

  /// No internet message
  ///
  /// In en, this message translates to:
  /// **'No internet connection'**
  String get noInternetConnection;

  /// Logout confirmation message
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to logout?'**
  String get logoutConfirmation;

  /// Accept button
  ///
  /// In en, this message translates to:
  /// **'Accept'**
  String get accept;

  /// Decline button
  ///
  /// In en, this message translates to:
  /// **'Decline'**
  String get decline;

  /// Pending status
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get pending;

  /// Confirmed status
  ///
  /// In en, this message translates to:
  /// **'Confirmed'**
  String get confirmed;

  /// Completed status
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get completed;

  /// Cancelled status
  ///
  /// In en, this message translates to:
  /// **'Cancelled'**
  String get cancelled;

  /// In progress status
  ///
  /// In en, this message translates to:
  /// **'In Progress'**
  String get inProgress;

  /// Map view label
  ///
  /// In en, this message translates to:
  /// **'Map'**
  String get map;

  /// List view label
  ///
  /// In en, this message translates to:
  /// **'List'**
  String get list;

  /// Gallery label
  ///
  /// In en, this message translates to:
  /// **'Gallery'**
  String get gallery;

  /// Camera label
  ///
  /// In en, this message translates to:
  /// **'Camera'**
  String get camera;

  /// Choose photo option
  ///
  /// In en, this message translates to:
  /// **'Choose Photo'**
  String get choosePhoto;

  /// Take photo option
  ///
  /// In en, this message translates to:
  /// **'Take Photo'**
  String get takePhoto;

  /// Bio field label
  ///
  /// In en, this message translates to:
  /// **'Bio'**
  String get bio;

  /// Age field label
  ///
  /// In en, this message translates to:
  /// **'Age'**
  String get age;

  /// City field label
  ///
  /// In en, this message translates to:
  /// **'City'**
  String get city;

  /// Start session button
  ///
  /// In en, this message translates to:
  /// **'Start Session'**
  String get startSession;

  /// End session button
  ///
  /// In en, this message translates to:
  /// **'End Session'**
  String get endSession;

  /// Session in progress label
  ///
  /// In en, this message translates to:
  /// **'Session in Progress'**
  String get sessionInProgress;

  /// Rating prompt
  ///
  /// In en, this message translates to:
  /// **'Rate your experience'**
  String get rateYourExperience;

  /// Review input placeholder
  ///
  /// In en, this message translates to:
  /// **'Write a review...'**
  String get writeAReview;

  /// Submit review button
  ///
  /// In en, this message translates to:
  /// **'Submit Review'**
  String get submitReview;

  /// Review submitted message
  ///
  /// In en, this message translates to:
  /// **'Thank you for your review!'**
  String get thankYouForReview;

  /// App version label
  ///
  /// In en, this message translates to:
  /// **'Version'**
  String get version;
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
      <String>['ar', 'en', 'fr', 'he', 'ru'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar':
      return AppLocalizationsAr();
    case 'en':
      return AppLocalizationsEn();
    case 'fr':
      return AppLocalizationsFr();
    case 'he':
      return AppLocalizationsHe();
    case 'ru':
      return AppLocalizationsRu();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
