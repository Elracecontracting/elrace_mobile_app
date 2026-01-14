# Camera Queue Implementation - تطبيق نظام الطابور للكاميرا

## المشكلة الأصلية

عند التقاط صورة من الكاميرا في الـ Bottom Bar، كان هناك تأخير طويل في حفظ الصورة بسبب:

- رسم اللوغو على الصورة
- إضافة التاريخ والوقت
- حفظ الصورة في الاستديو

هذا التأخير كان يمنع المستخدم من التقاط صور متتالية بسرعة.

## الحل المُنفذ

### 1. Image Queue Service

تم إنشاء `ImageQueueService` في:

```
lib/ui/presentation/camera/services/image_queue_service.dart
```

**الميزات:**

- ✅ **Queue System**: نظام طابور لإدارة الصور المُلتقطة
- ✅ **Background Processing**: معالجة الصور في الخلفية دون حظر واجهة المستخدم
- ✅ **Stream Updates**: تحديثات مباشرة لعدد الصور في الطابور وحالة المعالجة
- ✅ **Non-blocking**: التقاط الصور يحدث فوراً دون انتظار

### 2. آلية العمل

#### عند الضغط على زر التصوير:

1. **التقاط فوري** (Instant Capture):

   ```dart
   final file = await _controller!.takePicture();
   ```

2. **إضافة للطابور مباشرة**:

   ```dart
   await _imageQueueService.addImageToQueue(
     imagePath: file.path,
     currentDate: captureDate,
     currentTime: captureTime,
     logoBytes: _logoBytes,
   );
   ```

3. **المعالجة في الخلفية**:

   - رسم اللوغو
   - إضافة التاريخ والوقت
   - الحفظ في الاستديو (Album: RCC)

4. **تنظيف الملفات المؤقتة** بعد الحفظ

### 3. UI Feedback

تم إضافة مؤشر في الواجهة يُظهر:

- عدد الصور في الطابور: `📸 X photos in queue`
- حالة المعالجة: `Processing X/Y...`
- تأكيد الحفظ: `Saved X photos ✓`

```dart
/// Processing Status Indicator
if (_processingStatusText.isNotEmpty || _pendingImagesCount > 0)
  Container(
    child: Row(
      children: [
        CircularProgressIndicator(...), // أثناء المعالجة
        Text(_processingStatusText),
      ],
    ),
  ),
```

### 4. التحديثات في Camera Selection Screen

**الملف:** `lib/ui/presentation/camera/camera_selection_screen.dart`

**التغييرات:**

- إضافة `ImageQueueService` instance
- Stream subscriptions للاستماع لتحديثات الطابور
- تحديث `_takePicture()` لاستخدام Queue بدلاً من المعالجة المباشرة
- إضافة UI indicator لعرض حالة الطابور

## الفوائد

### للمستخدم:

- ⚡ **سرعة فائقة**: يمكن التقاط عدة صور متتالية بسرعة
- 👁️ **Feedback واضح**: معرفة عدد الصور المُلتقطة وحالة المعالجة
- 🎯 **لا انتظار**: عدم الحاجة للانتظار بعد كل صورة

### للنظام:

- 🔄 **معالجة منظمة**: الصور تُعالج واحدة تلو الأخرى بشكل منظم
- 💾 **إدارة ذاكرة أفضل**: تنظيف الملفات المؤقتة تلقائياً
- 🛡️ **معالجة الأخطاء**: استمرار المعالجة حتى لو فشلت صورة واحدة
- 📊 **Scalable**: يمكن إضافة المزيد من الصور دون مشاكل

## كيفية الاستخدام

1. **فتح الكاميرا**: من الـ Bottom Bar
2. **التقاط صور متتالية**: اضغط على زر الكاميرا عدة مرات بسرعة
3. **مراقبة التقدم**: شاهد المؤشر أسفل الشاشة
4. **الصور تُحفظ تلقائياً**: في الخلفية دون تأثير على التصوير

## الكود المهم

### إضافة صورة للطابور:

```dart
await _imageQueueService.addImageToQueue(
  imagePath: file.path,
  currentDate: captureDate,
  currentTime: captureTime,
  logoBytes: _logoBytes,
);
```

### الاستماع لتحديثات الطابور:

```dart
_queueCountSubscription = _imageQueueService.queueCount.listen((count) {
  setState(() => _pendingImagesCount = count);
});
```

### معالجة الصور في الخلفية:

```dart
Future<void> _processQueue() async {
  while (_queue.isNotEmpty) {
    final task = _queue.removeAt(0);
    final composedPath = await _composeWithOverlay(task);
    await Gal.putImage(composedPath ?? task.imagePath, album: 'RCC');
    // تنظيف + تحديثات
  }
}
```

## ملاحظات تقنية

- **Singleton Pattern**: `ImageQueueService` هو singleton لضمان طابور واحد فقط
- **Stream Controllers**: للتواصل بين Service والـ UI
- **Async Processing**: المعالجة تحدث بشكل غير متزامن
- **Error Handling**: معالجة الأخطاء دون توقف الطابور

## الاختبار

للتأكد من عمل النظام:

1. افتح الكاميرا من Bottom Bar
2. التقط 5-10 صور بسرعة متتالية
3. لاحظ:
   - سرعة استجابة الزر
   - ظهور المؤشر مع عدد الصور
   - تحديث العداد أثناء المعالجة
   - الصور تُحفظ في Gallery/RCC

---

**تم التنفيذ بنجاح ✅**
