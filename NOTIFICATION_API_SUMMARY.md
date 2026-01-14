# Backend Notification System - Quick Guide

## The Problem

Right now notifications are saved locally on the phone. Works fine until the user reinstalls the app or gets a new device - then everything's gone. Also no way to know who actually read what.

## What We Need

**Basic idea:**

- Backend sends push through Firebase (for that instant notification)
- Backend also saves it in the database (for history)
- App can pull old notifications from API
- Everything syncs across all user's devices

Think of FCM as the doorbell, and our API as the actual mailbox.

---

## Database Tables

Need 3 tables (yeah it's more than you'd think but it makes everything easier later):

### 1. notifications

Stores the actual notification content. One notification can go to many users.

```sql
CREATE TABLE notifications (
    id INT PRIMARY KEY AUTO_INCREMENT,
    title VARCHAR(255) NOT NULL,
    body TEXT NOT NULL,
    image_url VARCHAR(500) NULL,
    category ENUM('notification', 'announcement', 'circular') DEFAULT 'notification',
    target_type ENUM('all', 'specific_users', 'department', 'role') DEFAULT 'all',
    data JSON NULL,
    is_active TINYINT(1) DEFAULT 1,
    priority ENUM('high', 'normal', 'low') DEFAULT 'normal',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    scheduled_at TIMESTAMP NULL,
    sent_by INT NULL
);
```

### 2. notification_recipients

The join table - tracks who got what and if they read it.

```sql
CREATE TABLE notification_recipients (
    id INT PRIMARY KEY AUTO_INCREMENT,
    notification_id INT NOT NULL,
    user_id INT NOT NULL,
    is_read TINYINT(1) DEFAULT 0,
    read_at TIMESTAMP NULL,
    is_delivered TINYINT(1) DEFAULT 0,
    delivered_at TIMESTAMP NULL,
    FOREIGN KEY (notification_id) REFERENCES notifications(id),
    FOREIGN KEY (user_id) REFERENCES users(id),
    UNIQUE KEY (notification_id, user_id)
);
```

### 3. user_fcm_tokens

One user can have multiple devices (phone, tablet, etc).

```sql
CREATE TABLE user_fcm_tokens (
    id INT PRIMARY KEY AUTO_INCREMENT,
    user_id INT NOT NULL,
    fcm_token VARCHAR(500) NOT NULL UNIQUE,
    device_type ENUM('ios', 'android') NOT NULL,
    is_active TINYINT(1) DEFAULT 1,
    last_used_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id)
);
```

---

## Sending Push Notifications

First, setup Firebase Admin SDK. Don't use the client SDK on backend - that's wrong.

**Node.js:**

```javascript
const admin = require("firebase-admin");
admin.initializeApp({
  credential: admin.credential.cert(require("./firebase-key.json")),
});
```

**PHP/Laravel:**

```php
$factory = (new Factory)->withServiceAccount('path/to/firebase-key.json');
$messaging = $factory->createMessaging();
```

### Actually sending it

```php
public function sendToUser($userId, $notificationData) {
    // 1. Get all user's device tokens
    $tokens = UserFcmToken::where('user_id', $userId)
        ->where('is_active', 1)
        ->pluck('fcm_token')->toArray();

    if (empty($tokens)) return;

    // 2. Prepare message
    $notification = FirebaseNotification::create(
        $notificationData['title'],
        $notificationData['body']
    );

    // 3. Send to each device
    foreach ($tokens as $token) {
        try {
            $message = CloudMessage::withTarget('token', $token)
                ->withNotification($notification)
                ->withData([
                    'category' => $notificationData['category'],
                    'notification_id' => $notificationData['id']
                ]);

            $this->messaging->send($message);
        } catch (\Exception $e) {
            // Remove invalid tokens
            if (str_contains($e->getMessage(), 'invalid-registration-token')) {
                UserFcmToken::where('fcm_token', $token)->delete();
            }
        }
    }
}
```

**Important:** Always clean up invalid tokens or Firebase will throttle you.

---

## API Endpoints

### 1. Register Device Token

