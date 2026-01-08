# Global Search API - Petty Cash Data Issue ⚠️

## المشكلة الحالية

عند البحث عن Petty Cash في Global Search، الـ API يُرجع بيانات ناقصة:

### البيانات الحالية من API:

```json
{
  "id": 10119,
  "name": "RCCEXPSH-2026-00060"
}
```

### البيانات المطلوبة:

```json
{
  "id": 10119,
  "name": "RCCEXPSH-2026-00060",
  "state": "draft",
  "date": "2026-01-08",
  "total_amount": 1500.0,
  "create_date": "2026-01-08 10:30:00",
  "payment_date": "2026-01-10"
}
```

## الحقول المطلوبة

| Field          | Type   | Description                        | Required       |
| -------------- | ------ | ---------------------------------- | -------------- |
| `id`           | int    | معرف السجل                         | ✅ موجود       |
| `name`         | string | رقم المصروف                        | ✅ موجود       |
| `state`        | string | الحالة (draft, approved, rejected) | ❌ ناقص        |
| `date`         | string | تاريخ المصروف                      | ❌ ناقص        |
| `total_amount` | float  | المبلغ الإجمالي                    | ❌ ناقص        |
| `create_date`  | string | تاريخ الإنشاء                      | ❌ ناقص (بديل) |
| `payment_date` | string | تاريخ الدفع                        | ❌ ناقص (بديل) |

## الإصلاح المطلوب في Backend

في ملف API الخاص بالـ Global Search على Backend:

```python
# File: /api/global_search.py or similar

def search_petty_cash(keyword, limit):
    # Current implementation (WRONG)
    results = self.env['account.expense'].search([
        ('name', 'ilike', keyword)
    ], limit=limit)

    return [{
        'id': r.id,
        'name': r.name
    } for r in results]

    # Should be (CORRECT)
    results = self.env['account.expense'].search([
        ('name', 'ilike', keyword)
    ], limit=limit)

    return [{
        'id': r.id,
        'name': r.name,
        'state': r.state,
        'date': r.date.strftime('%Y-%m-%d') if r.date else False,
        'total_amount': r.total_amount,
        'create_date': r.create_date.strftime('%Y-%m-%d %H:%M:%S') if r.create_date else False,
        'payment_date': r.payment_date.strftime('%Y-%m-%d') if r.payment_date else False,
    } for r in results]
```

## الحل المؤقت في Frontend

تم تطبيق حل مؤقت في Frontend لعرض البطاقات بشكل أفضل حتى عند نقص البيانات:

1. عرض `--` للحقول الفارغة بدلاً من إخفاءها
2. إضافة Debug Logs لمراقبة البيانات القادمة
3. تحسين Layout للبطاقات
4. إضافة تحذيرات في Console عند نقص البيانات

## كيفية التحقق من الإصلاح

بعد إصلاح Backend، قم بالتالي:

1. ابحث عن "RCCEXPSH" في Global Search
2. تأكد من ظهور:

   - ✅ اسم المصروف
   - ✅ الحالة (Draft/Approved/etc)
   - ✅ التاريخ
   - ✅ المبلغ

3. تحقق من Console Logs:

```
[PettyCash Card] ID: 10119
[PettyCash Card] Title: RCCEXPSH-2026-00060
[PettyCash Card] Status: DRAFT
[PettyCash Card] Date: 08/01/26
[PettyCash Card] Amount: 1500.00
```

## الملفات المعدلة

- ✅ `/lib/ui/widgets/global_search_screen.dart` - تحسين عرض البطاقات
- ⏳ Backend API - **يحتاج إصلاح**

## التاريخ

- 2026-01-08: تم اكتشاف المشكلة
- 2026-01-08: تم تطبيق حل مؤقت في Frontend
- ⏳ في انتظار إصلاح Backend
