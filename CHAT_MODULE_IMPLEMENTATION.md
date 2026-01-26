# Chat Module Implementation Guide

## نظرة عامة (Overview)

تم إنشاء نظام محادثة شبيه بـ WhatsApp متكامل مع نظام تسجيل الدخول الحالي (Odoo Backend).

## الملفات المُنشأة

### 1. التبعيات (Dependencies)

تم إضافة التبعيات التالية في `pubspec.yaml`:

```yaml
firebase_auth: ^5.5.0
cloud_firestore: ^5.6.0
firebase_storage: ^12.4.0
firebase_database: ^11.3.0
record: ^5.1.2
just_audio: ^0.9.40
```

---

### 2. النماذج (Models) - `lib/chat/models/`

| الملف                    | الوصف                                  |
| ------------------------ | -------------------------------------- |
| `chat_user.dart`         | بروفايل المستخدم مع توليد كلمات البحث  |
| `chat.dart`              | وثيقة المحادثة (DM/مجموعة) مع توليد ID |
| `message.dart`           | الرسائل بجميع أنواع الوسائط            |
| `chat_member.dart`       | عضوية المحادثة                         |
| `user_chat.dart`         | فهرس قائمة محادثات المستخدم            |
| `chat_user_session.dart` | جلسة تسجيل الدخول للدردشة              |

---

### 3. الخدمات (Services) - `lib/chat/services/`

| الملف                             | الوصف                                       |
| --------------------------------- | ------------------------------------------- |
| `presence_service.dart`           | حالة التواجد (Online/Offline) ومؤشر الكتابة |
| `firebase_chat_auth_service.dart` | مصادقة Firebase بـ Custom Token             |
| `chat_lifecycle_observer.dart`    | إدارة حالة التواجد مع دورة حياة التطبيق     |
| `voice_recorder_service.dart`     | تسجيل الرسائل الصوتية                       |

---

### 4. المستودعات (Repositories) - `lib/chat/repositories/`

| الملف                  | الوصف                                   |
| ---------------------- | --------------------------------------- |
| `user_repository.dart` | إضافة/تحديث المستخدم، البحث، FCM tokens |
| `chat_repository.dart` | CRUD للمحادثات والرسائل، رفع الوسائط    |

---

### 5. نقاط الدخول الرئيسية

| الملف                              | الوصف                |
| ---------------------------------- | -------------------- |
| `lib/chat/chat.dart`               | تصدير المكتبة        |
| `lib/chat/chat_module_helper.dart` | مساعد التهيئة السهلة |

---

## هيكل البيانات في Firebase

### Firestore Collections

```
users/{uid}
├── odoo_user_id: int
├── employee_id: int?
├── name: string
├── email: string?
├── role_id: int
├── branch_id: int?
├── company_id: int
├── avatar_url: string?
├── last_seen_at: Timestamp?
├── last_login_at: Timestamp
├── created_at: Timestamp
├── updated_at: Timestamp
└── search_keywords: array<string>

chats/{chatId}
├── type: "dm" | "role"
├── created_at: Timestamp
├── updated_at: Timestamp
├── last_message: { text, type, sender_id, created_at }
├── dm_pair: [uidA, uidB] (للـ DM فقط)
├── role_id: int? (للمجموعات)
├── branch_id: int?
├── company_id: int?
└── title: string?

chats/{chatId}/members/{uid}
├── joined_at: Timestamp
├── role_id_snapshot: int?
├── branch_id_snapshot: int?
├── company_id_snapshot: int?
└── muted: bool

chats/{chatId}/messages/{messageId}
├── sender_id: string
├── type: "text" | "image" | "file" | "audio" | "video"
├── text: string?
├── media_url: string?
├── media_path: string?
├── file_name: string?
├── file_size: int?
├── mime_type: string?
├── duration_ms: int?
├── created_at: Timestamp
├── client_msg_id: string
└── status: "sent"

userChats/{uid}/chats/{chatId}
├── type: "dm" | "role"
├── title: string?
├── peer_uid: string?
├── role_id: int?
├── updated_at: Timestamp
├── last_read_at: Timestamp?
├── pinned: bool
└── muted: bool
```

### Realtime Database

```
presence/{uid}
├── online: bool
└── lastChanged: serverTimestamp

typing/{chatId}/{uid}: true/false
```

