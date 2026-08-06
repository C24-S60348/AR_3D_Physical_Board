import 'dart:io';

import 'package:flutter/services.dart';

/// What this device can do with the AR scanner.
///
/// i-GB is an "AR Optional" app on Android (see `AndroidManifest.xml`), so it
/// installs on phones ARCore does not support. Those phones still get the notes,
/// the board, and the quiz — only scanning is unavailable.
///
/// [needsArCoreInstall] is its own case on purpose. Marking the app AR Optional
/// means Google Play no longer installs "Google Play Services for AR" alongside
/// it, so a phone that genuinely supports ARCore can still be missing the
/// service. That is fixable by the player, and saying so beats opening a camera
/// that will never detect a card.
enum ArSupport {
  ready,
  needsArCoreInstall,
  unsupported;

  bool get canScan => this == ArSupport.ready;
}

const _channel = MethodChannel('com.af1productions.igb/arcore');

/// The Play Store entry for Google Play Services for AR.
const arCoreStoreUrl =
    'https://play.google.com/store/apps/details?id=com.google.ar.core';

Future<ArSupport> checkArSupport() async {
  // iOS ships as ARKit-only and every iPhone i-GB supports can run it.
  if (!Platform.isAndroid) return ArSupport.ready;
  try {
    final availability = await _channel.invokeMethod<String>(
      'arCoreAvailability',
    );
    switch (availability) {
      case 'SUPPORTED_INSTALLED':
        return ArSupport.ready;
      case 'SUPPORTED_NOT_INSTALLED':
      case 'SUPPORTED_APK_TOO_OLD':
        return ArSupport.needsArCoreInstall;
      default:
        // UNSUPPORTED_DEVICE_NOT_CAPABLE, UNKNOWN_ERROR, UNKNOWN_TIMED_OUT and
        // anything a future ARCore adds.
        return ArSupport.unsupported;
    }
  } on PlatformException {
    return ArSupport.unsupported;
  } on MissingPluginException {
    return ArSupport.unsupported;
  }
}
