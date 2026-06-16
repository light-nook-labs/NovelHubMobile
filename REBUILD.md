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
flutter build apk --release
```

## Create New Prerelease

```bash
# Delete old release
gh release delete v0.1.0-beta.2 --yes

# Delete old tag
git tag -d v0.1.0-beta.2
git push origin :refs/tags/v0.1.0-beta.2

# Create new tag
git tag v0.1.0-beta.3
git push origin v0.1.0-beta.3

# Create prerelease
gh release create v0.1.0-beta.3 \
  --prerelease \
  --title "v0.1.0-beta.3 - Bundled Data" \
  --notes "## Novel Hub Mobile v0.1.0-beta.3

### Changes

- Bundled cold chunk (240k novels) with app
- Fixed date parsing error
- No need to download data on first launch

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
