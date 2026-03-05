import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/material.dart';
import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:device_info_plus/device_info_plus.dart';

class AppPermissionHandler {
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
    if (!bluetoothGranted) {
      if (!context.mounted) return false;
      return false;
    }

    // 2. Foreground location (must come before background)
    final locationGranted = await _requestLocationPermission(context);
    if (!locationGranted) {
      if (!context.mounted) return false;
      return false;
    }

    // 3. Background location (only ask after foreground is granted)
    if (!context.mounted) return false;
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

    if (!context.mounted) return;

    // Show our own explanation before the system prompt
    await AwesomeDialog(
      context: context,
      dialogType: DialogType.info,
      animType: AnimType.scale,
      title: 'Background Location',
      desc:
          'Allow location access "All the time" so the exhaust auto-closes even when the app is minimized.',
      btnOkText: 'Continue',
      btnCancelText: 'Skip',
      btnOkOnPress: () async {
        final status = await Permission.locationAlways.request();
        // On Android 11+, this opens Settings — user must manually allow.
        // On Android 10, system dialog appears inline.
        if (!status.isGranted && context.mounted) {
          // Silently continue — foreground location still works
        }
      },
      btnCancelOnPress: () {
        // GPS works in foreground only — acceptable degraded mode
      },
    ).show();
  }

  /// Check if device is Android 12 or higher
  static Future<bool> _isAndroid12OrHigher() async {
    final androidInfo = await DeviceInfoPlugin().androidInfo;
    return androidInfo.version.sdkInt >= 31;
  }

  /// Generic permission rationale dialog
  static Future<void> _showPermissionDialog(
    BuildContext context, {
    required String title,
    required String description,
    required Future<bool> Function() onRetry,
  }) async {
    await AwesomeDialog(
      context: context,
      dialogType: DialogType.warning,
      animType: AnimType.scale,
      title: title,
      desc: description,
      btnOkText: 'Grant Permission',
      btnCancelText: 'Skip',
      btnOkOnPress: () async {
        await onRetry();
      },
      btnCancelOnPress: () {},
    ).show();
  }

  /// Open app settings (for permanently denied permissions)
  static Future<void> openSettings(BuildContext context) async {
    if (!context.mounted) return;
    await AwesomeDialog(
      context: context,
      dialogType: DialogType.info,
      animType: AnimType.scale,
      title: 'Permission Required',
      desc: 'Please enable permissions in app settings to use all features.',
      btnOkText: 'Open Settings',
      btnCancelText: 'Cancel',
      btnOkOnPress: () async {
        await openAppSettings();
      },
      btnCancelOnPress: () {},
    ).show();
  }
}
