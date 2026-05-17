# Flutter wrapper
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# Google Play Core (referenced by Flutter but may not be present outside Play Store)
-dontwarn com.google.android.play.core.**

# ARCore / ar_flutter_plugin
-keep class com.google.ar.** { *; }
-keep class io.github.sceneview.** { *; }

# Sceneform classes referenced by ar_flutter_plugin but not bundled in release
-dontwarn com.google.ar.sceneform.animation.AnimationEngine
-dontwarn com.google.ar.sceneform.animation.AnimationLibraryLoader
-dontwarn com.google.ar.sceneform.assets.Loader
-dontwarn com.google.ar.sceneform.assets.ModelData
-dontwarn com.google.devtools.build.android.desugar.runtime.ThrowableExtension
-dontwarn com.google.ar.sceneform.**

# Keep geolocator
-keep class com.baseflow.geolocator.** { *; }

# Keep permission_handler
-keep class com.baseflow.permissionhandler.** { *; }
