# نظام Check-in/Check-out مع Auto Check-out التلقائي

## نظرة عامة

تم تطوير نظام Check-in/Check-out ليدعم الميزات التالية:

### ✅ المتطلبات

1. **Check-in**: يمكن للموظف عمل check-in في أي وقت يريد مع طلب Face ID
2. **Check-out اليدوي (قبل 5 مساءً)**: يطلب Face ID verification
3. **Auto Check-out (في 5 مساءً)**: يتم تلقائياً بدون طلب Face ID

---

## 📁 الملفات المُعدّلة

### 1. `/lib/data/services/auto_checkout_service.dart` (جديد)

خدمة تنفيذ Auto Check-out التلقائي باستخدام WorkManager.

**الوظائف الرئيسية:**

- `initialize()`: تهيئة WorkManager
- `scheduleAutoCheckout()`: جدولة مهمة يومية في الساعة 5 مساءً
- `cancelAutoCheckout()`: إلغاء الجدولة عند Check-out اليدوي
- `_performAutoCheckout()`: تنفيذ Check-out التلقائي بدون Face ID

**كيف يعمل:**

```dart
// عند Check-in
await AutoCheckoutService.scheduleAutoCheckout();
// يتم جدولة مهمة WorkManager لتُنفذ في الساعة 5 مساءً

// عند الساعة 5 مساءً
// تُنفذ المهمة تلقائياً في الخلفية
sl.get<CheckOutBloc>().add(CheckOutET(checkInRecordId, isAutoCheckout: true));
```

### 2. `/lib/ui/presentation/landing_screen/bloc/checkin_out_bloc/check_out_event.dart`

تم إضافة معامل `isAutoCheckout` إلى `CheckOutET`:

```dart
final class CheckOutET extends CheckOutEvent {
  final int checkInRecordId;
  final bool isAutoCheckout; // true = auto (no Face ID), false = manual (with Face ID)

  const CheckOutET(this.checkInRecordId, {this.isAutoCheckout = false});
}
```

### 3. `/lib/ui/presentation/home_screen/screens/custom_swipe_button.dart`

تم تعديل `_performCheckInOut()`:

**عند Check-in:**

```dart
if (!isCheckedIn) {
  sl.get<CheckInBloc>().add(CheckInET());
  Get.find<TimerController>().startTimer();

  // جدولة Auto Check-out
  await AutoCheckoutService.scheduleAutoCheckout();
  debugPrint('✅ Auto checkout scheduled for 5:00 PM');
}
```

**عند Check-out اليدوي:**

```dart
else {
  sl.get<CheckOutBloc>().add(CheckOutET(checkInRecordId, isAutoCheckout: false));

  // إلغاء جدولة Auto Check-out
  await AutoCheckoutService.cancelAutoCheckout();
  debugPrint('✅ Auto checkout cancelled');
}
```

### 4. `/lib/main.dart`

تمت إضافة تهيئة الخدمة عند بدء التطبيق:

```dart
// تهيئة خدمة Auto Check-out
await AutoCheckoutService.initialize();

// إذا كان المستخدم checked-in عند فتح التطبيق
final isCheckedIn = SharedPref().getPreferenceBoolean('isCheckedIn');
if (isCheckedIn) {
  await AutoCheckoutService.scheduleAutoCheckout();
  debugPrint('✅ Auto checkout scheduled for 5:00 PM');
}
```

---

## 🔄 سيناريوهات الاستخدام

### السيناريو 1: Check-in صباحاً + Check-out يدوي قبل 5 مساءً

```
08:00 صباحاً → Check-in (مع Face ID) ✅
   ↓
   جدولة Auto Check-out في 5:00 مساءً
   ↓
04:30 مساءً → Check-out يدوي (مع Face ID) ✅
   ↓
   إلغاء جدولة Auto Check-out
```

### السيناريو 2: Check-in صباحاً + نسيان Check-out

```
08:00 صباحاً → Check-in (مع Face ID) ✅
   ↓
   جدولة Auto Check-out في 5:00 مساءً
   ↓
05:00 مساءً → Auto Check-out تلقائياً (بدون Face ID) ✅
   ↓
   يتم Check-out تلقائياً في الخلفية
```

