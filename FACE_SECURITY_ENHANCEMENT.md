# 🔐 Face Recognition Security Enhancement v2.0

## ملخص التحديثات الأمنية

تم تطبيق تحسينات أمنية شاملة على نظام التعرف على الوجه لحل مشكلة تسجيل الوجوه من أجهزة متعددة.

---

## 🆕 الملفات الجديدة

### 1. `firebase_face_service.dart`

خدمة للتعامل مع بيانات الوجه في Firebase مع ميزات:

- **Device Binding**: ربط الوجه بجهاز محدد
- **Security Audit Logging**: تسجيل جميع العمليات الأمنية
- **Device Transfer Requests**: طلب نقل الحساب لجهاز جديد

### 2. `dual_verification_service.dart`

خدمة التحقق المزدوج:

- **Local Verification**: التحقق من التخزين المحلي المشفر
- **Firebase Verification**: التحقق من السحابة
- **Combined Security**: يجب أن يمر كلا التحققين

---

## ⚙️ الإعدادات الجديدة (`face_recognition_config.dart`)

```dart
// التحقق المزدوج (جديد)
static const bool enableDualVerification = true;
static const bool requireBothVerificationSources = true;
static const bool enableFirebaseVerification = true;
static const double firebaseCosineSimilarityThreshold = 0.65;

// ربط الجهاز (مفعّل الآن)
static const bool enableDeviceBinding = true;
static const bool blockCrossDeviceRegistration = true;
static const bool enableSecurityAuditLog = true;
static const bool alwaysRequireLiveness = true;

// حدود أعلى للمطابقة
static const double cosineSimilarityThreshold = 0.65;  // كان 0.55
static const double euclideanDistanceThreshold = 0.60; // كان 0.8
```

---

## 🔒 كيف يعمل النظام الجديد

### عند تسجيل الوجه:

```
1. يتم استخراج Face Embedding من الصورة
2. يتم حفظ البيانات في:
   ├── Local Storage (مشفر AES-256)
   └── Firebase Firestore (مع device_id)
3. يتم تسجيل الجهاز المستخدم
```

### عند Check-in/Check-out:

```
1. التقاط صورة الوجه
2. التحقق من Liveness (حيوية)
3. التحقق من Device Binding:
   └── إذا كان الجهاز مختلف ← رفض + تسجيل الحدث
4. التحقق المزدوج:
   ├── Local: مقارنة مع التخزين المحلي
   └── Firebase: مقارنة مع السحابة
5. يجب أن يمر كلا التحققين ✓
```

---

## 🛡️ حماية ضد سيناريوهات الاحتيال

### السيناريو 1: تسجيل وجه من جهاز آخر

```
❌ مرفوض: "الوجه مسجل على جهاز آخر"
✅ الحل: يجب طلب نقل الجهاز من الإدارة
```

### السيناريو 2: استخدام صورة للتحايل

```
❌ مرفوض: Liveness check يكشف الصور الثابتة
✅ يتطلب حركة طبيعية للرأس
```

### السيناريو 3: شخص آخر يستخدم الحساب

```
❌ مرفوض: Face embedding لا يتطابق
✅ يتم تسجيل المحاولة في Audit Log
```

---

## 📊 هيكل البيانات في Firebase

### Collection: `users`

```json
{
  "id": "emp_123",
  "name": "EMPLOYEE NAME",
  "uuid": "emp_123",
  "faceEmbedding": [0.123, 0.456, ...], // 192 رقم
  "faceFeatures": {...},
  "registeredOn": 1706400000000,
  "registeredDeviceId": "abc123xyz",
  "registeredDeviceInfo": {
    "platform": "android",
    "model": "Samsung Galaxy S21",
    "android_version": "13"
  },
  "securityVersion": 2
}
```

### Collection: `face_audit_logs`

```json
{
  "userId": "emp_123",
  "eventType": "DEVICE_MISMATCH_VERIFICATION",
  "deviceId": "different_device_456",
  "details": {
    "registered_device": "abc123xyz",
    "verification_device": "different_device_456"
  },
  "timestamp": "2026-01-28T10:30:00Z",
  "platform": "android"
}
```

---

## 🎛️ مستويات الأمان

```dart
enum SecurityLevel {
  relaxed,   // للاختبار (threshold: 0.55)
  standard,  // العمليات العادية (threshold: 0.65)
  strict,    // أماكن عالية الأمان (threshold: 0.70)
  maximum,   // أقصى أمان (threshold: 0.80)
}
```

---

## 📱 طلب نقل الجهاز

إذا أراد الموظف استخدام جهاز جديد:

1. يتم إرسال طلب تلقائي للإدارة
2. يتم تسجيل الطلب في `device_transfer_requests`
3. بعد موافقة الإدارة، يمكن إعادة تسجيل الوجه

---

## ⚠️ ملاحظات مهمة

1. **للمستخدمين الحاليين**: يجب إعادة تسجيل الوجه لتفعيل Device Binding
2. **النسخ الاحتياطي**: بيانات Firebase هي المرجع الرئيسي
3. **المزامنة**: يمكن مزامنة Local مع Firebase عند الحاجة

---

## 🧪 اختبار النظام

```bash
# تشغيل التطبيق
flutter run

# سيناريوهات الاختبار:
1. تسجيل وجه جديد ← يجب أن يحفظ في Local + Firebase
2. Check-in من نفس الجهاز ← يجب أن ينجح
3. Check-in من جهاز آخر ← يجب أن يفشل
4. محاولة تسجيل وجه آخر ← يجب أن يُرفض
```

---

## 📋 قائمة الملفات المعدّلة

| الملف                            | التغيير                  |
| -------------------------------- | ------------------------ |
| `firebase_face_service.dart`     | جديد                     |
| `dual_verification_service.dart` | جديد                     |
| `face_recognition_config.dart`   | محدث (أمان أعلى)         |
| `check_in_bloc.dart`             | محدث (dual verification) |
| `face_recognition_bloc.dart`     | محدث (device binding)    |
| `face_recognition_event.dart`    | محدث (events جديدة)      |
| `face_recognition_state.dart`    | محدث (states جديدة)      |
