# Backend Notification API Development Guide - Detailed Documentation

## 📋 Table of Contents

1. [Overview](#overview)
2. [Database Structure](#database-structure)
3. [Sending Notifications via Firebase](#sending-notifications-via-firebase)
4. [Required API Endpoints](#required-api-endpoints)
5. [Code Examples](#code-examples)
6. [Security and Permissions](#security-and-permissions)
7. [Flutter Integration](#flutter-integration)

---

## 🎯 Overview

### Core Concept:

1. **Backend sends notification** via Firebase Cloud Messaging (FCM)
2. **Backend stores notification** in database
3. **Flutter receives notification** via FCM
4. **Flutter retrieves notifications** from Backend API
5. **Synchronization** across different devices for the same user

---

## Database Setup

You'll need 3 tables. I know it seems like overkill but trust me, this structure makes everything easier later.

### notifications table

```sql
CREATE TABLE notifications (
    id INT PRIMARY KEY AUTO_INCREMENT,
    title VARCHAR(255) NOT NULL,
    body TEXT NOT NULL,
    image_url VARCHAR(500) NULL,
    category ENUM('notification', 'announcement', 'circular') DEFAULT 'notification',

    -- For targeted notifications
    target_type ENUM('all', 'specific_users', 'department', 'role') DEFAULT 'all',

    -- Additional data (JSON)
    data JSON NULL,

    -- Status
    is_active TINYINT(1) DEFAULT 1,
    priority ENUM('high', 'normal', 'low') DEFAULT 'normal',

    -- Timestamps
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    scheduled_at TIMESTAMP NULL,
    expires_at TIMESTAMP NULL,

    -- Who sent the notification
    sent_by INT NULL,
    FOREIGN KEY (sent_by) REFERENCES users(id)
);

-- Indexes for performance
CREATE INDEX idx_category ON notifications(category);
CREATE INDEX idx_created_at ON notifications(created_at);
CREATE INDEX idx_target_type ON notifications(target_type);
```

This table stores the actual notification content. One notification can go to multiple users.

### notification_recipients table

```sql
CREATE TABLE notification_recipients (
    id INT PRIMARY KEY AUTO_INCREMENT,
    notification_id INT NOT NULL,
    user_id INT NOT NULL,

    -- Read status
    is_read TINYINT(1) DEFAULT 0,
    read_at TIMESTAMP NULL,

    -- Delivery status
    is_delivered TINYINT(1) DEFAULT 0,
    delivered_at TIMESTAMP NULL,

    -- View count
    view_count INT DEFAULT 0,
    last_viewed_at TIMESTAMP NULL,

    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    FOREIGN KEY (notification_id) REFERENCES notifications(id) ON DELETE CASCADE,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,

    UNIQUE KEY unique_notification_user (notification_id, user_id)
);

-- Indexes
CREATE INDEX idx_user_read ON notification_recipients(user_id, is_read);
CREATE INDEX idx_notification ON notification_recipients(notification_id);
```

### Table: `user_fcm_tokens`

```sql
CREATE TABLE user_fcm_tokens (
    id INT PRIMARY KEY AUTO_INCREMENT,
    user_id INT NOT NULL,
    fcm_token VARCHAR(500) NOT NULL,
    device_type ENUM('ios', 'android', 'web') NOT NULL,
    device_name VARCHAR(100) NULL,

    is_active TINYINT(1) DEFAULT 1,
    last_used_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    UNIQUE KEY unique_token (fcm_token)
);

CREATE INDEX idx_user_active ON user_fcm_tokens(user_id, is_active);
```

---

## 🔥 Sending Notifications via Firebase

### 1. Firebase Admin SDK Setup

#### Node.js / Express:

```javascript
const admin = require("firebase-admin");
const serviceAccount = require("./firebase-service-account.json");

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
});
```

#### PHP:

```php
use Kreait\Firebase\Factory;
use Kreait\Firebase\Messaging\CloudMessage;

$factory = (new Factory)
    ->withServiceAccount('path/to/firebase-credentials.json');

$messaging = $factory->createMessaging();
```

### 2. Send Notification Function

#### Node.js:

```javascript
async function sendNotificationToUser(userId, notificationData) {
  try {
    // 1. Get user's FCM tokens
    const tokens = await getUserFCMTokens(userId);

    if (tokens.length === 0) {
      console.log(`No FCM tokens found for user ${userId}`);
      return;
    }

    // 2. Prepare notification message
    const message = {
      notification: {
        title: notificationData.title,
        body: notificationData.body,
        imageUrl: notificationData.image_url || null,
      },
      data: {
        category: notificationData.category,
        notification_id: notificationData.id.toString(),
        ...notificationData.custom_data,
      },
      android: {
        priority: "high",
        notification: {
          channelId: "high_importance_channel",
          sound: "default",
          clickAction: "FLUTTER_NOTIFICATION_CLICK",
        },
      },
      apns: {
        payload: {
          aps: {
            alert: {
              title: notificationData.title,
              body: notificationData.body,
            },
            sound: "default",
            badge: await getUnreadCount(userId),
          },
        },
      },
    };

    // 3. Send to all devices
    const results = await Promise.all(
      tokens.map((token) =>
        admin.messaging().send({
          ...message,
          token: token,
        })
      )
    );

    // 4. Track results
    results.forEach((result, index) => {
      if (result.success) {
        console.log(`✅ Sent to ${tokens[index]}`);
      } else {
        console.log(`❌ Failed to ${tokens[index]}: ${result.error}`);
        // Delete token if invalid
        if (
          result.error.code === "messaging/invalid-registration-token" ||
          result.error.code === "messaging/registration-token-not-registered"
        ) {
          deleteInvalidToken(tokens[index]);
        }
      }
    });

    return results;
  } catch (error) {
    console.error("Error sending notification:", error);
    throw error;
  }
}

// Helper function to get tokens
async function getUserFCMTokens(userId) {
  const result = await db.query(
    "SELECT fcm_token FROM user_fcm_tokens WHERE user_id = ? AND is_active = 1",
    [userId]
  );
  return result.map((row) => row.fcm_token);
}

// Function to calculate unread notifications
async function getUnreadCount(userId) {
  const result = await db.query(
    "SELECT COUNT(*) as count FROM notification_recipients WHERE user_id = ? AND is_read = 0",
    [userId]
  );
  return result[0].count;
}
```

#### PHP (Laravel):

```php
<?php

namespace App\Services;

use Kreait\Firebase\Messaging\CloudMessage;
use Kreait\Firebase\Messaging\Notification as FirebaseNotification;
use App\Models\UserFcmToken;

class NotificationService
{
    protected $messaging;

    public function __construct()
    {
        $factory = (new \Kreait\Firebase\Factory)
            ->withServiceAccount(config('firebase.credentials'));
        $this->messaging = $factory->createMessaging();
    }

    public function sendToUser($userId, $notificationData)
    {
        // 1. Get FCM tokens
        $tokens = UserFcmToken::where('user_id', $userId)
            ->where('is_active', 1)
            ->pluck('fcm_token')
            ->toArray();

        if (empty($tokens)) {
            \Log::info("No FCM tokens for user: {$userId}");
            return;
        }

        // 2. Prepare notification
        $notification = FirebaseNotification::create(
            $notificationData['title'],
            $notificationData['body']
        );

        if (isset($notificationData['image_url'])) {
            $notification = $notification->withImageUrl($notificationData['image_url']);
        }

        // 3. Additional data
        $data = [
            'category' => $notificationData['category'] ?? 'notification',
            'notification_id' => (string) $notificationData['id'],
        ];

        // 4. Send to each token
        foreach ($tokens as $token) {
            try {
                $message = CloudMessage::withTarget('token', $token)
                    ->withNotification($notification)
                    ->withData($data)
                    ->withAndroidConfig([
                        'priority' => 'high',
                        'notification' => [
                            'channel_id' => 'high_importance_channel',
                            'sound' => 'default',
                        ]
                    ])
                    ->withApnsConfig([
                        'payload' => [
                            'aps' => [
                                'sound' => 'default',
                                'badge' => $this->getUnreadCount($userId),
                            ]
                        ]
                    ]);

                $this->messaging->send($message);
                \Log::info("✅ Sent to token: {$token}");

            } catch (\Exception $e) {
                \Log::error("❌ Failed to send to {$token}: " . $e->getMessage());

                // Delete invalid token
                if (str_contains($e->getMessage(), 'invalid-registration-token')) {
                    UserFcmToken::where('fcm_token', $token)->delete();
                }
            }
        }
    }

    private function getUnreadCount($userId)
    {
        return \DB::table('notification_recipients')
            ->where('user_id', $userId)
            ->where('is_read', 0)
            ->count();
    }
}
```

---

## 🔌 Required API Endpoints

### 1. Register FCM Token

```
POST /api/notifications/register-token
Authorization: Bearer {token}

Request Body:
{
  "fcm_token": "fXXXXXXXXXXXXXXX...",
  "device_type": "android",  // "ios" or "android"
  "device_name": "Samsung Galaxy S21"
}

Response:
{
  "success": true,
  "message": "Token registered successfully"
}
```

**Implementation (PHP/Laravel):**

```php
public function registerToken(Request $request)
{
    $validated = $request->validate([
        'fcm_token' => 'required|string|max:500',
        'device_type' => 'required|in:ios,android,web',
        'device_name' => 'nullable|string|max:100'
    ]);

    UserFcmToken::updateOrCreate(
        [
            'user_id' => auth()->id(),
            'fcm_token' => $validated['fcm_token']
        ],
        [
            'device_type' => $validated['device_type'],
            'device_name' => $validated['device_name'] ?? null,
            'is_active' => 1,
            'last_used_at' => now()
        ]
    );

    return response()->json([
        'success' => true,
        'message' => 'Token registered successfully'
    ]);
}
```

### 2. Retrieve Notifications

```
GET /api/notifications
Authorization: Bearer {token}

Query Parameters:
- page: 1
- per_page: 20
- category: "notification" | "announcement" | "circular" | "all"
- unread_only: true | false

Response:
{
  "success": true,
  "data": {
    "notifications": [
      {
        "id": 123,
        "title": "New Leave Approval",
        "body": "Your leave request has been approved",
        "image_url": null,
        "category": "notification",
        "data": {},
        "is_read": false,
        "read_at": null,
        "created_at": "2026-01-14T10:30:00Z"
      }
    ],
    "unread_count": 5,
    "pagination": {
      "current_page": 1,
      "per_page": 20,
      "total": 45,
      "last_page": 3
    }
  }
}
```

**Implementation (PHP/Laravel):**

```php
public function index(Request $request)
{
    $userId = auth()->id();
    $perPage = $request->input('per_page', 20);
    $category = $request->input('category', 'all');
    $unreadOnly = $request->boolean('unread_only');

    $query = DB::table('notifications as n')
        ->join('notification_recipients as nr', 'n.id', '=', 'nr.notification_id')
        ->where('nr.user_id', $userId)
        ->where('n.is_active', 1)
        ->select([
            'n.id',
            'n.title',
            'n.body',
            'n.image_url',
            'n.category',
            'n.data',
            'n.created_at',
            'nr.is_read',
            'nr.read_at'
        ])
        ->orderBy('n.created_at', 'desc');

    // Filter by category
    if ($category !== 'all') {
        $query->where('n.category', $category);
    }

    // Filter unread only
    if ($unreadOnly) {
        $query->where('nr.is_read', 0);
    }

    $notifications = $query->paginate($perPage);

    // Get unread count
    $unreadCount = DB::table('notification_recipients')
        ->where('user_id', $userId)
        ->where('is_read', 0)
        ->count();

    return response()->json([
        'success' => true,
        'data' => [
            'notifications' => $notifications->items(),
            'unread_count' => $unreadCount,
            'pagination' => [
                'current_page' => $notifications->currentPage(),
                'per_page' => $notifications->perPage(),
                'total' => $notifications->total(),
                'last_page' => $notifications->lastPage()
            ]
        ]
    ]);
}
```

### 3. Mark Notification as Read

```
PUT /api/notifications/{id}/read
Authorization: Bearer {token}

Response:
{
  "success": true,
  "message": "Notification marked as read"
}
```

**Implementation:**

```php
public function markAsRead($notificationId)
{
    $updated = DB::table('notification_recipients')
        ->where('notification_id', $notificationId)
        ->where('user_id', auth()->id())
        ->update([
            'is_read' => 1,
            'read_at' => now()
        ]);

    if (!$updated) {
        return response()->json([
            'success' => false,
            'message' => 'Notification not found'
        ], 404);
    }

    return response()->json([
        'success' => true,
        'message' => 'Notification marked as read'
    ]);
}
```

### 4. Mark All Notifications as Read

```
PUT /api/notifications/read-all
Authorization: Bearer {token}

Response:
{
  "success": true,
  "message": "All notifications marked as read",
  "count": 5
}
```

**Implementation:**

```php
public function markAllAsRead()
{
    $count = DB::table('notification_recipients')
        ->where('user_id', auth()->id())
        ->where('is_read', 0)
        ->update([
            'is_read' => 1,
            'read_at' => now()
        ]);

    return response()->json([
        'success' => true,
        'message' => 'All notifications marked as read',
        'count' => $count
    ]);
}
```

### 5. Delete Notification

```
DELETE /api/notifications/{id}
Authorization: Bearer {token}

Response:
{
  "success": true,
  "message": "Notification deleted"
}
```

**Implementation:**

```php
public function destroy($notificationId)
{
    $deleted = DB::table('notification_recipients')
        ->where('notification_id', $notificationId)
        ->where('user_id', auth()->id())
        ->delete();

    if (!$deleted) {
        return response()->json([
            'success' => false,
            'message' => 'Notification not found'
        ], 404);
    }

    return response()->json([
        'success' => true,
        'message' => 'Notification deleted'
    ]);
}
```

### 6. Unread Notifications Count

```
GET /api/notifications/unread-count
Authorization: Bearer {token}

Response:
{
  "success": true,
  "unread_count": 5
}
```

### 7. Send Notification (Admin Only)

```
POST /api/admin/notifications/send
Authorization: Bearer {admin_token}

Request Body:
{
  "title": "System Maintenance",
  "body": "The system will be down for maintenance on...",
  "category": "announcement",
  "image_url": "https://...",
  "target_type": "all",  // or "specific_users", "department", "role"
  "target_ids": [1, 2, 3],  // if specific_users
  "data": {
    "action": "open_page",
    "page": "maintenance"
  },
  "priority": "high",
  "scheduled_at": "2026-01-15T10:00:00Z"  // optional
}

Response:
{
  "success": true,
  "notification_id": 456,
  "recipients_count": 150,
  "message": "Notification sent successfully"
}
```

**Implementation:**

```php
public function sendNotification(Request $request)
{
    $validated = $request->validate([
        'title' => 'required|string|max:255',
        'body' => 'required|string',
        'category' => 'required|in:notification,announcement,circular',
        'image_url' => 'nullable|url',
        'target_type' => 'required|in:all,specific_users,department,role',
        'target_ids' => 'required_if:target_type,specific_users|array',
        'data' => 'nullable|array',
        'priority' => 'nullable|in:high,normal,low',
        'scheduled_at' => 'nullable|date'
    ]);

    // 1. Create notification in database
    $notificationId = DB::table('notifications')->insertGetId([
        'title' => $validated['title'],
        'body' => $validated['body'],
        'image_url' => $validated['image_url'] ?? null,
        'category' => $validated['category'],
        'target_type' => $validated['target_type'],
        'data' => json_encode($validated['data'] ?? []),
        'priority' => $validated['priority'] ?? 'normal',
        'scheduled_at' => $validated['scheduled_at'] ?? null,
        'sent_by' => auth()->id(),
        'created_at' => now()
    ]);

    // 2. Get target users
    $userIds = $this->getTargetUsers($validated['target_type'], $validated['target_ids'] ?? []);

    // 3. Add recipients
    $recipients = array_map(function($userId) use ($notificationId) {
        return [
            'notification_id' => $notificationId,
            'user_id' => $userId,
            'created_at' => now()
        ];
    }, $userIds);

    DB::table('notification_recipients')->insert($recipients);

    // 4. Send via FCM
    $notificationData = [
        'id' => $notificationId,
        'title' => $validated['title'],
        'body' => $validated['body'],
        'image_url' => $validated['image_url'] ?? null,
        'category' => $validated['category'],
        'custom_data' => $validated['data'] ?? []
    ];

    $notificationService = new NotificationService();

    foreach ($userIds as $userId) {
        $notificationService->sendToUser($userId, $notificationData);
    }

    return response()->json([
        'success' => true,
        'notification_id' => $notificationId,
        'recipients_count' => count($userIds),
        'message' => 'Notification sent successfully'
    ]);
}

private function getTargetUsers($targetType, $targetIds)
{
    switch ($targetType) {
        case 'all':
            return User::pluck('id')->toArray();

        case 'specific_users':
            return $targetIds;

        case 'department':
            return User::whereIn('department_id', $targetIds)->pluck('id')->toArray();

        case 'role':
            return User::whereIn('role_id', $targetIds)->pluck('id')->toArray();

        default:
            return [];
    }
}
```

---

## 🔐 Security and Permissions

### 1. Authentication Middleware

```php
// routes/api.php
Route::middleware(['auth:sanctum'])->group(function () {
    Route::post('/notifications/register-token', [NotificationController::class, 'registerToken']);
    Route::get('/notifications', [NotificationController::class, 'index']);
    Route::put('/notifications/{id}/read', [NotificationController::class, 'markAsRead']);
    Route::put('/notifications/read-all', [NotificationController::class, 'markAllAsRead']);
    Route::delete('/notifications/{id}', [NotificationController::class, 'destroy']);
});

// Admin only
Route::middleware(['auth:sanctum', 'admin'])->group(function () {
    Route::post('/admin/notifications/send', [AdminNotificationController::class, 'sendNotification']);
});
```

### 2. Rate Limiting

```php
// app/Http/Kernel.php
protected $middlewareGroups = [
    'api' => [
        'throttle:60,1', // 60 requests per minute
        \Illuminate\Routing\Middleware\SubstituteBindings::class,
    ],
];
```

### 3. Permission Verification

```php
public function markAsRead($notificationId)
{
    // Ensure notification belongs to current user
    $exists = DB::table('notification_recipients')
        ->where('notification_id', $notificationId)
        ->where('user_id', auth()->id())
        ->exists();

    if (!$exists) {
        return response()->json([
            'success' => false,
            'message' => 'Unauthorized'
        ], 403);
    }

    // ...
}
```

---

## 📱 Flutter Integration

### 1. Create API Service

```dart
// lib/data/services/notification_api_service.dart
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:el_race/core/utils/shared_pref.dart';

class NotificationApiService {
  static const String baseUrl = 'https://your-api.com/api';

  // Register FCM Token
  static Future<bool> registerFCMToken(String fcmToken) async {
    try {
      final token = SharedPref.getLoginData().result?.token;

      final response = await http.post(
        Uri.parse('$baseUrl/notifications/register-token'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'fcm_token': fcmToken,
          'device_type': Platform.isIOS ? 'ios' : 'android',
          'device_name': await _getDeviceName(),
        }),
      );

      return response.statusCode == 200;
    } catch (e) {
      print('❌ Error registering FCM token: $e');
      return false;
    }
  }

  // Retrieve notifications
  static Future<Map<String, dynamic>> getNotifications({
    int page = 1,
    int perPage = 20,
    String category = 'all',
    bool unreadOnly = false,
  }) async {
    try {
      final token = SharedPref.getLoginData().result?.token;

      final response = await http.get(
        Uri.parse('$baseUrl/notifications?page=$page&per_page=$perPage&category=$category&unread_only=$unreadOnly'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return {};
    } catch (e) {
      print('❌ Error fetching notifications: $e');
      return {};
    }
  }

  // Mark as read
  static Future<bool> markAsRead(int notificationId) async {
    try {
      final token = SharedPref.getLoginData().result?.token;

      final response = await http.put(
        Uri.parse('$baseUrl/notifications/$notificationId/read'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      return response.statusCode == 200;
    } catch (e) {
      print('❌ Error marking as read: $e');
      return false;
    }
  }

  // Get unread count
  static Future<int> getUnreadCount() async {
    try {
      final token = SharedPref.getLoginData().result?.token;

      final response = await http.get(
        Uri.parse('$baseUrl/notifications/unread-count'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['unread_count'] ?? 0;
      }
      return 0;
    } catch (e) {
      print('❌ Error getting unread count: $e');
      return 0;
    }
  }
}
```

### 2. Update FirebaseService

```dart
// lib/firebase_service.dart
static Future<void> initialize() async {
  // ... existing code ...

  // After getting FCM token
  String? token = await _firebaseMessaging.getToken();
  if (token != null) {
    SharedPref().setPreferencesString(fcm_token, token);

    // ✅ Register token in backend
    await NotificationApiService.registerFCMToken(token);
  }

  // On token refresh
  FirebaseMessaging.instance.onTokenRefresh.listen((newToken) async {
    SharedPref().setPreferencesString(fcm_token, newToken);

    // ✅ Register new token in backend
    await NotificationApiService.registerFCMToken(newToken);
  });
}
```

### 3. Hybrid Storage (API + Local)

```dart
// lib/core/services/notification_hybrid_service.dart
class NotificationHybridService {
  // Fetch from API and store locally
  static Future<void> syncNotifications() async {
    try {
      // 1. Request from API
      final apiData = await NotificationApiService.getNotifications();
      final notifications = apiData['data']?['notifications'] ?? [];

      // 2. Store locally for cache
      for (var notification in notifications) {
        await NotificationStorageService.saveNotification(
          title: notification['title'],
          body: notification['body'],
          imageUrl: notification['image_url'],
          category: notification['category'],
          data: notification['data'],
        );
      }

      print('✅ Synced ${notifications.length} notifications');
    } catch (e) {
      print('❌ Sync error: $e');
    }
  }

  // Display from local with background sync
  static Future<List<Map<String, dynamic>>> getNotifications() async {
    // 1. Display from local immediately
    final localNotifications = await NotificationStorageService.getNotifications();

    // 2. Sync in background
    syncNotifications();

    return localNotifications;
  }

  // Update badge from API
  static Future<int> getUnreadCount() async {
    try {
      return await NotificationApiService.getUnreadCount();
    } catch (e) {
      // Fallback to local
      return await NotificationStorageService.getUnreadCount();
    }
  }
}
```

---

## 📊 Advanced Additional Features

### 1. Scheduled Notifications

```php
// Schedule a notification for later
$notification = Notification::create([...]);
$notification->scheduled_at = Carbon::parse('2026-01-15 10:00:00');
$notification->save();

// Cron job to send scheduled notifications
// In Console/Kernel.php
$schedule->call(function () {
    $notifications = Notification::where('scheduled_at', '<=', now())
        ->where('is_sent', false)
        ->get();

    foreach ($notifications as $notification) {
        // Send notification
        $service = new NotificationService();
        $recipients = $notification->recipients()->pluck('user_id');

        foreach ($recipients as $userId) {
            $service->sendToUser($userId, $notification->toArray());
        }

        $notification->is_sent = true;
        $notification->save();
    }
})->everyMinute();
```

### 2. Statistics and Analytics

```php
// Dashboard statistics
public function getStatistics()
{
    $stats = [
        'total_sent' => Notification::count(),
        'total_delivered' => NotificationRecipient::where('is_delivered', 1)->count(),
        'total_read' => NotificationRecipient::where('is_read', 1)->count(),
        'delivery_rate' => 0,
        'read_rate' => 0,
        'by_category' => [],
    ];

    $totalRecipients = NotificationRecipient::count();
    if ($totalRecipients > 0) {
        $stats['delivery_rate'] = ($stats['total_delivered'] / $totalRecipients) * 100;
        $stats['read_rate'] = ($stats['total_read'] / $totalRecipients) * 100;
    }

    $stats['by_category'] = DB::table('notifications')
        ->select('category', DB::raw('COUNT(*) as count'))
        ->groupBy('category')
        ->get();

    return response()->json($stats);
}
```

### 3. Notification Templates

```php
// Pre-defined templates
$templates = [
    'leave_approved' => [
        'title' => 'Leave Request Approved',
        'body' => 'Your leave request from {start_date} to {end_date} has been approved.',
        'category' => 'notification'
    ],
    'attendance_reminder' => [
        'title' => 'Attendance Reminder',
        'body' => 'Please remember to check in before {time}.',
        'category' => 'notification'
    ]
];

// Usage
public function sendTemplateNotification($userId, $templateKey, $variables)
{
    $template = $templates[$templateKey];

    // Replace variables
    $body = $template['body'];
    foreach ($variables as $key => $value) {
        $body = str_replace("{{$key}}", $value, $body);
    }

    return $this->sendNotification([
        'title' => $template['title'],
        'body' => $body,
        'category' => $template['category'],
        'target_type' => 'specific_users',
        'target_ids' => [$userId]
    ]);
}
```

---

## 🎯 Summary

### Complete Workflow:

1. **Backend sends notification**
   - Stores in database
   - Sends via FCM to all user devices
2. **Flutter receives notification**
   - Stores locally in SharedPreferences (cache)
   - Updates badge immediately
3. **User opens notifications**
   - Displays from local (fast)
   - Requests from API in background (sync)
   - Updates read status in backend
4. **Cross-device synchronization**
   - All devices receive same notification
   - Read status syncs via API

### When to use what:

- **SharedPreferences only:** Simple apps, temporary notifications
- **API only:** Apps requiring permanent sync
- **Hybrid (Best):** Speed + Sync + Offline Support

---

**📝 Note:** This guide covers everything needed to develop a complete notification system!
