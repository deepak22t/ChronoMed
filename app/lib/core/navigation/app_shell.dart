import 'package:flutter/material.dart';
import '../theme/chrono_theme.dart';
import '../../../features/dashboard/presentation/dashboard_screen.dart';
import '../../../features/timeline/presentation/timeline_screen.dart';
import '../../../features/medications/presentation/medications_screen.dart';
import '../../../features/routine/presentation/routine_screen.dart';
import '../../../features/settings/presentation/settings_screen.dart';

/// Responsive App Shell.
/// On Mobile (< 640px): Native Material 3 BottomNavigationBar.
/// On Desktop (>= 640px): Sidebar NavigationRail.
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
    (icon: Icons.calendar_today_outlined, activeIcon: Icons.calendar_today_rounded, label: 'Today'),
    (icon: Icons.timeline_outlined, activeIcon: Icons.timeline_rounded, label: 'Timeline'),
    (icon: Icons.medication_outlined, activeIcon: Icons.medication_rounded, label: 'Meds'),
    (icon: Icons.alarm_outlined, activeIcon: Icons.alarm_rounded, label: 'Routine'),
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
        bottomNavigationBar: Container(
          decoration: const BoxDecoration(
            color: ChronoTheme.surface,
            border: Border(top: BorderSide(color: ChronoTheme.border)),
          ),
          child: NavigationBar(
            selectedIndex: _selectedIndex,
            onDestinationSelected: (idx) => setState(() => _selectedIndex = idx),
            backgroundColor: ChronoTheme.surface,
            indicatorColor: ChronoTheme.cyan.withOpacity(0.2),
            elevation: 0,
            height: 65,
            labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
            destinations: _navItems
                .map(
                  (item) => NavigationDestination(
                    icon: Icon(item.icon, color: ChronoTheme.textMuted, size: 22),
                    selectedIcon: Icon(item.activeIcon, color: ChronoTheme.cyan, size: 22),
                    label: item.label,
                  ),
                )
                .toList(),
          ),
        ),
      );
    }

    // Desktop layout
    return Scaffold(
      backgroundColor: ChronoTheme.obsidian,
      body: Row(
        children: [
          Container(
            decoration: const BoxDecoration(
              color: ChronoTheme.surface,
              border: Border(right: BorderSide(color: ChronoTheme.border)),
            ),
            child: NavigationRail(
              selectedIndex: _selectedIndex,
              onDestinationSelected: (index) => setState(() => _selectedIndex = index),
              labelType: NavigationRailLabelType.all,
              backgroundColor: ChronoTheme.surface,
              leading: Padding(
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: Column(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [ChronoTheme.cyan, ChronoTheme.emerald],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.medical_services_rounded,
                          color: ChronoTheme.obsidian, size: 20),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'ChronoMed',
                      style: TextStyle(
                        color: ChronoTheme.textPrimary,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
              destinations: _navItems
                  .map(
                    (item) => NavigationRailDestination(
                      icon: Icon(item.icon),
                      selectedIcon: Icon(item.activeIcon),
                      label: Text(item.label),
                    ),
                  )
                  .toList(),
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
