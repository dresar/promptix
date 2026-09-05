import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:permission_handler/permission_handler.dart';

class PermissionService {
  Future<bool> requestStoragePermission() async {
    if (kIsWeb) return true;
    final androidVersion = await _getAndroidVersion();

    if (androidVersion >= 34) {
      final status = await Permission.photos.request();
      if (status.isGranted) return true;
      if (status.isDenied) {
        final limited = await Permission.photos.request();
        return limited.isGranted || limited.isLimited;
      }
      return false;
    } else if (androidVersion >= 33) {
      final status = await Permission.photos.request();
      return status.isGranted;
    } else {
      final status = await Permission.storage.request();
      return status.isGranted;
    }
  }

  Future<bool> checkStoragePermission() async {
    if (kIsWeb) return true;
    final androidVersion = await _getAndroidVersion();

    if (androidVersion >= 33) {
      final status = await Permission.photos.status;
      return status.isGranted || status.isLimited;
    } else {
      final status = await Permission.storage.status;
      return status.isGranted;
    }
  }

  Future<bool> openSystemSettings() async {
    if (kIsWeb) return false;
    return await openAppSettings();
  }

  Future<int> _getAndroidVersion() async {
    if (kIsWeb) return 0;
    if (!Platform.isAndroid) return 0;
    try {
      final version = Platform.operatingSystemVersion;
      final match = RegExp(r'(\d+)').firstMatch(version);
      if (match != null) {
        return int.tryParse(match.group(1) ?? '0') ?? 0;
      }
    } catch (_) {}
    return 0;
  }
}
