# Android 16 KB AR Migration Notes

## Status

The current Android release bundle is stable on the tested V2130 device, but it
does **not** satisfy Google Play's 16 KB memory page-size requirement.

Do not upload the current bundle as a production update while Play Console
reports:

```text
Your app does not support 16 KB memory page sizes.
```

Current app version:

```yaml
version: 1.0.2+2
```

## Current AR Dependencies

The local patched plugin at
`patches/ar_flutter_plugin/android/build.gradle` currently uses:

```gradle
implementation "com.google.ar:core:1.22.0"
implementation "com.google.ar.sceneform:core:1.15.0"
implementation "com.google.ar.sceneform:assets:1.15.0"
implementation "com.google.ar.sceneform.ux:sceneform-ux:1.17.1"
```

These versions are old. Google Sceneform is discontinued, and its native
libraries were built for 4 KB memory pages.

## Native Libraries That Failed

The original release bundle contained these 4 KB-aligned libraries:

```text
libarcore_sdk_c.so
libarcore_sdk_jni.so
libarsceneview_jni.so
libconverter_jni.so
```

ELF load alignment was `0x1000`, which is 4 KB. Google Play requires 64-bit
native libraries to support at least `0x4000`, which is 16 KB.

APK ZIP alignment was already correct. This means `zipalign`, Gradle settings,
or packaging options alone cannot solve the problem. The native dependencies
must be replaced.

## Upgrade Experiment

The following experiment was attempted:

1. Upgraded ARCore from `1.22.0` to `1.54.0`.
2. Replaced discontinued Google Sceneform with:

   ```gradle
   implementation "com.gorisse.thomas.sceneform:sceneform:1.23.0"
   ```

3. Updated plugin API calls:
   - `setupSession(session)` to `session = session`
   - Legacy `RenderableSource` loading to Filament GLTF loading
   - Updated the plane-discovery layout name
4. Sceneform `1.23.0` still pulled Filament `1.21.1`, whose libraries were
   4 KB-aligned.
5. Filament was forced to `1.53.4`, whose libraries were 16 KB-aligned.
6. Compatibility adapters were added for renamed APIs:
   - `UbershaderLoader` to `UbershaderProvider`
   - `KTXLoader` to `KTX1Loader`

The bundle then passed the ELF 16 KB alignment check, but the scanner crashed
on the physical device.

## Crash Cause

The physical-device log showed:

```text
Material version mismatch. Expected 53 but received 21.
Fatal signal 6 (SIGABRT)
```

Sceneform `1.23.0` includes material files compiled for Filament material
version 21. Filament `1.53.4` expects material version 53. These generations
cannot be mixed safely.

Therefore, do not fix this by forcing a newer Filament version under old
Sceneform. A build may compile and pass the 16 KB check while crashing whenever
the AR camera opens.

## Safe Fix

Replace the Android side of `ar_flutter_plugin` with a modern AR implementation
whose Java/Kotlin code, materials, and native Filament libraries were released
together.

Recommended candidate:

```text
io.github.sceneview:arsceneview
```

Use a current SceneView release that explicitly supports the project's Android
SDK and 16 KB page sizes. Do not retain old Sceneform classes or material
assets.

The Flutter-facing API can remain similar:

```text
init session
detect augmented image
take camera snapshot
notify Flutter with image name
pause/dispose camera
```

The Kotlin implementation behind those method channels should be rewritten to
use modern SceneView/ARCore APIs.

## Migration Checklist

1. Create a separate branch for the AR migration.
2. Replace Sceneform dependencies with a single modern SceneView stack.
3. Reimplement `AndroidARView.kt` session creation and lifecycle handling.
4. Reimplement augmented-image database loading.
5. Preserve the `onImageDetected` Flutter method-channel callback.
6. Preserve `snapshot` and `dispose` behavior used by `ScannerScreen`.
7. Reimplement 3D model loading only if the AR demo still requires it.
8. Test opening and closing the scanner repeatedly.
9. Test scanning every registered image.
10. Confirm the camera stops after detection and on the survey page.
11. Build the release bundle.
12. Inspect every `arm64-v8a` and `x86_64` `.so` ELF load alignment.
13. Test the release build on a physical ARCore device.
14. Upload to an internal Play Console track before production.

## Alignment Verification

After building:

```bash
flutter build appbundle --release
```

Inspect the bundle's native libraries:

