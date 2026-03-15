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

    // Normalize role — handle both 'superadmin' and 'super_admin'
    final normalizedRole = role.replaceAll('_', '');

    final roleLabel =
        {
          'superadmin': 'Super Admin',
          'barangayofficial': 'Barangay Official',
          'rider': 'Rider',
        }[normalizedRole] ??
        'User';

    final roleColor =
        {
          'superadmin': const Color(0xFF6366F1),
          'barangayofficial': const Color(0xFF3B82F6),
          'rider': const Color(0xFF10B981),
        }[normalizedRole] ??
        const Color(0xFF6B7280);

    final gradientColors =
        {
          'superadmin': [const Color(0xFF6366F1), const Color(0xFF4338CA)],
          'barangayofficial': [
            const Color(0xFF3B82F6),
            const Color(0xFF1D4ED8),
          ],
          'rider': [const Color(0xFF10B981), const Color(0xFF059669)],
        }[normalizedRole] ??
        [const Color(0xFF6B7280), const Color(0xFF4B5563)];

    final initial = (user?.name.isNotEmpty == true)
        ? user!.name[0].toUpperCase()
        : '?';

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        title: const Text(
          'Profile',
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
            // ── Profile Header Card ───────────────────────────
            Container(
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                gradient: LinearGradient(
                  colors: gradientColors,
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: gradientColors[0].withValues(alpha: 0.35),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Row(
                  children: [
                    // Avatar
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.5),
                          width: 2,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          initial,
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            user?.name ?? 'Unknown',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            user?.email ?? '',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.white.withValues(alpha: 0.8),
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.4),
                              ),
                            ),
                            child: Text(
                              roleLabel,
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ── Account Details ───────────────────────────────
            _Section(
              title: 'Account Details',
              children: [
                _InfoRow(
                  icon: Icons.person_outline_rounded,
                  label: 'Full Name',
                  value: user?.name ?? '—',
                  color: roleColor,
                ),
                _Divider(),
                _InfoRow(
                  icon: Icons.email_outlined,
                  label: 'Email',
                  value: user?.email ?? '—',
                  color: roleColor,
                ),
                if (normalizedRole == 'barangayofficial') ...[
                  _Divider(),
                  _InfoRow(
                    icon: Icons.location_city_outlined,
                    label: 'Barangay',
                    value: user?.barangayName ?? user?.barangayId ?? '—',
                    color: roleColor,
                  ),
                ],
                _Divider(),
                _InfoRow(
                  icon: Icons.verified_user_outlined,
                  label: 'Role',
                  value: roleLabel,
                  color: roleColor,
                ),
              ],
            ),

            const SizedBox(height: 12),

            // ── App ───────────────────────────────────────────
            _Section(
              title: 'App',
              children: [
                _ActionRow(
                  icon: Icons.info_outline_rounded,
                  title: 'About',
                  subtitle: 'Exhaust Controller v0.7.0',
                  color: const Color(0xFF3B82F6),
                  onTap: () => showAboutDialog(
                    context: context,
                    applicationName: 'Exhaust Control System',
                    applicationVersion: '0.7.0',
                    applicationIcon: const Icon(
                      Icons.two_wheeler_rounded,
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
                _Divider(),
                _ActionRow(
                  icon: Icons.help_outline_rounded,
                  title: 'Help & Support',
                  subtitle: 'Get help with the app',
                  color: const Color(0xFF6B7280),
                  onTap: () => ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(const SnackBar(content: Text('Coming soon!'))),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // ── Logout ────────────────────────────────────────
            _Section(
              title: 'Session',
              children: [
                _ActionRow(
                  icon: Icons.logout_rounded,
                  title: 'Sign Out',
                  subtitle: 'Log out of your account',
                  color: const Color(0xFFEF4444),
                  titleColor: const Color(0xFFEF4444),
                  onTap: () => _showLogoutDialog(context),
                ),
              ],
            ),

            const SizedBox(height: 32),

            // ── Version footer ────────────────────────────────
            Text(
              'Exhaust Controller • v0.7.0',
              style: TextStyle(fontSize: 11, color: const Color(0xFF9CA3AF)),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Sign Out',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text(
              'Cancel',
              style: TextStyle(color: Color(0xFF6B7280)),
            ),
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
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );
  }
}

// ── Section wrapper ───────────────────────────────────────────

class _Section extends StatelessWidget {
  final String title;
  final List<Widget> children;
  const _Section({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
          child: Text(
            title.toUpperCase(),
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Color(0xFF9CA3AF),
              letterSpacing: 0.8,
            ),
          ),
        ),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(children: children),
        ),
      ],
    );
  }
}

// ── Info row (non-tappable) ───────────────────────────────────

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 18, color: color),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF9CA3AF),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF111827),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Action row (tappable) ─────────────────────────────────────

class _ActionRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final Color? titleColor;
  final VoidCallback onTap;

  const _ActionRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
    this.titleColor,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, size: 18, color: color),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: titleColor ?? const Color(0xFF111827),
                      ),
                    ),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFF9CA3AF),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: const Color(0xFFD1D5DB),
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Thin divider ──────────────────────────────────────────────

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return const Divider(
      height: 1,
      indent: 64,
      endIndent: 0,
      color: Color(0xFFF3F4F6),
    );
  }
}