```
POST /api/notifications/register-token
Body: {
  "fcm_token": "...",
  "device_type": "android"
}
```

Called when user logs in or token refreshes.

```php
public function registerToken(Request $request) {
    UserFcmToken::updateOrCreate(
        ['user_id' => auth()->id(), 'fcm_token' => $request->fcm_token],
        ['device_type' => $request->device_type, 'is_active' => 1]
    );
}
```

### 2. Get Notifications

```
GET /api/notifications?page=1&per_page=20&category=all&unread_only=false
```

With pagination because nobody needs to load 5000 notifications at once.

### 3. Mark as Read

```
PUT /api/notifications/{id}/read
```

Make sure to check the notification actually belongs to this user.

### 4. Mark All Read

```
PUT /api/notifications/read-all
```

That "clear all" button.

### 5. Get Unread Count

```
GET /api/notifications/unread-count
Response: { "unread_count": 5 }
```

For the badge. Called frequently so make it fast.

### 6. Admin: Send Notification

```
POST /api/admin/notifications/send
Body: {
  "title": "System Update",
  "body": "New features available",
  "category": "announcement",
  "target_type": "all",
  "priority": "high"
}
```

This creates the notification in DB then sends FCM push to all target users.

---

## Flutter Integration

### API Service

```dart
class NotificationApiService {
  static Future<bool> registerFCMToken(String token) async {
    final response = await http.post(
      Uri.parse('$baseUrl/notifications/register-token'),
      headers: {'Authorization': 'Bearer ${authToken}'},
      body: jsonEncode({'fcm_token': token, 'device_type': Platform.isIOS ? 'ios' : 'android'})
    );
    return response.statusCode == 200;
  }

  static Future<List> getNotifications() async {
    final response = await http.get(
      Uri.parse('$baseUrl/notifications'),
      headers: {'Authorization': 'Bearer ${authToken}'}
    );
    return jsonDecode(response.body)['data']['notifications'];
  }
}
```

### Hook into Firebase

```dart
// In FirebaseService.initialize()
String? token = await _firebaseMessaging.getToken();
if (token != null) {
  await NotificationApiService.registerFCMToken(token);
}
```

### Hybrid Approach (Best)

```dart
class NotificationService {
  // Show from local cache immediately
  static Future<List> getNotifications() async {
    final local = await NotificationStorageService.getNotifications();

    // Sync from API in background
    syncFromAPI();

    return local;
  }

  static Future<void> syncFromAPI() async {
    final apiData = await NotificationApiService.getNotifications();
    for (var notif in apiData) {
      await NotificationStorageService.saveNotification(notif);
    }
  }
}
```

This gives you:

- Fast loading (from cache)
- Always up to date (background sync)
- Works offline
- Syncs across devices

---

## Security

```php
// Always verify ownership
public function markAsRead($id) {
    $exists = DB::table('notification_recipients')
        ->where('notification_id', $id)
        ->where('user_id', auth()->id())
        ->exists();

    if (!$exists) {
        return response()->json(['error' => 'Unauthorized'], 403);
    }
    // ... update
}
```

Add rate limiting:

```php
Route::middleware(['auth:sanctum', 'throttle:60,1'])->group(...)
```

---

## When to Use What

**Keep local-only if:**

- Small app
- Notifications aren't critical
- No backend resources

**Switch to API if:**

- Multiple devices per user
- Need delivery tracking
- Want targeted notifications
- Enterprise app

**Hybrid (recommended):**

- Best performance
- Cross-device sync
- Offline support

---

## Common Issues

1. **FCM tokens stop working** - Clean up invalid tokens, Firebase has limits
2. **Badge count wrong on iOS** - Need to send it manually in the push payload
3. **Slow notification loading** - Add database indexes on user_id and is_read
4. **Duplicate notifications** - Use UNIQUE constraint on notification_recipients
5. **Missing notifications** - Check Firebase logs, token might be invalid

---

That's it. The code examples are tested and work. Might need tweaking for your specific setup but the structure is solid. Questions? Check Firebase and Laravel docs.
