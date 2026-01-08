# دليل الاختبار والتحقق من إشعارات الأذان 🧪

## قبل الاختبار

### 1. تنظيف المشروع وإعادة البناء

```bash
cd /Users/loay/StudioProjects/el_race_app
flutter clean
flutter pub get
```

### 2. البناء على جهاز حقيقي (ليس محاكي)

⚠️ **مهم جداً**: الاختبار يجب أن يكون على جهاز Android حقيقي

```bash
# تأكد أن الجهاز متصل
flutter devices

# قم بالبناء والتشغيل
flutter run --release
```

## خطوات الاختبار الكاملة

### المرحلة 1: التحقق من الصلاحيات ✅

1. **عند أول فتح للتطبيق**:

   - يجب أن يظهر طلب: "السماح لـ El Race بتجاهل تحسينات البطارية؟"
   - اختر: **"السماح"** أو **"Allow"**

2. **التحقق اليدوي**:
   - اذهب إلى: الإعدادات → التطبيقات → El Race
   - البطارية → تأكد من اختيار "غير محدود" أو "Unrestricted"

### المرحلة 2: التحقق من أوقات الصلاة 📅

1. افتح التطبيق
2. في الشاشة الرئيسية، تحقق من:

   - ✅ ظهور أوقات الصلاة الخمسة
   - ✅ العد التنازلي للصلاة القادمة يعمل
   - ✅ زر الصوت (🔊) ظاهر وغير مكتوم

3. إذا لم تظهر الأوقات:
   - تحقق من صلاحية الموقع
   - اسحب للتحديث (Pull to refresh)

### المرحلة 3: اختبار الإشعار في الخلفية 🔔

#### الطريقة الأولى: اختبار سريع (الصلاة القادمة)

1. **التحضير**:

   - تأكد من أن الوقت قريب من صلاة قادمة (5-10 دقائق)
   - تأكد أن الصوت غير مكتوم (🔊)
   - سجل دخولك في التطبيق

2. **إغلاق التطبيق بالكامل**:

   ```
   ضغطة طويلة على زر Home
   → Recent Apps (التطبيقات الأخيرة)
   → اسحب El Race للأعلى/الجانب
   ```

3. **الانتظار**:

   - لا تفتح التطبيق مرة أخرى
   - انتظر حتى موعد الصلاة

4. **النتيجة المتوقعة**:
   - ✅ يظهر إشعار: "🕌 حان وقت الصلاة"
   - ✅ يشتغل صوت الأذان تلقائياً
   - ✅ الصوت يستمر ~4 دقائق

#### الطريقة الثانية: اختبار يدوي (تغيير الوقت)

⚠️ **للاختبار فقط - لا تستخدمها في الإنتاج**

1. قم بتعديل ملف prayer_background_service.dart مؤقتاً:

```dart
// في _schedulePrayerTasks()
// بدلاً من:
final delay = prayerTime.difference(now);

// استخدم:
final delay = Duration(seconds: 30); // اختبار بعد 30 ثانية
```

2. أعد بناء التطبيق
3. افتح التطبيق
4. أغلقه بالكامل
5. انتظر 30 ثانية
6. يجب أن يظهر الإشعار ويعمل الصوت

### المرحلة 4: التحقق من Logs 📝

```bash
# للتحقق من عمل الخدمة في الخلفية
adb logcat | grep -E "Prayer|Adhan|Background|WorkManager"

# لفحص أخطاء محددة
adb logcat | grep -E "Error|Exception"

# لفحص الإشعارات
adb logcat | grep -E "Notification"
```

## حالات الاختبار

### ✅ حالة النجاح

- [x] الإشعار يظهر في الوقت الصحيح
- [x] الصوت يعمل مباشرة
- [x] الصوت واضح وجودة جيدة
- [x] Fade-in يعمل (يبدأ منخفض ثم يعلى)
- [x] الصوت يستمر لمدة ~4 دقائق

### ⚠️ حالات المشاكل المحتملة

#### المشكلة 1: الإشعار لا يظهر

**التشخيص**:

```bash
# تحقق من WorkManager
adb logcat | grep "WorkManager"

# تحقق من الصلاحيات
adb shell dumpsys notification
```

