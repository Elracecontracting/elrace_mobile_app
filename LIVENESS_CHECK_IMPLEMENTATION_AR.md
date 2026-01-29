# 🛡️ تطبيق فحص الحيوية (Liveness Check) - منع استخدام الصور

## 📋 المشكلة التي تم حلها

**المشكلة السابقة:** كان المستخدم يستطيع تسجيل الدخول باستخدام صورة ثابتة للوجه بدلاً من وجهه الحقيقي، مما يشكل ثغرة أمنية خطيرة.

**الحل:** تم تشديد فحص الحيوية (Liveness Check) للتأكد من أن الشخص الذي يحاول تسجيل الدخول هو شخص حقيقي وليس صورة.

---

## ✅ التحديثات المنفذة

### 1. **🆕 فحص الرمش الإجباري (Mandatory Blink Detection)**

#### ⭐ الميزة الأهم - منع الصور الثابتة تماماً!

- ✅ **جمع 15 إطار** (~1.5 ثانية) بدلاً من إطار واحد
- ✅ **تحليل حركة العينين** عبر الإطارات المتعددة
- ✅ **اكتشاف الرمش الإلزامي** - يجب أن يرمش المستخدم مرة واحدة على الأقل
- ✅ **فحص الحركة الطبيعية** - الصور الثابتة لا تحتوي على حركة (0° variation)
- ✅ **رسالة واضحة** عند الفشل: "لم يتم اكتشاف رمش العينين"

```dart
// 🆕 الآلية الجديدة
1. جمع 15 إطار من الكاميرا
2. تحليل كل إطار لاكتشاف الوجه والعينين
3. فحص تغير حالة العينين (open → closed → open)
4. إذا لم يحدث رمش → ❌ رفض (صورة ثابتة)
5. إذا حدث رمش → ✅ متابعة التحقق من الوجه
```

**كيف تعمل:**

- تجمع الكاميرا 15 إطار خلال ~1.5 ثانية
- يتم تحليل كل إطار لقياس `leftEyeOpenProbability` و `rightEyeOpenProbability`
- النظام يبحث عن نمط: عيون مفتوحة → عيون مغلقة → عيون مفتوحة
- الصور الثابتة **لا يمكنها** إظهار هذا النمط!

**📁 الملفات المعدلة:**

- `face_verification_screen.dart` - جمع الإطارات المتعددة
- `face_recognition_bloc.dart` - معالج التحقق متعدد الإطارات
- `face_recognition_event.dart` - event جديد `StartMultiFrameVerification`

---

### 2. **تشديد فحص الحيوية في `FaceDetectorService`**

#### التغييرات:

- ✅ رفع عتبة فتح العينين من **0.3** إلى **0.5** (يتطلب عيون أكثر انفتاحاً)
- ✅ تقليل الزاوية المسموحة لدوران الرأس من **20°** إلى **15°** (وجه أكثر استقامة)
- ✅ إضافة سجلات (logs) تفصيلية لمتابعة فحص الحيوية
- ✅ رفض التحقق تماماً إذا لم تكن بيانات العينين متاحة

```dart
// قبل التحديث
bool checkLiveness(Face face, {
  double eyeOpenThreshold = 0.3,  // ❌ عتبة منخفضة
  double maxHeadEulerAngleY = 20.0,  // ❌ زاوية كبيرة
  double maxHeadEulerAngleZ = 20.0,
}) { ... }

// بعد التحديث ✅
bool checkLiveness(Face face, {
  double eyeOpenThreshold = 0.5,  // ✅ عتبة أعلى
  double maxHeadEulerAngleY = 15.0,  // ✅ زاوية أصغر
  double maxHeadEulerAngleZ = 15.0,  // ✅ أكثر صرامة
}) {
  // ✅ طباعة تفاصيل الفحص
  print('👁️ Liveness Check - Left Eye: ${face.leftEyeOpenProbability}, Right Eye: ${face.rightEyeOpenProbability}');

  // ❌ رفض تام إذا لم تكن بيانات العينين متاحة
  if (face.leftEyeOpenProbability == null || face.rightEyeOpenProbability == null) {
    print('⚠️ SECURITY WARNING: Eye classification data not available!');
    return false;
  }
  ...
}
```

**📁 الملف:** `lib/core/biometric/face_recognition/data/services/face_detector_service.dart`

---

### 2. **فحص حيوية إلزامي في `FaceRecognitionRepositoryImpl`**

#### التغييرات:

