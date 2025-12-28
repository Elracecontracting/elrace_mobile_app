# Test Scenarios Checklist

## ✅ اختبار Android

### Scenario 1: App مثبت + مسجل دخول

- [ ] امسح QR code
- [ ] يفتح التطبيق تلقائياً
- [ ] يظهر AppBar + BottomNavigationBar
- [ ] يعرض محتوى الـ survey/documents/media
- [ ] زر الرجوع يعمل

### Scenario 2: App مثبت + غير مسجل دخول (Guest)

- [ ] امسح QR code
- [ ] يفتح التطبيق تلقائياً
- [ ] يظهر بدون AppBar/BottomBar (واجهة نظيفة)
- [ ] يعرض المحتوى
- [ ] يمكن الإجابة على الاستبيان

### Scenario 3: App غير مثبت

- [ ] امسح QR code
- [ ] يوجه تلقائياً لـ Play Store
- [ ] يعرض صفحة التطبيق El Race

### Scenario 4: اختبار من browser

- [ ] افتح الرابط في Chrome
- [ ] اضغط على الرابط
- [ ] يسأل: "Open with El Race?"
- [ ] اختر "Always" ثم افتح
- [ ] يجب أن يفتح التطبيق

---

## ✅ اختبار iOS

### Scenario 1: App مثبت + مسجل دخول

- [ ] امسح QR code بالكاميرا
- [ ] notification يظهر: "Open in El Race"
- [ ] اضغط notification
- [ ] يفتح التطبيق مع AppBar + BottomBar
- [ ] المحتوى يظهر صحيح

### Scenario 2: App مثبت + غير مسجل دخول

- [ ] امسح QR code
- [ ] يفتح التطبيق
- [ ] يظهر بدون navigation bars
- [ ] المحتوى يظهر صحيح

### Scenario 3: App غير مثبت

- [ ] امسح QR code
- [ ] يوجه لـ qrcodeapp.php
- [ ] يعرض loading screen
- [ ] يوجه تلقائياً لـ App Store بعد 2.5 ثانية

### Scenario 4: اختبار من Safari

- [ ] افتح Safari
- [ ] اكتب الرابط في address bar
- [ ] اضغط Go
- [ ] يفتح التطبيق مباشرة (بدون notification)

### Scenario 5: اختبار من Notes/Messages

- [ ] اكتب الرابط في Notes app
- [ ] اضغط على الرابط
- [ ] يفتح التطبيق مباشرة

---

## ✅ اختبار Desktop

### Scenario 1: فتح من Chrome/Safari على desktop

- [ ] افتح الرابط
- [ ] يعرض صفحة desktop-friendly
- [ ] يعرض روابط لـ App Store و Play Store
- [ ] يعرض رسالة: "Scan with mobile"

---

## ✅ اختبار API Integration

### Test 1: API Response

```bash
curl -X GET https://test.elrace.com/api/survey/any_published \
  -H "Content-Type: application/json" \
  -H "Accept: application/json"
```

- [ ] يرجع status 200
- [ ] يحتوي على: type (survey/documents/media)
- [ ] يحتوي على: data array

### Test 2: API with Token

```bash
curl -X GET https://test.elrace.com/api/survey/any_published \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -H "Content-Type: application/json"
```

- [ ] يرجع بيانات خاصة بالمستخدم

---

## ✅ اختبار Server Files

### assetlinks.json (Android)

```bash
curl -I https://elrace.com/.well-known/assetlinks.json
```

- [ ] Status: 200 OK
- [ ] Content-Type: application/json
- [ ] Accessible via HTTPS
- [ ] No redirect

### apple-app-site-association (iOS)

```bash
curl -I https://elrace.com/.well-known/apple-app-site-association
```

- [ ] Status: 200 OK
- [ ] Content-Type: application/json
- [ ] NO .json extension
- [ ] Accessible via HTTPS

### qrcodeapp.php

```bash
curl -I https://elrace.com/RCC4/Requirements/qrcodeapp.php
```

- [ ] Status: 200 OK
- [ ] Content-Type: text/html
- [ ] يعرض HTML صحيح

---

## 🐛 Debug Commands

### Android Logs:

```bash
adb logcat | grep -E "AppLinks|DeepLink|QR|elrace"
```

### iOS Logs:

```bash
xcrun simctl spawn booted log stream --predicate 'eventMessage contains "swcd"'
```

### Flutter Logs:

```bash
flutter logs | grep -i "deep\|qr"
```

---

## 📊 Expected Results Summary

| Scenario                  | Android                | iOS                    |
| ------------------------- | ---------------------- | ---------------------- |
| App installed + logged in | Opens with nav bars    | Opens with nav bars    |
| App installed + guest     | Opens without nav bars | Opens without nav bars |
| App not installed         | Play Store             | App Store              |
| Desktop browser           | Shows download page    | Shows download page    |

---

## ⚠️ Common Issues

### Issue: App doesn't open

**Android:**

- Check SHA256 fingerprint in assetlinks.json
- Verify android:autoVerify="true" in AndroidManifest.xml
- Reinstall app

**iOS:**

- Check Team ID in apple-app-site-association
- Add Associated Domains in Xcode
- Delete and reinstall app
- Test in Safari only (not Chrome)

### Issue: Shows app chooser (Android)

- App Links verification failed
- Check assetlinks.json is accessible
- Clear app data and retry

### Issue: Opens browser instead of app (iOS)

- Universal Links not configured
- Check apple-app-site-association
- Must use Safari (not Chrome)
- Reinstall app after fixing

---

## 📝 Test Report Template

```
Test Date: _________
Tested By: _________
Device: _________
OS Version: _________

Scenarios Tested:
☐ Android - Logged In
☐ Android - Guest
☐ Android - Not Installed
☐ iOS - Logged In
☐ iOS - Guest
☐ iOS - Not Installed
☐ Desktop

Issues Found:
1. ___________________
2. ___________________

Notes:
_____________________
```
