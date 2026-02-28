import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/services/bubble_overlay_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_shadows.dart';

class HomeShell extends ConsumerStatefulWidget {
  final Widget child;
  const HomeShell({super.key, required this.child});

  @override
  ConsumerState<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends ConsumerState<HomeShell> {
  bool _bubbleStarted = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_bubbleStarted) {
      _bubbleStarted = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) BubbleOverlayService.instance.startMonitoring(context);
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
    final isNanny = user?.isNanny == true;
    final isAdmin = user?.isAdmin == true;

    final routes = isNanny
        ? ['/dashboard', '/bookings', '/chat', '/profile']
        : isAdmin
            ? ['/home', '/bookings', '/map', '/admin', '/profile']
            : ['/home', '/bookings', '/map', '/chat', '/profile'];

    int currentIndex = routes.indexWhere((r) => location.startsWith(r));
    if (currentIndex < 0) currentIndex = 0;

    final navItems = isNanny
        ? const [
            _NavItem(Icons.dashboard_outlined, Icons.dashboard_rounded, 'Dashboard'),
            _NavItem(Icons.calendar_today_outlined, Icons.calendar_today_rounded, 'Jobs'),
            _NavItem(Icons.chat_bubble_outline_rounded, Icons.chat_bubble_rounded, 'Chat'),
            _NavItem(Icons.person_outline_rounded, Icons.person_rounded, 'Profile'),
          ]
        : isAdmin
            ? const [
                _NavItem(Icons.search_outlined, Icons.search_rounded, 'Find'),
                _NavItem(Icons.calendar_today_outlined, Icons.calendar_today_rounded, 'Bookings'),
                _NavItem(Icons.map_outlined, Icons.map_rounded, 'Map'),
                _NavItem(Icons.admin_panel_settings_outlined, Icons.admin_panel_settings_rounded, 'Admin'),
                _NavItem(Icons.person_outline_rounded, Icons.person_rounded, 'Profile'),
              ]
            : const [
                _NavItem(Icons.search_outlined, Icons.search_rounded, 'Find'),
                _NavItem(Icons.calendar_today_outlined, Icons.calendar_today_rounded, 'Bookings'),
                _NavItem(Icons.map_outlined, Icons.map_rounded, 'Map'),
                _NavItem(Icons.chat_bubble_outline_rounded, Icons.chat_bubble_rounded, 'Chat'),
                _NavItem(Icons.person_outline_rounded, Icons.person_rounded, 'Profile'),
              ];

    return Scaffold(
      body: widget.child,
      bottomNavigationBar: _PremiumBottomNav(
        items: navItems,
        currentIndex: currentIndex,
        onTap: (i) {
          HapticFeedback.selectionClick();
          context.go(routes[i]);
        },
      ),
    );
  }
}

// ═══════ Premium Bottom Nav (Wolt-style) ═══════════════

class _NavItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  const _NavItem(this.icon, this.activeIcon, this.label);
}

class _PremiumBottomNav extends StatelessWidget {
  final List<_NavItem> items;
  final int currentIndex;
  final ValueChanged<int> onTap;

  const _PremiumBottomNav({required this.items, required this.currentIndex, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: AppShadows.top,
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 60,
          child: Row(
            children: items.asMap().entries.map((e) {
              final i = e.key;
              final item = e.value;
              final isActive = i == currentIndex;
              return Expanded(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => onTap(i),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                        decoration: BoxDecoration(
                          color: isActive ? AppColors.primaryLight : Colors.transparent,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Icon(
                          isActive ? item.activeIcon : item.icon,
                          size: 22,
                          color: isActive ? AppColors.primary : AppColors.textHint,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        item.label,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                          color: isActive ? AppColors.primary : AppColors.textHint,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}
