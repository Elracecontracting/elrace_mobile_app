# Firebase Cloud Messaging (FCM) - Backend Integration Guide

## Overview

This document provides the backend team with all necessary information to send push notifications to the mobile app.

---

## 1. FCM Token Registration

### Endpoint: `POST /api/register_fcm_token`

The mobile app will send the FCM token after successful login.

**Request Body:**

```json
{
  "jsonrpc": "2.0",
  "params": {
    "fcm_token": "dXzY1a2B3c4D5e6F7g8H9i0J:APA91b..."
  }
}
```

**Expected Response:**

```json
{
  "result": {
    "status": "success",
    "message": "FCM token registered successfully"
  }
}
```

---

## 2. Sending Push Notifications

### Base URL

```
https://fcm.googleapis.com/fcm/send
```

### Headers Required

```
Content-Type: application/json
Authorization: key=YOUR_SERVER_KEY
```

**Note:** Get the Server Key from Firebase Console → Project Settings → Cloud Messaging → Server key

---

## 3. Notification Payload Structure

### Basic Notification (General)

```json
{
  "to": "DEVICE_FCM_TOKEN",
  "notification": {
    "title": "Leave Approved",
    "body": "Your leave request from Jan 15 to Jan 20 has been approved."
  },
  "data": {
    "category": "notification",
    "type": "leave_approval",
    "request_id": "12345"
  },
  "priority": "high"
}
```

### Announcement Notification

```json
{
  "to": "DEVICE_FCM_TOKEN",
  "notification": {
    "title": "New Project Launch",
    "body": "We are excited to announce the launch of Abu Dhabi Dialysis Center project."
  },
  "data": {
    "category": "announcement",
    "type": "project_announcement",
    "project_id": "67890"
  },
  "priority": "high"
}
```

### Circular Notification

```json
{
  "to": "DEVICE_FCM_TOKEN",
  "notification": {
    "title": "Safety Guidelines Update",
    "body": "Please review the updated safety guidelines for construction sites."
  },
  "data": {
    "category": "circular",
    "type": "policy_update",
    "document_id": "54321"
  },
  "priority": "high"
}
```

---

## 4. Notification Categories

The app supports **3 main categories** of notifications:

| Category       | Description                 | Use Cases                                               |
| -------------- | --------------------------- | ------------------------------------------------------- |
| `notification` | General notifications       | Leave approvals, attendance reminders, task assignments |
| `announcement` | Company announcements       | Project launches, meetings, events                      |
| `circular`     | Official circulars/policies | Safety guidelines, policy updates, regulations          |

**Important:** Always include `"category"` in the `data` object to ensure proper categorization in the app.

---

## 5. Sending to Multiple Devices

### Topic-Based Messaging (Recommended for Broadcasting)

**Subscribe users to topics:**

```json
POST https://iid.googleapis.com/iid/v1/DEVICE_TOKEN/rel/topics/TOPIC_NAME
Authorization: key=YOUR_SERVER_KEY
```

**Send to topic:**

```json
{
  "to": "/topics/all_employees",
  "notification": {
    "title": "Company Meeting",
    "body": "All staff meeting scheduled for tomorrow at 10:00 AM."
  },
  "data": {
    "category": "announcement",
    "type": "meeting"
  },
  "priority": "high"
}
```

### Multiple Specific Devices

```json
{
  "registration_ids": ["DEVICE_TOKEN_1", "DEVICE_TOKEN_2", "DEVICE_TOKEN_3"],
  "notification": {
    "title": "Urgent Notice",
    "body": "Please check your email for important updates."
  },
  "data": {
    "category": "notification",
    "type": "urgent"
  },
  "priority": "high"
}
```

---

## 6. Additional Data Fields

You can include additional custom data that will be available in the app:

```json
{
  "to": "DEVICE_FCM_TOKEN",
  "notification": {
    "title": "Leave Approved",
    "body": "Your leave request has been approved."
  },
  "data": {
    "category": "notification",
    "type": "leave_approval",
    "request_id": "12345",
    "employee_id": "EMP001",
    "start_date": "2025-01-15",
    "end_date": "2025-01-20",
    "approver": "Manager Name",
    "click_action": "OPEN_LEAVE_DETAILS"
  },
  "priority": "high"
}
```

---

## 7. Notification Priority

Use `"priority": "high"` for important notifications that should be delivered immediately even when the device is in low-power mode.

```json
{
  "priority": "high", // or "normal"
  "content_available": true // For iOS background updates
}
```

---

## 8. iOS-Specific Configuration

For iOS devices, include additional sound and badge settings:

```json
{
  "to": "DEVICE_FCM_TOKEN",
  "notification": {
    "title": "New Message",
    "body": "You have a new message",
    "sound": "default",
    "badge": "1"
  },
  "data": {
    "category": "notification"
  },
  "priority": "high",
  "content_available": true
}
```

---

## 9. Testing Notifications

### Using curl

```bash
curl -X POST https://fcm.googleapis.com/fcm/send \
  -H "Content-Type: application/json" \
  -H "Authorization: key=YOUR_SERVER_KEY" \
  -d '{
    "to": "DEVICE_FCM_TOKEN",
    "notification": {
      "title": "Test Notification",
      "body": "This is a test message"
    },
    "data": {
      "category": "notification",
      "type": "test"
    },
    "priority": "high"
  }'
```

