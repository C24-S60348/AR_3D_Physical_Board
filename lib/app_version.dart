/// The app's version as set in pubspec.yaml, shown on the About screen.
///
/// Update this together with `version` in pubspec.yaml on every release;
/// test/app_version_test.dart fails when the two differ.
const appVersion = '1.0.10+16';

/// The version as players see it, e.g. "1.0.10 (16)".
String get appVersionLabel {
  final parts = appVersion.split('+');
  return parts.length == 2 ? '${parts[0]} (${parts[1]})' : appVersion;
}
