
import 'package:cloud_firestore/cloud_firestore.dart';
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
    // Center(child: Text('Session Tab')),
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
  //   final List<String> sessions = const [
  //   "Session 1: 01/10/2025 - Avg 75 bpm - 16 mi - Cycling",
  //   "Session 2: 02/11/2025 - Avg 78 bpm - 10 mi - Cycling",
  //   "Session 3: 02/12/2025 - Avg 95 bpm - 6 mi - Running",
  // ];

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final scale = screenWidth / 400.0;
    return Scaffold(
      appBar: AppBar(title: const Text('HeartLink Home')),
      body: Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          ElevatedButton(
            onPressed: () {
              Navigator.pushNamed(context, '/session');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 40),
              textStyle: TextStyle(fontSize: 24 * scale),
            ),
            child: const Text("Start a New Session"),
          ),
          SizedBox(height: 20* scale),
          const Divider(thickness: 2, color: Colors.grey),
          
          Text(
                  "Previous Sessions",
                  style: TextStyle(fontSize: 16 * scale, fontWeight: FontWeight.w500),
                  textAlign: TextAlign.center,
          ),
          //read session doc from firestore
          Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                  .collection('allSessions')
                  .orderBy('finishedAt', descending: true)
                  .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return const Center(child: Text('Error loading sessions'));
                  }
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final docs = snapshot.data!.docs;
                  if (docs.isEmpty) {
                    return const Center(child: Text('No sessions found.'));
                  }

                  return ListView.builder(
                    itemCount: docs.length,
                    itemBuilder: (context, index) {
                      final doc = docs[index];
                      final data = doc.data() as Map<String, dynamic>;
                      
                      final String sport = data['sport'] ?? 'Unknown';
                      final int timeSpent = data['timeSpent'] ?? 0; 
                      final int timeInSameZone = data['timeInSameZone'] ?? 0; 
                      final double avgUserHR = data['avgUserHR'] ?? 0.0;
                      final double avgPartnerHR = data['avgPartnerHR'] ?? 0.0;
                      final double avgHR = data['avgHR'] ?? 0.0;
                      final finishedAt = data['finishedAt']; 
                      
                      final durationMin = (timeSpent / 60).toStringAsFixed(1);
                      final sameZoneMin = (timeInSameZone / 60).toStringAsFixed(1);
                      
                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 8),
                        child: ListTile(
                          leading: const Icon(Icons.history),
                          title: Text(
                            '$sport Session\n'
                            'Total Time: $durationMin min, '
                            'Same-Zone: $sameZoneMin min,'
                            'Primary User\'s Avg HR: ${avgUserHR.toStringAsFixed(1)} bpm,'
                            'Secondary User\'s Avg HR: ${avgPartnerHR.toStringAsFixed(1)} bpm,'
                            'Avg HR: ${avgHR.toStringAsFixed(1)} bpm',
                          ),
                          subtitle: finishedAt != null
                              ? Text('Finished: ${finishedAt.toDate().toString()}')
                              : const Text('No finish time'),
                        ),
                      );
                    },
                  );
                },
              ),
            ),

          // Expanded(
          //   child: ListView.builder(
          //     itemCount: sessions.length,
          //     itemBuilder: (context, index) {
          //       return Card(
          //         margin: const EdgeInsets.symmetric(vertical: 8),
          //         child: ListTile(
          //           leading: const Icon(Icons.history),
          //           title: Text(sessions[index]),
          //         ),
          //       );
          //     },
          //   ),
          // ),
        ],
      ),
    ),
    );
  }
}
