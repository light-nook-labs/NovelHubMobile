# Android SDK Setup Commands

## Option A: Use Android Studio's bundled JDK (Recommended)

Android Studio already includes JDK 21. No need to install Java separately.

Add to `~/.bashrc`:

```bash
export JAVA_HOME=/opt/android-studio/jbr
export PATH=$PATH:$JAVA_HOME/bin
```

Then reload:

```bash
source ~/.bashrc
```

## Option B: Install OpenJDK 17

If you prefer to install Java separately:

```bash
sudo apt-get update
sudo apt-get install -y openjdk-17-jdk
```

Then add to `~/.bashrc`:

```bash
export JAVA_HOME=/usr/lib/jvm/java-17-openjdk-amd64
export PATH=$PATH:$JAVA_HOME/bin
```

Then reload:

```bash
source ~/.bashrc
```

## 3. Configure Android SDK

After Java is installed, run these commands:

```bash
# Set Android SDK path
export ANDROID_HOME=$HOME/Android/Sdk
export PATH=$PATH:$ANDROID_HOME/cmdline-tools/latest/bin
export PATH=$PATH:$ANDROID_HOME/platform-tools

# Accept licenses
yes | $ANDROID_HOME/cmdline-tools/latest/bin/sdkmanager --licenses

# Install required SDK components
$ANDROID_HOME/cmdline-tools/latest/bin/sdkmanager "platforms;android-34" "build-tools;34.0.0" "platform-tools"
```

## 4. Configure Flutter

```bash
flutter config --android-sdk $HOME/Android/Sdk
flutter doctor --android-licenses
flutter doctor
```

## 5. Build APK

```bash
cd /home/interset/Desktop/mobile
flutter build apk --debug
```

## Quick Reference

| Command | Description |
|---------|-------------|
| `flutter doctor` | Check Flutter setup |
| `flutter build apk --debug` | Build debug APK |
| `flutter build apk --release` | Build release APK |
| `flutter install` | Install on connected device |
| `flutter run` | Run on device |
