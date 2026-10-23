import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:trash/core/constants/app_constants.dart';
import 'package:trash/core/theme/app_theme.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Bottom Nav State
// ─────────────────────────────────────────────────────────────────────────────
final bottomNavIndexProvider = StateProvider<int>((ref) => 0);

// ─────────────────────────────────────────────────────────────────────────────
// App Shell – persistent bottom nav + tab bodies
// ─────────────────────────────────────────────────────────────────────────────
class AppShell extends ConsumerWidget {
  final Widget child;

  const AppShell({super.key, required this.child});

  static const _tabs = [
    _NavTab(icon: Icons.home_rounded, label: 'Home', route: AppConstants.routeHome),
    _NavTab(icon: Icons.map_rounded, label: 'Map', route: AppConstants.routeMap),
    _NavTab(icon: Icons.flag_rounded, label: 'Missions', route: AppConstants.routeMissions),
    _NavTab(icon: Icons.people_rounded, label: 'Social', route: AppConstants.routeSocial),
    _NavTab(icon: Icons.person_rounded, label: 'Profile', route: AppConstants.routeProfile),
  ];

  int _indexFromRoute(String? location) {
    if (location == null) return 0;
    if (location.startsWith(AppConstants.routeMap)) return 1;
    if (location.startsWith(AppConstants.routeMissions)) return 2;
    if (location.startsWith(AppConstants.routeSocial)) return 3;
    if (location.startsWith(AppConstants.routeProfile)) return 4;
    return 0;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final location = GoRouterState.of(context).uri.toString();
    final currentIndex = _indexFromRoute(location);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: child,

      // ── Floating Claim FAB ───────────────────────────────────────────────
      floatingActionButton: _ClaimFAB(),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,

      // ── Bottom Navigation Bar ────────────────────────────────────────────
      bottomNavigationBar: _AppBottomBar(
        currentIndex: currentIndex,
        tabs: _tabs,
        onTap: (i) {
          HapticFeedback.selectionClick();
          context.go(_tabs[i].route);
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Bottom Bar
// ─────────────────────────────────────────────────────────────────────────────
class _AppBottomBar extends StatelessWidget {
  final int currentIndex;
  final List<_NavTab> tabs;
  final void Function(int) onTap;

  const _AppBottomBar({
    required this.currentIndex,
    required this.tabs,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: const Border(
          top: BorderSide(color: AppColors.cardBorder, width: 1),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 64,
          child: Row(
            children: [
              // Left two tabs
              ...List.generate(2, (i) => Expanded(
                child: _NavItem(
                  tab: tabs[i],
                  isSelected: currentIndex == i,
                  onTap: () => onTap(i),
                ),
              )),
              // Center gap for FAB
              const SizedBox(width: 72),
              // Right two tabs
              ...List.generate(2, (i) => Expanded(
                child: _NavItem(
                  tab: tabs[i + 3],
                  isSelected: currentIndex == i + 3,
                  onTap: () => onTap(i + 3),
                ),
              )),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final _NavTab tab;
  final bool isSelected;
  final VoidCallback onTap;

  const _NavItem({
    required this.tab,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.accentGreen.withOpacity(0.12)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(
                tab.icon,
                size: 22,
                color: isSelected ? AppColors.accentGreen : AppColors.textHint,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              tab.label,
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                color: isSelected ? AppColors.accentGreen : AppColors.textHint,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Claim FAB – centre-docked, glowing green
// ─────────────────────────────────────────────────────────────────────────────
class _ClaimFAB extends StatefulWidget {
  @override
  State<_ClaimFAB> createState() => _ClaimFABState();
}

class _ClaimFABState extends State<_ClaimFAB>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseCtrl;
  late final Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 1.0, end: 1.08).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _pulseAnim,
      child: Container(
        width: 64,
        height: 64,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppColors.accentGreen, AppColors.forestGreen],
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.accentGreen.withOpacity(0.45),
              blurRadius: 18,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(32),
            onTap: () {
              HapticFeedback.heavyImpact();
              context.push(AppConstants.routeCamera);
            },
            child: const Center(
              child: Icon(
                Icons.camera_alt_rounded,
                color: Colors.white,
                size: 28,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _NavTab {
  final IconData icon;
  final String label;
  final String route;

  const _NavTab({
    required this.icon,
    required this.label,
    required this.route,
  });
}
