// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'SuperNanny';

  @override
  String get welcomeBack => 'Welcome back';

  @override
  String get signIn => 'Sign In';

  @override
  String get signUp => 'Sign Up';

  @override
  String get email => 'Email';

  @override
  String get password => 'Password';

  @override
  String get confirmPassword => 'Confirm Password';

  @override
  String get forgotPassword => 'Forgot Password?';

  @override
  String get continueWithGoogle => 'Continue with Google';

  @override
  String get signInWithBiometric => 'Sign in with Biometric';

  @override
  String get signInWithFingerprint => 'Sign in with Fingerprint';

  @override
  String get signInWithFaceId => 'Sign in with Face ID';

  @override
  String get dontHaveAccount => 'Don\'t have an account?';

  @override
  String get alreadyHaveAccount => 'Already have an account?';

  @override
  String get fullName => 'Full Name';

  @override
  String get phoneNumber => 'Phone Number';

  @override
  String get createAccount => 'Create Account';

  @override
  String get orContinueWith => 'Or continue with';

  @override
  String get searchNanniesCities => 'Search nannies, cities...';

  @override
  String get myLocation => 'My Location';

  @override
  String get topRated => 'Top Rated';

  @override
  String get availableNow => 'Available Now';

  @override
  String get newOnSuperNanny => 'New on SuperNanny';

  @override
  String get allNannies => 'All Nannies';

  @override
  String get filter => 'Filter';

  @override
  String get filters => 'Filters';

  @override
  String get sortBy => 'Sort By';

  @override
  String get rating => 'Rating';

  @override
  String get price => 'Price';

  @override
  String get distance => 'Distance';

  @override
  String get experience => 'Experience';

  @override
  String get skills => 'Skills';

  @override
  String get reviews => 'Reviews';

  @override
  String get seeAll => 'See All';

  @override
  String get bookNow => 'Book Now';

  @override
  String get oneTime => 'One-time';

  @override
  String get recurring => 'Recurring';

  @override
  String get selectDate => 'Select Date';

  @override
  String get startTime => 'Start';

  @override
  String get endTime => 'End';

  @override
  String get numberOfChildren => 'Number of Children';

  @override
  String get address => 'Address';

  @override
  String get notes => 'Notes';

  @override
  String get requestBooking => 'Request Booking';

  @override
  String get bookingSummary => 'Booking Summary';

  @override
  String get paymentAfterSession => 'Payment after session';

  @override
  String get hourlyRate => 'Hourly Rate';

  @override
  String get estimatedTotal => 'Estimated Total';

  @override
  String get bookingConfirmed => 'Booking Confirmed';

  @override
  String get bookingPending => 'Booking Pending';

  @override
  String get bookingCancelled => 'Booking Cancelled';

  @override
  String get bookingCompleted => 'Booking Completed';

  @override
  String get upcomingBookings => 'Upcoming Bookings';

  @override
  String get pastBookings => 'Past Bookings';

  @override
  String get noBookingsYet => 'No bookings yet';

  @override
  String get typeAMessage => 'Type a message...';

  @override
  String get startTheConversation => 'Start the conversation!';

  @override
  String get typing => 'typing...';

  @override
  String get online => 'Online';

  @override
  String get offline => 'Offline';

  @override
  String get messages => 'Messages';

  @override
  String get noMessages => 'No messages yet';

  @override
  String get editProfile => 'Edit Profile';

  @override
  String get privacyAndSecurity => 'Privacy & Security';

  @override
  String get about => 'About';

  @override
  String get help => 'Help';

  @override
  String get notifications => 'Notifications';

  @override
  String get logout => 'Logout';

  @override
  String get deleteAccount => 'Delete Account';

  @override
  String get deleteAccountConfirmation =>
      'Are you sure you want to delete your account? This action cannot be undone.';

  @override
  String get pendingRequests => 'Pending Requests';

  @override
  String get totalEarned => 'Total Earned';

  @override
  String get totalJobs => 'Total Jobs';

  @override
  String get quickActions => 'Quick Actions';

  @override
  String get availability => 'Availability';

  @override
  String get earnings => 'Earnings';

  @override
  String get profile => 'Profile';

  @override
  String get home => 'Home';

  @override
  String get bookings => 'Bookings';

  @override
  String get chat => 'Chat';

  @override
  String get settings => 'Settings';

  @override
  String get termsOfService => 'Terms of Service';

  @override
  String get privacyPolicy => 'Privacy Policy';

  @override
  String get openSourceLicenses => 'Open Source Licenses';

  @override
  String get cancel => 'Cancel';

  @override
  String get confirm => 'Confirm';

  @override
  String get save => 'Save';

  @override
  String get loading => 'Loading...';

  @override
  String get error => 'Error';

  @override
  String get success => 'Success';

  @override
  String get noResults => 'No results';

  @override
  String get retry => 'Retry';

  @override
  String get ok => 'OK';

  @override
  String get yes => 'Yes';

  @override
  String get no => 'No';

  @override
  String get close => 'Close';

  @override
  String get done => 'Done';

  @override
  String get next => 'Next';

  @override
  String get back => 'Back';

  @override
  String get skip => 'Skip';

  @override
  String get apply => 'Apply';

  @override
  String get reset => 'Reset';

  @override
  String get delete => 'Delete';

  @override
  String get edit => 'Edit';

  @override
  String get add => 'Add';

  @override
  String get remove => 'Remove';

  @override
  String get search => 'Search';

  @override
  String get share => 'Share';

  @override
  String get favorites => 'Favorites';

  @override
  String get addToFavorites => 'Add to Favorites';

  @override
  String get removeFromFavorites => 'Remove from Favorites';

  @override
  String get noFavoritesYet => 'No favorites yet';

  @override
  String get perHour => '/hr';

  @override
  String yearsExperience(int count) {
    return '$count years experience';
  }

  @override
  String childrenCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count children',
      one: '1 child',
    );
    return '$_temp0';
  }

  @override
  String reviewsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count reviews',
      one: '1 review',
      zero: 'No reviews',
    );
    return '$_temp0';
  }

  @override
  String get km => 'km';

  @override
  String get today => 'Today';

  @override
  String get tomorrow => 'Tomorrow';

  @override
  String get yesterday => 'Yesterday';

  @override
  String get language => 'Language';

  @override
  String get selectLanguage => 'Select Language';

  @override
  String get darkMode => 'Dark Mode';

  @override
  String get locationPermission => 'Location Permission';

  @override
  String get locationPermissionDescription =>
      'We need your location to find nannies near you';

  @override
  String get notificationPermission => 'Notification Permission';

  @override
  String get notificationPermissionDescription =>
      'Get notified about bookings and messages';

  @override
  String get allow => 'Allow';

  @override
  String get deny => 'Deny';

  @override
  String get connectionError => 'Connection error. Please check your internet.';

  @override
  String get somethingWentWrong => 'Something went wrong. Please try again.';

  @override
  String get sessionExpired => 'Session expired. Please sign in again.';

  @override
  String get noInternetConnection => 'No internet connection';

  @override
  String get logoutConfirmation => 'Are you sure you want to logout?';

  @override
  String get accept => 'Accept';

  @override
  String get decline => 'Decline';

  @override
  String get pending => 'Pending';

  @override
  String get confirmed => 'Confirmed';

  @override
  String get completed => 'Completed';

  @override
  String get cancelled => 'Cancelled';

  @override
  String get inProgress => 'In Progress';

  @override
  String get map => 'Map';

  @override
  String get list => 'List';

  @override
  String get gallery => 'Gallery';

  @override
  String get camera => 'Camera';

  @override
  String get choosePhoto => 'Choose Photo';

  @override
  String get takePhoto => 'Take Photo';

  @override
  String get bio => 'Bio';

  @override
  String get age => 'Age';

  @override
  String get city => 'City';

  @override
  String get startSession => 'Start Session';

  @override
  String get endSession => 'End Session';

  @override
  String get sessionInProgress => 'Session in Progress';

  @override
  String get rateYourExperience => 'Rate your experience';

  @override
  String get writeAReview => 'Write a review...';

  @override
  String get submitReview => 'Submit Review';

  @override
  String get thankYouForReview => 'Thank you for your review!';

  @override
  String get version => 'Version';
}
