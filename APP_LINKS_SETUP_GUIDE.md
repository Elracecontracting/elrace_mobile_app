# Android App Links Configuration Guide

## Purpose

This configuration enables Android App Links, which allows:

1. **App installed**: Direct deep link to the app
2. **App NOT installed**: Redirect user to Google Play Store

## Steps to Configure:

### 1. Get SHA256 Certificate Fingerprint

Run this command in terminal:

```bash
keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey -storepass android -keypass android
```

For release keystore:

```bash
keytool -list -v -keystore /path/to/your/release.keystore -alias your_alias
```

Copy the **SHA256 fingerprint** (format: XX:XX:XX:XX:...)

### 2. Update assetlinks.json

1. Open `assetlinks.json` in this project
2. Replace `YOUR_SHA256_FINGERPRINT_HERE` with your SHA256 fingerprint (uppercase, with colons)
3. Replace `com.elrace.app` with your actual package name from AndroidManifest.xml

### 3. Upload to Server

Upload `assetlinks.json` to your server at:

```
https://elrace.com/.well-known/assetlinks.json
```

**Important**:

- Must be accessible via HTTPS (not HTTP)
- Must return `Content-Type: application/json`
- Must be in `.well-known` directory at domain root

### 4. Verify Configuration

Test the link using Google's testing tool:

```
https://digitalassetlinks.googleapis.com/v1/statements:list?source.web.site=https://elrace.com&relation=delegate_permission/common.handle_all_urls
```

### 5. Test Deep Linking

#### With App Installed:

```bash
adb shell am start -W -a android.intent.action.VIEW -d "https://elrace.com/RCC4/Requirements/qrcodeapp"
```

#### Without App Installed:

User will be redirected to Play Store automatically.

## Current Configuration

- **Domain**: elrace.com
- **Path**: /RCC4/Requirements/qrcodeapp
- **Package**: com.elrace.app (check AndroidManifest.xml)
- **Auto Verify**: Enabled in AndroidManifest.xml

## Troubleshooting

If deep linking doesn't work:

1. Check assetlinks.json is accessible at https://elrace.com/.well-known/assetlinks.json
2. Verify SHA256 fingerprint matches your signing certificate
3. Make sure `android:autoVerify="true"` is in AndroidManifest.xml
4. Clear app data and reinstall
5. Check logs: `adb logcat | grep -i "AppLinks"`

## Fallback Behavior

If Android App Links verification fails:

- Android will show app chooser dialog
- User can choose to open with your app or browser
- Browser will show the webpage (you should create a landing page)

## Landing Page (Recommended)

Create a landing page at https://elrace.com/RCC4/Requirements/qrcodeapp that:

1. Detects if user is on mobile
2. Shows "Open in App" button
3. If app not installed, shows "Download App" button linking to Play Store
4. For desktop users, shows QR code to scan or download link
