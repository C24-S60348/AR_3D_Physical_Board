# Release Versioning

Before every Android release, update the `version` field in `pubspec.yaml`.

## Version Rule

The version code and the last part of the version name must use the same
number:

```yaml
version: 1.0.<version-code>+<version-code>
```

Examples:

| Version code | Version name | `pubspec.yaml` |
| --- | --- | --- |
| 2 | 1.0.2 | `version: 1.0.2+2` |
| 3 | 1.0.3 | `version: 1.0.3+3` |
| 14 | 1.0.14 | `version: 1.0.14+14` |

Always use a version code greater than the latest version uploaded to Google
Play Console. Never reuse an old version code.

## Release Steps

1. Check the latest version code in Google Play Console.
2. Increase it by one.
3. Update `pubspec.yaml` using the rule above.
4. Build the release bundle:

```bash
flutter build appbundle --release
```

The generated bundle is:

```text
build/app/outputs/bundle/release/app-release.aab
```

Current project version: `1.0.9+9`.
