# QR Code Deep Linking System - Backend Setup Guide

## 📋 Overview

This system enables users to scan QR codes that open the El Race mobile app directly to specific survey/document/media screens. It supports both **Android App Links** and **iOS Universal Links**.

---

## 🎯 How It Works

```
User scans QR code
    ↓
Opens: https://elrace.com/RCC4/Requirements/qrcodeapp
    ↓
System detects:
    ├─ App installed → Opens app directly (Android/iOS)
    └─ App NOT installed → Redirects to App Store/Play Store
    ↓
App calls API: GET /api/survey/any_published
    ↓
Displays content based on user login status:
    ├─ Logged in → Shows with AppBar & BottomBar
    └─ Guest → Shows clean interface (no navigation bars)
```

---

## 📁 Required Files to Upload

Please upload these **3 files** to the server:

### 1. qrcodeapp.php

**Location:** `/RCC4/Requirements/qrcodeapp.php`  
**URL:** `https://elrace.com/RCC4/Requirements/qrcodeapp.php`

**Description:** Landing page that:

- Detects user's platform (Android/iOS/Desktop)
- Opens app via deep link if installed
- Redirects to store if app not installed
- Shows download links for desktop users

**Status:** ✅ Ready to upload (included in project)

---

### 2. assetlinks.json (Android App Links)

**Location:** `/.well-known/assetlinks.json`  
**URL:** `https://elrace.com/.well-known/assetlinks.json`

**File Content:**

```json
[
  {
    "relation": ["delegate_permission/common.handle_all_urls"],
    "target": {
      "namespace": "android_app",
      "package_name": "com.el_race.app",
      "sha256_cert_fingerprints": [
        "F9:B6:93:71:9D:C5:1E:EA:69:FE:24:DE:FA:F4:2E:30:E8:BE:CC:BC:20:DF:8C:ED:7C:51:87:5F:34:9E:38:4B"
      ]
    }
  }
]
```

**Important Requirements:**

- ✅ Must be accessible via HTTPS
- ✅ Must return `Content-Type: application/json`
- ✅ Must be publicly accessible (no authentication)
- ✅ SHA256 fingerprint is already configured for **debug builds**
- ⚠️ **For production:** Update SHA256 with release keystore fingerprint

**Status:** ✅ Ready to upload (included in project)

---

### 3. apple-app-site-association (iOS Universal Links)

**Location:** `/.well-known/apple-app-site-association`  
**URL:** `https://elrace.com/.well-known/apple-app-site-association`

**File Content:**

```json
{
  "applinks": {
    "apps": [],
    "details": [
      {
        "appID": "Z9KA83YY82.com.elrace.app",
        "paths": [
          "/RCC4/Requirements/qrcodeapp",
          "/RCC4/Requirements/qrcodeapp.php"
        ]
      }
    ]
  },
  "webcredentials": {
    "apps": ["Z9KA83YY82.com.elrace.app"]
  }
}
```

**Important Requirements:**

- ✅ Must be accessible via HTTPS
- ✅ Must return `Content-Type: application/json`
- ⚠️ **NO file extension** (not .json!)
- ✅ Must be publicly accessible
- ✅ Team ID (Z9KA83YY82) is already configured

**Status:** ✅ Ready to upload (included in project)

---

## 🔧 Server Configuration

### Apache (.htaccess)

If using Apache, add this to `.htaccess` in `/.well-known/` directory:

```apache
# Serve assetlinks.json with correct Content-Type
<Files "assetlinks.json">
    Header set Content-Type "application/json"
    Header set Access-Control-Allow-Origin "*"
</Files>

# Serve apple-app-site-association with correct Content-Type
<Files "apple-app-site-association">
    Header set Content-Type "application/json"
    Header set Access-Control-Allow-Origin "*"
</Files>
```

### Nginx

If using Nginx, add this to your server config:

```nginx
location /.well-known/assetlinks.json {
    add_header Content-Type application/json;
    add_header Access-Control-Allow-Origin *;
}

location /.well-known/apple-app-site-association {
    add_header Content-Type application/json;
    add_header Access-Control-Allow-Origin *;
}
```

---

## 🧪 Verification Steps

After uploading files, verify they are accessible:

### 1. Check assetlinks.json

```bash
curl -I https://elrace.com/.well-known/assetlinks.json
```

**Expected:**

- Status: `200 OK`
- Content-Type: `application/json`
- HTTPS enabled

### 2. Check apple-app-site-association

```bash
curl -I https://elrace.com/.well-known/apple-app-site-association
```

**Expected:**