```bash
unzip -l build/app/outputs/bundle/release/app-release.aab | grep '\.so$'
```

Use the NDK's `llvm-readelf` on each 64-bit `.so`:

```bash
llvm-readelf -lW library.so
```

Every `LOAD` alignment must be at least:

```text
0x4000
```

Values such as `0x10000` are also valid. Any `0x1000` value means the library
is still limited to 4 KB pages.

## Important

The experimental mixed Sceneform/Filament changes were reverted. The source
tree and generated release bundle were restored to the stable, non-crashing AR
implementation after testing.

The current stable bundle still has the Play Console 16 KB warning. Treat this
document as the starting point for the future full SceneView migration.

## Complete Investigation Timeline

This section is an append-only record of the work performed during the first
16 KB investigation. Keep it when updating this document so future work does
not repeat the same dependency experiments.

### 1. Google Play Rejected Version Code 2

The release bundle for app version `1.0.2+2` was built successfully:

```text
build/app/outputs/bundle/release/app-release.aab
```

Google Play Console then reported:

```text
Your app does not support 16 KB memory page sizes.
```

At this point, the app itself still worked on the V2130 physical device.

### 2. The Existing Bundle Was Inspected

The release bundle was listed to find all included `.so` native libraries.
The APK's ZIP alignment was checked with:

```bash
zipalign -c -P 16 -v 4 app-release.apk
```

That check passed. Therefore, APK packaging was not the cause.

The NDK's `llvm-readelf` was then used to inspect ELF `LOAD` alignment. The
following old libraries reported `0x1000`, or 4 KB:

```text
libarcore_sdk_c.so
libarcore_sdk_jni.so
libarsceneview_jni.so
libconverter_jni.so
```

The Flutter engine and Dart application libraries were already compatible.
The problem came from the old ARCore and Sceneform dependencies.

### 3. Existing Dependency Versions Were Identified

The patched Android AR plugin used:

```gradle
com.google.ar:core:1.22.0
com.google.ar.sceneform:core:1.15.0
com.google.ar.sceneform:assets:1.15.0
com.google.ar.sceneform.ux:sceneform-ux:1.17.1
```

Google's official Maven metadata showed that ARCore `1.54.0` was current at
the time of the investigation.

The original Google Sceneform packages were discontinued. The maintained
Sceneform fork's latest release was `1.23.0`.

### 4. First Upgrade Attempt

The plugin dependencies were temporarily changed to:

```gradle
implementation "com.google.ar:core:1.54.0"
implementation "com.gorisse.thomas.sceneform:sceneform:1.23.0"
```

The old separate Google Sceneform `core`, `assets`, and `sceneform-ux`
dependencies were removed.

#### Result

The project did not compile. The maintained Sceneform APIs differed from the
old Google Sceneform APIs.

Reported compile errors included:

```text
Unresolved reference 'setupSession'
Unresolved reference 'sceneform_plane_discovery_layout'
Unresolved reference 'RenderableSource'
```

### 5. Sceneform API Adaptations

The local patched plugin was temporarily adapted:

```text
arSceneView.setupSession(session)
```

was changed to:

```text
arSceneView.session = session
```

The plane-discovery layout was changed from:

```text
sceneform_plane_discovery_layout
```

to:

```text
sceneform_instructions_plane_discovery
```

Legacy `RenderableSource` GLTF/GLB model loading was changed to direct URI
loading with Filament GLTF enabled.

#### Result

The release bundle compiled successfully.

However, ELF inspection showed that maintained Sceneform `1.23.0` still
depended on Filament `1.21.1`. Its native libraries remained 4 KB-aligned:

```text
libfilament-jni.so
libfilament-utils-jni.so
libgltfio-jni.so
```

The ARCore libraries were now 16 KB-compatible, but the bundle still did not
fully satisfy the requirement.

### 6. Modern Filament Was Tested

Several official Filament releases were downloaded and inspected.

Observed alignment:

```text
Filament 1.49.3 -> 0x1000
Filament 1.51.6 -> 0x1000
Filament 1.52.0 -> 0x1000
Filament 1.53.4 -> 0x4000
Filament 1.54.5 -> 0x4000
Filament 1.56.0 -> 0x4000
Filament 1.57.1 -> 0x4000
Filament 1.64.1 -> 0x4000
```

