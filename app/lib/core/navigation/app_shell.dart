import 'package:flutter/material.dart';
import '../theme/chrono_theme.dart';
import '../../../features/dashboard/presentation/dashboard_screen.dart';
import '../../../features/medications/presentation/medications_screen.dart';
import '../../../features/settings/presentation/settings_screen.dart';

/// Responsive App Shell — 3-tab navigation.
///
/// Today · Medications · Settings
/// Mobile < 640px: bottom nav bar.
/// Desktop >= 640px: 76px sidebar rail.
class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _selectedIndex = 0;

  static const _screens = [
    DashboardScreen(),
    MedicationsScreen(),
    _HistoryScreen(),
    SettingsScreen(),
  ];

  static const _navItems = [
    (icon: Icons.calendar_today_outlined, activeIcon: Icons.calendar_today_rounded, label: 'Today'),
    (icon: Icons.dashboard_outlined,      activeIcon: Icons.dashboard_rounded,      label: 'Dashboard'),
    (icon: Icons.history_rounded,         activeIcon: Icons.history_rounded,        label: 'History'),
    (icon: Icons.person_outline_rounded,  activeIcon: Icons.person_rounded,         label: 'Profile'),
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
                // App monogram — C for ChronoMed
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: ChronoTheme.cyanSurface,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: ChronoTheme.primary.withOpacity(0.3)),
                  ),
                  child: const Center(
                    child: Text(
                      'C',
                      style: TextStyle(
                        color: ChronoTheme.primary,
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        fontFamily: ChronoTheme.monoFont,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
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
          Expanded(child: _buildBody()),
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

// ── Bottom Navigation Bar ─────────────────────────────────────────────────────

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

class _HistoryScreen extends StatelessWidget {
  const _HistoryScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF090D14),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Adherence History',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                '7-Day Circadian Consistency & Logging',
                style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12.5),
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF131A26),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white.withOpacity(0.08)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildStat('98%', 'Adherence Rate', const Color(0xFF2DD4BF)),
                    _buildStat('7 Days', 'Current Streak', const Color(0xFF38BDF8)),
                    _buildStat('0', 'Missed Doses', const Color(0xFF34D399)),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Recent Logged Doses',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: ListView(
                  physics: const BouncingScrollPhysics(),
                  children: const [
                    _HistoryItem(
                      time: '07:02 AM',
                      name: 'Levothyroxine Sodium',
                      dose: '50 mcg',
                      status: 'Taken on empty stomach',
                      isSuccess: true,
                    ),
                    _HistoryItem(
                      time: 'Yesterday 22:04 PM',
                      name: 'Atorvastatin',
                      dose: '20 mg',
                      status: 'Taken at bedtime',
                      isSuccess: true,
                    ),
                    _HistoryItem(
                      time: 'Yesterday 13:10 PM',
                      name: 'Calcium Carbonate',
                      dose: '500 mg',
                      status: 'Taken with food (4h gap verified)',
                      isSuccess: true,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static Widget _buildStat(String value, String label, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 20,
            fontWeight: FontWeight.w800,
            fontFamily: ChronoTheme.monoFont,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 10.5),
        ),
      ],
    );
  }
}

class _HistoryItem extends StatelessWidget {
  final String time;
  final String name;
  final String dose;
  final String status;
  final bool isSuccess;

  const _HistoryItem({
    required this.time,
    required this.name,
    required this.dose,
    required this.status,
    required this.isSuccess,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF131A26),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.06)),
      ),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: isSuccess ? const Color(0xFF2DD4BF) : Colors.amber,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$name  ($dose)',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  status,
                  style: const TextStyle(
                    color: Color(0xFF94A3B8),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          Text(
            time,
            style: const TextStyle(
              color: Color(0xFF64748B),
              fontSize: 10.5,
              fontFamily: ChronoTheme.monoFont,
            ),
          ),
        ],
      ),
    );
  }
}
