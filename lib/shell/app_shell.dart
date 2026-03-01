import 'package:flutter/material.dart';
import 'package:heart_link_app/screens/home/home_screen.dart';
import 'package:heart_link_app/screens/history/history_screen.dart';
import 'package:heart_link_app/screens/profile/profile_screen.dart';
import 'package:heart_link_app/screens/session/sensor_selection_screen.dart';
import 'package:heart_link_app/screens/heartratedial/heartratedial_screen.dart';
import 'package:heart_link_app/screens/session/session_screen.dart';
import 'package:heart_link_app/screens/heartratedial/hr.state.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key});
  @override
  State<AppShell> createState() => _AppShellState();
}

// use to manage bottom navigation and floating action button
class _AppShellState extends State<AppShell> {
  // current selected index
  int _index = 0;

  // use this key to manage the inner navigator of Heart tab
  final GlobalKey<NavigatorState> _heartNavKey = GlobalKey<NavigatorState>();

  // switch tab
  void _go(int i) => setState(() => _index = i);

  // floating action button opens the session selection flow
  void _openSessionFlow() {
  if (_index != 2) _go(2);
  // 
  _heartNavKey.currentState?.pushNamed('/session');
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
    // four main pages
    final pages = <Widget>[
      const HomeScreen(),
      const HistoryScreen(),
      // Heart rate tab with inner navigator
      HeartTabNavigator(navKey: _heartNavKey), 
      const ProfileScreen(),
    ];

    return Scaffold(
      extendBody: true, // extend body behind bottom app bar
      body: SafeArea(
        // use IndexedStack to maintain state of each tab
        child: IndexedStack(index: _index, children: pages),
      ),
      // floating action button
      floatingActionButton: FloatingActionButton(
      onPressed: () {
        if (hrState.sessionActive) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("You can't start a new session while a workout is active."),
            ),
          );
          return;
        }
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
                Expanded(child: _navItem(i: 0, icon: Icons.home_rounded,    label: 'Home')),
                Expanded(child: _navItem(i: 1, icon: Icons.history_rounded, label: 'History')),
                const SizedBox(width: 64),
                Expanded(child: _navItem(i: 2, icon: Icons.favorite_rounded,label: 'Workout')),
                Expanded(child: _navItem(i: 3, icon: Icons.person_rounded,  label: 'Profile')),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// Navigator for Heart Rate tab
class HeartTabNavigator extends StatelessWidget {
  final GlobalKey<NavigatorState> navKey;
  const HeartTabNavigator({super.key, required this.navKey});

  @override
  Widget build(BuildContext context) {
    return Navigator(
      key: navKey,
      initialRoute: '/heartrate',
      onGenerateRoute: (settings) {
        // apply routing based on route name
        switch (settings.name) {
          case '/heartrate':
          case '/dial': 
          case '/':
            return MaterialPageRoute(
              builder: (_) => const HeartratedialScreen(),
              settings: settings,
            );
          case '/session':
            return MaterialPageRoute(
              builder: (_) => const SessionScreen(),
              settings: settings,
            );
          case '/sensor':
            return MaterialPageRoute(
              builder: (_) => const SensorSelectionScreen(),
              settings: settings,
            );
          default:
            // fallback to heartrate screen
            return MaterialPageRoute(
              builder: (_) => const HeartratedialScreen(),
              settings: settings,
            );
        }
      },
    );
  }
}