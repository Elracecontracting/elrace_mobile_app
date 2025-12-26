# نظام التقارير - Reports System

## توثيق شامل ومفصل

---

## 📋 نظرة عامة (Overview)

نظام التقارير في تطبيق El Race هو نظام متكامل لإنشاء وإدارة التقارير الميدانية. يتيح للموظفين إنشاء تقارير تحتوي على صور، نصوص، مواقع GPS، وتصديرها كملفات PDF.

### الهدف الرئيسي

- إنشاء تقارير ميدانية احترافية
- إدارة المجلدات والتقارير بشكل هرمي
- التقاط الصور وإضافة الملاحظات
- تصدير التقارير بصيغة PDF
- مزامنة البيانات مع السيرفر

---

## 🏗️ البنية المعمارية (Architecture)

### الهيكل العام

```
lib/report_module/
├── core/                    # المكونات الأساسية
│   ├── constants/          # الثوابت (ألوان، نصوص)
│   └── utils/              # أدوات مساعدة
├── data/                    # طبقة البيانات
│   ├── models/             # نماذج البيانات
│   ├── provider/           # مزود الحالة (State Management)
│   ├── repositories/       # مستودعات البيانات
│   └── services/           # الخدمات (API, Hive, PDF)
└── presentation/            # طبقة العرض
    ├── bottom_sheets/      # القوائم السفلية
    ├── dialogs/            # مربعات الحوار
    ├── screens/            # الشاشات
    └── widgets/            # المكونات القابلة لإعادة الاستخدام
```

---

## 📦 نماذج البيانات (Data Models)

### 1. ReportModel

```dart
@HiveType(typeId: 105)
class ReportModel extends HiveObject {
  @HiveField(0) final String id;
  @HiveField(1) final String name;
  @HiveField(2) final String companyId;
  @HiveField(3) final DateTime createdAt;
  @HiveField(4) final String folderId;
  @HiveField(5) final DateTime updatedAt;
}
```

**الوصف:**

- `id`: معرف التقرير الفريد
- `name`: اسم التقرير
- `companyId`: معرف الشركة
- `folderId`: معرف المجلد الذي ينتمي إليه
- `createdAt` / `updatedAt`: تواريخ الإنشاء والتعديل

**الاستخدام:**

- تمثيل التقرير الأساسي
- التخزين المحلي باستخدام Hive
- المزامنة مع API

---

### 2. FolderModel

```dart
class FolderModel {
  final String id;
  final String folderName;
  final String description;
  final String companyId;
  final DateTime createdAt;
  final DateTime updatedAt;
}
```

**الوصف:**

- يمثل مجلد يحتوي على عدة تقارير
- يستخدم لتنظيم التقارير بشكل هرمي

---

### 3. ReportItemModel

```dart
@HiveType(typeId: 104)
class ReportItemModel extends HiveObject {
  @HiveField(0) final String id;
  @HiveField(1) final String reportId;
  @HiveField(2) final String type;        // "image" | "text" | "location"
  @HiveField(3) final String image;       // صورة أو base64
  @HiveField(4) final String location;    // GPS coordinates
  @HiveField(5) final String description; // وصف
  @HiveField(6) final DateTime createdAt;
  @HiveField(7) final DateTime updatedAt;
}
```

**الأنواع المدعومة:**

- `"image"`: عنصر صورة
- `"text"`: عنصر نصي
- `"location"`: موقع GPS

---

### 4. CoverPageModel

```dart
@HiveType(typeId: 102)
class CoverPageModel extends HiveObject {
  @HiveField(0) final String empId;
  @HiveField(1) final String title;
  @HiveField(2) final String? description;
  @HiveField(3) final String? id;
  @HiveField(4) final DateTime? createdAt;
  @HiveField(5) final DateTime? updatedAt;
}
```

**الوصف:**

- صفحة الغلاف للتقرير
- تحتوي على عنوان ووصف التقرير

---

### 5. ReportDetailModel

```dart
@HiveType(typeId: 103)
class ReportDetailModel extends HiveObject {
  @HiveField(0) final ReportModel report;
  @HiveField(1) final CoverPageModel? coverPage;
  @HiveField(2) final List<ReportItemModel> items;
}
```

**الوصف:**

