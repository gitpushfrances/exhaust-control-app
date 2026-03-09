import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/bluetooth_provider.dart';

class SharedProfileScreen extends StatelessWidget {
  const SharedProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.appUser;
    final role = user?.role ?? 'rider';

    final roleLabel =
        {
          'super_admin': 'Super Admin',
          'barangay_official': 'Barangay Official',
          'rider': 'Rider',
        }[role] ??
        'User';

    final roleColor =
        {
          'super_admin': const Color(0xFF8B5CF6),
          'barangay_official': const Color(0xFF3B82F6),
          'rider': const Color(0xFF10B981),
        }[role] ??
        const Color(0xFF6B7280);

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        title: const Text(
          'Profile & Settings',
          style: TextStyle(
            color: Color(0xFF111827),
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // ── Header ──────────────────────────────────────────
            Container(
              color: Colors.white,
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 36,
                    backgroundColor: roleColor.withValues(alpha: 0.12),
                    child: Text(
                      (user?.name.isNotEmpty == true)
                          ? user!.name[0].toUpperCase()
                          : '?',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                        color: roleColor,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    user?.name ?? 'Unknown',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF111827),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    user?.email ?? '',
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF6B7280),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: roleColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      roleLabel,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: roleColor,
                      ),
                    ),
                  ),
                  if (role == 'barangay_official' &&
                      (user?.barangayName?.isNotEmpty ?? false)) ...[
                    const SizedBox(height: 6),
                    Text(
                      user!.barangayName!,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF9CA3AF),
                      ),
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 16),

            // ── Account Info ─────────────────────────────────────
            _Section(
              title: 'Account',
              children: [
                _Item(
                  icon: Icons.info_outline,
                  title: 'About App',
                  subtitle: 'Exhaust Controller v0.7.0',
                  onTap: () => showAboutDialog(
                    context: context,
                    applicationName: 'Exhaust Control System',
                    applicationVersion: '0.7.0',
                    applicationIcon: const Icon(
                      Icons.motorcycle,
                      size: 32,
                      color: Color(0xFF3B82F6),
                    ),
                    children: const [
                      Text(
                        'Automatic Motorcycle Exhaust Noise Control System — Capstone Project',
                      ),
                    ],
                  ),
                ),
                _Item(
                  icon: Icons.help_outline,
                  title: 'Help & Support',
                  subtitle: 'Get help with the app',
                  onTap: () => ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(const SnackBar(content: Text('Coming soon!'))),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // ── Logout ───────────────────────────────────────────
            Container(
              color: Colors.white,
              child: _Item(
                icon: Icons.logout,
                title: 'Logout',
                subtitle: 'Sign out and switch accounts',
                titleColor: const Color(0xFFEF4444),
                onTap: () => _showLogoutDialog(context),
              ),
            ),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              final auth = context.read<AuthProvider>();
              final bt = context.read<BluetoothProvider>();
              if (bt.isConnected) await bt.disconnect();
              await auth.signOut();
              if (ctx.mounted) {
                Navigator.pop(ctx);
                Navigator.pushReplacementNamed(ctx, '/login');
              }
            },
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFFEF4444),
            ),
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }
}

// ── Reusable Section ──────────────────────────────────────────
class _Section extends StatelessWidget {
  final String title;
  final List<Widget> children;
  const _Section({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFF6B7280),
                letterSpacing: 0.5,
              ),
            ),
          ),
          ...children,
        ],
      ),
    );
  }
}

// ── Reusable Item ─────────────────────────────────────────────
class _Item extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback? onTap;
  final Color? titleColor;

  const _Item({
    required this.icon,
    required this.title,
    this.subtitle,
    this.onTap,
    this.titleColor,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          child: Row(
            children: [
              Icon(
                icon,
                size: 22,
                color: titleColor ?? const Color(0xFF6B7280),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        color: titleColor ?? const Color(0xFF111827),
                      ),
                    ),
                    if (subtitle != null)
                      Text(
                        subtitle!,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF9CA3AF),
                        ),
                      ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right,
                color: Color(0xFF9CA3AF),
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
