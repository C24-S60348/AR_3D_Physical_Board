# AR App Setup & Build Guide

## 🎯 Quick Start

```bash
cd my_ar_app
flutter pub get
flutter run
```

---

## 📱 iOS Setup

### **Prerequisites**
- Mac with Xcode 14+
- CocoaPods
- iOS device with ARKit support (iPhone 6S+)

### **Enable ARKit in iOS**

1. **Open iOS project**
   ```bash
   cd ios
   pod deintegrate
   pod install
   cd ..
   ```

2. **Edit `ios/Podfile`** - Uncomment minimum deployment target:
   ```ruby
   post_install do |installer|
     installer.pods_project.targets.each do |target|
       flutter_additional_ios_build_settings(target)
       target.build_configurations.each do |config|
         config.build_settings['GCC_PREPROCESSOR_DEFINITIONS'] ||= [
           '$(inherited)',
           'FLUTTER_ROOT=\$(FLUTTER_ROOT)',
           'FLUTTER_APPLICATION_PATH=\$(FLUTTER_APPLICATION_PATH)',
         ]
       end
     end
   end
   ```

3. **Build & Run on iOS**
   ```bash
   flutter run -v
   ```

### **Common iOS Issues**

- **Pod install fails**: Run `pod repo update` then try again
- **ARKit not available**: Ensure iOS 11.0+ and compatible device
- **Camera permission denied**: Grant in Settings → Privacy → Camera

---

## 🤖 Android Setup

### **Prerequisites**
- Android Studio
- Android SDK 24+ (API 24)
- ARCore-compatible Android device

### **Enable ARCore**

1. **Edit `android/build.gradle`**
   ```gradle
   minSdkVersion = 24  // Changed from default
   ```

2. **Edit `android/app/build.gradle`**
   ```gradle
   dependencies {
       implementation 'com.google.ar:core:1.42.0'
   }
   ```

3. **Add Permissions** in `android/app/src/main/AndroidManifest.xml`
   ```xml
   <uses-permission android:name="android.permission.CAMERA" />
   <uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
   
   <uses-feature android:name="android.hardware.camera.ar" android:required="true" />
   ```

4. **Build & Run on Android**
   ```bash
   flutter run -v
   ```

### **Common Android Issues**

- **ARCore not installed**: Install from Play Store
- **Camera permission denied**: Grant in App Settings → Permissions
- **Build fails**: Run `flutter clean` then `flutter pub get`

---

## 🏗️ Build Release Versions

### **iOS Release Build**
```bash
flutter build ios --release
```

Then in Xcode:
1. Select generic iOS device
2. Product → Archive
3. Upload to App Store

### **Android Release Build**
```bash
flutter build apk --release
```

Or AAB for Play Store:
```bash
flutter build appbundle --release
```

---

## 🔍 Testing on Physical Device

### **Via USB**

**Android:**
```bash
adb devices  # List connected devices
flutter run -d <device-id>
```

**iOS:**
```bash
flutter devices  # List connected devices
flutter run -d <device-id>
```

### **Wireless Debugging**

**Android:**
```bash
adb connect 192.168.1.100:5555
flutter run -d <device-ip>
```

---

## 📊 Flutter Diagnostic

Check your Flutter setup:
```bash
flutter doctor -v
```

Should show:
- ✅ Flutter SDK
- ✅ Android toolchain
- ✅ Xcode (if on Mac)
- ✅ VS Code / Android Studio

---

## 🔧 Environment Variables

Set up for optimal development:

```bash
# Add to ~/.zshrc or ~/.bash_profile
export ANDROID_HOME=$HOME/Library/Android/sdk
export ANDROID_SDK_ROOT=$ANDROID_HOME
export PATH="$PATH:$ANDROID_HOME/emulator"
export PATH="$PATH:$ANDROID_HOME/tools"
export PATH="$PATH:$ANDROID_HOME/tools/bin"
export PATH="$PATH:$ANDROID_HOME/platform-tools"
```

Then reload:
```bash
source ~/.zshrc
```

---

## 🚀 Development Workflow

### **Hot Reload Development**
```bash
flutter run
```

Then press `r` for hot reload, `R` for hot restart

### **Debug Mode**
```bash
flutter run -v  # Verbose logging
```

### **Release Mode**
```bash
flutter run --release  # Better performance
```

### **Profile Mode** (Performance profiling)
```bash
flutter run --profile
```

---

## 📦 Packaging & Distribution

### **Create Signed APK (Android)**
```bash
keytool -genkey -v -keystore ~/key.jks -keyalg RSA -keysize 2048 -validity 10000 -alias key

flutter build apk --release --key-store ~/key.jks --key-store-password PASSWORD \
  --key-alias key --key-password PASSWORD
```

### **Create Signed IPA (iOS)**
1. In Xcode: Signing & Capabilities
2. Select your development team
3. Product → Archive
4. Validate and upload

---

## 🎯 Performance Optimization

### **Reduce App Size**
```bash
flutter build apk --target-platform android-arm64 --split-per-abi
```

### **Monitor Performance**
```bash
flutter run --profile
# In terminal: press 't' for timeline, 'p' for memory
```

### **Reduce Frame Drops**
- Limit object count in AR scene
- Optimize 3D models (reduce polygon count)
- Use simpler materials/textures

---

## ✅ Checklist Before Release

- [ ] Tested on real iOS device
- [ ] Tested on real Android device
- [ ] Permissions working correctly
- [ ] Plane detection reliable
- [ ] Objects place smoothly
- [ ] No crashes found
- [ ] Performance acceptable
- [ ] UI responsive
- [ ] Screenshots captured
- [ ] Version bumped in pubspec.yaml

---

## 📞 Troubleshooting

### **App Crashes on Startup**
```bash
flutter clean
flutter pub get
flutter run -v
```

### **Gradle Build Issues (Android)**
```bash
cd android
./gradlew clean
cd ..
flutter pub get
flutter run
```

### **CocoaPods Issues (iOS)**
```bash
cd ios
rm -rf Pods Pod.lock
pod install
cd ..
flutter run
```

### **Permission Issues**
- Android: Check AndroidManifest.xml permissions
- iOS: Check Info.plist privacy descriptions
- Request runtime permissions in app

---

## 🎓 Next Level: Advanced Features

1. **Multi-object physics**: Add Bullet physics engine
2. **3D model animations**: Load animated GLB models
3. **Multiplayer AR**: Use WebSockets + Firebase Realtime DB
4. **Face filters**: Implement face mesh tracking
5. **Recording**: Capture AR experiences as videos
6. **Cloud sync**: Store AR scenes in Firebase

---

**Ready to build your AR app! 🚀**
