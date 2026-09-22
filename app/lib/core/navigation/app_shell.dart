import 'package:flutter/material.dart';
import '../theme/chrono_theme.dart';
import '../../../features/dashboard/presentation/dashboard_screen.dart';
import '../../../features/timeline/presentation/timeline_screen.dart';
import '../../../features/medications/presentation/medications_screen.dart';
import '../../../features/routine/presentation/routine_screen.dart';
import '../../../features/settings/presentation/settings_screen.dart';

/// Responsive App Shell (Calm Health Aesthetic).
///
/// Features a gentle, feather-weight bottom navigation bar for mobile (< 640px)
/// with subtle active dot indicators, and a calm, quiet sidebar for desktop (>= 640px).
class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _selectedIndex = 0;

  static const _screens = [
    DashboardScreen(),
    TimelineScreen(),
    MedicationsScreen(),
    RoutineScreen(),
    SettingsScreen(),
  ];

  static const _navItems = [
    (icon: Icons.today_outlined, activeIcon: Icons.today_rounded, label: 'Today'),
    (icon: Icons.schedule_outlined, activeIcon: Icons.schedule_rounded, label: 'Timeline'),
    (icon: Icons.medication_outlined, activeIcon: Icons.medication_rounded, label: 'Meds'),
    (icon: Icons.bedtime_outlined, activeIcon: Icons.bedtime_rounded, label: 'Routine'),
    (icon: Icons.tune_outlined, activeIcon: Icons.tune_rounded, label: 'Settings'),
  ];

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final isMobile = width < 640;

    if (isMobile) {
      return Scaffold(
        backgroundColor: ChronoTheme.obsidian,
        body: SafeArea(
          bottom: false,
          child: _buildBody(),
        ),
        bottomNavigationBar: _CalmBottomNav(
          currentIndex: _selectedIndex,
          items: _navItems,
          onTap: (index) => setState(() => _selectedIndex = index),
        ),
      );
    }

    // Desktop/Tablet Sidebar
    return Scaffold(
      backgroundColor: ChronoTheme.obsidian,
      body: Row(
        children: [
          Container(
            width: 76,
            decoration: const BoxDecoration(
              color: ChronoTheme.surface,
              border: Border(right: BorderSide(color: ChronoTheme.border)),
            ),
            child: Column(
              children: [
                const SizedBox(height: 20),
                // Calm Monogram
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: ChronoTheme.cyanSurface,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: ChronoTheme.primary.withOpacity(0.3)),
                  ),
                  child: const Center(
                    child: Icon(Icons.blur_circular_rounded, color: ChronoTheme.primary, size: 20),
                  ),
                ),
                const SizedBox(height: 24),
                // Nav Items
                Expanded(
                  child: ListView.separated(
                    itemCount: _navItems.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, i) {
                      final item = _navItems[i];
                      final isSelected = _selectedIndex == i;
                      return InkWell(
                        onTap: () => setState(() => _selectedIndex = i),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              isSelected ? item.activeIcon : item.icon,
                              color: isSelected ? ChronoTheme.primary : ChronoTheme.textMuted,
                              size: 20,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              item.label,
                              style: TextStyle(
                                color: isSelected ? ChronoTheme.textPrimary : ChronoTheme.textDim,
                                fontSize: 10,
                                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 2),
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              width: isSelected ? 4 : 0,
                              height: isSelected ? 4 : 0,
                              decoration: const BoxDecoration(
                                color: ChronoTheme.primary,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: _buildBody(),
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 220),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      transitionBuilder: (child, animation) {
        return FadeTransition(
          opacity: animation,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 0.02),
              end: Offset.zero,
            ).animate(animation),
            child: child,
          ),
        );
      },
      child: KeyedSubtree(
        key: ValueKey<int>(_selectedIndex),
        child: _screens[_selectedIndex],
      ),
    );
  }
}

// ── Gentle Calm Bottom Navigation Bar ───────────────────────────────────────

class _CalmBottomNav extends StatelessWidget {
  final int currentIndex;
  final List<({IconData icon, IconData activeIcon, String label})> items;
  final ValueChanged<int> onTap;

  const _CalmBottomNav({
    required this.currentIndex,
    required this.items,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 58,
      decoration: const BoxDecoration(
        color: ChronoTheme.surface,
        border: Border(top: BorderSide(color: ChronoTheme.border, width: 1)),
      ),
      child: Row(
        children: List.generate(items.length, (index) {
          final item = items[index];
          final isSelected = currentIndex == index;

          return Expanded(
            child: InkResponse(
              onTap: () => onTap(index),
              highlightShape: BoxShape.rectangle,
              splashColor: ChronoTheme.cyanSurface,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    isSelected ? item.activeIcon : item.icon,
                    color: isSelected ? ChronoTheme.primary : ChronoTheme.textMuted,
                    size: 20,
                  ),
                  const SizedBox(height: 3),
                  Text(
                    item.label,
                    style: TextStyle(
                      color: isSelected ? ChronoTheme.textPrimary : ChronoTheme.textDim,
                      fontSize: 10.5,
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                      letterSpacing: 0.1,
                    ),
                  ),
                  const SizedBox(height: 2),
                  // Subtle Active Dot Indicator
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.easeInOut,
                    width: isSelected ? 3.5 : 0,
                    height: isSelected ? 3.5 : 0,
                    decoration: const BoxDecoration(
                      color: ChronoTheme.primary,
                      shape: BoxShape.circle,
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }
}
