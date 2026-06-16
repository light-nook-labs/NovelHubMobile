# Rebuild APK Commands

## Environment Setup

```bash
export JAVA_HOME=/usr/lib/jvm/java-17-openjdk-amd64
export ANDROID_HOME=$HOME/Android/Sdk
export PATH=$PATH:$ANDROID_HOME/cmdline-tools/latest/bin:$ANDROID_HOME/platform-tools:$JAVA_HOME/bin
```

## Build Release APK

```bash
cd /home/interset/Desktop/mobile

# Get dependencies
flutter pub get

# Build release APK
flutter build apk --release
```

## Create New Prerelease

```bash
# Delete old release
gh release delete v0.1.0-beta.5 --yes 2>/dev/null || true

# Delete old tag
git tag -d v0.1.0-beta.5 2>/dev/null || true
git push origin :refs/tags/v0.1.0-beta.5 2>/dev/null || true

# Create new tag
git tag v0.1.0-beta.6
git push origin v0.1.0-beta.6

# Create prerelease
gh release create v0.1.0-beta.6 \
  --prerelease \
  --title "v0.1.0-beta.6 - Load Bundled Chunks" \
  --notes "## Novel Hub Mobile v0.1.0-beta.6

### Changes

- All three chunks (cold, warm, hot) are now loaded on app startup
- No need to download data on first launch
- App works immediately after installation

### Features

- Offline-first novel metadata browser
- 246k+ novels from sfacg.com
- 6 ranking dimensions
- Full text search
- Dark mode support
- Multi-filter support

### Testing

Download and install the APK on your Android device." \
  build/app/outputs/flutter-apk/app-release.apk
```
