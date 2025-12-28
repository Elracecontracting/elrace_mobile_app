# iOS Universal Links Setup Guide

## ✅ ما تم تعديله

تم تحديث نظام الـ QR Code ليدعم **iOS و Android** معاً:

### 📱 Android Support:

- ✅ Android App Links
- ✅ Deep linking عبر URI scheme
- ✅ Fallback إلى Play Store

### 🍎 iOS Support:

- ✅ Universal Links
- ✅ Deep linking عبر URL scheme
- ✅ Fallback إلى App Store

---

## 📁 الملفات المطلوبة على السيرفر

### 1️⃣ For Android - assetlinks.json

**الموقع:** `https://elrace.com/.well-known/assetlinks.json`

```json
[
  {
    "relation": ["delegate_permission/common.handle_all_urls"],
    "target": {
      "namespace": "android_app",
      "package_name": "com.el_race.app",
      "sha256_cert_fingerprints": ["YOUR_SHA256_FINGERPRINT_HERE"]
    }
  }
]
```

**كيف تحصل على SHA256:**

```bash
# For release keystore
keytool -list -v -keystore /path/to/your/keystore.jks -alias your-alias

# For debug (testing only)
keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey -storepass android -keypass android
```

---

### 2️⃣ For iOS - apple-app-site-association

**الموقع:** `https://elrace.com/.well-known/apple-app-site-association`

**IMPORTANT:**

- ⚠️ بدون extension (.json)
- ⚠️ Content-Type: application/json
- ⚠️ يجب أن يكون accessible عبر HTTPS

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
  },
  "webcredentials": {
    "apps": ["TEAM_ID.com.elrace.app"]
  }
}
```

**كيف تحصل على Team ID:**

1. افتح Xcode
2. اذهب لـ Runner target → Signing & Capabilities
3. Team ID موجود تحت "Team"
4. أو من https://developer.apple.com/account (Membership Details)

**مثال:**

- إذا Team ID = `ABC123XYZ`
- يصير appID: `ABC123XYZ.com.elrace.app`

---

## 🔧 iOS Configuration في المشروع

### Step 1: تحديث Info.plist

افتح [ios/Runner/Info.plist](ios/Runner/Info.plist) وأضف:

```xml
<!-- Add Associated Domains Entitlement will be done in Xcode -->
<key>CFBundleURLTypes</key>
<array>
    <dict>
        <key>CFBundleTypeRole</key>
        <string>Editor</string>
        <key>CFBundleURLName</key>
        <string>com.elrace.app</string>
        <key>CFBundleURLSchemes</key>
        <array>
            <string>elrace</string>
        </array>
    </dict>
</array>
```

### Step 2: إضافة Associated Domains في Xcode

1. افتح مشروع iOS في Xcode:

   ```bash
   open ios/Runner.xcworkspace
   ```

2. اختر **Runner** target من القائمة اليسار

3. اذهب لتبويب **Signing & Capabilities**

4. اضغط **+ Capability**

5. اختر **Associated Domains**

6. أضف:
   ```
   applinks:elrace.com
   ```

**الصورة المتوقعة:**

```
Associated Domains
  Domains:
    applinks:elrace.com
```

### Step 3: تحديث flutter code لدعم iOS

الكود الحالي في [lib/main.dart](lib/main.dart) يدعم iOS تلقائياً عبر `app_links` package، لكن تأكد من:

```dart
void _initDeepLinking(BuildContext context) async {
  final appLinks = AppLinks();

  // Listen to all incoming links
  appLinks.uriLinkStream.listen((uri) {
    print('🔗 Deep link received (stream): $uri');
    _handleDeepLink(uri, context);
  });

  // Handle initial link
  appLinks.getInitialLink().then((uri) {
    if (uri != null) {
      print('🔗 Initial deep link found: $uri');
      _handleDeepLink(uri, context);
    }
  });
}
```

---

## 🧪 اختبار iOS Universal Links

### Test على جهاز حقيقي (Recommended):

1. **Install التطبيق** على iPhone/iPad
2. **افتح Safari** (ليس Chrome)
3. **اكتب الرابط** في address bar:
   ```
   https://elrace.com/RCC4/Requirements/qrcodeapp
   ```
4. **اضغط Go**
5. **النتيجة المتوقعة:** يفتح التطبيق مباشرة

### Test على Simulator:

```bash
# Test universal link
xcrun simctl openurl booted "https://elrace.com/RCC4/Requirements/qrcodeapp"

