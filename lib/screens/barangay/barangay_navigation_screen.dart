import 'package:flutter/material.dart';
import 'barangay_home_screen.dart';
import 'barangay_submit_request_screen.dart';
import 'barangay_my_requests_screen.dart';
import 'barangay_profile_screen.dart';

class BarangayNavigationScreen extends StatefulWidget {
  const BarangayNavigationScreen({super.key});

  @override
  State<BarangayNavigationScreen> createState() =>
      _BarangayNavigationScreenState();
}

class _BarangayNavigationScreenState extends State<BarangayNavigationScreen> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final screens = [
      const BarangayHomeScreen(),
      const BarangaySubmitRequestScreen(),
      const BarangayMyRequestsScreen(),
      const BarangayProfileScreen(),
    ];

    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: screens),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        type: BottomNavigationBarType.fixed,
        selectedItemColor: const Color(0xFF3B82F6),
        unselectedItemColor: const Color(0xFF9CA3AF),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.add_location_outlined),
            activeIcon: Icon(Icons.add_location),
            label: 'Submit',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.list_alt_outlined),
            activeIcon: Icon(Icons.list_alt),
            label: 'Requests',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
