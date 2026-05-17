import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';

Future<bool> isRunningOnEmulator() async {
  if (Platform.isAndroid) {
    final info = await DeviceInfoPlugin().androidInfo;
    if (!info.isPhysicalDevice) return true;
    final fp = info.fingerprint.toLowerCase();
    final model = info.model.toLowerCase();
    final hw = info.hardware.toLowerCase();
    final product = info.product.toLowerCase();
    return fp.contains('generic') ||
        fp.contains('emulator') ||
        fp.contains('sdk_gphone') ||
        fp.contains('unknown') ||
        model.contains('emulator') ||
        model.contains('sdk gphone') ||
        model.contains('android sdk') ||
        hw == 'goldfish' ||
        hw == 'ranchu' ||
        product.contains('sdk_gphone') ||
        product.contains('emulator');
  }
  if (Platform.isIOS) {
    final info = await DeviceInfoPlugin().iosInfo;
    return !info.isPhysicalDevice;
  }
  return false;
}