# Check logs
xcrun simctl spawn booted log stream --predicate 'eventMessage contains "elrace"'
```

### Verify apple-app-site-association:

**اختبار الملف:**

```bash
# يجب أن يعيد JSON بدون errors
curl -v https://elrace.com/.well-known/apple-app-site-association
```

**يجب أن يكون:**

- ✅ Status 200 OK
- ✅ Content-Type: application/json
- ✅ Valid JSON format
- ✅ Accessible عبر HTTPS

**استخدم Apple's validator:**
https://search.developer.apple.com/appsearch-validation-tool/

---

## 🐛 Troubleshooting iOS

### المشكلة: التطبيق لا يفتح عند النقر على الرابط

**الحلول:**

1. **تحقق من apple-app-site-association:**

   ```bash
   curl https://elrace.com/.well-known/apple-app-site-association
   ```

2. **احذف التطبيق وأعد التثبيت:**

   - iOS يحمل apple-app-site-association عند أول تثبيت فقط
   - امسح التطبيق تماماً ثم ثبته من جديد

3. **تأكد من Team ID صحيح:**

   ```json
   "appID": "CORRECT_TEAM_ID.com.elrace.app"
   ```

4. **افحص Xcode Console:**

   ```
   Window → Devices and Simulators → View Device Logs
   ```

   ابحث عن "swcd" or "apple-app-site-association"

5. **استخدم Safari فقط:**

   - Universal Links تعمل فقط في Safari، ليس في Chrome أو apps أخرى
   - من Notes app: اكتب الرابط واضغط عليه

6. **تحقق من Associated Domains:**
   - Runner target → Signing & Capabilities
   - تأكد من وجود: `applinks:elrace.com`

---

## 📊 الفرق بين Android و iOS

| Feature            | Android                     | iOS                                    |
| ------------------ | --------------------------- | -------------------------------------- |
| Configuration File | assetlinks.json             | apple-app-site-association             |
| Location           | .well-known/assetlinks.json | .well-known/apple-app-site-association |
| File Extension     | .json                       | **NO extension**                       |
| Verification       | SHA256 fingerprint          | Team ID + Bundle ID                    |
| Testing            | adb command                 | Safari browser                         |
| Fallback           | Play Store                  | App Store                              |

---

## 🚀 خطوات النشر النهائية

### 1. رفع الملفات على السيرفر:

```bash
# تأكد من وجود هذه الملفات على elrace.com:
https://elrace.com/.well-known/assetlinks.json
https://elrace.com/.well-known/apple-app-site-association
https://elrace.com/RCC4/Requirements/qrcodeapp.php
```

### 2. تحديث apple-app-site-association:

```bash
# استبدل TEAM_ID بـ Team ID الحقيقي
{
  "applinks": {
    "apps": [],
    "details": [
      {
        "appID": "YOUR_TEAM_ID.com.elrace.app",
        "paths": ["/RCC4/Requirements/qrcodeapp", "/RCC4/Requirements/qrcodeapp.php"]
      }
    ]
  }
}
```

### 3. Configure .htaccess (إذا كنت تستخدم Apache):

```apache
# Ensure apple-app-site-association is served with correct Content-Type
<Files "apple-app-site-association">
    Header set Content-Type "application/json"
    Header set Access-Control-Allow-Origin "*"
</Files>

# Same for assetlinks.json
<Files "assetlinks.json">
    Header set Content-Type "application/json"
    Header set Access-Control-Allow-Origin "*"
</Files>
```

### 4. Test كل شيء:

**Android:**

```bash
adb shell am start -W -a android.intent.action.VIEW \
  -d "https://elrace.com/RCC4/Requirements/qrcodeapp"
```

**iOS:**

```bash
xcrun simctl openurl booted "https://elrace.com/RCC4/Requirements/qrcodeapp"
```

---

## 📱 ملف qrcodeapp.php المحدث

الملف الجديد يدعم:

- ✅ Android App Links
- ✅ iOS Universal Links
- ✅ Automatic detection للـ platform
- ✅ Smart fallback للـ stores
- ✅ UI أفضل مع spinner و messages
- ✅ Desktop support (يعرض رسالة + روابط التحميل)
- ✅ Debug mode (أضف `?debug=1` للـ URL)

---

## 🎯 الخطوات التالية:

1. **احصل على iOS Team ID** من Xcode أو Apple Developer Account
2. **عدّل apple-app-site-association** بالـ Team ID الصحيح
3. **ارفع الملفات** على السيرفر:
   - `.well-known/assetlinks.json` (Android)
   - `.well-known/apple-app-site-association` (iOS)
   - `RCC4/Requirements/qrcodeapp.php` (Landing page)
4. **افتح Xcode** وأضف Associated Domains
5. **Build و Test** على أجهزة حقيقية (iOS و Android)
6. **احذف وأعد تثبيت** التطبيق بعد رفع الملفات على السيرفر

---

## 📞 Important Notes:

⚠️ **iOS Universal Links Requirements:**

- يجب تثبيت التطبيق من TestFlight أو App Store (ليس من Xcode direct install)
- أو: Enable Associated Domains في Development mode
- الملف apple-app-site-association يجب أن يكون accessible قبل تثبيت التطبيق

⚠️ **Android App Links Requirements:**

- SHA256 fingerprint يجب أن يطابق الـ release keystore
- للـ testing، استخدم debug keystore fingerprint
- assetlinks.json يجب أن يكون public و accessible

---

## ✅ Checklist:

- [ ] حصلت على iOS Team ID
- [ ] عدلت apple-app-site-association بالـ Team ID
- [ ] رفعت assetlinks.json على السيرفر
- [ ] رفعت apple-app-site-association على السيرفر
- [ ] رفعت qrcodeapp.php المحدث
- [ ] أضفت Associated Domains في Xcode
- [ ] اختبرت على Android device
- [ ] اختبرت على iOS device
- [ ] تحققت من الـ fallbacks (Play Store & App Store)

---

**الخلاصة:** الآن نظام الـ QR code يدعم iOS و Android بشكل كامل! 🎉