- يجمع كل مكونات التقرير معاً
- التخزين المحلي الكامل للتقرير
- يستخدم عند تحرير وعرض التقرير

---

### 6. ReportPdfModel

```dart
class ReportPdfModel {
  final String id;
  final String reportId;
  final String folderId;
  final String fileName;
  final String filePath;
  final DateTime createdAt;
}
```

**الوصف:**

- يمثل ملف PDF المصدر من التقرير
- يحتوي على رابط التحميل ومعلومات الملف

---

## 🔄 مزود الحالة (ReportsProvider)

### المسؤوليات الرئيسية

#### 1. إدارة المجلدات (Folders Management)

**إنشاء مجلد:**

```dart
Future<void> createFolder({
  required String title,
  String description = ""
}) async
```

- API Endpoint: `/api/create_report_folder`
- يرسل: `emp_id`, `folder_name`, `description`, `company_id`
- يعيد: `FolderModel` جديد
- يضيف المجلد إلى القائمة المحلية

**جلب جميع المجلدات:**

```dart
Future<void> fetchAllFolders() async
```

- API Endpoint: `/reports/list`
- يرسل: `emp_id`, `company_id`
- يخزن في `_folders` list
- يعرض في الشاشة الرئيسية

---

#### 2. إدارة التقارير (Reports Management)

**إنشاء تقرير:**

```dart
Future<void> createReport({
  required String title,
  required String folderID
}) async
```

- API Endpoint: `/api/create_report`
- يرسل: `emp_id`, `name`, `company_id`, `folder_id`
- يضيف التقرير للقائمة المحلية

**جلب تقارير مجلد محدد:**

```dart
Future<void> fetchAllReports({
  required String folderID
}) async
```

- API Endpoint: `/api/get_folder_report_list`
- يجلب كل التقارير داخل مجلد

**تحديث اسم تقرير:**

```dart
Future<void> updateReport({
  required String name,
  required String reportId
}) async
```

- API Endpoint: `/reports/update`

**حذف تقرير:**

```dart
Future<void> deleteReport({
  required String reportId
}) async
```

- API Endpoint: `/reports/delete`
- يحذف محلياً ومن السيرفر

---

#### 3. إدارة تفاصيل التقرير (Report Details)

**جلب تفاصيل التقرير:**

```dart
Future<ReportDetailModel?> getReportDetail(ReportModel report) async
```

- يستخدم Hive للتخزين المحلي
- Key: `"$empID-${report.folderId}-${report.id}"`
- يعيد: `ReportDetailModel` أو `null`

**تحديث تفاصيل التقرير:**

```dart
Future<void> updateReportDetail(ReportDetailModel report) async
```

- يحفظ في Hive محلياً
- يحفظ Cover Page + Items

**حذف صفحة الغلاف:**

```dart
Future<bool> deleteCoverPage(ReportDetailModel report) async
```

- يحدث التقرير في Hive بدون cover page

---

#### 4. إدارة ملفات PDF

**جلب قائمة PDFs:**

```dart
Future<List<ReportPdfModel>> fetchReports({
  required String empId,
  required String reportId,
  required String folderId
}) async
```

- API Endpoint: `/api/get_report_list`
- يعيد قائمة بجميع PDFs المصدرة

**رفع PDF جديد:**

```dart
Future<bool> uploadReportPdf({
  required String empId,
  required Uint8List pdfBytes,
  required String reportId,
  required String folderId,
  required String fileName,
}) async
```

- API Endpoint: `/api/upload_site_report`
- يرفع PDF كـ MultipartFile
- يعيد `true` في حالة النجاح

---

## 🎨 واجهة المستخدم (UI Flow)

### 1. الشاشة الرئيسية (Report Home Screen)

**الموقع:** `lib/report_module/presentation/screens/report_listing/report_app_home_screen.dart`

**المكونات:**

- قائمة المجلدات
- زر إنشاء مجلد جديد
- عرض عدد التقارير لكل مجلد

**التفاعل:**

- الضغط على مجلد → الانتقال إلى قائمة التقارير
- زر `+` → إنشاء مجلد جديد

---

### 2. شاشة التقارير داخل المجلد (Folder Reports Screen)

**الموقع:** `lib/report_module/presentation/screens/report_listing/folder_reports_screen.dart`

