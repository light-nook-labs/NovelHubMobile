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
gh release delete v0.1.0-beta.3 --yes 2>/dev/null || true

# Delete old tag
git tag -d v0.1.0-beta.3 2>/dev/null || true
git push origin :refs/tags/v0.1.0-beta.3 2>/dev/null || true

# Create new tag
git tag v0.1.0-beta.4
git push origin v0.1.0-beta.4

# Create prerelease
gh release create v0.1.0-beta.4 \
  --prerelease \
  --title "v0.1.0-beta.4 - Database Sync" \
  --notes "## Novel Hub Mobile v0.1.0-beta.4

### Changes

- Removed JSONL-based sync
- Added database file import functionality
- Sync now downloads SQLite chunks from GitHub
- Import allows loading local SQLite files
- Bundled cold chunk (240k novels) with app

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
