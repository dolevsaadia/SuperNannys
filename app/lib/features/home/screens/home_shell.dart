import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/services/bubble_overlay_service.dart';
import '../../../core/services/connectivity_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_shadows.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/biometric_prompt_dialog.dart';
import '../../session/widgets/session_banner.dart';

class HomeShell extends ConsumerStatefulWidget {
  final Widget child;
  const HomeShell({super.key, required this.child});

  @override
  ConsumerState<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends ConsumerState<HomeShell> {
  bool _bubbleStarted = false;
  bool _biometricChecked = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_bubbleStarted) {
      _bubbleStarted = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) BubbleOverlayService.instance.startMonitoring(context);
      });
    }
    if (!_biometricChecked) {
      _biometricChecked = true;
      _checkBiometricPrompt();
    }
  }

  Future<void> _checkBiometricPrompt() async {
    // Wait for the home screen to fully render before showing the prompt
    await Future.delayed(const Duration(milliseconds: 800));
    if (!mounted) return;
    final token = await ref.read(authProvider.notifier).getStoredToken();
    if (token != null && mounted) {
      await showBiometricPrompt(context, token);
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

    final routes = isNanny
        ? ['/dashboard', '/bookings', '/chat', '/profile']
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
        : const [
            _NavItem(Icons.search_outlined, Icons.search_rounded, 'Find'),
            _NavItem(Icons.calendar_today_outlined, Icons.calendar_today_rounded, 'Bookings'),
            _NavItem(Icons.map_outlined, Icons.map_rounded, 'Map'),
            _NavItem(Icons.chat_bubble_outline_rounded, Icons.chat_bubble_rounded, 'Chat'),
            _NavItem(Icons.person_outline_rounded, Icons.person_rounded, 'Profile'),
          ];

    final keyboardOpen = MediaQuery.of(context).viewInsets.bottom > 50;
    final connectivity = ref.watch(connectivityProvider);

    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: SafeArea(
        bottom: false, // bottom nav handles its own SafeArea
        child: Column(
          children: [
            // ── Offline banner (animated) ──
            AnimatedSize(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              child: !connectivity.isOnline
                  ? Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      color: AppColors.error,
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.wifi_off_rounded, size: 16, color: Colors.white),
                          SizedBox(width: 6),
                          Text(
                            'No internet connection',
                            style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    )
                  : const SizedBox.shrink(),
            ),
            // ── Persistent session banner ──
            const SessionBanner(),
            // ── Main content ─────────────────────────────
            Expanded(
              child: MediaQuery.removePadding(
                context: context,
                removeTop: true,
                child: widget.child,
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: keyboardOpen ? null : _PremiumBottomNav(
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
        color: AppColors.white,
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
                          borderRadius: AppRadius.borderCard,
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
