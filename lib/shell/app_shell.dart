import 'package:flutter/material.dart';
import 'package:heart_link_app/screens/home/home_screen.dart';
import 'package:heart_link_app/screens/history/history_screen.dart';
import 'package:heart_link_app/screens/profile/profile_screen.dart';
import 'package:heart_link_app/screens/session/session_screen.dart';
import 'package:heart_link_app/screens/heartratedial/hr.state.dart';
import 'package:heart_link_app/screens/session/workout_root_screen.dart';

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
    final Color color =
        selected ? const Color.fromARGB(255, 190, 88, 88) : Colors.black54;

    return InkWell(
      onTap: () => _go(i),
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 2.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: color,
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
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // if (hrState.sessionActive) {
          //   ScaffoldMessenger.of(context).showSnackBar(
          //     const SnackBar(
          //       content: Text("You can't start a new session while a workout is active."),
          //     ),
          //   );
          //   return;
          // }
          _openSessionFlow();
        },
        shape: const CircleBorder(),
        backgroundColor: const Color.fromARGB(255, 175, 82, 82),
        child: const Icon(Icons.add, size: 30, color: Colors.white),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,

      // bottom navigation bar
      bottomNavigationBar: BottomAppBar(
        shape: const CircularNotchedRectangle(),
        notchMargin: 8,
        elevation: 8,
        color: const Color.fromARGB(255, 73, 75, 76),
        child: SafeArea(
          top: false,
          minimum: const EdgeInsets.only(bottom: 4),
          child: SizedBox(
            height: 68,
            child: Row(
              children: [
                Expanded(
                    child: _navItem(
                        i: 0,
                        icon: Icons.home_rounded,
                        label: 'Home',
                    ),
                ),
                Expanded(
                    child: _navItem(
                        i: 1,
                        icon: Icons.history_rounded,
                        label: 'History',
                    ),
                ),
                const SizedBox(width: 110),
                Expanded(
                    child: _navItem(
                        i: 2,
                        icon: Icons.favorite_rounded,
                        label: 'Workout',
                    ),
                ),
                const SizedBox(width: 30),
                Expanded(
                    child: _navItem(
                        i: 3,
                        icon: Icons.person_rounded,
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
