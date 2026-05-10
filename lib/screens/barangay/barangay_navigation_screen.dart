import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/firestore_service.dart';
import 'barangay_home_screen.dart';
import 'barangay_submit_request_screen.dart';
import 'barangay_my_requests_screen.dart';
import 'barangay_notifications_screen.dart';
import 'barangay_profile_screen.dart';
import 'barangay_ride_logs_screen.dart';

class BarangayNavigationScreen extends StatefulWidget {
  const BarangayNavigationScreen({super.key});

  @override
  State<BarangayNavigationScreen> createState() =>
      _BarangayNavigationScreenState();
}

class _BarangayNavigationScreenState extends State<BarangayNavigationScreen> {
  int _currentIndex = 0;

  static const _items = [
    _NavItem(
      icon: Icons.home_outlined,
      activeIcon: Icons.home_rounded,
      label: 'Home',
    ),
    _NavItem(
      icon: Icons.add_circle_outline_rounded,
      activeIcon: Icons.add_circle_rounded,
      label: 'Submit',
    ),
    _NavItem(
      icon: Icons.folder_outlined,
      activeIcon: Icons.folder_rounded,
      label: 'Requests',
    ),
    _NavItem(
      icon: Icons.notifications_outlined,
      activeIcon: Icons.notifications_rounded,
      label: 'Alerts',
    ),
    _NavItem(
      icon: Icons.bar_chart_outlined,
      activeIcon: Icons.bar_chart_rounded,
      label: 'Logs',
    ),
    _NavItem(
      icon: Icons.person_outline_rounded,
      activeIcon: Icons.person_rounded,
      label: 'Profile',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final uid = context.read<AuthProvider>().appUser?.uid ?? '';
    final fs = FirestoreService();

    final screens = [
      const BarangayHomeScreen(),
      const BarangaySubmitRequestScreen(),
      const BarangayMyRequestsScreen(),
      const BarangayNotificationsScreen(),
      const BarangayRideLogsScreen(),
      const BarangayProfileScreen(),
    ];

    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: screens),
      bottomNavigationBar: StreamBuilder<int>(
        stream: fs.streamUnreadNotificationCount(uid),
        builder: (context, snap) {
          final unread = snap.data ?? 0;
          return _ProNavBar(
            currentIndex: _currentIndex,
            items: _items,
            notifBadge: unread,
            notifIndex: 3, // Alerts tab index unchanged
            onTap: (index) => setState(() => _currentIndex = index),
          );
        },
      ),
    );
  }
}

class _NavItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
  });
}

class _ProNavBar extends StatelessWidget {
  final int currentIndex;
  final List<_NavItem> items;
  final int notifBadge;
  final int notifIndex;
  final ValueChanged<int> onTap;

  const _ProNavBar({
    required this.currentIndex,
    required this.items,
    required this.notifBadge,
    required this.notifIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(color: const Color(0xFFE5E7EB), width: 1),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 60,
          child: Row(
            children: List.generate(items.length, (index) {
              final item = items[index];
              final isActive = index == currentIndex;
              final showBadge = index == notifIndex && notifBadge > 0;

              return Expanded(
                child: GestureDetector(
                  onTap: () => onTap(index),
                  behavior: HitTestBehavior.opaque,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Stack(
                        clipBehavior: Clip.none,
                        children: [
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            curve: Curves.easeInOut,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: isActive
                                  ? const Color(
                                      0xFF3B82F6,
                                    ).withValues(alpha: 0.1)
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Icon(
                              isActive ? item.activeIcon : item.icon,
                              size: 22,
                              color: isActive
                                  ? const Color(0xFF3B82F6)
                                  : const Color(0xFF9CA3AF),
                            ),
                          ),
                          if (showBadge)
                            Positioned(
                              right: 6,
                              top: 0,
                              child: Container(
                                width: 16,
                                height: 16,
                                decoration: const BoxDecoration(
                                  color: Color(0xFFEF4444),
                                  shape: BoxShape.circle,
                                ),
                                child: Center(
                                  child: Text(
                                    notifBadge > 9 ? '9+' : '$notifBadge',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 9,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(
                        item.label,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: isActive
                              ? FontWeight.w600
                              : FontWeight.w400,
                          color: isActive
                              ? const Color(0xFF3B82F6)
                              : const Color(0xFF9CA3AF),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}
