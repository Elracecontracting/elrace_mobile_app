# QR Survey Deep Linking - Complete Implementation

## ✅ ما تم إنجازه

تم تنفيذ نظام Deep Linking متكامل للـ QR Survey مع دعم ثلاث حالات:

### 1️⃣ مستخدم مسجل دخول (Logged-in User)

- **السلوك**: عند مسح QR Code، يفتح التطبيق الشاشات **مع AppBar و BottomNavigationBar**
- **الشاشة**: `QrSurveyAuthenticatedScreen`
- **المميزات**:
  - AppBar علوي مع زر رجوع
  - BottomNavigationBar سفلي (Home, Tasks, QR Survey, Profile)
  - تبويب QR Survey محدد تلقائياً
  - عند النقر على تبويب آخر، يرجع للصفحة السابقة

### 2️⃣ مستخدم غير مسجل دخول (Guest User)

- **السلوك**: عند مسح QR Code، يفتح التطبيق الشاشات **بدون AppBar أو BottomNavigationBar**
- **الشاشة**: `QrCodeWrapper`
- **المميزات**:
  - واجهة نظيفة بدون navigation bars
  - يمكن للضيف الإجابة على الاستبيانات
  - عرض المستندات والفيديوهات

### 3️⃣ المستخدم ليس لديه التطبيق

- **السلوك**: عند النقر على الرابط، يتم توجيهه لـ Google Play Store تلقائياً
- **التكوين**: Android App Links مع `android:autoVerify="true"`
- **المتطلبات**: رفع `assetlinks.json` على السيرفر

---

## 📁 الملفات المعدلة والمنشأة

### ملفات جديدة:

1. **`lib/ui/presentation/qr_survey/screens/qr_survey_authenticated_screen.dart`**

   - شاشة QR Survey للمستخدم المسجل دخوله
   - تحتوي على AppBar و BottomNavigationBar
   - تعرض المحتوى حسب النوع (survey/documents/media)

2. **`assetlinks.json`**

   - ملف تكوين Android App Links
   - يحتاج للرفع على: `https://elrace.com/.well-known/assetlinks.json`
   - Package name: `com.el_race.app`

3. **`APP_LINKS_SETUP_GUIDE.md`**
   - دليل شامل لإعداد Android App Links
   - شرح كيفية الحصول على SHA256 fingerprint
   - خطوات التحقق والاختبار

### ملفات معدلة:

1. **`lib/main.dart`**

   - إضافة import للشاشة الجديدة
   - تعديل `_handleDeepLink()` للتحقق من حالة تسجيل الدخول
   - التوجيه للشاشة المناسبة حسب الحالة

2. **`android/app/src/main/AndroidManifest.xml`**
   - تم إضافة `android:autoVerify="true"` (سابقاً)
   - Intent filter للـ deep link

---

## 🔧 كيفية عمل النظام

### التدفق الكامل:

```
1. User scans QR Code → https://elrace.com/RCC4/Requirements/qrcodeapp

2. Android checks App Links configuration
   ├─ App NOT installed → Redirect to Play Store ✅
   └─ App installed → Open app with deep link

3. App receives deep link → _handleDeepLink() in main.dart

4. Fetch content from API → QrSurveyApiService.getContentAfterQrCodeScanned()

5. Store in provider → QrSurveyDataProvider.setContentData()

6. Check login status → SharedPref.getLoginData()
   ├─ Logged in → Navigate to QrSurveyAuthenticatedScreen (with AppBar/BottomBar)
   └─ Guest → Navigate to QrCodeWrapper (no AppBar/BottomBar)

7. Display content based on type:
   ├─ survey → ListQuestionsScreen
   ├─ documents → ListDocumentsScreen
   └─ media → ListMediaScreen
```

---

## 🚀 خطوات الإعداد النهائية

### 1. احصل على SHA256 Fingerprint

```bash
# For debug build
keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey -storepass android -keypass android

# For release build
keytool -list -v -keystore /path/to/your/release.keystore -alias your_alias
```

### 2. حدث `assetlinks.json`

افتح `assetlinks.json` واستبدل:

- `YOUR_SHA256_FINGERPRINT_HERE` بالـ fingerprint الفعلي
- تأكد من Package name: `com.el_race.app`

### 3. ارفع على السيرفر

ارفع `assetlinks.json` على:

