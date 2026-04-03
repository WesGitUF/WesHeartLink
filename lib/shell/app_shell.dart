import 'package:flutter/material.dart';
import 'package:heart_link_app/screens/home/home_screen.dart';
import 'package:heart_link_app/screens/history/history_screen.dart';
import 'package:heart_link_app/screens/profile/profile_screen.dart';
import 'package:heart_link_app/screens/session/session_screen.dart';
import 'package:heart_link_app/screens/heartratedial/hr.state.dart';
import 'package:heart_link_app/screens/session/workout_root_screen.dart';
import 'package:heart_link_app/app/theme/app_theme.dart';
import 'package:heart_link_app/screens/history/history_repo.dart';
import 'package:heart_link_app/services/workout_service.dart';

class AppShell extends StatefulWidget {
  const AppShell({
    super.key,
    this.initialIndex = 0,
  });

  final int initialIndex;
  @override
  State<AppShell> createState() => _AppShellState();
}

// use to manage bottom navigation and floating action button
class _AppShellState extends State<AppShell> {
  // current selected index
  late int _index;
  final ValueNotifier<int> _historyTabs = ValueNotifier(0);
  final ValueNotifier<int> _homeTabs = ValueNotifier(0);

  @override
  void initState() {
    super.initState();
    _index = widget.initialIndex;
    _recoverCrashedWorkoutIfNeeded();
  }

  Future<void> _recoverCrashedWorkoutIfNeeded() async {
    final recovered = await WorkoutService.recoverCrashedWorkout();
    if (!recovered) return;

    // Refresh the in-memory history list so the recovered workout appears
    // immediately without requiring the user to restart the app.
    // loadFromCloud() works offline too — Firestore's local persistence cache
    // includes the write that was just queued.
    await HistoryRepo.instance.loadFromCloud();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Your previous workout was automatically saved.'),
          duration: Duration(seconds: 4),
        ),
      );
    }
  }

  // switch tab
  void _go(int i) {
    setState(() {
      if (i == 1) _historyTabs.value++;
      if (i == 0) _homeTabs.value++;
      _index = i;
    });
  }

  // floating action button opens the session selection flow
  Future<void> _openSessionFlow() async {
    if (hrState.sessionActive) {
      _go(2); // go to Workout tab if one is already active
      return;
    }

    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const SessionScreen(),
      ),
    );
  }

  // bottom navigation item
  Widget _navItem({
    required int i,
    required IconData icon,
    required String label,
  }) {
    final bool selected = _index == i;

    final Color iconColor =
    selected ? AppColors.textPrimary : AppColors.iconDefault;

    final Color labelColor =
    selected ? AppColors.textPrimary : AppColors.textMuted;

    return InkWell(
      onTap: () => _go(i),
      borderRadius: BorderRadius.circular(12),
      splashColor: AppColors.red.withValues(alpha: 0.2),
      highlightColor: Colors.transparent,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: iconColor,
              size: 26,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: labelColor,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }



  // main interface structure
  @override
  Widget build(BuildContext context) {
    final pages = <Widget>[
      HomeScreen(onTabVisible: _homeTabs), // index 0
      HistoryScreen(onTabVisible: _historyTabs), // index 1
      const WorkoutRootScreen(), // index 2
      const ProfileScreen(), // index 3
    ];

    return Scaffold(
      extendBody: true, // extend body behind bottom app bar
      body: SafeArea(
        // use IndexedStack to maintain state of each tab
        child: IndexedStack(
            index: _index,
            children: pages
        ),
      ),
      // floating action button
      floatingActionButton: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: AppGradients.accentPink,
          boxShadow: AppShadows.fabGlow,
        ),
        child: FloatingActionButton(
          onPressed: _openSessionFlow,
          elevation: 0,
          backgroundColor: Colors.transparent,
          foregroundColor: AppColors.white,
          shape: const CircleBorder(),
          child: const Icon(Icons.add, size: 30),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,

      // bottom navigation bar
      bottomNavigationBar: BottomAppBar(
        shape: const CircularNotchedRectangle(),
        notchMargin: 10,
        elevation: 0,
        color: Colors.transparent,
        padding: EdgeInsets.zero,
        child: Container(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).padding.bottom > 0
                ? MediaQuery.of(context).padding.bottom
                : 6,
          ),
          decoration: BoxDecoration(
            color: AppColors.surfacePrimary.withValues(alpha: 0.96),
            border: Border(
              top: BorderSide(color: AppColors.strokeSoft),
            ),
            boxShadow: const [
              BoxShadow(
                color: Color(0x66000000),
                blurRadius: 24,
                offset: Offset(0, -6),
              ),
            ],
          ),
          child: SizedBox(
            height: 74,
            child: Row(
              children: [
                Expanded(
                  child: _navItem(
                    i: 0,
                    icon: Icons.home_outlined,
                    label: 'Home',
                  ),
                ),
                Expanded(
                  child: _navItem(
                    i: 1,
                    icon: Icons.history,
                    label: 'History',
                  ),
                ),
                const SizedBox(width: 96),
                Expanded(
                  child: _navItem(
                    i: 2,
                    icon: Icons.favorite_border,
                    label: 'Workout',
                  ),
                ),
                Expanded(
                  child: _navItem(
                    i: 3,
                    icon: Icons.person_outline,
                    label: 'Profile',
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