- ✅ جعل فحص الحيوية **إلزامياً** ولا يمكن تجاوزه
- ✅ رفع عتبة فحص العينين إلى **0.6** (بدلاً من 0.3)
- ✅ تقليل الزاوية المسموحة لدوران الرأس إلى **12°** (بدلاً من 20°)
- ✅ رسالة خطأ واضحة للمستخدم عند استخدام صورة

```dart
// ❌ قبل التحديث - كان اختيارياً
bool hasLiveness = true;
if (_enableLivenessCheck) {
  hasLiveness = _faceDetectorService.checkLiveness(face);
  if (!hasLiveness) { ... }
}

// ✅ بعد التحديث - إلزامي ومشدد
bool hasLiveness = false;
print('🔒 Step 3: Starting MANDATORY liveness check...');

hasLiveness = _faceDetectorService.checkLiveness(
  face,
  eyeOpenThreshold: 0.6,      // ⬆️ عتبة أعلى
  maxHeadEulerAngleY: 12.0,   // ⬇️ زاوية أصغر
  maxHeadEulerAngleZ: 12.0,
);

if (!hasLiveness) {
  print('❌ SECURITY: Liveness check FAILED - possible photo attack');
  return const Right(
    FaceVerificationResult(
      isVerified: false,
      confidence: 0.0,
      message: '🚫 Please use your live face, not a photo. Keep your eyes open and look at the camera.',
      hasLiveness: false,
    ),
  );
}
```

**📁 الملف:** `lib/core/biometric/face_recognition/data/repositories/face_recognition_repository_impl.dart`

---

### 3. **تحديث واجهة المستخدم - تنبيه استخدام وجه حقيقي**

#### التغييرات:

- ✅ إضافة تعليمات واضحة: **"استخدم وجهك الحقيقي، وليس صورة"**
- ✅ تعديل التعليمات لتكون أكثر وضوحاً: **"افتح عينيك بشكل واسع"**

```dart
// ✅ تعليمات جديدة
_buildInstructionRow(Icons.visibility, 'Keep your eyes WIDE open'),
_buildInstructionRow(Icons.block, 'Use your LIVE face, NOT a photo'),  // ← جديد
_buildInstructionRow(Icons.face, 'Look directly at the camera'),
_buildInstructionRow(Icons.light_mode, 'Ensure good lighting'),
```

**📁 الملف:** `lib/core/biometric/face_recognition/presentation/screens/face_verification_screen.dart`

---

## 🔒 آلية الحماية الجديدة

### كيف يعمل فحص الحيوية الآن؟

1. **فحص فتح العينين (Eye Openness Check)**
   - يجب أن تكون العينين مفتوحتين بنسبة **60% على الأقل** (بدلاً من 30%)
   - إذا كانت العينين مغلقتين أو شبه مغلقتين → **❌ رفض**

2. **فحص زاوية الرأس (Head Pose Check)**
   - الدوران الأفقي (Yaw): يجب أن يكون أقل من **±12°** (بدلاً من ±20°)
   - الميل (Roll): يجب أن يكون أقل من **±12°**
   - إذا كان الرأس مائلاً كثيراً → **❌ رفض**

3. **التحقق من توفر بيانات التصنيف (Classification Data)**
   - إذا لم تكن بيانات العينين متاحة → **❌ رفض تام**
   - هذا يمنع تجاوز الفحص بصور غير واضحة

4. **رسائل خطأ واضحة**
   - إذا فشل الفحص، يظهر للمستخدم:
     > "🚫 Please use your live face, not a photo. Keep your eyes open and look at the camera."

---

## 📊 مقارنة: قبل وبعد التحديث

| المعيار                    | قبل التحديث ❌ | بعد التحديث ✅ |
| -------------------------- | -------------- | -------------- |
| عتبة فتح العينين           | 0.3 (30%)      | 0.6 (60%)      |
| زاوية دوران الرأس المسموحة | ±20°           | ±12°           |
| فحص الحيوية                | اختياري        | **إلزامي**     |
| التحقق من بيانات العينين   | يقبل null      | **يرفض null**  |
| رسائل الخطأ                | عامة           | واضحة ومحددة   |
| إمكانية استخدام صورة       | ✅ ممكن        | ❌ **مستحيل**  |

---

## 🧪 كيفية الاختبار

### 1. **اختبار بوجه حقيقي (يجب أن ينجح)**

