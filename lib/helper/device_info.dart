import 'package:device_info_plus/device_info_plus.dart';
import 'dart:io';

/// finding deviceId to control user just logins with one device  no more
Future<String> getDeviceId() async {
  final deviceInfo = DeviceInfoPlugin();

  if (Platform.isAndroid) {
    final androidInfo = await deviceInfo.androidInfo;
    return androidInfo.id ?? 'unknown';
  } else if (Platform.isIOS) {
    final iosInfo = await deviceInfo.iosInfo;
    return iosInfo.identifierForVendor ?? 'unknown';
  } else {
    return 'unknown';
  }
}

/// replace some characters on the Firebase path
String encodeDeviceId(String id) {
  return id.replaceAll(RegExp(r'[.#$/\[\]]'), '_');
}
