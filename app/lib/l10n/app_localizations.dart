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
  /// **'Welcome back!'**
  String get welcomeBack;

  /// Login subtitle
  ///
  /// In en, this message translates to:
  /// **'Sign in to your SuperNanny account'**
  String get signInToAccount;

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
  /// **'Forgot password?'**
  String get forgotPassword;

  /// Google sign-in button
  ///
  /// In en, this message translates to:
  /// **'Continue with Google'**
  String get continueWithGoogle;

  /// Google sign-up button
  ///
  /// In en, this message translates to:
  /// **'Sign up with Google'**
  String get signUpWithGoogle;

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

  /// Face Recognition sign-in button
  ///
  /// In en, this message translates to:
  /// **'Sign in with Face Recognition'**
  String get signInWithFaceRecognition;

  /// Iris scan sign-in button
  ///
  /// In en, this message translates to:
  /// **'Sign in with Iris Scan'**
  String get signInWithIrisScan;

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

  /// Phone field label
  ///
  /// In en, this message translates to:
  /// **'Phone'**
  String get phone;

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

  /// OR divider text
  ///
  /// In en, this message translates to:
  /// **'OR'**
  String get or;

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

  /// Sort label
  ///
  /// In en, this message translates to:
  /// **'Sort'**
  String get sort;

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
  /// **'See all'**
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

  /// Dashboard pending requests section
  ///
  /// In en, this message translates to:
  /// **'Pending Requests'**
  String get pendingRequests;

  /// Dashboard stat - total earned
  ///
  /// In en, this message translates to:
  /// **'Total Earned'**
  String get totalEarned;

  /// Dashboard stat - total jobs
  ///
  /// In en, this message translates to:
  /// **'Total Jobs'**
  String get totalJobs;

  /// Dashboard quick actions section
  ///
  /// In en, this message translates to:
  /// **'Quick Actions'**
  String get quickActions;

  /// Availability action label
  ///
  /// In en, this message translates to:
  /// **'Availability'**
  String get availability;

  /// Earnings action label
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

  /// Pending status label
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get pending;

  /// Confirmed status
  ///
  /// In en, this message translates to:
  /// **'Confirmed'**
  String get confirmed;

  /// Completed status label
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get completed;

  /// Cancelled status label
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

  /// Review rating title
  ///
  /// In en, this message translates to:
  /// **'Rate Your Experience'**
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

  /// Review submitted confirmation
  ///
  /// In en, this message translates to:
  /// **'Thank you for your review!'**
  String get thankYouForReview;

  /// App version label
  ///
  /// In en, this message translates to:
  /// **'Version'**
  String get version;

  /// Email validation error
  ///
  /// In en, this message translates to:
  /// **'Enter a valid email'**
  String get enterValidEmail;

  /// Password too short validation
  ///
  /// In en, this message translates to:
  /// **'Password too short'**
  String get passwordTooShort;

  /// Biometric not enabled message
  ///
  /// In en, this message translates to:
  /// **'Sign in first to enable {label} for quick login.'**
  String signInFirstBiometric(String label);

  /// Biometric not configured
  ///
  /// In en, this message translates to:
  /// **'{label} is not set up. Please enable it in your device settings first.'**
  String biometricNotSetUp(String label);

  /// Biometric locked out
  ///
  /// In en, this message translates to:
  /// **'{label} is locked. Try again later or use your passcode.'**
  String biometricLocked(String label);

  /// Biometric error
  ///
  /// In en, this message translates to:
  /// **'{label} error occurred.'**
  String biometricErrorOccurred(String label);

  /// Biometric auth reason
  ///
  /// In en, this message translates to:
  /// **'Use {label} to sign in'**
  String useBiometricToSignIn(String label);

  /// Google not configured error
  ///
  /// In en, this message translates to:
  /// **'Google Sign-In is not configured yet. Please use email login.'**
  String get googleSignInNotConfigured;

  /// Google sign-in no token error
  ///
  /// In en, this message translates to:
  /// **'Google Sign-In failed: no ID token'**
  String get googleSignInFailedNoToken;

  /// Google config error
  ///
  /// In en, this message translates to:
  /// **'Google Sign-In configuration error. Please check SHA-1 fingerprint in Firebase Console.'**
  String get googleSignInConfigError;

  /// Network error message
  ///
  /// In en, this message translates to:
  /// **'Network error. Please check your internet connection.'**
  String get networkError;

  /// Login failure message
  ///
  /// In en, this message translates to:
  /// **'Login failed'**
  String get loginFailed;

  /// Google login failure
  ///
  /// In en, this message translates to:
  /// **'Google login failed'**
  String get googleLoginFailed;

  /// Face ID label
  ///
  /// In en, this message translates to:
  /// **'Face ID'**
  String get faceId;

  /// Face recognition label
  ///
  /// In en, this message translates to:
  /// **'Face Recognition'**
  String get faceRecognition;

  /// Fingerprint label
  ///
  /// In en, this message translates to:
  /// **'Fingerprint'**
  String get fingerprint;

  /// Iris scan label
  ///
  /// In en, this message translates to:
  /// **'Iris Scan'**
  String get irisScan;

  /// Generic biometric label
  ///
  /// In en, this message translates to:
  /// **'Biometric'**
  String get biometric;

  /// Enable biometric dialog title
  ///
  /// In en, this message translates to:
  /// **'Enable {label}?'**
  String enableBiometric(String label);

  /// Enable biometric dialog body
  ///
  /// In en, this message translates to:
  /// **'Sign in faster next time using {label}. You can change this in settings.'**
  String signInFasterWithBiometric(String label);

  /// Not now button
  ///
  /// In en, this message translates to:
  /// **'Not Now'**
  String get notNow;

  /// Session expired dialog title
  ///
  /// In en, this message translates to:
  /// **'Session Expired'**
  String get sessionExpiredTitle;

  /// Session expired dialog body
  ///
  /// In en, this message translates to:
  /// **'Your session has expired for security reasons. Please sign in again to continue.'**
  String get sessionExpiredMessage;

  /// Role badge on register screen
  ///
  /// In en, this message translates to:
  /// **'Signing up as {role}'**
  String signingUpAsRole(String role);

  /// Nanny role label
  ///
  /// In en, this message translates to:
  /// **'Nanny'**
  String get nanny;

  /// Parent role label
  ///
  /// In en, this message translates to:
  /// **'Parent'**
  String get parent;

  /// Role select title
  ///
  /// In en, this message translates to:
  /// **'I am a...'**
  String get iAmA;

  /// Google role select title
  ///
  /// In en, this message translates to:
  /// **'One more step!'**
  String get oneMoreStep;

  /// Role select subtitle
  ///
  /// In en, this message translates to:
  /// **'Choose your role to get started'**
  String get chooseRoleToGetStarted;

  /// Google role select subtitle
  ///
  /// In en, this message translates to:
  /// **'Choose your role to complete sign-up'**
  String get chooseRoleToCompleteSignUp;

  /// Parent role card title
  ///
  /// In en, this message translates to:
  /// **'Parent'**
  String get parentRoleTitle;

  /// Parent role card subtitle
  ///
  /// In en, this message translates to:
  /// **'I want to find and hire a babysitter for my children'**
  String get parentRoleSubtitle;

  /// Nanny role card title
  ///
  /// In en, this message translates to:
  /// **'Nanny / Babysitter'**
  String get nannyRoleTitle;

  /// Nanny role card subtitle
  ///
  /// In en, this message translates to:
  /// **'I want to offer childcare services and find families'**
  String get nannyRoleSubtitle;

  /// Complete sign-up button
  ///
  /// In en, this message translates to:
  /// **'Complete Sign-Up'**
  String get completeSignUp;

  /// Continue button
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get continueButton;

  /// Full name validation
  ///
  /// In en, this message translates to:
  /// **'Enter your full name'**
  String get enterYourFullName;

  /// Email required validation
  ///
  /// In en, this message translates to:
  /// **'Email is required'**
  String get emailRequired;

  /// Email format validation
  ///
  /// In en, this message translates to:
  /// **'Enter a valid email address'**
  String get enterValidEmailAddress;

  /// Phone validation
  ///
  /// In en, this message translates to:
  /// **'Enter a valid phone number'**
  String get enterValidPhoneNumber;

  /// Date of birth field label
  ///
  /// In en, this message translates to:
  /// **'Date of Birth'**
  String get dateOfBirth;

  /// Date of birth picker hint
  ///
  /// In en, this message translates to:
  /// **'Select your date of birth'**
  String get selectYourDateOfBirth;

  /// Date of birth validation
  ///
  /// In en, this message translates to:
  /// **'Date of birth is required'**
  String get dateOfBirthRequired;

  /// Password min length validation
  ///
  /// In en, this message translates to:
  /// **'Password must be at least 8 characters'**
  String get passwordMinLength;

  /// Password complexity validation
  ///
  /// In en, this message translates to:
  /// **'Password must contain letters and numbers'**
  String get passwordLettersAndNumbers;

  /// Complete registration button
  ///
  /// In en, this message translates to:
  /// **'Complete Registration'**
  String get completeRegistration;

  /// Registration failure
  ///
  /// In en, this message translates to:
  /// **'Registration failed'**
  String get registrationFailed;

  /// Google account linked snackbar
  ///
  /// In en, this message translates to:
  /// **'Google account linked! Please complete the remaining fields.'**
  String get googleAccountLinked;

  /// Google linked banner
  ///
  /// In en, this message translates to:
  /// **'Google account linked. Complete the fields below to finish registration.'**
  String get googleAccountLinkedInfo;

  /// Terms agreement text
  ///
  /// In en, this message translates to:
  /// **'By creating an account, you agree to our Terms of Service and Privacy Policy.'**
  String get agreeToTerms;

  /// Google not configured for signup
  ///
  /// In en, this message translates to:
  /// **'Google Sign-In is not configured yet. Please use email registration.'**
  String get googleSignUpNotConfigured;

  /// Verify phone screen title
  ///
  /// In en, this message translates to:
  /// **'Verify Phone'**
  String get verifyPhone;

  /// Phone verification title
  ///
  /// In en, this message translates to:
  /// **'Enter Verification Code'**
  String get enterVerificationCode;

  /// Phone code sent message
  ///
  /// In en, this message translates to:
  /// **'We sent a 6-digit code to\n{phone}'**
  String weSentCodeToPhone(String phone);

  /// 6-digit code validation
  ///
  /// In en, this message translates to:
  /// **'Please enter the 6-digit code'**
  String get enterSixDigitCode;

  /// Phone verified success
  ///
  /// In en, this message translates to:
  /// **'Phone verified successfully!'**
  String get phoneVerified;

  /// Invalid code error
  ///
  /// In en, this message translates to:
  /// **'Invalid or expired code. Please try again.'**
  String get invalidOrExpiredCode;

  /// Code resent success
  ///
  /// In en, this message translates to:
  /// **'Code resent!'**
  String get codeResent;

  /// Resend code failure
  ///
  /// In en, this message translates to:
  /// **'Failed to resend code'**
  String get failedToResendCode;

  /// Verify button
  ///
  /// In en, this message translates to:
  /// **'Verify'**
  String get verify;

  /// Resend code link
  ///
  /// In en, this message translates to:
  /// **'Didn\'t receive it? Resend code'**
  String get didntReceiveResend;

  /// Email verification title
  ///
  /// In en, this message translates to:
  /// **'Verify your email'**
  String get verifyYourEmail;

  /// Email code sent prefix
  ///
  /// In en, this message translates to:
  /// **'We sent a 6-digit code to'**
  String get weSentCodeTo;

  /// OTP incomplete validation
  ///
  /// In en, this message translates to:
  /// **'Please enter all 6 digits'**
  String get enterAllDigits;

  /// OTP verification failure
  ///
  /// In en, this message translates to:
  /// **'Verification failed'**
  String get verificationFailed;

  /// Resend OTP success
  ///
  /// In en, this message translates to:
  /// **'A new code has been sent to your email'**
  String get newCodeSentToEmail;

  /// Resend OTP failure
  ///
  /// In en, this message translates to:
  /// **'Failed to resend code. Please try again.'**
  String get failedToResendCodeRetry;

  /// Resend countdown
  ///
  /// In en, this message translates to:
  /// **'Resend code in {seconds}s'**
  String resendCodeIn(int seconds);

  /// Resend code button
  ///
  /// In en, this message translates to:
  /// **'Resend code'**
  String get resendCode;

  /// Wrong email link
  ///
  /// In en, this message translates to:
  /// **'Wrong email?'**
  String get wrongEmail;

  /// Go back link
  ///
  /// In en, this message translates to:
  /// **'Go back'**
  String get goBack;

  /// Booking detail screen title
  ///
  /// In en, this message translates to:
  /// **'Booking Details'**
  String get bookingDetails;

  /// Booking load error
  ///
  /// In en, this message translates to:
  /// **'Could not load booking'**
  String get couldNotLoadBooking;

  /// Requested status
  ///
  /// In en, this message translates to:
  /// **'Requested'**
  String get requested;

  /// Accepted status label
  ///
  /// In en, this message translates to:
  /// **'Accepted'**
  String get accepted;

  /// Declined status
  ///
  /// In en, this message translates to:
  /// **'Declined'**
  String get declinedStatus;

  /// Requested status description
  ///
  /// In en, this message translates to:
  /// **'Waiting for nanny to respond'**
  String get waitingForNannyResponse;

  /// Accepted status description
  ///
  /// In en, this message translates to:
  /// **'Booking confirmed! Start the session when ready'**
  String get bookingConfirmedStartReady;

  /// In progress status description
  ///
  /// In en, this message translates to:
  /// **'Session is currently active'**
  String get sessionCurrentlyActive;

  /// Completed status description
  ///
  /// In en, this message translates to:
  /// **'This session has been completed'**
  String get sessionHasBeenCompleted;

  /// Declined status description
  ///
  /// In en, this message translates to:
  /// **'The nanny declined this request'**
  String get nannyDeclinedRequest;

  /// Cancelled status description
  ///
  /// In en, this message translates to:
  /// **'This booking was cancelled'**
  String get bookingWasCancelled;

  /// Nanny card header for parent
  ///
  /// In en, this message translates to:
  /// **'Your Nanny'**
  String get yourNanny;

  /// Recurring booking badge
  ///
  /// In en, this message translates to:
  /// **'Part of Recurring Booking'**
  String get partOfRecurringBooking;

  /// Schedule section title
  ///
  /// In en, this message translates to:
  /// **'Schedule'**
  String get schedule;

  /// Start CTA button
  ///
  /// In en, this message translates to:
  /// **'Start'**
  String get start;

  /// End label
  ///
  /// In en, this message translates to:
  /// **'End'**
  String get end;

  /// Duration label
  ///
  /// In en, this message translates to:
  /// **'Duration'**
  String get duration;

  /// Hours display
  ///
  /// In en, this message translates to:
  /// **'{count} hours'**
  String hoursLabel(String count);

  /// Payment section title
  ///
  /// In en, this message translates to:
  /// **'Payment'**
  String get payment;

  /// Rate label
  ///
  /// In en, this message translates to:
  /// **'Rate'**
  String get rate;

  /// Estimated label
  ///
  /// In en, this message translates to:
  /// **'Estimated'**
  String get estimated;

  /// Booked label
  ///
  /// In en, this message translates to:
  /// **'Booked'**
  String get booked;

  /// Total label
  ///
  /// In en, this message translates to:
  /// **'Total'**
  String get total;

  /// Price calculation note
  ///
  /// In en, this message translates to:
  /// **'Final price calculated by session timer'**
  String get finalPriceByTimer;

  /// Overtime label
  ///
  /// In en, this message translates to:
  /// **'Overtime'**
  String get overtime;

  /// Final total label
  ///
  /// In en, this message translates to:
  /// **'Final Total'**
  String get finalTotal;

  /// Actual duration label
  ///
  /// In en, this message translates to:
  /// **'Actual Duration'**
  String get actualDuration;

  /// Minutes abbreviation
  ///
  /// In en, this message translates to:
  /// **'min'**
  String get minLabel;

  /// Status label
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get statusLabel;

  /// Paid status
  ///
  /// In en, this message translates to:
  /// **'Paid'**
  String get paid;

  /// Processing status
  ///
  /// In en, this message translates to:
  /// **'Processing'**
  String get processing;

  /// Pending session payment status
  ///
  /// In en, this message translates to:
  /// **'Pending session'**
  String get pendingSessionStatus;

  /// Cancel booking button
  ///
  /// In en, this message translates to:
  /// **'Cancel Booking'**
  String get cancelBooking;

  /// Start live session button
  ///
  /// In en, this message translates to:
  /// **'Start Live Session'**
  String get startLiveSession;

  /// View live session button
  ///
  /// In en, this message translates to:
  /// **'View Live Session'**
  String get viewLiveSession;

  /// Leave review button
  ///
  /// In en, this message translates to:
  /// **'Leave a Review'**
  String get leaveReview;

  /// Review input hint
  ///
  /// In en, this message translates to:
  /// **'Write your review (optional)'**
  String get writeYourReview;

  /// Submit button
  ///
  /// In en, this message translates to:
  /// **'Submit'**
  String get submit;

  /// Generic action failure
  ///
  /// In en, this message translates to:
  /// **'Action failed. Please try again.'**
  String get actionFailed;

  /// Navigate button
  ///
  /// In en, this message translates to:
  /// **'Navigate'**
  String get navigate;

  /// See on map fallback
  ///
  /// In en, this message translates to:
  /// **'See on map'**
  String get seeOnMap;

  /// Call person button
  ///
  /// In en, this message translates to:
  /// **'Call {name}'**
  String callName(String name);

  /// Recurring booking type label
  ///
  /// In en, this message translates to:
  /// **'Recurring Booking'**
  String get recurringBookingLabel;

  /// One-time booking type label
  ///
  /// In en, this message translates to:
  /// **'One-time Booking'**
  String get oneTimeBookingLabel;

  /// Children label
  ///
  /// In en, this message translates to:
  /// **'Children'**
  String get children;

  /// Payment info note
  ///
  /// In en, this message translates to:
  /// **'Payment is charged only after the session ends, based on actual hours.'**
  String get paymentChargedAfterSession;

  /// Booking success title
  ///
  /// In en, this message translates to:
  /// **'Booking Requested!'**
  String get bookingRequested;

  /// Booking success message
  ///
  /// In en, this message translates to:
  /// **'Your booking request has been sent to the nanny.\nYou\'ll receive a notification when they respond.'**
  String get bookingRequestSentMessage;

  /// Push notification pill
  ///
  /// In en, this message translates to:
  /// **'Push notification'**
  String get pushNotification;

  /// Chat available pill
  ///
  /// In en, this message translates to:
  /// **'Chat available'**
  String get chatAvailable;

  /// View booking button
  ///
  /// In en, this message translates to:
  /// **'View Booking'**
  String get viewBooking;

  /// Back to home button
  ///
  /// In en, this message translates to:
  /// **'Back to Home'**
  String get backToHome;

  /// Route to person map title
  ///
  /// In en, this message translates to:
  /// **'Route to {name}'**
  String routeTo(String name);

  /// Google Maps navigation button
  ///
  /// In en, this message translates to:
  /// **'Navigate with Google Maps'**
  String get navigateWithGoogleMaps;

  /// Distance calculation loading
  ///
  /// In en, this message translates to:
  /// **'Calculating distance...'**
  String get calculatingDistance;

  /// Distance display
  ///
  /// In en, this message translates to:
  /// **'Distance: {distance}'**
  String distanceValue(String distance);

  /// No location fallback
  ///
  /// In en, this message translates to:
  /// **'Location not available'**
  String get locationNotAvailable;

  /// Account section header
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get account;

  /// My bookings menu item
  ///
  /// In en, this message translates to:
  /// **'My Bookings'**
  String get myBookings;

  /// Recurring bookings menu item
  ///
  /// In en, this message translates to:
  /// **'Recurring Bookings'**
  String get recurringBookings;

  /// Saved nannies menu item
  ///
  /// In en, this message translates to:
  /// **'Saved Nannies'**
  String get savedNannies;

  /// Dashboard menu item
  ///
  /// In en, this message translates to:
  /// **'Dashboard'**
  String get dashboard;

  /// Manage availability menu item
  ///
  /// In en, this message translates to:
  /// **'Manage Availability'**
  String get manageAvailability;

  /// Get verified menu item
  ///
  /// In en, this message translates to:
  /// **'Get Verified'**
  String get getVerified;

  /// Documents action label
  ///
  /// In en, this message translates to:
  /// **'Documents'**
  String get documents;

  /// iOS biometric menu label
  ///
  /// In en, this message translates to:
  /// **'Face ID / Touch ID'**
  String get faceIdTouchId;

  /// Android biometric menu label
  ///
  /// In en, this message translates to:
  /// **'Fingerprint Login'**
  String get fingerprintLogin;

  /// Help menu item
  ///
  /// In en, this message translates to:
  /// **'Help & Support'**
  String get helpAndSupport;

  /// About menu item
  ///
  /// In en, this message translates to:
  /// **'About SuperNanny'**
  String get aboutSuperNanny;

  /// Sign out button
  ///
  /// In en, this message translates to:
  /// **'Sign Out'**
  String get signOut;

  /// Biometric not available error
  ///
  /// In en, this message translates to:
  /// **'Biometric authentication is not available on this device'**
  String get biometricNotAvailable;

  /// Biometric disabled message
  ///
  /// In en, this message translates to:
  /// **'Biometric login disabled'**
  String get biometricLoginDisabled;

  /// Biometric enabled message
  ///
  /// In en, this message translates to:
  /// **'{label} login enabled!'**
  String biometricLoginEnabled(String label);

  /// Re-login for biometric
  ///
  /// In en, this message translates to:
  /// **'Please sign in again to enable biometric login'**
  String get signInAgainBiometric;

  /// Biometric verification reason
  ///
  /// In en, this message translates to:
  /// **'Verify your identity to enable biometric login'**
  String get verifyIdentityBiometric;

  /// Delete account warning
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to permanently delete your account?\n\nThis action cannot be undone. All your data will be removed, and any upcoming bookings will be cancelled.'**
  String get deleteAccountWarning;

  /// Final confirmation dialog title
  ///
  /// In en, this message translates to:
  /// **'Final Confirmation'**
  String get finalConfirmation;

  /// Final delete warning
  ///
  /// In en, this message translates to:
  /// **'This is your last chance. Once deleted, your account and all associated data will be permanently removed.\n\nType \"DELETE\" below is not required — just tap the button to confirm.'**
  String get finalDeleteWarning;

  /// Keep account button
  ///
  /// In en, this message translates to:
  /// **'Keep My Account'**
  String get keepMyAccount;

  /// Confirm delete button
  ///
  /// In en, this message translates to:
  /// **'Yes, Delete Forever'**
  String get yesDeleteForever;

  /// Account deleted message
  ///
  /// In en, this message translates to:
  /// **'Your account has been deleted'**
  String get accountDeleted;

  /// Delete account failure
  ///
  /// In en, this message translates to:
  /// **'Failed to delete account. Please try again.'**
  String get failedToDeleteAccount;

  /// Sign out confirmation
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to sign out?'**
  String get signOutConfirmation;

  /// Change photo hint
  ///
  /// In en, this message translates to:
  /// **'Tap to change photo'**
  String get tapToChangePhoto;

  /// Profile updated success
  ///
  /// In en, this message translates to:
  /// **'Profile updated'**
  String get profileUpdated;

  /// Update failure prefix
  ///
  /// In en, this message translates to:
  /// **'Update failed'**
  String get updateFailed;

  /// Save changes button
  ///
  /// In en, this message translates to:
  /// **'Save Changes'**
  String get saveChanges;

  /// Required field validation
  ///
  /// In en, this message translates to:
  /// **'Required'**
  String get required;

  /// Find nav tab
  ///
  /// In en, this message translates to:
  /// **'Find'**
  String get find;

  /// Jobs nav tab
  ///
  /// In en, this message translates to:
  /// **'Jobs'**
  String get jobs;

  /// Nearby nav tab
  ///
  /// In en, this message translates to:
  /// **'Nearby'**
  String get nearby;

  /// Search bar placeholder
  ///
  /// In en, this message translates to:
  /// **'Search by city or area...'**
  String get searchByCityOrArea;

  /// Location picker title
  ///
  /// In en, this message translates to:
  /// **'Select Location'**
  String get selectLocation;

  /// City search placeholder
  ///
  /// In en, this message translates to:
  /// **'Search city...'**
  String get searchCity;

  /// Use my location option
  ///
  /// In en, this message translates to:
  /// **'Use My Location'**
  String get useMyLocation;

  /// Search results count
  ///
  /// In en, this message translates to:
  /// **'{count} nannies found'**
  String nanniesFound(int count);

  /// Empty nannies list
  ///
  /// In en, this message translates to:
  /// **'No nannies found'**
  String get noNanniesFound;

  /// Empty search hint
  ///
  /// In en, this message translates to:
  /// **'Try adjusting your search or filters'**
  String get tryAdjustingSearch;

  /// Nannies load error
  ///
  /// In en, this message translates to:
  /// **'Could not load nannies'**
  String get couldNotLoadNannies;

  /// Sort option
  ///
  /// In en, this message translates to:
  /// **'Price: Low → High'**
  String get priceLowToHigh;

  /// Sort option
  ///
  /// In en, this message translates to:
  /// **'Price: High → Low'**
  String get priceHighToLow;

  /// Sort option
  ///
  /// In en, this message translates to:
  /// **'Most Experienced'**
  String get mostExperienced;

  /// Sort option
  ///
  /// In en, this message translates to:
  /// **'Most Reviews'**
  String get mostReviews;

  /// Sort option
  ///
  /// In en, this message translates to:
  /// **'Newest'**
  String get newest;

  /// Reset all filters
  ///
  /// In en, this message translates to:
  /// **'Reset all'**
  String get resetAll;

  /// Filter section title
  ///
  /// In en, this message translates to:
  /// **'Care Type'**
  String get careType;

  /// Ongoing care filter
  ///
  /// In en, this message translates to:
  /// **'Ongoing Care'**
  String get ongoingCare;

  /// Recurring rate slider label
  ///
  /// In en, this message translates to:
  /// **'Recurring Rate (₪)'**
  String get recurringRateLabel;

  /// Hourly rate slider label
  ///
  /// In en, this message translates to:
  /// **'Hourly Rate (₪)'**
  String get hourlyRateLabel;

  /// Filter section title
  ///
  /// In en, this message translates to:
  /// **'Minimum Rating'**
  String get minimumRating;

  /// Any option
  ///
  /// In en, this message translates to:
  /// **'Any'**
  String get any;

  /// Filter section title
  ///
  /// In en, this message translates to:
  /// **'Min. Experience'**
  String get minExperience;

  /// Filter section title
  ///
  /// In en, this message translates to:
  /// **'Specialization'**
  String get specialization;

  /// Apply filters button
  ///
  /// In en, this message translates to:
  /// **'Apply Filters'**
  String get applyFilters;

  /// Admin dashboard title
  ///
  /// In en, this message translates to:
  /// **'Admin Dashboard'**
  String get adminDashboard;

  /// Admin overview title
  ///
  /// In en, this message translates to:
  /// **'Platform Overview'**
  String get platformOverview;

  /// Users section
  ///
  /// In en, this message translates to:
  /// **'Users'**
  String get users;

  /// Parents label
  ///
  /// In en, this message translates to:
  /// **'Parents'**
  String get parents;

  /// Nannies label
  ///
  /// In en, this message translates to:
  /// **'Nannies'**
  String get nannies;

  /// Management section
  ///
  /// In en, this message translates to:
  /// **'Management'**
  String get management;

  /// Manage users menu
  ///
  /// In en, this message translates to:
  /// **'Manage Users'**
  String get manageUsers;

  /// Users management subtitle
  ///
  /// In en, this message translates to:
  /// **'View, activate, or deactivate accounts'**
  String get viewActivateDeactivate;

  /// Review bookings menu
  ///
  /// In en, this message translates to:
  /// **'Review Bookings'**
  String get reviewBookings;

  /// Bookings management subtitle
  ///
  /// In en, this message translates to:
  /// **'Monitor and manage all bookings'**
  String get monitorManageBookings;

  /// Verify nannies menu
  ///
  /// In en, this message translates to:
  /// **'Verify Nannies'**
  String get verifyNannies;

  /// Nanny approval subtitle
  ///
  /// In en, this message translates to:
  /// **'Review and approve nanny applications'**
  String get reviewApproveNannies;

  /// Approvals tab
  ///
  /// In en, this message translates to:
  /// **'Approvals'**
  String get approvals;

  /// Revenue section
  ///
  /// In en, this message translates to:
  /// **'Revenue'**
  String get revenue;

  /// Platform fees label
  ///
  /// In en, this message translates to:
  /// **'Platform Fees'**
  String get platformFees;

  /// Gross volume label
  ///
  /// In en, this message translates to:
  /// **'Gross Volume'**
  String get grossVolume;

  /// Admin data error
  ///
  /// In en, this message translates to:
  /// **'Could not load admin data'**
  String get couldNotLoadAdminData;

  /// Generic load error title
  ///
  /// In en, this message translates to:
  /// **'Could not load'**
  String get couldNotLoad;

  /// Dashboard error subtitle
  ///
  /// In en, this message translates to:
  /// **'Check your connection and try again'**
  String get checkConnectionRetry;

  /// Inline error title
  ///
  /// In en, this message translates to:
  /// **'Failed to load'**
  String get failedToLoad;

  /// Photo upload success
  ///
  /// In en, this message translates to:
  /// **'Profile photo updated'**
  String get profilePhotoUpdated;

  /// Photo upload failure
  ///
  /// In en, this message translates to:
  /// **'Upload failed. Please try again.'**
  String get uploadFailed;

  /// Permission dialog title
  ///
  /// In en, this message translates to:
  /// **'{feature} Access Required'**
  String featureAccessRequired(String feature);

  /// Gallery option subtitle
  ///
  /// In en, this message translates to:
  /// **'Choose from Gallery'**
  String get chooseFromGallery;

  /// Camera option subtitle
  ///
  /// In en, this message translates to:
  /// **'Use your camera'**
  String get useYourCamera;

  /// System default language option
  ///
  /// In en, this message translates to:
  /// **'System Default'**
  String get systemDefault;

  /// Empty notifications
  ///
  /// In en, this message translates to:
  /// **'No notifications yet'**
  String get noNotifications;

  /// Full name hint text
  ///
  /// In en, this message translates to:
  /// **'Your full name'**
  String get yourFullName;

  /// Nearby section title
  ///
  /// In en, this message translates to:
  /// **'Nannies near you'**
  String get nanniesNearYou;

  /// Open settings button
  ///
  /// In en, this message translates to:
  /// **'Open Settings'**
  String get openSettings;

  /// Location required message
  ///
  /// In en, this message translates to:
  /// **'Location access is needed to show nearby nannies'**
  String get locationRequired;

  /// Verification banner - approved title
  ///
  /// In en, this message translates to:
  /// **'Verified'**
  String get verified;

  /// Unverified badge
  ///
  /// In en, this message translates to:
  /// **'Unverified'**
  String get unverified;

  /// Active status
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get active;

  /// Inactive status
  ///
  /// In en, this message translates to:
  /// **'Inactive'**
  String get inactive;

  /// Empty data message
  ///
  /// In en, this message translates to:
  /// **'No data available'**
  String get noDataAvailable;

  /// Booking status update snackbar
  ///
  /// In en, this message translates to:
  /// **'Booking {status}'**
  String bookingStatusUpdated(String status);

  /// Onboarding get started button
  ///
  /// In en, this message translates to:
  /// **'Get Started'**
  String get getStarted;

  /// Onboarding welcome title
  ///
  /// In en, this message translates to:
  /// **'Welcome to SuperNanny'**
  String get welcomeToSuperNanny;

  /// Onboarding subtitle
  ///
  /// In en, this message translates to:
  /// **'Find the perfect nanny for your family'**
  String get findPerfectNanny;

  /// Live session screen title
  ///
  /// In en, this message translates to:
  /// **'Live Session'**
  String get liveSessionTimer;

  /// Session started message
  ///
  /// In en, this message translates to:
  /// **'Session Started'**
  String get sessionStarted;

  /// Session ended message
  ///
  /// In en, this message translates to:
  /// **'Session Ended'**
  String get sessionEnded;

  /// End session confirmation
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to end this session?'**
  String get endSessionConfirmation;

  /// Session summary title
  ///
  /// In en, this message translates to:
  /// **'Session Summary'**
  String get sessionSummary;

  /// Total time label
  ///
  /// In en, this message translates to:
  /// **'Total Time'**
  String get totalTime;

  /// Total cost label
  ///
  /// In en, this message translates to:
  /// **'Total Cost'**
  String get totalCost;

  /// Verification screen title
  ///
  /// In en, this message translates to:
  /// **'Verification Request'**
  String get verificationRequest;

  /// Upload documents button
  ///
  /// In en, this message translates to:
  /// **'Upload Documents'**
  String get uploadDocuments;

  /// Verification pending status
  ///
  /// In en, this message translates to:
  /// **'Verification Pending'**
  String get verificationPending;

  /// Verification approved status
  ///
  /// In en, this message translates to:
  /// **'Verification Approved'**
  String get verificationApproved;

  /// Empty verifications
  ///
  /// In en, this message translates to:
  /// **'No pending verifications'**
  String get noPendingVerifications;

  /// Approve button
  ///
  /// In en, this message translates to:
  /// **'Approve'**
  String get approve;

  /// Reject button
  ///
  /// In en, this message translates to:
  /// **'Reject'**
  String get reject;

  /// All bookings title
  ///
  /// In en, this message translates to:
  /// **'All Bookings'**
  String get allBookings;

  /// Empty admin bookings
  ///
  /// In en, this message translates to:
  /// **'No bookings found'**
  String get noBookingsFound;

  /// User details title
  ///
  /// In en, this message translates to:
  /// **'User Details'**
  String get userDetails;

  /// Deactivate account button
  ///
  /// In en, this message translates to:
  /// **'Deactivate Account'**
  String get deactivateAccount;

  /// Activate account button
  ///
  /// In en, this message translates to:
  /// **'Activate Account'**
  String get activateAccount;

  /// Select days label
  ///
  /// In en, this message translates to:
  /// **'Select Days'**
  String get selectDays;

  /// From time label
  ///
  /// In en, this message translates to:
  /// **'From'**
  String get fromTime;

  /// To time label
  ///
  /// In en, this message translates to:
  /// **'To'**
  String get toTime;

  /// Add time slot button
  ///
  /// In en, this message translates to:
  /// **'Add Time Slot'**
  String get addTimeSlot;

  /// Empty availability
  ///
  /// In en, this message translates to:
  /// **'No availability set'**
  String get noAvailabilitySet;

  /// Earnings screen title
  ///
  /// In en, this message translates to:
  /// **'Earnings Summary'**
  String get earningsSummary;

  /// This month label
  ///
  /// In en, this message translates to:
  /// **'This Month'**
  String get thisMonth;

  /// All time label
  ///
  /// In en, this message translates to:
  /// **'All Time'**
  String get allTime;

  /// Empty earnings
  ///
  /// In en, this message translates to:
  /// **'No earnings yet'**
  String get noEarningsYet;

  /// Address selection label
  ///
  /// In en, this message translates to:
  /// **'Choose address'**
  String get chooseAddress;

  /// Registered address option
  ///
  /// In en, this message translates to:
  /// **'Registered Address'**
  String get registeredAddress;

  /// Current location option
  ///
  /// In en, this message translates to:
  /// **'Current Location'**
  String get currentLocation;

  /// Manual address entry
  ///
  /// In en, this message translates to:
  /// **'Enter Manually'**
  String get enterManually;

  /// Street field label
  ///
  /// In en, this message translates to:
  /// **'Street'**
  String get street;

  /// House number field label
  ///
  /// In en, this message translates to:
  /// **'House Number'**
  String get houseNumber;

  /// Postal code field label
  ///
  /// In en, this message translates to:
  /// **'Postal Code'**
  String get postalCode;

  /// Booking step: when
  ///
  /// In en, this message translates to:
  /// **'When'**
  String get when;

  /// Booking step: details
  ///
  /// In en, this message translates to:
  /// **'Details'**
  String get details;

  /// Booking step: confirm
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get confirmBooking;

  /// Recurring start date
  ///
  /// In en, this message translates to:
  /// **'Select start date'**
  String get selectStartDate;

  /// Recurring end date
  ///
  /// In en, this message translates to:
  /// **'Select end date'**
  String get selectEndDate;

  /// Location type label
  ///
  /// In en, this message translates to:
  /// **'Location Type'**
  String get locationType;

  /// Parent home option
  ///
  /// In en, this message translates to:
  /// **'Parent\'s Home'**
  String get parentHome;

  /// Nanny home option
  ///
  /// In en, this message translates to:
  /// **'Nanny\'s Home'**
  String get nannyHome;

  /// Minimum hours message
  ///
  /// In en, this message translates to:
  /// **'Minimum {hours} hours required'**
  String minimumHoursRequired(String hours);

  /// Booking history title
  ///
  /// In en, this message translates to:
  /// **'Booking History'**
  String get bookingHistory;

  /// Notification settings title
  ///
  /// In en, this message translates to:
  /// **'Notification Settings'**
  String get notificationsSettings;

  /// Push notifications toggle
  ///
  /// In en, this message translates to:
  /// **'Push Notifications'**
  String get pushNotifications;

  /// Email notifications toggle
  ///
  /// In en, this message translates to:
  /// **'Email Notifications'**
  String get emailNotifications;

  /// Booking reminders toggle
  ///
  /// In en, this message translates to:
  /// **'Booking Reminders'**
  String get bookingReminders;

  /// Message notifications toggle
  ///
  /// In en, this message translates to:
  /// **'Message Notifications'**
  String get messageNotifications;

  /// Contact us label
  ///
  /// In en, this message translates to:
  /// **'Contact Us'**
  String get contactUs;

  /// FAQ label
  ///
  /// In en, this message translates to:
  /// **'FAQ'**
  String get faq;

  /// Report problem label
  ///
  /// In en, this message translates to:
  /// **'Report a Problem'**
  String get reportProblem;

  /// Privacy settings title
  ///
  /// In en, this message translates to:
  /// **'Privacy Settings'**
  String get privacySettings;

  /// Privacy toggle
  ///
  /// In en, this message translates to:
  /// **'Show profile to nearby users'**
  String get showProfileToNearby;

  /// Privacy toggle
  ///
  /// In en, this message translates to:
  /// **'Show phone number'**
  String get showPhoneNumber;

  /// Nearby screen title
  ///
  /// In en, this message translates to:
  /// **'Nannies Nearby'**
  String get nanniesNearby;

  /// View on map button
  ///
  /// In en, this message translates to:
  /// **'View on Map'**
  String get viewOnMap;

  /// Added to favorites toast
  ///
  /// In en, this message translates to:
  /// **'Added to favorites'**
  String get addedToFavorites;

  /// Removed from favorites toast
  ///
  /// In en, this message translates to:
  /// **'Removed from favorites'**
  String get removedFromFavorites;

  /// Empty chat list
  ///
  /// In en, this message translates to:
  /// **'No chats yet'**
  String get noChatsYet;

  /// Empty chat hint
  ///
  /// In en, this message translates to:
  /// **'Start a conversation by booking a nanny'**
  String get startChatting;

  /// Gallery subtitle in photo picker
  ///
  /// In en, this message translates to:
  /// **'Select an existing photo'**
  String get selectExistingPhoto;

  /// Placeholder text for profile image board
  ///
  /// In en, this message translates to:
  /// **'Tap to add photo'**
  String get tapToAddPhoto;

  /// Permission denied dialog message
  ///
  /// In en, this message translates to:
  /// **'Please enable {feature} access in your device Settings to use this feature.'**
  String pleaseEnableFeatureAccess(String feature);

  /// Error when camera/gallery cannot open
  ///
  /// In en, this message translates to:
  /// **'Could not open {source}. Please check app permissions in Settings.'**
  String couldNotOpenSource(String source);

  /// Short error when camera/gallery cannot open
  ///
  /// In en, this message translates to:
  /// **'Could not open {source}. Please check app permissions.'**
  String couldNotOpenSourceShort(String source);

  /// View button on nanny card
  ///
  /// In en, this message translates to:
  /// **'View'**
  String get viewButton;

  /// More button on section header
  ///
  /// In en, this message translates to:
  /// **'More'**
  String get moreButton;

  /// First Aid badge label
  ///
  /// In en, this message translates to:
  /// **'First Aid'**
  String get firstAidBadge;

  /// Top Rated badge label
  ///
  /// In en, this message translates to:
  /// **'Top Rated'**
  String get topRatedBadge;

  /// Fast Responder badge label
  ///
  /// In en, this message translates to:
  /// **'Fast'**
  String get fastBadge;

  /// Background Checked badge label
  ///
  /// In en, this message translates to:
  /// **'Checked'**
  String get checkedBadge;

  /// 5+ years experience badge label
  ///
  /// In en, this message translates to:
  /// **'5+ Years'**
  String get fiveYearsPlusBadge;

  /// Recurring badge label
  ///
  /// In en, this message translates to:
  /// **'Recurring'**
  String get recurringBadge;

  /// Blocked day in availability calendar
  ///
  /// In en, this message translates to:
  /// **'Blocked'**
  String get blockedDay;

  /// Day with existing bookings
  ///
  /// In en, this message translates to:
  /// **'Has existing booking(s)'**
  String get hasExistingBookings;

  /// Available time range for a date
  ///
  /// In en, this message translates to:
  /// **'Available: {timeRange}'**
  String availableTime(String timeRange);

  /// Minimum hours per booking session
  ///
  /// In en, this message translates to:
  /// **'Minimum {hours} hours per session'**
  String minimumHoursPerSession(String hours);

  /// Nanny count badge on mini map
  ///
  /// In en, this message translates to:
  /// **'nannies nearby {count}'**
  String nanniesNearbyCount(int count);

  /// Map expand hint
  ///
  /// In en, this message translates to:
  /// **'Tap to expand map'**
  String get tapToExpandMap;

  /// Open map button
  ///
  /// In en, this message translates to:
  /// **'Open Map'**
  String get openMap;

  /// Dismiss button
  ///
  /// In en, this message translates to:
  /// **'Dismiss'**
  String get dismiss;

  /// Booking starts in countdown
  ///
  /// In en, this message translates to:
  /// **'Starts in {time}'**
  String startsIn(String time);

  /// All category label
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get categoryAll;

  /// Ongoing Care category label
  ///
  /// In en, this message translates to:
  /// **'Ongoing Care'**
  String get categoryOngoingCare;

  /// Infant category label
  ///
  /// In en, this message translates to:
  /// **'Infant'**
  String get categoryInfant;

  /// Toddler category label
  ///
  /// In en, this message translates to:
  /// **'Toddler'**
  String get categoryToddler;

  /// School Age category label
  ///
  /// In en, this message translates to:
  /// **'School Age'**
  String get categorySchoolAge;

  /// Special Needs category label
  ///
  /// In en, this message translates to:
  /// **'Special Needs'**
  String get categorySpecialNeeds;

  /// First Aid category label
  ///
  /// In en, this message translates to:
  /// **'First Aid'**
  String get categoryFirstAid;

  /// Night Care category label
  ///
  /// In en, this message translates to:
  /// **'Night Care'**
  String get categoryNightCare;

  /// Weekend category label
  ///
  /// In en, this message translates to:
  /// **'Weekend'**
  String get categoryWeekend;

  /// Welcome promo banner title
  ///
  /// In en, this message translates to:
  /// **'Welcome to SuperNanny!'**
  String get promoWelcomeTitle;

  /// Welcome promo banner subtitle
  ///
  /// In en, this message translates to:
  /// **'Find your perfect babysitter in minutes'**
  String get promoWelcomeSubtitle;

  /// Verified promo banner title
  ///
  /// In en, this message translates to:
  /// **'Verified & Trusted'**
  String get promoVerifiedTitle;

  /// Verified promo banner subtitle
  ///
  /// In en, this message translates to:
  /// **'All nannies are background-checked'**
  String get promoVerifiedSubtitle;

  /// Book promo banner title
  ///
  /// In en, this message translates to:
  /// **'Book Instantly'**
  String get promoBookTitle;

  /// Book promo banner subtitle
  ///
  /// In en, this message translates to:
  /// **'No waiting, no hassle — just book & go'**
  String get promoBookSubtitle;

  /// Calendar legend - available
  ///
  /// In en, this message translates to:
  /// **'Available'**
  String get legendAvailable;

  /// Calendar legend - booked
  ///
  /// In en, this message translates to:
  /// **'Booked'**
  String get legendBooked;

  /// Calendar legend - blocked
  ///
  /// In en, this message translates to:
  /// **'Blocked'**
  String get legendBlocked;

  /// Chat list error title
  ///
  /// In en, this message translates to:
  /// **'Could not load messages'**
  String get couldNotLoadMessages;

  /// Chat list empty state title
  ///
  /// In en, this message translates to:
  /// **'No messages yet'**
  String get noMessagesYet;

  /// Chat list empty state subtitle
  ///
  /// In en, this message translates to:
  /// **'Start a conversation by booking a nanny'**
  String get startConversationByBooking;

  /// Mark all notifications as read
  ///
  /// In en, this message translates to:
  /// **'Mark all read'**
  String get markAllRead;

  /// Notifications error title
  ///
  /// In en, this message translates to:
  /// **'Could not load notifications'**
  String get couldNotLoadNotifications;

  /// Notifications empty state title
  ///
  /// In en, this message translates to:
  /// **'No notifications yet'**
  String get noNotificationsYet;

  /// Notifications empty state subtitle
  ///
  /// In en, this message translates to:
  /// **'When you receive booking updates, messages, or other alerts, they\'ll appear here.'**
  String get notificationsEmptyDescription;

  /// Nearby screen title
  ///
  /// In en, this message translates to:
  /// **'Nearby Nannies'**
  String get nearbyNannies;

  /// Near you location chip
  ///
  /// In en, this message translates to:
  /// **'Near you'**
  String get nearYou;

  /// Nearby empty state
  ///
  /// In en, this message translates to:
  /// **'No nannies found nearby'**
  String get noNanniesFoundNearby;

  /// Favorites error title
  ///
  /// In en, this message translates to:
  /// **'Could not load favorites'**
  String get couldNotLoadFavorites;

  /// Favorites empty state title
  ///
  /// In en, this message translates to:
  /// **'No saved nannies yet'**
  String get noSavedNanniesYet;

  /// Favorites empty state subtitle
  ///
  /// In en, this message translates to:
  /// **'Tap the heart icon on a nanny\'s profile to save them here for quick access.'**
  String get savedNanniesEmptyDescription;

  /// Browse nannies button
  ///
  /// In en, this message translates to:
  /// **'Browse Nannies'**
  String get browseNannies;

  /// Session reconnecting message
  ///
  /// In en, this message translates to:
  /// **'Reconnecting to session...'**
  String get reconnectingToSession;

  /// Label for current user in session
  ///
  /// In en, this message translates to:
  /// **'You'**
  String get you;

  /// Waiting for other user confirmation
  ///
  /// In en, this message translates to:
  /// **'Waiting for {name} to confirm...'**
  String waitingForUserToConfirm(String name);

  /// Both parties must confirm start
  ///
  /// In en, this message translates to:
  /// **'Both parties need to confirm to start the session'**
  String get bothPartiesNeedConfirm;

  /// Parent confirm start prompt
  ///
  /// In en, this message translates to:
  /// **'Confirm that the nanny has arrived and the session can begin'**
  String get confirmNannyArrived;

  /// Nanny confirm start prompt
  ///
  /// In en, this message translates to:
  /// **'Confirm that you have arrived and the session can begin'**
  String get confirmYouArrived;

  /// Waiting for confirmation status
  ///
  /// In en, this message translates to:
  /// **'Waiting for confirmation...'**
  String get waitingForConfirmation;

  /// Session auto-end warning
  ///
  /// In en, this message translates to:
  /// **'Session auto-ends in 10 min if unconfirmed'**
  String get sessionAutoEnds;

  /// Confirm end session button
  ///
  /// In en, this message translates to:
  /// **'Confirm End'**
  String get confirmEnd;

  /// Waiting for other party end confirm
  ///
  /// In en, this message translates to:
  /// **'Waiting for the other party to confirm...'**
  String get waitingForOtherParty;

  /// Confirming session phase title
  ///
  /// In en, this message translates to:
  /// **'Confirming...'**
  String get confirming;

  /// Active session phase title
  ///
  /// In en, this message translates to:
  /// **'Live Session'**
  String get liveSession;

  /// Ending session phase title
  ///
  /// In en, this message translates to:
  /// **'Ending...'**
  String get ending;

  /// Session complete title
  ///
  /// In en, this message translates to:
  /// **'Session Complete'**
  String get sessionComplete;

  /// Session complete heading
  ///
  /// In en, this message translates to:
  /// **'Session Complete!'**
  String get sessionCompleteExclamation;

  /// Session summary subtitle
  ///
  /// In en, this message translates to:
  /// **'Great job! Here\'s your session summary.'**
  String get sessionSummarySubtitle;

  /// Review comment hint
  ///
  /// In en, this message translates to:
  /// **'Add a comment (optional)'**
  String get addCommentOptional;

  /// Submitting state label
  ///
  /// In en, this message translates to:
  /// **'Submitting...'**
  String get submitting;

  /// Review submit error
  ///
  /// In en, this message translates to:
  /// **'Could not submit review. Please try again.'**
  String get couldNotSubmitReview;

  /// Back to booking button
  ///
  /// In en, this message translates to:
  /// **'Back to Booking'**
  String get backToBooking;

  /// Go home button
  ///
  /// In en, this message translates to:
  /// **'Go Home'**
  String get goHome;

  /// End session dialog title
  ///
  /// In en, this message translates to:
  /// **'End Session?'**
  String get endSessionQuestion;

  /// End session dialog message
  ///
  /// In en, this message translates to:
  /// **'Both parties need to confirm. The other party will be notified.'**
  String get endSessionConfirmMessage;

  /// Waiting status label
  ///
  /// In en, this message translates to:
  /// **'Waiting...'**
  String get waiting;

  /// App tagline
  ///
  /// In en, this message translates to:
  /// **'Find trusted babysitters near you'**
  String get findTrustedBabysitters;

  /// Biometric enable dialog title
  ///
  /// In en, this message translates to:
  /// **'Enable {label}?'**
  String enableLabelQuestion(String label);

  /// Biometric enable dialog message
  ///
  /// In en, this message translates to:
  /// **'Sign in faster next time using {label}. You can change this in settings.'**
  String signInFasterWithLabel(String label);

  /// Enable biometric button
  ///
  /// In en, this message translates to:
  /// **'Enable {label}'**
  String enableLabel(String label);

  /// Dashboard greeting prefix
  ///
  /// In en, this message translates to:
  /// **'Welcome back,'**
  String get welcomeBackComma;

  /// Nanny dashboard status
  ///
  /// In en, this message translates to:
  /// **'Active & Available'**
  String get activeAndAvailable;

  /// Dashboard pending payout label
  ///
  /// In en, this message translates to:
  /// **'Pending Payout'**
  String get pendingPayout;

  /// Verification banner - approved subtitle
  ///
  /// In en, this message translates to:
  /// **'Your identity has been verified. You have a trusted badge on your profile.'**
  String get verifiedSubtitle;

  /// Verification banner - pending title
  ///
  /// In en, this message translates to:
  /// **'Under Review'**
  String get underReview;

  /// Verification banner - pending subtitle
  ///
  /// In en, this message translates to:
  /// **'Your verification request is being reviewed. You can still add missing documents.'**
  String get underReviewSubtitle;

  /// Verification banner - update CTA
  ///
  /// In en, this message translates to:
  /// **'Update Request'**
  String get updateRequest;

  /// Verification banner - rejected title
  ///
  /// In en, this message translates to:
  /// **'Verification Rejected'**
  String get verificationRejected;

  /// Verification banner - rejected subtitle
  ///
  /// In en, this message translates to:
  /// **'Your request was not approved. Please update your documents and resubmit.'**
  String get verificationRejectedSubtitle;

  /// Verification banner - resubmit CTA
  ///
  /// In en, this message translates to:
  /// **'Resubmit'**
  String get resubmit;

  /// Verification banner - no request title
  ///
  /// In en, this message translates to:
  /// **'Verification Required'**
  String get verificationRequired;

  /// Verification banner - no request subtitle
  ///
  /// In en, this message translates to:
  /// **'Upload your documents and send a verification request to increase trust.'**
  String get verificationRequiredSubtitle;

  /// Dashboard error title
  ///
  /// In en, this message translates to:
  /// **'Could not load dashboard'**
  String get couldNotLoadDashboard;

  /// Minutes ago time label
  ///
  /// In en, this message translates to:
  /// **'{count}m ago'**
  String minutesAgo(int count);

  /// Hours ago time label
  ///
  /// In en, this message translates to:
  /// **'{count}h ago'**
  String hoursAgo(int count);

  /// Days ago time label
  ///
  /// In en, this message translates to:
  /// **'{count}d ago'**
  String daysAgo(int count);

  /// Cancel session button
  ///
  /// In en, this message translates to:
  /// **'Cancel Session'**
  String get cancelSession;

  /// Cancel session instead button during end flow
  ///
  /// In en, this message translates to:
  /// **'Cancel Session Instead'**
  String get cancelSessionInstead;

  /// Cancel active session dialog title
  ///
  /// In en, this message translates to:
  /// **'Cancel Active Session?'**
  String get cancelActiveSessionQuestion;

  /// Cancel session start dialog title
  ///
  /// In en, this message translates to:
  /// **'Cancel Session Start?'**
  String get cancelSessionStartQuestion;

  /// Cancel active session dialog message
  ///
  /// In en, this message translates to:
  /// **'This will cancel the active session. No charges will be applied. Both parties will need to confirm again to restart.'**
  String get cancelActiveSessionMessage;

  /// Cancel session start dialog message
  ///
  /// In en, this message translates to:
  /// **'This will cancel the confirmation. You can restart the session later — both parties will need to confirm again.'**
  String get cancelSessionStartMessage;

  /// Keep going button in cancel dialog
  ///
  /// In en, this message translates to:
  /// **'Keep Going'**
  String get keepGoing;

  /// Delete chat dialog title
  ///
  /// In en, this message translates to:
  /// **'Delete Chat'**
  String get deleteChat;

  /// Delete chat dialog message
  ///
  /// In en, this message translates to:
  /// **'Hide your conversation with {name}?\n\nThis only removes it from your list. The other person can still see the chat.'**
  String hideChatMessage(String name);

  /// Chat removed snackbar
  ///
  /// In en, this message translates to:
  /// **'Chat removed'**
  String get chatRemoved;

  /// Delete chat error snackbar
  ///
  /// In en, this message translates to:
  /// **'Could not delete chat'**
  String get couldNotDeleteChat;

  /// Delete user dialog/button title
  ///
  /// In en, this message translates to:
  /// **'Delete User'**
  String get deleteUser;

  /// Active users tab label
  ///
  /// In en, this message translates to:
  /// **'Active Users'**
  String get activeUsersTab;

  /// Deleted users tab label
  ///
  /// In en, this message translates to:
  /// **'Deleted Users'**
  String get deletedUsersTab;

  /// Phone required validation message
  ///
  /// In en, this message translates to:
  /// **'Phone number is required'**
  String get phoneNumberRequired;

  /// Delete booking button
  ///
  /// In en, this message translates to:
  /// **'Delete Booking'**
  String get deleteBooking;

  /// Cancel and delete button
  ///
  /// In en, this message translates to:
  /// **'Cancel & Delete'**
  String get cancelAndDelete;

  /// Delete booking dialog title
  ///
  /// In en, this message translates to:
  /// **'Delete Booking?'**
  String get deleteBookingQuestion;

  /// Cancel and delete dialog title
  ///
  /// In en, this message translates to:
  /// **'Cancel & Delete?'**
  String get cancelAndDeleteQuestion;

  /// All tab/filter label
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get all;

  /// Deleted date label for admin
  ///
  /// In en, this message translates to:
  /// **'Deleted: {date}'**
  String deletedDate(String date);

  /// Declined status label
  ///
  /// In en, this message translates to:
  /// **'Declined'**
  String get declined;

  /// Keep button in confirmation dialogs
  ///
  /// In en, this message translates to:
  /// **'Keep'**
  String get keep;

  /// Snackbar message after booking deletion
  ///
  /// In en, this message translates to:
  /// **'Booking deleted'**
  String get bookingDeleted;

  /// Error message when booking deletion fails
  ///
  /// In en, this message translates to:
  /// **'Failed to delete booking'**
  String get failedToDeleteBooking;

  /// Delete confirmation for completed/cancelled bookings
  ///
  /// In en, this message translates to:
  /// **'This will permanently delete this booking. This action cannot be undone.'**
  String get deleteConfirmTerminal;

  /// Delete confirmation for active/requested bookings
  ///
  /// In en, this message translates to:
  /// **'This will cancel the booking and permanently delete it. This action cannot be undone.'**
  String get deleteConfirmActive;

  /// Empty bookings list subtitle
  ///
  /// In en, this message translates to:
  /// **'Your bookings will appear here'**
  String get bookingsAppearHere;

  /// Children count label on booking card
  ///
  /// In en, this message translates to:
  /// **'{count} child(ren)'**
  String childrenCountLabel(int count);
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