Filament `1.53.4` was selected as the earliest tested version with 16 KB ELF
alignment, to minimize the size of the version jump.

### 7. Filament 1.71.6 Was Tried First

The three Filament components were temporarily forced to version `1.71.6`:

```gradle
filament-android
gltfio-android
filament-utils-android
```

#### Result

The release build failed during R8 because Sceneform `1.23.0` referenced APIs
that had been removed or renamed:

```text
Missing class com.google.android.filament.gltfio.UbershaderLoader
Missing class com.google.android.filament.utils.KTXLoader
Missing class com.google.android.filament.utils.KTXLoader$Options
```

This showed that a direct Filament override was not API-compatible.

### 8. Filament 1.53.4 With Compatibility Adapters

Filament was changed to `1.53.4`.

Temporary Java compatibility adapters were written:

```text
UbershaderLoader -> delegates to UbershaderProvider
KTXLoader -> delegates to KTX1Loader
```

Kotlin-generated `$default` method bridges were also added after a physical
device test found that Sceneform called those exact generated signatures.

#### First Runtime Result

Before adding the `$default` bridges, the app crashed with:

```text
NoSuchMethodError:
KTXLoader.createIndirectLight$default(...)
```

The missing bridge methods were then implemented.

#### Build and Alignment Result

After adding the adapters and bridge methods:

- The release bundle compiled successfully.
- Every inspected 64-bit native library reported at least `0x4000`.
- The bundle technically passed the manual 16 KB ELF alignment check.

The relevant libraries included:

```text
libarcore_sdk_c.so -> 0x4000
libarcore_sdk_jni.so -> 0x4000
libdartjni.so -> 0x4000
libfilament-jni.so -> 0x4000
libfilament-utils-jni.so -> 0x4000
libgltfio-jni.so -> 0x4000
libflutter.so -> 0x10000
libapp.so -> 0x10000
```

### 9. Physical Scanner Test Failed

The upgraded app was installed on the V2130 through wireless ADB.

The app launched, and ARCore initialized. The augmented-image database loaded
11 accepted images. Two low-quality icon images were rejected by ARCore:

```text
instagramicon.png
whatsappicon.png
```

Those image-quality warnings were not the fatal problem.

When the AR scanner platform view initialized, Filament aborted the process:

```text
Material version mismatch. Expected 53 but received 21.
Fatal signal 6 (SIGABRT)
```

The native Filament `1.53.4` renderer expected material version 53, but
Sceneform `1.23.0` contained material resources compiled for Filament version
21.

The Android process crashed inside `libfilament-jni.so`.

### 10. Why That Attempt Cannot Be Kept

The Java/Kotlin API adapters solved missing class and method problems, but they
could not convert Sceneform's precompiled binary material resources.

The following combination is therefore invalid:

```text
Sceneform 1.23.0 materials + Filament 1.53.4 native renderer
```

It can:

- Compile successfully.
- Build a valid app bundle.
- Pass manual 16 KB ELF checks.
- Launch the Flutter application.
- Still crash as soon as the AR renderer consumes the old materials.

This is not fixable with ProGuard rules, Gradle resolution rules, Java adapter
classes, `zipalign`, or NDK flags.

### 11. Experimental Changes Were Reverted

All temporary dependency and compatibility changes were removed.

The project was restored to:

```gradle
ARCore 1.22.0
Google Sceneform 1.15.0 / 1.17.1
```

The stable debug APK was rebuilt and installed on the V2130. This replaced the
crashing experimental app.

The stable release app bundle was also rebuilt, replacing the experimental
bundle so it would not be uploaded accidentally.

The stable implementation works, but remains non-compliant with the 16 KB
Google Play requirement.

### 12. Current Unresolved Dependency Boundary

No safe dependency-only combination was found.

The investigation established:

```text
Old Sceneform + old Filament
  -> scanner works
  -> fails 16 KB requirement

Old/maintained Sceneform + modern Filament
  -> can be made to compile
  -> passes 16 KB alignment
  -> crashes because material versions do not match
```

The remaining path is not another version override. The Android AR platform
implementation must migrate as a complete stack to modern SceneView:

```text
io.github.sceneview:arsceneview
```

SceneView's renderer, material resources, Java/Kotlin APIs, and native Filament
libraries must be used together from the same compatible release.

At the end of this investigation, that full migration had not yet been
implemented. There is no safe dependency-only answer recorded here.
