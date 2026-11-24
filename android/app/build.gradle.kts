plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// Release keystore: CI supplies it via KEYSTORE_PATH / KEYSTORE_PASSWORD / KEY_ALIAS /
// KEY_PASSWORD env vars; locally it falls back to the developer's keystore. If no keystore
// is found, the build falls back to the debug keystore.
val releaseKeystoreFile = file(System.getenv("KEYSTORE_PATH") ?: "/Users/afwanhaziq/documents/keystore.jks")
val hasReleaseKeystore  = releaseKeystoreFile.exists()
val releaseStorePassword = System.getenv("KEYSTORE_PASSWORD") ?: "123456"
val releaseKeyAlias      = System.getenv("KEY_ALIAS") ?: "af1"
val releaseKeyPassword   = System.getenv("KEY_PASSWORD") ?: "123456"

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
                storePassword = releaseStorePassword
                keyAlias     = releaseKeyAlias
                keyPassword  = releaseKeyPassword
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

dependencies {
    // MainActivity calls ArCoreApk directly to answer the Dart-side support
    // check. ar_flutter_plugin already pulls this in transitively; naming the
    // same version keeps it on the app module's own compile classpath.
    implementation("com.google.ar:core:1.52.0")
}

flutter {
    source = "../.."
}
