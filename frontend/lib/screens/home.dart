import 'package:flutter/material.dart';
import 'scan.dart';
import 'history.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  // The pages corresponding to the bottom tabs
  final List<Widget> _pages = [
    const DashboardTab(),
    const HistoryScreen(), // We create this later
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("FarmGuard"),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      body: _pages[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        selectedItemColor: Colors.green,
        onTap: (index) => setState(() => _currentIndex = index),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),
          BottomNavigationBarItem(icon: Icon(Icons.history), label: "History"),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.green,
        child: const Icon(Icons.camera_alt, color: Colors.white),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const ScanScreen()),
          );
        },
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }
}

// A simple internal widget for the main dashboard content
class DashboardTab extends StatelessWidget {
  const DashboardTab({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          color: Colors.green[50],
          child: ListTile(
            leading: const Icon(Icons.wb_sunny, color: Colors.orange),
            title: const Text("Weather Today"),
            subtitle: const Text("28°C, Sunny. Good for spraying."),
          ),
        ),
        const SizedBox(height: 20),
        const Text(
          "Quick Actions",
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _actionCard(Icons.local_library, "Guide"),
            _actionCard(Icons.support_agent, "Expert"),
            _actionCard(Icons.settings, "Settings"),
          ],
        ),
      ],
    );
  }

  Widget _actionCard(IconData icon, String label) {
    return Column(
      children: [
        CircleAvatar(
          radius: 30,
          backgroundColor: Colors.green[100],
          child: Icon(icon, color: Colors.green),
        ),
        const SizedBox(height: 8),
        Text(label),
      ],
    );
  }
}
