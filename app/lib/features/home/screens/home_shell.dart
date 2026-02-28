import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/services/bubble_overlay_service.dart';
import '../../../core/theme/app_colors.dart';

class HomeShell extends ConsumerStatefulWidget {
  final Widget child;
  const HomeShell({super.key, required this.child});

  @override
  ConsumerState<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends ConsumerState<HomeShell> {
  bool _bubbleStarted = false;

  static final _routes = ['/home', '/bookings', '/chat', '/profile'];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Start bubble monitoring once the shell is built
    if (!_bubbleStarted) {
      _bubbleStarted = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          BubbleOverlayService.instance.startMonitoring(context);
        }
      });
    }
  }

  @override
  void dispose() {
    BubbleOverlayService.instance.stopMonitoring();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    final location = GoRouterState.of(context).matchedLocation;

    int currentIndex = _routes.indexWhere((r) => location.startsWith(r));
    if (currentIndex < 0) currentIndex = 0;

    // Nanny sees Dashboard instead of Find
    final isNanny = user?.isNanny == true;
    final isAdmin = user?.isAdmin == true;

    final routes = isNanny
        ? ['/dashboard', '/bookings', '/chat', '/profile']
        : isAdmin
            ? ['/home', '/bookings', '/map', '/admin', '/profile']
            : ['/home', '/bookings', '/map', '/chat', '/profile'];

    final navItems = isNanny
        ? const [
            NavigationDestination(icon: Icon(Icons.dashboard_outlined), selectedIcon: Icon(Icons.dashboard_rounded), label: 'Dashboard'),
            NavigationDestination(icon: Icon(Icons.calendar_today_outlined), selectedIcon: Icon(Icons.calendar_today_rounded), label: 'Jobs'),
            NavigationDestination(icon: Icon(Icons.chat_bubble_outline_rounded), selectedIcon: Icon(Icons.chat_bubble_rounded), label: 'Chat'),
            NavigationDestination(icon: Icon(Icons.person_outline_rounded), selectedIcon: Icon(Icons.person_rounded), label: 'Profile'),
          ]
        : isAdmin
            ? const [
                NavigationDestination(icon: Icon(Icons.search_outlined), selectedIcon: Icon(Icons.search_rounded), label: 'Find'),
                NavigationDestination(icon: Icon(Icons.calendar_today_outlined), selectedIcon: Icon(Icons.calendar_today_rounded), label: 'Bookings'),
                NavigationDestination(icon: Icon(Icons.map_outlined), selectedIcon: Icon(Icons.map_rounded), label: 'Map'),
                NavigationDestination(icon: Icon(Icons.admin_panel_settings_outlined), selectedIcon: Icon(Icons.admin_panel_settings_rounded), label: 'Admin'),
                NavigationDestination(icon: Icon(Icons.person_outline_rounded), selectedIcon: Icon(Icons.person_rounded), label: 'Profile'),
              ]
            : const [
                NavigationDestination(icon: Icon(Icons.search_outlined), selectedIcon: Icon(Icons.search_rounded), label: 'Find'),
                NavigationDestination(icon: Icon(Icons.calendar_today_outlined), selectedIcon: Icon(Icons.calendar_today_rounded), label: 'Bookings'),
                NavigationDestination(icon: Icon(Icons.map_outlined), selectedIcon: Icon(Icons.map_rounded), label: 'Map'),
                NavigationDestination(icon: Icon(Icons.chat_bubble_outline_rounded), selectedIcon: Icon(Icons.chat_bubble_rounded), label: 'Chat'),
                NavigationDestination(icon: Icon(Icons.person_outline_rounded), selectedIcon: Icon(Icons.person_rounded), label: 'Profile'),
              ];

    return Scaffold(
      body: widget.child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: currentIndex < 0 ? 0 : currentIndex,
        onDestinationSelected: (i) => context.go(routes[i]),
        destinations: navItems,
        backgroundColor: Colors.white,
        indicatorColor: AppColors.primaryLight,
        elevation: 8,
        height: 65,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
      ),
    );
  }
}