### Storage

```
chat_media/{chatId}/{messageId}/{filename}
```

---

## قواعد Chat ID

### DM (محادثة خاصة)

```
dm_{min(uidA, uidB)}_{max(uidA, uidB)}
```

مثال: `dm_odoo_100_odoo_200`

### Role Group (مجموعة حسب الدور)

```
role_{roleId}
```

مثال: `role_5`

إذا كان `groupByBranch = true`:

```
role_{roleId}_branch_{branchId}
```

---

## متطلبات Backend

يجب أن يُرجع Backend هذه الحقول في استجابة تسجيل الدخول:

```json
{
  "result": {
    "token": "backend_jwt_token",
    "data": {
      "uid": 123,
      "name": "أحمد محمد",
      "email": "ahmed@example.com",
      "role_id": 5,
      "branch_id": 1,
      "company_id": 1,
      "firebase_uid": "odoo_123",
      "firebase_custom_token": "eyJhbGciOiJSUzI1NiIs..."
    }
  }
}
```

### توليد Firebase Custom Token (في Backend)

```python
# Python example using Firebase Admin SDK
import firebase_admin
from firebase_admin import auth

def generate_custom_token(odoo_user_id, role_id):
    uid = f"odoo_{odoo_user_id}"
    custom_claims = {
        'role_id': role_id,
        'odoo_user_id': odoo_user_id
    }
    token = auth.create_custom_token(uid, custom_claims)
    return token.decode('utf-8')
```

---

## التكامل (Integration)

### تم التكامل تلقائياً في:

1. **`lib/main.dart`** - استعادة جلسة الدردشة عند بدء التطبيق
2. **`lib/ui/presentation/signin/bloc/sign_in_bloc.dart`** - تهيئة الدردشة بعد تسجيل الدخول

### استخدام الدردشة في الكود

```dart
import 'package:el_race/chat/chat.dart';

// التحقق من جاهزية الدردشة
if (ChatModuleHelper.instance.isChatEnabled) {
  // الدردشة جاهزة للاستخدام
}

// بدء محادثة خاصة
final chatId = await ChatRepository.instance.createOrGetDmChat(
  otherUid: 'odoo_456',
  otherName: 'محمد أحمد',
  currentUserName: 'علي حسن',
);

// إرسال رسالة نصية
await ChatRepository.instance.sendText(chatId, 'مرحباً!');

// إرسال صورة
await ChatRepository.instance.sendImage(chatId, imageFile, caption: 'صورة');

// إرسال ملف
await ChatRepository.instance.sendFile(chatId, file);

// إرسال رسالة صوتية
final recording = await VoiceRecorderService.instance.stopRecording();
if (recording?.isValid == true) {
  await ChatRepository.instance.sendVoice(
    chatId,
    recording!.file!,
    durationMs: recording.durationMs,
  );
}

// الاستماع للرسائل
ChatRepository.instance.subscribeToMessages(chatId).listen((messages) {
  // تحديث الواجهة
});

// قائمة المحادثات
ChatRepository.instance.subscribeToUserChats(currentUid).listen((chats) {
  // تحديث قائمة المحادثات
});

// البحث عن مستخدمين
final result = await UserRepository.instance.searchUsers(query: 'أحمد');

// تعليم المحادثة كمقروءة
await ChatRepository.instance.markChatRead(chatId);

// حالة الكتابة
await PresenceService.instance.setTyping(chatId, true);

// الاستماع لحالة التواجد
PresenceService.instance.subscribeToUserPresence(otherUid).listen((status) {
  print(status.online ? 'متصل' : status.lastSeenText);
});
```

---

## الميزات المُنفذة

- ✅ تسجيل الدخول بـ Firebase Custom Token
- ✅ المحادثات الخاصة (DM)
- ✅ مجموعات حسب الدور (Role Groups)
- ✅ الرسائل النصية
- ✅ إرسال الصور
- ✅ إرسال الملفات
- ✅ الرسائل الصوتية
- ✅ حالة التواجد (Online/Offline)
- ✅ مؤشر الكتابة (Typing Indicator)
- ✅ إيصالات القراءة (Read Receipts)
- ✅ البحث عن المستخدمين
- ✅ FCM Topics للمجموعات
- ✅ تخزين FCM Token
- ✅ واجهات المستخدم (Chat UI)
  - ✅ قائمة المحادثات
  - ✅ شاشة الرسائل
  - ✅ شاشة بدء محادثة جديدة
  - ✅ فقاعات الرسائل (نص/صورة/صوت/فيديو/ملف)
  - ✅ شريط الإدخال مع المرفقات
  - ✅ مؤشر الكتابة المتحرك
  - ✅ مؤشرات حالة التواجد

