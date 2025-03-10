
import 'package:flutter/material.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    _HomeTab(),
    Center(child: Text('Session Tab')),
    Center(child: Text('Profile Tab')),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          // BottomNavigationBarItem(
          //   icon: Icon(Icons.favorite),
          //   label: 'Session',
          // ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}

class _HomeTab extends StatelessWidget {
  const _HomeTab();
    final List<String> sessions = const [
    "Session 1: 01/10/2025 - Avg 75 bpm - 16 mi - Cycling",
    "Session 2: 02/11/2025 - Avg 78 bpm - 10 mi - Cycling",
    "Session 3: 02/12/2025 - Avg 95 bpm - 6 mi - Running",
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('HeartLink Home')),
      // body: Center(
      //   child: ElevatedButton(
      //     child: const Text('Start New Session'),
      //     onPressed: () {
      //       Navigator.pushNamed(context, '/session');
      //     },
      //   ),
      // ),
      //Changing the UI elements to match our LowFi design.
      body: Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          // Large green "Start a New Session" button.
          ElevatedButton(
            onPressed: () {
              Navigator.pushNamed(context, '/session');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 40),
              textStyle: const TextStyle(fontSize: 24),
            ),
            child: const Text("Start a New Session"),
          ),
          const SizedBox(height: 20),
          // Recent sessions list in a ListView.
          Expanded(
            child: ListView.builder(
              itemCount: sessions.length,
              itemBuilder: (context, index) {
                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  child: ListTile(
                    leading: const Icon(Icons.history),
                    title: Text(sessions[index]),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    ),
    );
  }
}
