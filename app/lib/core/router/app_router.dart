import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/auth_provider.dart';
import '../../features/auth/screens/login_screen.dart';
import '../../features/auth/screens/register_screen.dart';
import '../../features/auth/screens/role_select_screen.dart';
import '../../features/onboarding/screens/onboarding_screen.dart';
import '../../features/home/screens/home_shell.dart';
import '../../features/home/screens/search_screen.dart';
import '../../features/nanny_profile/screens/nanny_profile_screen.dart';
import '../../features/booking/screens/booking_form_screen.dart';
import '../../features/booking/screens/booking_summary_screen.dart';
import '../../features/booking/screens/booking_success_screen.dart';
import '../../features/booking/screens/booking_detail_screen.dart';
import '../../features/chat/screens/chat_list_screen.dart';
import '../../features/chat/screens/chat_screen.dart';
import '../../features/profile/screens/profile_screen.dart';
import '../../features/profile/screens/edit_profile_screen.dart';
import '../../features/profile/screens/bookings_history_screen.dart';
import '../../features/nanny_dashboard/screens/dashboard_screen.dart';
import '../../features/nanny_dashboard/screens/availability_screen.dart';
import '../../features/nanny_dashboard/screens/earnings_screen.dart';
import '../../features/nanny_dashboard/screens/documents_screen.dart';
import '../../features/nanny_onboarding/screens/nanny_onboarding_screen.dart';
import '../../features/admin/screens/admin_screen.dart';
import '../../features/admin/screens/admin_users_screen.dart';
import '../../features/admin/screens/admin_bookings_screen.dart';
import '../../features/admin/screens/admin_verify_nannies_screen.dart';
import '../../features/map/screens/map_screen.dart';
import '../../features/auth/screens/otp_verification_screen.dart';
import '../../features/session/screens/live_session_screen.dart';
import '../../features/recurring_bookings/screens/recurring_bookings_screen.dart';
import '../../features/recurring_bookings/screens/recurring_booking_detail_screen.dart';
import '../../features/profile/screens/notifications_settings_screen.dart';
import '../../features/profile/screens/privacy_screen.dart';
import '../../features/profile/screens/help_screen.dart';
import '../../features/profile/screens/about_screen.dart';
import '../../features/favorites/screens/favorites_screen.dart';

/// Bridges Riverpod [AuthState] changes into a [Listenable] that GoRouter can
/// use via [refreshListenable] — this re-evaluates the redirect function
/// without recreating the entire GoRouter (which would reset navigation state).
class _AuthNotifierBridge extends ChangeNotifier {
  _AuthNotifierBridge(Ref ref) {
    ref.listen<AuthState>(authProvider, (_, __) => notifyListeners());
  }
}

