# Flutter Network Proxy Fix

## Problem

Flutter fails to connect to pub.dev with error:
```
ClientException with SocketException: Connection refused
```

## Solution

Set `NO_PROXY` environment variable:

### Temporary (for current session)

```bash
export NO_PROXY="*"
export no_proxy="*"
```

### Permanent (add to ~/.bashrc)

```bash
echo 'export NO_PROXY="*"' >> ~/.bashrc
echo 'export no_proxy="*"' >> ~/.bashrc
source ~/.bashrc
```

### Usage

```bash
# Or prefix each command
NO_PROXY="*" flutter pub get
NO_PROXY="*" flutter run -d linux
NO_PROXY="*" flutter build apk --release
```

## Build APK

```bash
cd /home/interset/Desktop/mobile
NO_PROXY="*" flutter pub get
NO_PROXY="*" flutter build apk --release
```

## Create Prerelease

```bash
gh release delete v0.1.0-beta.8 --yes 2>/dev/null || true
git tag -d v0.1.0-beta.8 2>/dev/null || true
git push origin :refs/tags/v0.1.0-beta.8 2>/dev/null || true

git tag v0.1.0-beta.8
git push origin v0.1.0-beta.8

gh release create v0.1.0-beta.8 \
  --prerelease \
  --title "v0.1.0-beta.8 - Force Fresh Data" \
  --notes "Force recreate database from chunks on startup" \
  build/app/outputs/flutter-apk/app-release.apk
```