- Status: `200 OK`
- Content-Type: `application/json`
- NO .json extension in URL
- HTTPS enabled

### 3. Check qrcodeapp.php

```bash
curl -I https://elrace.com/RCC4/Requirements/qrcodeapp.php
```

**Expected:**

- Status: `200 OK`
- Content-Type: `text/html`

### 4. Validate with Apple

Use Apple's validation tool:

```
https://search.developer.apple.com/appsearch-validation-tool/
```

Enter: `https://elrace.com/RCC4/Requirements/qrcodeapp`

---

## 📱 Mobile App API Integration

The mobile app will call this API endpoint after scanning QR code:

### Endpoint

```
GET https://test.elrace.com/api/survey/any_published
```

### Headers

```
Content-Type: application/json
Accept: application/json
Authorization: Bearer {token}  (optional - only for logged-in users)
```

### Expected Response Format

The API should return **ONE** of the following:

#### Option 1: Survey

```json
{
  "result": {
    "data": {
      "survey": {
        "id": 123,
        "title": "Customer Satisfaction Survey",
        "questions": [
          {
            "id": 1,
            "text": "How satisfied are you?",
            "type": "choice",
            "options": ["Very Satisfied", "Satisfied", "Neutral"]
          }
        ]
      }
    }
  }
}
```

#### Option 2: Documents

```json
{
  "result": {
    "data": {
      "documents": [
        {
          "id": 1,
          "title": "User Manual",
          "url": "https://...",
          "description": "...",
          "file_type": "pdf"
        }
      ]
    }
  }
}
```

#### Option 3: Media

```json
{
  "result": {
    "data": {
      "media": [
        {
          "id": 1,
          "title": "Training Video",
          "url": "https://...",
          "thumbnail": "https://...",
          "type": "video"
        }
      ]
    }
  }
}
```

### Current Issue

⚠️ The API currently returns:

```
400 Bad Request
Function declared as capable of handling request of type 'json'
but called with a request of type 'http'
```

**Action Required:** Please fix the API to accept HTTP GET requests with JSON headers.

---

## 🔐 Authentication Handling

The mobile app supports two modes:

### 1. Authenticated Users (with token)

- Request includes: `Authorization: Bearer {token}`
- App displays content with AppBar & BottomNavigationBar
- User can navigate within the app

### 2. Guest Users (no token)

- Request without Authorization header
- App displays content without navigation bars
- Clean, focused interface for survey completion

**Note:** The API must support both modes (with and without token).

---

## 📊 File Summary

| File                       | Location            | Size       | Content-Type     | Extension |
| -------------------------- | ------------------- | ---------- | ---------------- | --------- |
| qrcodeapp.php              | /RCC4/Requirements/ | ~6 KB      | text/html        | .php      |
| assetlinks.json            | /.well-known/       | ~250 bytes | application/json | .json     |
| apple-app-site-association | /.well-known/       | ~300 bytes | application/json | **NONE**  |

---

## 🚀 Deployment Checklist

- [ ] Upload `qrcodeapp.php` to `/RCC4/Requirements/`
- [ ] Upload `assetlinks.json` to `/.well-known/`
- [ ] Upload `apple-app-site-association` to `/.well-known/` (no extension!)
- [ ] Configure server to return correct Content-Type headers
- [ ] Verify all files are accessible via HTTPS
- [ ] Test with curl commands (see Verification Steps above)
- [ ] Fix API endpoint `/api/survey/any_published` to accept HTTP requests
- [ ] Test with Android device
- [ ] Test with iOS device

---

## 🐛 Troubleshooting

### Issue: 404 Not Found

**Solution:** Verify files are uploaded to correct locations with correct names.

### Issue: Files not accessible

**Solution:** Check file permissions, ensure files are readable by web server.

### Issue: Wrong Content-Type

**Solution:** Configure server (Apache/Nginx) to return `application/json` for both JSON files.

### Issue: Android app opens browser instead of app

**Solution:** Verify `assetlinks.json` is accessible and has correct SHA256 fingerprint.

### Issue: iOS app doesn't open

**Solution:**

- Verify `apple-app-site-association` has NO file extension
- Check Team ID is correct (Z9KA83YY82)
- File must be accessible BEFORE app is installed on device

---

## 📞 Support

**Frontend Team:** Already configured and ready  
**Files Location:** Project root directory  
**Last Updated:** December 28, 2025

**Action Required from Backend:**

1. Upload the 3 files to server
2. Configure Content-Type headers
3. Fix API endpoint `/api/survey/any_published`

Once these are complete, the QR code system will work seamlessly on both Android and iOS! 🎉