---

## ملاحظات مهمة

1. **لا يوجد حذف رسائل** - حسب المتطلبات
2. **الصور كـ URLs فقط** - لا base64
3. **Chat متوقف بدون Firebase Token** - التطبيق يعمل طبيعي، فقط الدردشة معطلة
4. **groupByBranch = false** - افتراضياً المجموعات حسب الدور فقط

---

## الخطوات التالية

1. إضافة `firebase_custom_token` و `firebase_uid` في استجابة Backend
2. تفعيل Firestore Security Rules
3. إضافة Cloud Functions لإرسال الإشعارات (Push Notifications)

---

## واجهات المستخدم (UI) - `lib/ui/chat/`

### الشاشات الرئيسية

| الملف                   | الوصف                             |
| ----------------------- | --------------------------------- |
| `chat_list_screen.dart` | قائمة المحادثات مع مؤشر التواجد   |
| `chat_screen.dart`      | شاشة الرسائل (إرسال/استقبال)      |
| `new_chat_screen.dart`  | البحث عن مستخدم لبدء محادثة جديدة |

### المكونات (Widgets) - `lib/ui/chat/widgets/`

| الملف                     | الوصف                                   |
| ------------------------- | --------------------------------------- |
| `message_bubble.dart`     | فقاعة الرسالة (نص/صورة/صوت/فيديو/ملف)   |
| `chat_input_bar.dart`     | شريط الإدخال مع أزرار الوسائط           |
| `typing_indicator.dart`   | مؤشر "يكتب..." المتحرك                  |
| `chat_avatar.dart`        | صورة المستخدم/المجموعة مع الأحرف الأولى |
| `presence_indicator.dart` | مؤشر حالة التواجد (متصل/غير متصل)       |

### استخدام واجهات الدردشة

```dart
import 'package:el_race/ui/chat/chat_ui.dart';

// الانتقال لقائمة المحادثات
Navigator.push(
  context,
  MaterialPageRoute(builder: (context) => const ChatListScreen()),
);

// الانتقال لمحادثة معينة
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => ChatScreen(
      chatId: 'dm_odoo_100_odoo_200',
      title: 'أحمد محمد',
      chatType: ChatType.dm,
      peerUid: 'odoo_200',
    ),
  ),
);

// البحث عن مستخدم جديد
Navigator.push(
  context,
  MaterialPageRoute(builder: (context) => const NewChatScreen()),
);
```

---

## هيكل الملفات النهائي

```
lib/chat/
├── chat.dart                          # Main export
├── chat_module_helper.dart            # Easy initialization
├── models/
│   ├── models.dart                    # Barrel export
│   ├── chat_user.dart
│   ├── chat.dart
│   ├── message.dart
│   ├── chat_member.dart
│   ├── user_chat.dart
│   └── chat_user_session.dart
├── repositories/
│   ├── repositories.dart              # Barrel export
│   ├── user_repository.dart
│   └── chat_repository.dart
└── services/
    ├── services.dart                  # Barrel export
    ├── presence_service.dart
    ├── firebase_chat_auth_service.dart
    ├── chat_lifecycle_observer.dart
    └── voice_recorder_service.dart

lib/ui/chat/
├── chat_ui.dart                       # Barrel export
├── chat_list_screen.dart              # قائمة المحادثات
├── chat_screen.dart                   # شاشة الرسائل
├── new_chat_screen.dart               # بدء محادثة جديدة
└── widgets/
    ├── widgets.dart                   # Barrel export
    ├── message_bubble.dart            # فقاعة الرسالة
    ├── chat_input_bar.dart            # شريط الإدخال
    ├── typing_indicator.dart          # مؤشر الكتابة
    ├── chat_avatar.dart               # صورة المستخدم
    └── presence_indicator.dart        # مؤشر التواجد
```