### السيناريو 3: التطبيق مغلق والساعة 5 مساءً

```
WorkManager يعمل في الخلفية حتى لو كان التطبيق مغلق
   ↓
05:00 مساءً → Auto Check-out تلقائياً ✅
   ↓
   يتم تحديث الحالة في SharedPreferences
```

---

## 🎯 المنطق الأساسي

### متى يُطلب Face ID؟

- ✅ **Check-in**: دائماً
- ✅ **Check-out اليدوي (قبل 5 مساءً)**: دائماً
- ❌ **Auto Check-out (في 5 مساءً)**: لا يُطلب أبداً

### التحكم في Face ID

```dart
// في custom_swipe_button.dart
showLeftToRightPopupClean(
  context: context,
  isCheckedIn: isCheckedIn,
  onConfirmed: () async {
    if (!AppConfigService.instance.isTestMode) {
      // طلب Face ID authentication
      final authenticated = await UnifiedBiometricHelper.authenticateForAttendance(context);

      if (authenticated) {
        _performCheckInOut(); // تنفيذ Check-in/out
      } else {
        _resetPosition(); // إلغاء العملية
      }
    }
  }
);
```

---

## 🧪 الاختبار

### 1. اختبار Check-in مع Face ID

```dart
1. افتح التطبيق
2. Swipe لـ Check-in
3. تحقق من ظهور Face ID prompt
4. تأكد من جدولة Auto Check-out:
   // في الـ logs
   ✅ Auto checkout scheduled for 5:00 PM
```

### 2. اختبار Check-out اليدوي مع Face ID

```dart
1. بعد Check-in
2. Swipe لـ Check-out (قبل 5 مساءً)
3. تحقق من ظهور Face ID prompt
4. تأكد من إلغاء Auto Check-out:
   // في الـ logs
   ✅ Auto checkout cancelled after manual check-out
```

### 3. اختبار Auto Check-out في 5 مساءً

```dart
1. عمل Check-in
2. انتظر حتى الساعة 5 مساءً (أو غيّر الوقت للاختبار)
3. تحقق من:
   - عدم ظهور Face ID prompt
   - تنفيذ Check-out تلقائياً
   - تحديث الحالة
```

### 4. اختبار التطبيق في الخلفية

```dart
1. عمل Check-in
2. أغلق التطبيق
3. انتظر حتى الساعة 5 مساءً
4. افتح التطبيق وتحقق من:
   - isCheckedIn = false
   - checkInRecordId = 0
```

---

## 🔧 استكشاف الأخطاء

### المشكلة: Auto Check-out لا يعمل في الخلفية

**الحل:**

```dart
// تأكد من إعطاء صلاحيات WorkManager
// Android: في AndroidManifest.xml
<uses-permission android:name="android.permission.RECEIVE_BOOT_COMPLETED"/>
<uses-permission android:name="android.permission.WAKE_LOCK"/>
```

### المشكلة: Face ID لا يُطلب عند Check-out اليدوي

**الحل:**

```dart
// تأكد من تمرير isAutoCheckout = false
sl.get<CheckOutBloc>().add(CheckOutET(checkInRecordId, isAutoCheckout: false));
```

### المشكلة: Auto Check-out يُنفذ أكثر من مرة

**الحل:**

```dart
// إلغاء المهام السابقة قبل الجدولة
await Workmanager().cancelByUniqueName(uniqueName);
```

---

## 📝 ملاحظات مهمة

1. **WorkManager**: يستخدم لجدولة المهام في الخلفية حتى لو كان التطبيق مغلق
2. **SharedPreferences**: يحفظ حالة Check-in/out لاسترجاعها عند فتح التطبيق
3. **isAutoCheckout**: معامل مهم لتمييز Check-out التلقائي من اليدوي
4. **Face ID**: يُطلب فقط عند Check-in و Check-out اليدوي

---

## 🚀 التحديثات المستقبلية المحتملة

1. إضافة إشعار push قبل Auto Check-out بـ 15 دقيقة
2. إمكانية تخصيص وقت Auto Check-out من الإعدادات
3. تقرير يومي يُرسل بعد Auto Check-out
4. دعم multiple check-in/out في نفس اليوم

---

تاريخ التحديث: 8 يناير 2026
