import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'app_colors.dart';
import 'app_text_styles.dart';

class AppPermissionHandler {
  static const _kBgLocationSkippedKey = 'bg_location_skipped';

  /// Check if all required permissions are granted
  static Future<bool> checkAllPermissions() async {
    final bluetoothStatus = await _checkBluetoothPermissions();
    final locationStatus = await Permission.locationWhenInUse.status;
    final bgLocationStatus = await Permission.locationAlways.status;

    return bluetoothStatus &&
        locationStatus.isGranted &&
        bgLocationStatus.isGranted;
  }

  /// Request all required permissions in correct order
  static Future<bool> requestAllPermissions(BuildContext context) async {
    // 1. Bluetooth
    final bluetoothGranted = await _requestBluetoothPermissions(context);
    if (!bluetoothGranted) return false;
    if (!context.mounted) return false;

    // 2. Foreground location (must come before background)
    final locationGranted = await _requestLocationPermission(context);
    if (!locationGranted) return false;
    if (!context.mounted) return false;

    // 3. Background location (only ask after foreground is granted)
    await _requestBackgroundLocationPermission(context);

    // Background location is non-blocking — app works without it,
    // but GPS will stop when app is minimized.
    return true;
  }

  /// Check Bluetooth permissions (Android 12+)
  static Future<bool> _checkBluetoothPermissions() async {
    if (await _isAndroid12OrHigher()) {
      final scan = await Permission.bluetoothScan.status;
      final connect = await Permission.bluetoothConnect.status;
      return scan.isGranted && connect.isGranted;
    } else {
      final bt = await Permission.bluetooth.status;
      return bt.isGranted;
    }
  }

  /// Request Bluetooth permissions
  static Future<bool> _requestBluetoothPermissions(BuildContext context) async {
    if (await _isAndroid12OrHigher()) {
      final statuses = await [
        Permission.bluetoothScan,
        Permission.bluetoothConnect,
      ].request();

      final allGranted = statuses.values.every((s) => s.isGranted);

      if (!allGranted) {
        if (!context.mounted) return false;
        await _showPermissionDialog(
          context,
          title: 'Bluetooth Permission Required',
          description:
              'This app needs Bluetooth to connect to your exhaust controller.',
          onRetry: () => _requestBluetoothPermissions(context),
        );
        return false;
      }
      return true;
    } else {
      final status = await Permission.bluetooth.request();
      if (!status.isGranted) {
        if (!context.mounted) return false;
        await _showPermissionDialog(
          context,
          title: 'Bluetooth Permission Required',
          description:
              'This app needs Bluetooth to connect to your exhaust controller.',
          onRetry: () => _requestBluetoothPermissions(context),
        );
        return false;
      }
      return true;
    }
  }

  /// Request foreground location
  static Future<bool> _requestLocationPermission(BuildContext context) async {
    final status = await Permission.locationWhenInUse.request();
    if (!status.isGranted) {
      if (!context.mounted) return false;
      await _showPermissionDialog(
        context,
        title: 'Location Permission Required',
        description:
            'This app needs location access to detect restricted areas and auto-close the exhaust.',
        onRetry: () => _requestLocationPermission(context),
      );
      return false;
    }
    return true;
  }

  /// Request background location — shown AFTER foreground location is granted.
  /// On Android 10+, the system shows its own rationale dialog.
  /// On Android 11+, this opens app settings directly.
  static Future<void> _requestBackgroundLocationPermission(
    BuildContext context,
  ) async {
    final current = await Permission.locationAlways.status;
    if (current.isGranted) return;

    // Never ask again if user already dismissed once
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool(_kBgLocationSkippedKey) ?? false) return;

    if (!context.mounted) return;

    await _showPermissionModal(
      context,
      icon: Icons.my_location_outlined,
      title: 'Background Location',
      description:
          'Allow location access "All the time" so the exhaust valve auto-closes even when the app is minimized or your screen is off.',
      primaryLabel: 'Allow',
      secondaryLabel: 'Not Now',
      onPrimary: () async {
        await Permission.locationAlways.request();
        // Don't set the flag — if they deny the system prompt,
        // we ask again next launch until actually granted.
      },
      onSecondary: () async {
        // User explicitly skipped — respect it, never ask again.
        await prefs.setBool(_kBgLocationSkippedKey, true);
      },
    );
  }

  // ─── Modal ─────────────────────────────────────────────────────────────────

  static Future<void> _showPermissionModal(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String description,
    required String primaryLabel,
    String? secondaryLabel,
    Future<void> Function()? onPrimary,
    Future<void> Function()? onSecondary,
  }) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withOpacity(0.4),
      builder: (_) => _PermissionModal(
        icon: icon,
        title: title,
        description: description,
        primaryLabel: primaryLabel,
        secondaryLabel: secondaryLabel,
        onPrimary: onPrimary,
        onSecondary: onSecondary,
      ),
    );
  }

  /// Check if device is Android 12 or higher
  static Future<bool> _isAndroid12OrHigher() async {
    final androidInfo = await DeviceInfoPlugin().androidInfo;
    return androidInfo.version.sdkInt >= 31;
  }

  /// Generic permission rationale modal
  static Future<void> _showPermissionDialog(
    BuildContext context, {
    required String title,
    required String description,
    required Future<bool> Function() onRetry,
  }) async {
    await _showPermissionModal(
      context,
      icon: Icons.lock_outline,
      title: title,
      description: description,
      primaryLabel: 'Grant Permission',
      secondaryLabel: 'Skip',
      onPrimary: () async => await onRetry(),
    );
  }

  static Future<void> openSettings(BuildContext context) async {
    if (!context.mounted) return;
    await _showPermissionModal(
      context,
      icon: Icons.settings_outlined,
      title: 'Permission Required',
      description:
          'Some permissions are disabled. Please enable them in app settings to use all features.',
      primaryLabel: 'Open Settings',
      secondaryLabel: 'Cancel',
      onPrimary: () async => await openAppSettings(),
    );
  }
}

// ─── Modal Widget ──────────────────────────────────────────────────────────────

class _PermissionModal extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final String primaryLabel;
  final String? secondaryLabel;
  final Future<void> Function()? onPrimary;
  final Future<void> Function()? onSecondary;

  const _PermissionModal({
    required this.icon,
    required this.title,
    required this.description,
    required this.primaryLabel,
    this.secondaryLabel,
    this.onPrimary,
    this.onSecondary,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(
        24,
        20,
        24,
        24 + MediaQuery.of(context).viewPadding.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.grayBorder,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 24),
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: AppColors.primary, size: 26),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: AppTextStyles.headingSmall,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            description,
            style: AppTextStyles.bodyMedium.copyWith(height: 1.6),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 28),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: () async {
                Navigator.pop(context);
                await onPrimary?.call();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: Text(
                primaryLabel,
                style: AppTextStyles.button.copyWith(color: AppColors.white),
              ),
            ),
          ),
          if (secondaryLabel != null) ...[
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: TextButton(
                onPressed: () async {
                  Navigator.pop(context);
                  await onSecondary?.call();
                },
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.textSecondary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: Text(
                  secondaryLabel!,
                  style: AppTextStyles.buttonSmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