**المكونات:**

- قائمة التقارير داخل المجلد
- زر إنشاء تقرير جديد
- عرض تاريخ إنشاء كل تقرير

**التفاعل:**

- الضغط على تقرير → فتح تفاصيل التقرير
- الضغط المطول → خيارات (تعديل / حذف)

---

### 3. شاشة تفاصيل التقرير (Report Detail Screen)

**الموقع:** `lib/report_module/presentation/screens/report_detail/report_detail.dart`

**المكونات:**

- Cover Page (اختياري)
- قائمة Report Items (صور، نصوص، مواقع)
- أزرار: إضافة صورة، إضافة نص، تصدير PDF
- Bottom AppBar للتحكم السريع

**التفاعل:**

- زر كاميرا → فتح شاشة التقاط الصور
- زر نص → إضافة ملاحظة نصية
- زر موقع → حفظ GPS الحالي
- زر تصدير → تحويل التقرير إلى PDF

---

### 4. شاشة الكاميرا (Camera Screen)

**الموقع:** `lib/report_module/presentation/screens/report_detail/camera_screen.dart`

**الميزات:**

- التقاط صورة بالكاميرا
- اختيار صورة من المعرض
- معاينة الصورة قبل الحفظ
- إضافة وصف للصورة

---

### 5. شاشة تحرير الصورة (Image Editing Screen)

**الموقع:** `lib/report_module/presentation/screens/report_detail/image_editing_screen.dart`

**الأدوات المتاحة:**

- الرسم على الصورة
- إضافة نصوص
- أشكال هندسية
- قص وتدوير
- حفظ التعديلات

---

### 6. شاشة معاينة PDF (PDF Preview Screen)

**الموقع:** `lib/report_module/presentation/screens/report_detail/pdf_preview_screen.dart`

**الوظائف:**

- معاينة PDF قبل الحفظ
- حفظ محلياً
- رفع إلى السيرفر
- مشاركة

---

### 7. شاشة تاريخ PDFs (PDF History Screen)

**الموقع:** `lib/report_module/presentation/screens/report_detail/pdf_history_screen.dart`

**المكونات:**

- قائمة جميع PDFs المصدرة
- تاريخ كل ملف
- خيارات: تحميل، مشاركة، حذف

---

## 🔌 خدمات API (API Services)

### Base URL

```dart
static String baseUrl = "https://test.elrace.com" (أو ما يتم تعيينه)
```

### Authentication

يستخدم النظام:

- `emp_id`: معرف الموظف
- `company_id`: معرف الشركة
- يتم جلبهما من `SharedPreferences` عند تسجيل الدخول

---

### API Endpoints

#### 1. المجلدات (Folders)

**إنشاء مجلد:**

```
POST /api/create_report_folder
Body: {
  emp_id: string,
  folder_name: string,
  description: string,
  company_id: string
}
Response: { data: FolderModel }
```

**جلب المجلدات:**

```
POST /reports/list
Body: {
  emp_id: string,
  company_id: string
}
Response: { data: [FolderModel] }
```

---

#### 2. التقارير (Reports)

**إنشاء تقرير:**

```
POST /api/create_report
Body: {
  emp_id: string,
  name: string,
  company_id: string,
  folder_id: string
}
Response: { data: ReportModel }
```

**جلب تقارير المجلد:**

```
POST /api/get_folder_report_list
Body: {
  emp_id: string,
  company_id: string,
  folder_id: string
}
Response: { data: [ReportModel] }
```

**تحديث تقرير:**

```
POST /reports/update
Body: {
  emp_id: string,
  report_id: string,
  name: string
}
Response: { data: ReportModel }
```

**حذف تقرير:**

```
POST /reports/delete
Body: {
  emp_id: string,
  report_id: string
}
Response: { status: "success" }
```

---

#### 3. ملفات PDF

**جلب قائمة PDFs:**

```
POST /api/get_report_list
Body: {
  emp_id: string,
  report_id: string,
  folder_id: string
}
Response: { data: [ReportPdfModel] }
```

**رفع PDF:**

```
POST /api/upload_site_report?folder_id={id}&file_name={name}
Body: MultipartFile
Fields: {
  emp_id: string,
  report_id: string,
  folder_id: string,
  file_name: string,
  file: binary
}
Response: { status: "success" }
```

