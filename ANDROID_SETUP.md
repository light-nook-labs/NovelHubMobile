# Android Development Setup

## Required Software

### 1. Android Studio

Download and install Android Studio:
```bash
# Download Android Studio
wget https://redirector.gvt1.com/edgedl/android/studio/ide-zips/2024.3.1.13/android-studio-2024.3.1.13-linux.tar.gz

# Extract
tar -xzf android-studio-2024.3.1.13-linux.tar.gz

# Move to /opt
sudo mv android-studio /opt/

# Run Android Studio
/opt/android-studio/bin/studio.sh
```

### 2. Android SDK

After installing Android Studio, install the SDK:

1. Open Android Studio
2. Go to **Tools > SDK Manager**
3. Install the following:
   - **Android SDK Platform** (API 34 or latest)
   - **Android SDK Build-Tools** (34.0.0 or latest)
   - **Android SDK Platform-Tools**
   - **Android SDK Command-line Tools**

### 3. Configure Flutter

After installing Android SDK:

```bash
# Set Android SDK path
flutter config --android-sdk ~/Android/Sdk

# Accept Android licenses
flutter doctor --android-licenses

# Verify setup
flutter doctor
```

### 4. Environment Variables

Add to `~/.bashrc` or `~/.zshrc`:

```bash
export ANDROID_HOME=$HOME/Android/Sdk
export PATH=$PATH:$ANDROID_HOME/platform-tools
export PATH=$PATH:$ANDROID_HOME/cmdline-tools/latest/bin
```

Then reload:
```bash
source ~/.bashrc
```

## Build APK

After setup, build the APK:

```bash
cd /home/interset/Desktop/mobile

# Build debug APK
flutter build apk --debug

# Build release APK
flutter build apk --release
```

The APK will be at:
- Debug: `build/app/outputs/flutter-apk/app-debug.apk`
- Release: `build/app/outputs/flutter-apk/app-release.apk`

## Create Prerelease

After building the APK:

```bash
# Create a tag
git tag v0.1.0-beta.1

# Push the tag
git push origin v0.1.0-beta.1

# Create release using GitHub CLI
gh release create v0.1.0-beta.1 \
  --prerelease \
  --title "v0.1.0-beta.1 - Initial Beta" \
  --notes "Initial beta release for testing" \
  build/app/outputs/flutter-apk/app-release.apk
```

## Quick Commands Reference

```bash
# Check Flutter setup
flutter doctor

# Build debug APK
flutter build apk --debug

# Build release APK
flutter build apk --release

# Install on connected device
flutter install

# Run on device
flutter run
```
