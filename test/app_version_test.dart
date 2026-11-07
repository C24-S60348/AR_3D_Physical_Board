import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:my_ar_app/app_version.dart';

void main() {
  test('appVersion matches the version in pubspec.yaml', () {
    final pubspec = File('pubspec.yaml').readAsStringSync();
    final match = RegExp(r'^version:\s*(\S+)', multiLine: true).firstMatch(pubspec);
    expect(match, isNotNull);
    expect(appVersion, match!.group(1));
  });
}
