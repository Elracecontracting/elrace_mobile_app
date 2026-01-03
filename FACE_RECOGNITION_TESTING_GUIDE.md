# 🧪 تعليمات اختبار Face Recognition بعد إزالة Firestore

## 📋 الإعداد

### 1. تنظيف وإعادة بناء المشروع

```bash
cd /Users/loay/StudioProjects/el_race_app
flutter clean
flutter pub get
flutter run
```

---

## 🧪 سيناريوهات الاختبار

### ✅ اختبار 1: تسجيل دخول لأول مرة + Face Registration

**الخطوات:**

1. **تسجيل الدخول:**

   - افتح التطبيق
   - أدخل username و password
   - اضغط Login

2. **تسجيل الوجه:**

   - بعد تسجيل الدخول الناجح، يجب أن تفتح شاشة Face Registration تلقائياً
   - اتبع التعليمات على الشاشة
   - ضع وجهك أمام الكاميرا
   - انتظر حتى يتم الكشف عن الوجه (إطار أخضر)
   - سيتم حفظ face embedding محلياً

3. **التحقق من الحفظ:**
   - ابحث في logs عن:
   ```
   ✅ FACE REGISTERED SUCCESSFULLY!
   👤 User ID: [user_id]
   📊 Embedding Dimensions: 128
   ```

**النتيجة المتوقعة:**

- ✅ تسجيل وجه ناجح
- ✅ حفظ embedding في flutter_secure_storage
- ✅ الانتقال إلى HomeScreen

**في حال الفشل:**

- تحقق من صلاحيات الكاميرا
- تحقق من وجود ملف `mobilefacenet.tflite` في assets
- راجع logs للأخطاء

---

### ✅ اختبار 2: Check-in بالوجه

**الخطوات:**

1. **تسجيل الدخول** (بعد Face Registration)
2. **Check-in:**

   - في HomeScreen، اضغط على زر Check-in
   - يجب أن تفتح الكاميرا للتحقق من الوجه
   - ضع وجهك أمام الكاميرا
   - انتظر التحقق

3. **التحقق من المطابقة:**
   - ابحث في logs عن:
   ```
   🔄 Comparing faces...
   📊 Similarity: 0.92 (> 0.85 threshold)
   ✅ Face matched successfully!
   ```

**النتيجة المتوقعة:**

- ✅ التحقق من الوجه ناجح
- ✅ تسجيل check-in ناجح
- ✅ عرض رسالة نجاح

**في حال الفشل:**

- تحقق من الإضاءة (يفضل إضاءة جيدة)
- تأكد من أن الوجه واضح وكامل في الكاميرا
- راجع threshold في الإعدادات (يجب أن يكون 0.85)

---

### ✅ اختبار 3: Check-out بالوجه

**الخطوات:**

1. بعد Check-in الناجح
2. انتظر قليلاً (دقيقة واحدة على الأقل)
3. اضغط على زر Check-out
4. كرر نفس عملية التحقق من الوجه

**النتيجة المتوقعة:**

- ✅ التحقق من الوجه ناجح
- ✅ تسجيل check-out ناجح

---

### ✅ اختبار 4: التحقق من عدم الاتصال بـ Firestore

**الخطوات:**

1. افتح Android Studio / VS Code
2. افتح Device Monitor أو Logcat
3. قم بـ Clear Logs
4. سجل دخول → سجل وجه → check-in
5. ابحث في logs عن:

**يجب ألا تجد:**

```
❌ FirebaseFirestore
❌ collection('users')
❌ Firestore connection
❌ cloud_firestore
```

**يجب أن تجد:**

```
✅ Saving to flutter_secure_storage
✅ Loading from flutter_secure_storage
✅ FaceEmbeddingStorageService
```

---

### ✅ اختبار 5: الأمان - محاولة وجه مختلف

**الخطوات:**

1. بعد تسجيل وجهك
2. عند Check-in، اطلب من شخص آخر الوقوف أمام الكاميرا

**النتيجة المتوقعة:**

- ❌ رفض التحقق
- ❌ رسالة خطأ: "Face does not match"
- ❌ عدم السماح بـ check-in

**في logs:**

```
📊 Similarity: 0.45 (< 0.85 threshold)
❌ Face does not match!
```

---

### ✅ اختبار 6: FCM Notifications (يجب أن تعمل)

**الخطوات:**

1. تأكد من أن التطبيق يعمل
2. أرسل notification من Firebase Console أو Backend
3. تحقق من استلام الإشعار

**النتيجة المتوقعة:**

- ✅ استلام الإشعار بنجاح
- ✅ عرض الإشعار في Notification Bar

**في logs:**

```
✅ FCM Token: [token]
📩 Notification received: [title]
```

---

## 📊 جدول التحقق

| الاختبار                 | الحالة | ملاحظات |
| ------------------------ | ------ | ------- |
| تسجيل الدخول             | ⬜     |         |
| Face Registration        | ⬜     |         |
| Check-in بالوجه          | ⬜     |         |
| Check-out بالوجه         | ⬜     |         |
| عدم الاتصال بـ Firestore | ⬜     |         |
| رفض وجه مختلف            | ⬜     |         |
| FCM Notifications        | ⬜     |         |

---

## 🐛 حل المشاكل الشائعة

### مشكلة: الكاميرا لا تفتح

**الحل:**

```dart
// تحقق من الصلاحيات في AndroidManifest.xml
<uses-permission android:name="android.permission.CAMERA" />
```

### مشكلة: Face detection failed

**الحل:**

1. تحقق من الإضاءة
2. تأكد من أن الوجه كامل في الإطار
3. تحقق من وجود ملف `mobilefacenet.tflite`

### مشكلة: Face does not match (دائماً)

**الحل:**

1. احذف التطبيق وأعد تثبيته
2. سجل وجهك مرة أخرى بإضاءة أفضل
3. تحقق من threshold (يجب أن يكون 0.85)

### مشكلة: FCM لا يعمل

**الحل:**

```bash
# تحقق من FCM token
String? token = await FirebaseMessaging.instance.getToken();
print('FCM Token: $token');
```

---

## 📝 ملاحظات مهمة

1. **الإضاءة:** يجب أن تكون الإضاءة جيدة لتحقق أفضل
2. **المسافة:** ابقَ على مسافة 30-50 سم من الكاميرا
3. **الثبات:** لا تتحرك كثيراً أثناء التسجيل
4. **الوضوح:** تأكد من أن الوجه واضح وغير مغطى

---

## 🎯 الخطوات التالية

بعد اكتمال جميع الاختبارات:

1. ✅ التأكد من عمل جميع الوظائف
2. ✅ التحقق من عدم وجود أخطاء في logs
3. ✅ بناء APK للاختبار على أجهزة متعددة
4. ✅ نشر التطبيق

```bash
# بناء APK
flutter build apk --release

# بناء iOS (على macOS)
flutter build ios --release
```

---

**تاريخ:** 2025-01-23  
**الحالة:** جاهز للاختبار 🚀