final routerProvider = Provider<GoRouter>((ref) {
  final notifier = _AuthNotifierBridge(ref);

  return GoRouter(
    initialLocation: '/onboarding',
    refreshListenable: notifier,
    redirect: (context, state) {
      final authState = ref.read(authProvider);
      final isAuth = authState.isAuthenticated;
      final isLoading = authState.isLoading;
      final loc = state.matchedLocation;

      if (isLoading) return null;

      final publicRoutes = ['/login', '/register', '/role-select', '/onboarding', '/verify-otp'];
      final isPublic = publicRoutes.any((r) => loc.startsWith(r));

      if (!isAuth && !isPublic) return '/onboarding';
      if (isAuth && isPublic) {
        final user = authState.user;
        if (user?.isNanny == true) return '/dashboard';
        return '/home';
      }
      return null;
    },
    routes: [
      GoRoute(path: '/onboarding', builder: (_, __) => const OnboardingScreen()),
      GoRoute(path: '/login', builder: (_, __) => const LoginScreen()),
      GoRoute(path: '/register', builder: (_, __) => const RegisterScreen()),
      GoRoute(path: '/role-select', builder: (_, __) => const RoleSelectScreen()),
      GoRoute(
        path: '/verify-otp',
        builder: (_, state) {
          final extra = state.extra as Map<String, dynamic>?;
          final email = extra?['email'] as String? ?? '';
          return OtpVerificationScreen(email: email);
        },
      ),

      // Main shell with bottom nav
      ShellRoute(
        builder: (context, state, child) => HomeShell(child: child),
        routes: [
          GoRoute(
            path: '/home',
            builder: (_, __) => const SearchScreen(),
            routes: [
              GoRoute(
                path: 'nanny/:id',
                builder: (_, state) => NannyProfileScreen(nannyId: state.pathParameters['id']!),
                routes: [
                  GoRoute(
                    path: 'book',
                    builder: (_, state) => BookingFormScreen(nannyId: state.pathParameters['id']!),
                  ),
                  GoRoute(
                    path: 'book/summary',
                    builder: (_, state) {
                      final extra = state.extra as Map<String, dynamic>?;
                      return BookingSummaryScreen(bookingData: extra ?? {});
                    },
                  ),
                  GoRoute(
                    path: 'book/success',
                    builder: (_, state) {
                      final extra = state.extra as Map<String, dynamic>?;
                      return BookingSuccessScreen(bookingId: extra?['bookingId'] as String? ?? '');
                    },
                  ),
                ],
              ),
            ],
          ),
          GoRoute(
            path: '/bookings',
            builder: (_, __) => const BookingsHistoryScreen(),
            routes: [
              GoRoute(
                path: ':id',
                builder: (_, state) => BookingDetailScreen(bookingId: state.pathParameters['id']!),
              ),
            ],
          ),
          GoRoute(
            path: '/chat',
            builder: (_, __) => const ChatListScreen(),
            routes: [
              GoRoute(
                path: ':bookingId',
                builder: (_, state) {
                  final extra = state.extra as Map<String, dynamic>?;
                  return ChatScreen(
                    bookingId: state.pathParameters['bookingId']!,
                    otherUserName: extra?['otherUserName'] as String? ?? '',
                    otherUserAvatar: extra?['otherUserAvatar'] as String?,
                  );
                },
              ),
            ],
          ),
          GoRoute(
            path: '/profile',
            builder: (_, __) => const ProfileScreen(),
            routes: [
              GoRoute(path: 'edit', builder: (_, __) => const EditProfileScreen()),
              GoRoute(path: 'notifications', builder: (_, __) => const NotificationsSettingsScreen()),
              GoRoute(path: 'privacy', builder: (_, __) => const PrivacyScreen()),
              GoRoute(path: 'help', builder: (_, __) => const HelpScreen()),
              GoRoute(path: 'about', builder: (_, __) => const AboutScreen()),
            ],
          ),
          GoRoute(path: '/map', builder: (_, __) => const MapScreen()),
          GoRoute(path: '/favorites', builder: (_, __) => const FavoritesScreen()),
          GoRoute(
            path: '/recurring-bookings',
            builder: (_, __) => const RecurringBookingsScreen(),
            routes: [
              GoRoute(
                path: ':id',
                builder: (_, state) => RecurringBookingDetailScreen(id: state.pathParameters['id']!),
              ),
            ],
          ),
          // Nanny-only routes
          GoRoute(
            path: '/dashboard',
            builder: (_, __) => const DashboardScreen(),
            routes: [
              GoRoute(path: 'availability', builder: (_, __) => const AvailabilityScreen()),
              GoRoute(path: 'earnings', builder: (_, __) => const EarningsScreen()),
              GoRoute(path: 'documents', builder: (_, __) => const DocumentsScreen()),
            ],
          ),
          GoRoute(
            path: '/admin',
            builder: (_, __) => const AdminScreen(),
            routes: [
              GoRoute(path: 'users', builder: (_, __) => const AdminUsersScreen()),
              GoRoute(path: 'bookings', builder: (_, __) => const AdminBookingsScreen()),
              GoRoute(path: 'verify-nannies', builder: (_, __) => const AdminVerifyNanniesScreen()),
            ],
          ),
        ],
      ),

      GoRoute(path: '/nanny-onboarding', builder: (_, __) => const NannyOnboardingScreen()),

      // Live session — full screen, no bottom nav
      GoRoute(
        path: '/session/:bookingId',
        builder: (_, state) {
          final extra = state.extra as Map<String, dynamic>?;
          return LiveSessionScreen(
            bookingId: state.pathParameters['bookingId']!,
            otherUserName: extra?['otherUserName'] as String? ?? '',
            otherUserAvatar: extra?['otherUserAvatar'] as String?,
            isParent: extra?['isParent'] as bool? ?? true,
          );
        },
      ),
    ],
    errorBuilder: (_, state) => Scaffold(
      body: Center(child: Text('Page not found: ${state.error}')),
    ),
  );
});
