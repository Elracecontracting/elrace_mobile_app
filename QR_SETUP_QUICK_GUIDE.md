# 🚀 Quick Setup - QR System (iOS + Android)

## ملفات يجب رفعها على السيرفر:

### 1️⃣ Android - assetlinks.json

**المسار:** `https://elrace.com/.well-known/assetlinks.json`

```json
[
  {
    "relation": ["delegate_permission/common.handle_all_urls"],
    "target": {
      "namespace": "android_app",
      "package_name": "com.el_race.app",
      "sha256_cert_fingerprints": ["YOUR_SHA256_FINGERPRINT"]
    }
  }
]
```

احصل على SHA256:

```bash
keytool -list -v -keystore /path/to/keystore.jks -alias your-alias
```

---

### 2️⃣ iOS - apple-app-site-association

**المسار:** `https://elrace.com/.well-known/apple-app-site-association`

**⚠️ ملاحظة: بدون extension!**

```json
{
  "applinks": {
    "apps": [],
    "details": [
      {
        "appID": "TEAM_ID.com.elrace.app",
        "paths": [
          "/RCC4/Requirements/qrcodeapp",
          "/RCC4/Requirements/qrcodeapp.php"
        ]
      }
    ]
  }
}
```

احصل على Team ID من Xcode:

- Runner target → Signing & Capabilities → Team

---

### 3️⃣ Landing Page - qrcodeapp.php

**المسار:** `https://elrace.com/RCC4/Requirements/qrcodeapp.php`

الملف موجود في المشروع: `qrcodeapp.php`

---

## خطوات iOS في Xcode:

1. افتح المشروع:

```bash
cd ios
open Runner.xcworkspace
```

2. اختر **Runner** target

3. **Signing & Capabilities** → اضغط **+ Capability**

4. اختر **Associated Domains**

5. أضف:

```
applinks:elrace.com
```

---

## اختبار:

### Android:

```bash
adb shell am start -W -a android.intent.action.VIEW -d "https://elrace.com/RCC4/Requirements/qrcodeapp"
```

### iOS (على جهاز حقيقي):

1. افتح Safari
2. اكتب: `https://elrace.com/RCC4/Requirements/qrcodeapp`
3. اضغط Go

---

## ⚠️ Important:

- **iOS:** احذف التطبيق وأعد تثبيته بعد رفع apple-app-site-association
- **Android:** تأكد من SHA256 fingerprint صحيح
- **كلاهما:** الملفات يجب تكون accessible عبر HTTPS

---

للتفاصيل الكاملة، شاهد: [IOS_UNIVERSAL_LINKS_SETUP.md](IOS_UNIVERSAL_LINKS_SETUP.md)
