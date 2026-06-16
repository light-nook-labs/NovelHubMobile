# Build and Release Commands

## Environment Setup

Add these to `~/.bashrc`:

```bash
export JAVA_HOME=/usr/lib/jvm/java-17-openjdk-amd64
export ANDROID_HOME=$HOME/Android/Sdk
export PATH=$PATH:$ANDROID_HOME/cmdline-tools/latest/bin:$ANDROID_HOME/platform-tools:$JAVA_HOME/bin
```

Then reload:

```bash
source ~/.bashrc
```

## Build APK

```bash
cd /home/interset/Desktop/mobile

# Build debug APK
flutter build apk --debug

# Build release APK
flutter build apk --release
```

APK location:
- Debug: `build/app/outputs/flutter-apk/app-debug.apk`
- Release: `build/app/outputs/flutter-apk/app-release.apk`

## Create Prerelease

```bash
# Create tag
git tag v0.1.0-beta.1

# Push tag
git push origin v0.1.0-beta.1

# Create prerelease with APK
gh release create v0.1.0-beta.1 \
  --prerelease \
  --title "v0.1.0-beta.1 - Initial Beta" \
  --notes "Initial beta release for testing" \
  build/app/outputs/flutter-apk/app-release.apk
```

## Quick Reference

| Command | Description |
|---------|-------------|
| `flutter doctor` | Check Flutter setup |
| `flutter build apk --debug` | Build debug APK |
| `flutter build apk --release` | Build release APK |
| `flutter install` | Install on connected device |
| `flutter run` | Run on connected device |