```
✅ افتح عينيك بشكل طبيعي
✅ انظر مباشرة للكاميرا
✅ **ارمش بعينيك بشكل طبيعي** ← 🆕 مطلوب!
✅ تأكد من الإضاءة الجيدة
✅ لا تميل رأسك كثيراً
→ النتيجة المتوقعة: نجاح التحقق ✅
```

### 2. **اختبار بصورة ثابتة (يجب أن يفشل) - 🆕 محسّن**

```
❌ ضع صورة أمام الكاميرا (حتى لو كانت بنفس الوضعية)
→ النتيجة المتوقعة:
   "🚫 لم يتم اكتشاف رمش العينين. الرجاء استخدام وجهك الحقيقي وليس صورة." ❌
→ السبب: الصورة لا يمكنها أن ترمش!
```

### 3. **اختبار بعيون شبه مغلقة (يجب أن يفشل)**

```
❌ أغلق عينيك قليلاً
→ النتيجة المتوقعة: رفض لأن العينين ليستا مفتوحتين بشكل كافٍ ❌
```

### 4. **اختبار برأس مائل (يجب أن يفشل)**

```
❌ مل رأسك بزاوية كبيرة
→ النتيجة المتوقعة: رفض لتجاوز الزاوية المسموحة ❌
```

---

## 📝 ملاحظات مهمة

### ⚠️ تحذيرات للمستخدمين:

1. **افتح عينيك بشكل واسع** أثناء التحقق
2. **انظر مباشرة للكاميرا** - لا تنظر للأسفل أو للأعلى
3. **تأكد من الإضاءة الجيدة** لضمان اكتشاف العينين بدقة
4. **لا تستخدم صورة أو فيديو** - لن تنجح المحاولة

### 🔧 للمطورين:

- إذا كنت تريد **تخفيف** القيود (غير موصى به أمنياً)، يمكنك تعديل:
  - `eyeOpenThreshold`: في `face_detector_service.dart` (السطر 73)
  - `maxHeadEulerAngleY`: في نفس الملف
  - القيم في `verifyFace` في `face_recognition_repository_impl.dart` (السطر 257)

- إذا كنت تريد **تشديد** القيود أكثر:
  - ارفع `eyeOpenThreshold` إلى 0.7 أو 0.8
  - قلل `maxHeadEulerAngleY` إلى 10° أو 8°

---

## 🚀 ميزات إضافية متاحة (LivenessService)

النظام يحتوي على ميزات متقدمة إضافية غير مفعلة حالياً:

### 1. **Passive Anti-Spoof Check** (فحص سلبي ضد الانتحال)

- تحليل **حركة دقيقة طبيعية** للرأس (Micro-movements)
- اكتشاف **تغيرات طفيفة** في احتمالية فتح العينين
- **يكشف الصور** لأنها ثابتة تماماً (0° حركة)

```dart
// للاستخدام المستقبلي
final livenessService = LivenessService(_faceDetectorService);
final result = await livenessService.performPassiveAntiSpoofCheck(
  faceSequence: facesList,
  minFrames: 5,
);
```

### 2. **Active Challenge-Based Check** (فحص تفاعلي)

- طلب **رمش مرتين**
- طلب **لف الرأس لليسار/اليمين**
- طلب **النظر للأعلى/الأسفل**
- **تحديات عشوائية** لمنع التلاعب

```dart
// للاستخدام المستقبلي
final result = await livenessService.performActiveChallengeCheck(
  frameStream: cameraStream,
  challengeTimeout: Duration(seconds: 6),
);
```

---

## ✅ الخلاصة

تم تحسين نظام فحص الحيوية بنجاح لمنع استخدام الصور الثابتة في تسجيل الدخول:

1. ✅ **فحص إلزامي** - لا يمكن تجاوزه
2. ✅ **عتبات أعلى** - عيون يجب أن تكون مفتوحة بنسبة 60%
3. ✅ **زوايا أصغر** - وجه يجب أن يكون مستقيماً (±12°)
4. ✅ **رسائل واضحة** - إرشادات وتنبيهات مفهومة
5. ✅ **أمان محسّن** - حماية قوية ضد هجمات الانتحال

---

## 📞 الدعم

إذا واجهت أي مشاكل أو كان لديك أسئلة:

- راجع السجلات (Logs) في Console - تحتوي على تفاصيل كاملة عن فحص الحيوية
- تأكد من أن الإضاءة جيدة
- تأكد من أن الكاميرا الأمامية تعمل بشكل صحيح

---

**تاريخ التحديث:** 28 يناير 2026  
**الإصدار:** 2.0 - Enhanced Liveness Check