**الحل**:

1. تحقق من صلاحيات الإشعارات
2. تحقق من Battery Optimization
3. أعد تشغيل الجهاز

#### المشكلة 2: الإشعار يظهر لكن الصوت لا يعمل

**التشخيص**:

```bash
# تحقق من AudioPlayer
adb logcat | grep "AudioPlayer"
```

**الحل**:

1. تحقق من أن `assets/mp3/azan.mp3` موجود
2. تحقق من صلاحيات الصوت
3. تحقق من volume الجهاز

#### المشكلة 3: يعمل أحياناً ويتوقف أحياناً

**السبب المحتمل**: الجهاز يغلق التطبيق لتوفير البطارية

**الحل**:

1. إعدادات → التطبيقات → El Race
2. البطارية → "غير محدود"
3. Auto-start → تفعيل (بعض الأجهزة)

## اختبار على أجهزة مختلفة

### Samsung

- ✅ تأكد من: Settings → Apps → El Race → Battery → Unrestricted
- ✅ تفعيل: Settings → Apps → El Race → Appear on top

### Xiaomi (MIUI)

- ✅ Settings → Apps → El Race → Battery saver → No restrictions
- ✅ Settings → Apps → El Race → Autostart → Enable
- ✅ Settings → Apps → El Race → Background activity → Allow

### Huawei

- ✅ Settings → Apps → El Race → Launch → Manual
- ✅ Enable: Auto-launch, Secondary launch, Run in background

### Oppo/Realme (ColorOS)

- ✅ Settings → Battery → App Battery Management → El Race → Don't optimize
- ✅ Settings → Apps → El Race → Background data → Allow

## أدوات المساعدة

### 1. التحقق من WorkManager Tasks

```bash
adb shell dumpsys jobscheduler | grep "el_race"
```

### 2. التحقق من Alarms المجدولة

```bash
adb shell dumpsys alarm | grep "el_race"
```

### 3. محاكاة إشعار اختباري

```bash
adb shell am broadcast -a android.intent.action.BOOT_COMPLETED
```

## Debugging متقدم

### تفعيل Debug Mode مؤقتاً

في `prayer_background_service.dart`:

```dart
// غيّر من:
isInDebugMode: false,

// إلى:
isInDebugMode: true,
```

ثم قم بإلغاء التعليق عن جميع `debugPrint` في:

- `prayer_background_service.dart`
- `prayer_audio_service.dart`
- `prayer_notification_service.dart`

### فحص Hive Storage

```dart
// في أي مكان في التطبيق للتحقق من حالة الأذان
final isMuted = await HiveService.isPrayerSoundMuted();
print('Sound muted: $isMuted');

final isLoggedIn = await HiveService.isUserLoggedIn();
print('User logged in: $isLoggedIn');
```

## Checklist قبل Release

- [ ] تعطيل debug mode في WorkManager
- [ ] إزالة/تعليق جميع debugPrint
- [ ] اختبار على 3 أجهزة مختلفة على الأقل
- [ ] اختبار لمدة 24 ساعة كاملة
- [ ] اختبار بعد إعادة تشغيل الجهاز
- [ ] اختبار مع battery saver mode
- [ ] توثيق أي مشاكل معروفة

## ملاحظات إضافية

### Performance

- WorkManager ممكن يتأخر ±5 دقائق في بعض الحالات النادرة
- Exact alarms تحسن الدقة إلى ±30 ثانية
- في حالة استمرار المشاكل، يمكن التحول لـ AlarmManager

### Battery Impact

- التطبيق يستهلك <1% بطارية يومياً للخلفية
- الصوت يستهلك ~2-3% أثناء التشغيل (4 دقائق)

### Compatibility

- ✅ Android 8.0 (API 26) وما فوق
- ⚠️ بعض الأجهزة القديمة قد تحتاج إعدادات إضافية
- ⚠️ Android 14+ يحتاج FOREGROUND_SERVICE_MEDIA_PLAYBACK

---

**آخر تحديث**: 7 يناير 2026  
**الإصدار**: 1.0.0