### Using Postman

1. Method: `POST`
2. URL: `https://fcm.googleapis.com/fcm/send`
3. Headers:
   - `Content-Type: application/json`
   - `Authorization: key=YOUR_SERVER_KEY`
4. Body: (see payload examples above)

---

## 10. Error Handling

### Common Response Codes

| Code | Description          | Action                                                |
| ---- | -------------------- | ----------------------------------------------------- |
| 200  | Success              | Notification sent successfully                        |
| 400  | Invalid JSON         | Check payload format                                  |
| 401  | Authentication Error | Verify server key                                     |
| 404  | Invalid FCM Token    | Token expired or invalid, request new token from user |

### Error Response Example

```json
{
  "multicast_id": 123456789,
  "success": 0,
  "failure": 1,
  "results": [
    {
      "error": "InvalidRegistration"
    }
  ]
}
```

**Common Errors:**

- `InvalidRegistration`: FCM token is invalid
- `NotRegistered`: Device uninstalled the app or token expired
- `MismatchSenderId`: Wrong server key

---

## 11. Best Practices

### ✅ DO:

- Include `category` in the `data` object
- Use meaningful titles and bodies
- Set appropriate priority
- Store FCM tokens securely in your database
- Update tokens when they change
- Remove invalid tokens from your database

### ❌ DON'T:

- Send sensitive data in notification body (it's visible on lock screen)
- Send too many notifications (respect user experience)
- Forget to handle token refresh
- Use expired or invalid tokens

---

## 12. Database Schema Recommendation

Store FCM tokens in your database:

```sql
CREATE TABLE fcm_tokens (
    id INT PRIMARY KEY AUTO_INCREMENT,
    employee_id INT NOT NULL,
    fcm_token VARCHAR(255) NOT NULL,
    platform VARCHAR(10) NOT NULL, -- 'ios' or 'android'
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    is_active BOOLEAN DEFAULT true,
    FOREIGN KEY (employee_id) REFERENCES employees(id)
);

CREATE INDEX idx_employee_id ON fcm_tokens(employee_id);
CREATE INDEX idx_is_active ON fcm_tokens(is_active);
```

---

## 13. Integration Flow

```
1. User logs into app
   ↓
2. App gets FCM token
   ↓
3. App sends token to backend via /api/register_fcm_token
   ↓
4. Backend stores token in database
   ↓
5. When event occurs (leave approved, new announcement, etc.)
   ↓
6. Backend retrieves relevant FCM tokens
   ↓
7. Backend sends notification via FCM API
   ↓
8. User receives notification
```

---

## 14. Example Backend Implementation (PHP)

```php
<?php
function sendFCMNotification($fcmToken, $title, $body, $category, $additionalData = []) {
    $serverKey = 'YOUR_SERVER_KEY'; // From Firebase Console

    $data = array_merge([
        'category' => $category,
        'timestamp' => date('c')
    ], $additionalData);

    $notification = [
        'to' => $fcmToken,
        'notification' => [
            'title' => $title,
            'body' => $body,
            'sound' => 'default'
        ],
        'data' => $data,
        'priority' => 'high'
    ];

    $ch = curl_init('https://fcm.googleapis.com/fcm/send');
    curl_setopt($ch, CURLOPT_HTTPHEADER, [
        'Content-Type: application/json',
        'Authorization: key=' . $serverKey
    ]);
    curl_setopt($ch, CURLOPT_POST, true);
    curl_setopt($ch, CURLOPT_POSTFIELDS, json_encode($notification));
    curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);

    $response = curl_exec($ch);
    $httpCode = curl_getinfo($ch, CURLINFO_HTTP_CODE);
    curl_close($ch);

    return [
        'success' => $httpCode == 200,
        'response' => json_decode($response, true)
    ];
}

// Usage Examples:

// 1. Leave Approval
sendFCMNotification(
    $userFcmToken,
    'Leave Approved',
    'Your leave request from Jan 15 to Jan 20 has been approved.',
    'notification',
    ['type' => 'leave_approval', 'request_id' => '12345']
);

// 2. Company Announcement
sendFCMNotification(
    $userFcmToken,
    'New Project Launch',
    'We are excited to announce the launch of Abu Dhabi Dialysis Center project.',
    'announcement',
    ['type' => 'project_announcement', 'project_id' => '67890']
);

// 3. Safety Circular
sendFCMNotification(
    $userFcmToken,
    'Safety Guidelines Update',
    'Please review the updated safety guidelines.',
    'circular',
    ['type' => 'policy_update', 'document_id' => '54321']
);
?>
```

---

## 15. Support & Troubleshooting

### Mobile App Storage

- Notifications are stored locally in the app (last 100 notifications)
- Each notification includes: title, body, category, timestamp, read status
- Notifications are marked as read 2 seconds after opening the notification screen

### Badge Count

- Badge count shows unread notifications
- Automatically updates when notifications screen is opened
- Resets when all notifications are read

### Contact

For any questions or issues, contact the mobile development team.

---

**Last Updated:** December 15, 2025
**Version:** 1.0
