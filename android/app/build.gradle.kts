plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// Release keystore lives on the developer's machine. In CI (GitHub Actions) the file
// won't exist, so we fall back to the auto-generated debug keystore instead.
val releaseKeystoreFile = file("/Users/afwanhaziq/documents/keystore.jks")
val hasReleaseKeystore  = releaseKeystoreFile.exists()

android {
    namespace = "com.af1productions.igb"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = "28.2.13676358"  // NDK r28 — required for 16KB page size support (Android 15+)

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    signingConfigs {
        if (hasReleaseKeystore) {
            create("release") {
                storeFile    = releaseKeystoreFile
                storePassword = "123456"
                keyAlias     = "af1"
                keyPassword  = "123456"
            }
        }
    }

    defaultConfig {
        applicationId = "com.af1productions.igb"
        minSdk = 24  // ARCore requires API 24+
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            // Use release signing locally; fall back to debug signing in CI
            signingConfig = if (hasReleaseKeystore) {
                signingConfigs.getByName("release")
            } else {
                signingConfigs.getByName("debug")
            }
            proguardFiles(getDefaultProguardFile("proguard-android-optimize.txt"), "proguard-rules.pro")
        }
    }
}

flutter {
    source = "../.."
}

// Force Filament 1.72.0 — 16KB memory page size compliant (Android 15+)
configurations.all {
    resolutionStrategy {
        force("com.google.android.filament:filament-android:1.72.0")
        force("com.google.android.filament:filament-utils-android:1.72.0")
        force("com.google.android.filament:gltfio-android:1.72.0")
    }
}
