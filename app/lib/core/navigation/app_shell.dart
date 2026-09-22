import 'package:flutter/material.dart';
import '../theme/chrono_theme.dart';
import '../../../features/dashboard/presentation/dashboard_screen.dart';
import '../../../features/timeline/presentation/timeline_screen.dart';
import '../../../features/medications/presentation/medications_screen.dart';
import '../../../features/routine/presentation/routine_screen.dart';
import '../../../features/settings/presentation/settings_screen.dart';

/// Responsive App Shell (Phase 1 Refined).
///
/// Features a custom, minimalist bottom navigation bar for mobile (< 640px)
/// and a sleek sidebar for tablet/desktop (>= 640px) adhering to the
/// strict 2-color clinical design system.
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
          child: IndexedStack(
            index: _selectedIndex,
            children: _screens,
          ),
        ),
        bottomNavigationBar: _MinimalBottomNav(
          currentIndex: _selectedIndex,
          items: _navItems,
          onTap: (index) => setState(() => _selectedIndex = index),
        ),
      );
    }

    // Desktop/Tablet Sidebar Layout
    return Scaffold(
      backgroundColor: ChronoTheme.obsidian,
      body: Row(
        children: [
          Container(
            width: 80,
            decoration: const BoxDecoration(
              color: ChronoTheme.surface,
              border: Border(right: BorderSide(color: ChronoTheme.border)),
            ),
            child: Column(
              children: [
                const SizedBox(height: 20),
                // Brand Monogram
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: ChronoTheme.cyanSurface,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: ChronoTheme.cyan.withOpacity(0.3)),
                  ),
                  child: const Center(
                    child: Icon(Icons.show_chart_rounded, color: ChronoTheme.cyan, size: 20),
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
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 180),
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                              decoration: BoxDecoration(
                                color: isSelected ? ChronoTheme.cyanSurface : Colors.transparent,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(
                                isSelected ? item.activeIcon : item.icon,
                                color: isSelected ? ChronoTheme.cyan : ChronoTheme.textMuted,
                                size: 20,
                              ),
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
            child: IndexedStack(
              index: _selectedIndex,
              children: _screens,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Minimalist Mobile Bottom Navigation Bar ─────────────────────────────────

class _MinimalBottomNav extends StatelessWidget {
  final int currentIndex;
  final List<({IconData icon, IconData activeIcon, String label})> items;
  final ValueChanged<int> onTap;

  const _MinimalBottomNav({
    required this.currentIndex,
    required this.items,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 60,
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
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    curve: Curves.easeInOut,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
                    decoration: BoxDecoration(
                      color: isSelected ? ChronoTheme.cyanSurface : Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      isSelected ? item.activeIcon : item.icon,
                      color: isSelected ? ChronoTheme.cyan : ChronoTheme.textMuted,
                      size: 20,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    item.label,
                    style: TextStyle(
                      color: isSelected ? ChronoTheme.cyan : ChronoTheme.textDim,
                      fontSize: 10.5,
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                      letterSpacing: 0.1,
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