```
https://elrace.com/.well-known/assetlinks.json
```

**مهم جداً**:

- يجب أن يكون عبر HTTPS (ليس HTTP)
- Content-Type: application/json
- يجب أن يكون في المسار `.well-known` من root domain

### 4. تحقق من الإعداد

```bash
# Test the assetlinks.json
curl https://elrace.com/.well-known/assetlinks.json

# Verify with Google
curl "https://digitalassetlinks.googleapis.com/v1/statements:list?source.web.site=https://elrace.com&relation=delegate_permission/common.handle_all_urls"
```

### 5. اختبر Deep Linking

```bash
# على جهاز Android متصل
adb shell am start -W -a android.intent.action.VIEW -d "https://elrace.com/RCC4/Requirements/qrcodeapp"
```

---

## 📊 الحالات المختلفة

| الحالة | التطبيق مثبت؟ | مسجل دخول؟ | النتيجة                                                  |
| ------ | ------------- | ---------- | -------------------------------------------------------- |
| 1      | ✅ نعم        | ✅ نعم     | يفتح `QrSurveyAuthenticatedScreen` (مع AppBar/BottomBar) |
| 2      | ✅ نعم        | ❌ لا      | يفتح `QrCodeWrapper` (بدون AppBar/BottomBar)             |
| 3      | ❌ لا         | -          | يفتح Play Store تلقائياً                                 |

---

## 🐛 Troubleshooting

### المشكلة: التطبيق لا يفتح عند مسح QR Code

**الحل**:

1. تأكد من رفع `assetlinks.json` على السيرفر
2. تحقق من SHA256 fingerprint
3. امسح بيانات التطبيق وأعد التثبيت
4. افحص logs: `adb logcat | grep -i "AppLinks"`

### المشكلة: يظهر app chooser بدلاً من الفتح المباشر

**الحل**:

- Android App Links verification فشل
- تحقق من `android:autoVerify="true"` في AndroidManifest
- تحقق من `assetlinks.json` accessible

### المشكلة: التطبيق يفتح ولكن لا ينتقل للشاشة

**الحل**:

- تحقق من logs: `print` statements في `_handleDeepLink()`
- تأكد من API يعيد بيانات صحيحة
- تحقق من `QrSurveyDataProvider` تم تسجيله في `MultiProvider`

---

## 📱 اختبار المستخدم

### سيناريو 1: Guest User

1. افتح التطبيق بدون تسجيل دخول
2. امسح QR Code
3. **النتيجة المتوقعة**: تفتح الشاشات بدون AppBar/BottomBar

### سيناريو 2: Logged-in User

1. سجل دخول للتطبيق
2. امسح QR Code
3. **النتيجة المتوقعة**: تفتح الشاشات مع AppBar/BottomBar

### سيناريو 3: App Not Installed

1. على جهاز ليس فيه التطبيق
2. اضغط على الرابط أو امسح QR Code
3. **النتيجة المتوقعة**: يفتح Play Store تلقائياً

---

## 🎯 ملاحظات مهمة

1. **Android App Links** تعمل فقط على Android 6.0 (API 23) وما فوق
2. للأجهزة الأقدم، سيظهر app chooser dialog
3. يجب أن يكون السيرفر HTTPS (ليس HTTP)
4. يجب أن يكون `assetlinks.json` في `.well-known` directory
5. SHA256 fingerprint يختلف بين debug و release builds

---

## ✨ المميزات الإضافية المقترحة

### Landing Page (موصى به بشدة):

أنشئ صفحة على `https://elrace.com/RCC4/Requirements/qrcodeapp` تحتوي على:

- كشف الجهاز (mobile/desktop)
- زر "Open in App" للمستخدمين الذين لديهم التطبيق
- زر "Download App" للمستخدمين الجدد
- QR Code للمستخدمين على Desktop
- معلومات عن المحتوى

### إحصائيات:

- تتبع عدد مرات مسح QR Code
- تتبع معدل تحويل (scan → app open)
- تتبع معدل تحويل (scan → survey completion)

---

## 📞 الدعم

للمزيد من المعلومات، راجع:

- [APP_LINKS_SETUP_GUIDE.md](./APP_LINKS_SETUP_GUIDE.md)
- [Android App Links Documentation](https://developer.android.com/training/app-links)
- [app_links Package](https://pub.dev/packages/app_links)
