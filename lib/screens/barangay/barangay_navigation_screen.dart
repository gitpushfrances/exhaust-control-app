import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/firestore_service.dart';
import 'barangay_home_screen.dart';
import 'barangay_submit_request_screen.dart';
import 'barangay_my_requests_screen.dart';
import 'barangay_notifications_screen.dart';
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
    final uid = context.read<AuthProvider>().appUser?.uid ?? '';
    final fs = FirestoreService();

    final screens = [
      const BarangayHomeScreen(),
      const BarangaySubmitRequestScreen(),
      const BarangayMyRequestsScreen(),
      const BarangayNotificationsScreen(),
      const BarangayProfileScreen(),
    ];

    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: screens),
      bottomNavigationBar: StreamBuilder<int>(
        stream: fs.streamUnreadNotificationCount(uid),
        builder: (context, snap) {
          final unread = snap.data ?? 0;
          return BottomNavigationBar(
            currentIndex: _currentIndex,
            onTap: (index) => setState(() => _currentIndex = index),
            type: BottomNavigationBarType.fixed,
            selectedItemColor: const Color(0xFF3B82F6),
            unselectedItemColor: const Color(0xFF9CA3AF),
            items: [
              const BottomNavigationBarItem(
                icon: Icon(Icons.home_outlined),
                activeIcon: Icon(Icons.home),
                label: 'Home',
              ),
              const BottomNavigationBarItem(
                icon: Icon(Icons.add_location_outlined),
                activeIcon: Icon(Icons.add_location),
                label: 'Submit',
              ),
              const BottomNavigationBarItem(
                icon: Icon(Icons.list_alt_outlined),
                activeIcon: Icon(Icons.list_alt),
                label: 'Requests',
              ),
              BottomNavigationBarItem(
                icon: Badge(
                  isLabelVisible: unread > 0,
                  label: Text('$unread'),
                  child: const Icon(Icons.notifications_outlined),
                ),
                activeIcon: Badge(
                  isLabelVisible: unread > 0,
                  label: Text('$unread'),
                  child: const Icon(Icons.notifications),
                ),
                label: 'Notifications',
              ),
              const BottomNavigationBarItem(
                icon: Icon(Icons.person_outline),
                activeIcon: Icon(Icons.person),
                label: 'Profile',
              ),
            ],
          );
        },
      ),
    );
  }
}