---

## 💾 التخزين المحلي (Local Storage - Hive)

### Hive Service

**الموقع:** `lib/report_module/data/services/report_hive_service.dart`

### Boxes المستخدمة

**1. Report Details Box:**

```dart
Box<ReportDetailModel> getReportDetailBox()
Key Format: "$empID-$folderId-$reportId"
```

- يخزن التقرير الكامل مع كل العناصر
- يتم تحديثه عند كل إضافة/حذف

**2. Models Registration:**

```dart
Hive.registerAdapter(ReportModelAdapter());           // typeId: 105
Hive.registerAdapter(CoverPageModelAdapter());        // typeId: 102
Hive.registerAdapter(ReportItemModelAdapter());       // typeId: 104
Hive.registerAdapter(ReportDetailModelAdapter());     // typeId: 103
```

---

## 📄 خدمة PDF (PDF Service)

**الموقع:** `lib/report_module/data/services/pdf_service.dart`

### الوظائف الرئيسية

**1. توليد PDF من التقرير:**

```dart
Future<Uint8List> generatePdfFromReport(ReportDetailModel report) async
```

- يحول `ReportDetailModel` إلى PDF
- يضيف Cover Page إن وجدت
- يضيف جميع الصور والنصوص
- يعيد PDF كـ `Uint8List`

**2. إضافة Cover Page:**

```dart
void addCoverPage(pw.Document pdf, CoverPageModel cover)
```

- يضيف صفحة غلاف بعنوان ووصف
- تنسيق احترافي

**3. إضافة عناصر التقرير:**

```dart
void addReportItems(pw.Document pdf, List<ReportItemModel> items)
```

- يضيف كل عنصر حسب نوعه:
  - `image`: صورة
  - `text`: فقرة نصية
  - `location`: خريطة GPS

**4. الحفظ المحلي:**

```dart
Future<String> savePdfLocally(Uint8List pdfBytes, String fileName) async
```

- يحفظ PDF في مجلد التطبيق
- يعيد المسار الكامل

---

## 🔧 مثال على سير العمل (Workflow Example)

### سيناريو: إنشاء تقرير ميداني كامل

**الخطوة 1: إنشاء مجلد**

```dart
await reportProvider.createFolder(
  title: "مشروع البناء - الموقع أ",
  description: "تقارير المراقبة اليومية"
);
```

**الخطوة 2: إنشاء تقرير**

```dart
await reportProvider.createReport(
  title: "تقرير يوم 26 ديسمبر",
  folderID: folder.id
);
```

**الخطوة 3: إضافة Cover Page**

```dart
CoverPageModel cover = CoverPageModel(
  empId: empID,
  title: "تقرير المراقبة اليومية",
  description: "فحص شامل للموقع"
);
```

**الخطوة 4: إضافة عناصر**

```dart
// إضافة صورة
ReportItemModel imageItem = ReportItemModel(
  id: uuid.v4(),
  reportId: report.id,
  type: "image",
  image: base64Image,
  location: "GPS: 24.7136, 46.6753",
  description: "واجهة المبنى الرئيسية",
  createdAt: DateTime.now(),
  updatedAt: DateTime.now()
);

// إضافة نص
ReportItemModel textItem = ReportItemModel(
  id: uuid.v4(),
  reportId: report.id,
  type: "text",
  image: "",
  location: "",
  description: "تم إنجاز 80% من أعمال الأساسات",
  createdAt: DateTime.now(),
  updatedAt: DateTime.now()
);
```

**الخطوة 5: حفظ محلياً**

```dart
ReportDetailModel detail = ReportDetailModel(
  report: report,
  coverPage: cover,
  items: [imageItem, textItem]
);
await reportProvider.updateReportDetail(detail);
```

**الخطوة 6: تصدير PDF**

```dart
Uint8List pdfBytes = await PdfService.generatePdfFromReport(detail);
String fileName = "report_${report.id}_${DateTime.now().millisecondsSinceEpoch}.pdf";
```

**الخطوة 7: رفع إلى السيرفر**

```dart
bool success = await reportProvider.uploadReportPdf(
  empId: empID,
  pdfBytes: pdfBytes,
  reportId: report.id,
  folderId: report.folderId,
  fileName: fileName
);
```

