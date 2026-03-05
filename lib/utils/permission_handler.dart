import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/material.dart';
import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:device_info_plus/device_info_plus.dart';

class AppPermissionHandler {
  /// Check if all required permissions are granted
  static Future<bool> checkAllPermissions() async {
    final bluetoothStatus = await _checkBluetoothPermissions();
    final locationStatus = await Permission.locationWhenInUse.status;

    return bluetoothStatus && locationStatus.isGranted;
  }

  /// Request all required permissions
  static Future<bool> requestAllPermissions(BuildContext context) async {
    // Request Bluetooth permissions
    final bluetoothGranted = await _requestBluetoothPermissions(context);
    if (!bluetoothGranted) {
      if (!context.mounted) return false; // ✅ FIX 1: Check mounted
      return false;
    }

    // Request Location permission
    final locationGranted = await _requestLocationPermission(context);
    if (!locationGranted) {
      if (!context.mounted) return false; // ✅ FIX 1: Check mounted
      return false;
    }

    return true;
  }

  /// Check Bluetooth permissions (Android 12+)
  static Future<bool> _checkBluetoothPermissions() async {
    if (await _isAndroid12OrHigher()) {
      final bluetoothScan = await Permission.bluetoothScan.status;
      final bluetoothConnect = await Permission.bluetoothConnect.status;
      return bluetoothScan.isGranted && bluetoothConnect.isGranted;
    } else {
      final bluetooth = await Permission.bluetooth.status;
      return bluetooth.isGranted;
    }
  }

  /// Request Bluetooth permissions
  static Future<bool> _requestBluetoothPermissions(BuildContext context) async {
    if (await _isAndroid12OrHigher()) {
      // Android 12+ requires BLUETOOTH_SCAN and BLUETOOTH_CONNECT
      Map<Permission, PermissionStatus> statuses = await [
        Permission.bluetoothScan,
        Permission.bluetoothConnect,
      ].request();

      final allGranted = statuses.values.every((status) => status.isGranted);

      if (!allGranted) {
        if (!context.mounted) return false;
        await _showPermissionDialog(
          context,
          title: 'Bluetooth Permission Required',
          description:
              'This app needs Bluetooth access to connect to your motorcycle\'s exhaust controller.',
          onRetry: () => _requestBluetoothPermissions(context),
        );
        return false;
      }

      return allGranted;
    } else {
      // Android 11 and below
      final status = await Permission.bluetooth.request();

      if (!status.isGranted) {
        if (!context.mounted) return false; // ✅ FIX 1: Check mounted
        _showPermissionDialog(
          context,
          title: 'Bluetooth Permission Required',
          description:
              'This app needs Bluetooth access to connect to your motorcycle\'s exhaust controller.',
          onRetry: () => _requestBluetoothPermissions(context),
        );
        return false;
      }

      return status.isGranted;
    }
  }

  /// Request Location permission
  static Future<bool> _requestLocationPermission(BuildContext context) async {
    final status = await Permission.locationWhenInUse.request();

    if (!status.isGranted) {
      if (!context.mounted) return false; // ✅ FIX 1: Check mounted
      _showPermissionDialog(
        context,
        title: 'Location Permission Required',
        description:
            'This app needs location access to automatically close the exhaust in restricted areas.',
        onRetry: () => _requestLocationPermission(context),
      );
      return false;
    }

    return status.isGranted;
  }

  /// Check if device is Android 12 or higher
  static Future<bool> _isAndroid12OrHigher() async {
    final deviceInfo = DeviceInfoPlugin();
    final androidInfo = await deviceInfo.androidInfo;
    print('>>> Android SDK: ${androidInfo.version.sdkInt}');
    return androidInfo.version.sdkInt >= 31;
  }

  /// Show beautiful permission dialog
  static Future<void> _showPermissionDialog(
    BuildContext context, {
    required String title,
    required String description,
    required Future<bool> Function() onRetry,
  }) async {
    AwesomeDialog(
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
      btnCancelOnPress: () {
        // User skipped - app will have limited functionality
      },
    ).show();
  }

  /// Open app settings if permission is permanently denied
  static Future<void> openSettings(BuildContext context) async {
    if (!context.mounted) return; // ✅ FIX 1: Check mounted

    AwesomeDialog(
      context: context,
      dialogType: DialogType.info,
      animType: AnimType.scale,
      title: 'Permission Required',
      desc: 'Please enable permissions in app settings to use all features.',
      btnOkText: 'Open Settings',
      btnCancelText: 'Cancel',
      btnOkOnPress: () async {
        await openAppSettings(); // ✅ FIX 2: No parameter needed
      },
      btnCancelOnPress: () {},
    ).show();
  }
}