---

## 🎯 ميزات متقدمة (Advanced Features)

### 1. التخزين المؤقت الذكي

- جميع التقارير تخزن محلياً في Hive
- عدم الحاجة لإنترنت للعمل
- المزامنة التلقائية عند الاتصال

### 2. معالجة الصور

- التقاط صور عالية الجودة
- ضغط تلقائي لتقليل الحجم
- تحرير الصور قبل الحفظ

### 3. GPS Integration

- حفظ موقع كل صورة/عنصر
- عرض على الخريطة في PDF
- دعم الأوفلاين

### 4. PDF Customization

- إضافة شعار الشركة
- تنسيقات متعددة
- دعم اللغة العربية

---

## 🐛 معالجة الأخطاء (Error Handling)

### أخطاء الشبكة

```dart
Future<Map<String, dynamic>> _handleResponse(
  http.StreamedResponse response,
  {bool alwaysShowMessage = false}
) async {
  final res = await response.stream.bytesToString();
  final jsonData = json.decode(res);

  if (jsonData['status'] == "upcoming") {
    showFlushBar(context, message: jsonData['message']);
    return {};
  }

  if (jsonData['status'] != "success") {
    showFlushBar(context, message: jsonData['message']);
  }

  return jsonData;
}
```

### أخطاء Hive

```dart
try {
  await reportDetailBox.put(key, report);
} catch (e) {
  debugPrint('Hive Error: $e');
  // Fallback to memory storage
}
```

---

## 📱 دعم الأجهزة (Device Support)

- ✅ Android 5.0+
- ✅ iOS 11.0+
- ✅ الكاميرا والمعرض
- ✅ GPS/Location Services
- ✅ التخزين المحلي
- ✅ مشاركة الملفات

---

## 🔐 الأمان (Security)

### 1. المصادقة

- كل طلب يتطلب `emp_id`
- Bearer Token للـ API (إن وجد)

### 2. تشفير البيانات

- Hive مشفر محلياً
- HTTPS للاتصالات

### 3. صلاحيات الوصول

- الموظف يرى تقاريره فقط
- المدير يرى تقارير فريقه

---

## 📊 الأداء (Performance)

### تحسينات مطبقة

- Lazy Loading للصور
- Caching ذكي
- Batch Updates لـ Hive
- Compression للصور
- Pagination للقوائم

---

## 🚀 خطط مستقبلية (Future Plans)

1. **التعاون الجماعي:**

   - مشاركة التقارير بين الموظفين
   - التعليقات والملاحظات

2. **القوالب الجاهزة:**

   - قوالب تقارير محددة مسبقاً
   - حقول مخصصة

3. **التحليلات:**

   - إحصائيات عن التقارير
   - Dashboard إداري

4. **التوقيعات الإلكترونية:**
   - توقيع الموظف
   - ختم الشركة

---

## 💡 نصائح للمطورين (Developer Tips)

### 1. إضافة نوع عنصر جديد

```dart
// في ReportItemModel
if (type == "your_new_type") {
  // Handle new type
}
```

### 2. تخصيص PDF

```dart
// في PdfService
void addCustomElement(pw.Document pdf) {
  pdf.addPage(
    pw.Page(
      build: (context) => pw.Center(
        child: pw.Text('Custom Content')
      )
    )
  );
}
```

### 3. إضافة فلترة

```dart
List<ReportModel> filterByDate(DateTime date) {
  return _reports.where(
    (r) => r.createdAt.day == date.day
  ).toList();
}
```

---

## 📞 الدعم والمساعدة

للأسئلة والمشاكل:

- راجع الكود في `lib/report_module/`
- تحقق من Logs في `debugPrint`
- اختبر API باستخدام Postman

---

## ✅ Checklist للتنفيذ

عند إضافة ميزة جديدة:

- [ ] تحديث Models
- [ ] تحديث API في ReportsProvider
- [ ] تحديث UI Screens
- [ ] اختبار التخزين المحلي
- [ ] اختبار المزامنة مع السيرفر
- [ ] تحديث التوثيق

---

**آخر تحديث:** 26 ديسمبر 2025  
**الإصدار:** 1.0.0  
**الحالة:** قيد التطوير النشط ✅
