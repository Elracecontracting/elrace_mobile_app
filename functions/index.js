const { onDocumentCreated } = require("firebase-functions/v2/firestore");
const { initializeApp } = require("firebase-admin/app");
const { getFirestore } = require("firebase-admin/firestore");
const { getMessaging } = require("firebase-admin/messaging");

initializeApp();

const db = getFirestore();
const messaging = getMessaging();

/**
 * Cloud Function: Send push notification when a new chat message is created.
 *
 * Triggers on: chats/{chatId}/messages/{messageId}
 *
 * For each member of the chat (except the sender):
 *   1. Look up their FCM tokens from users/{uid}/fcm_tokens
 *   2. Send a push notification with the message preview
 *   3. Include chat metadata in the data payload for navigation
 */
exports.onNewChatMessage = onDocumentCreated(
  "chats/{chatId}/messages/{messageId}",
  async (event) => {
    const snap = event.data;
    if (!snap) return;

    const messageData = snap.data();
    const chatId = event.params.chatId;
    const senderId = messageData.sender_id;

    if (!senderId) {
      console.log("No sender_id in message, skipping");
      return;
    }

    // Get chat document to find members and chat info
    const chatDoc = await db.collection("chats").doc(chatId).get();
    if (!chatDoc.exists) {
      console.log(`Chat ${chatId} not found`);
      return;
    }

    const chatData = chatDoc.data();
    const memberIds = chatData.member_ids || [];
    const chatType = chatData.type || "dm";

    // Get sender name for notification title
    let senderName = "Someone";
    try {
      const senderDoc = await db.collection("users").doc(senderId).get();
      if (senderDoc.exists) {
        senderName = senderDoc.data().name || senderDoc.data().display_name || "Someone";
      }
    } catch (e) {
      console.log(`Could not get sender name: ${e}`);
    }

    // Build notification content
    const title = chatType === "dm"
      ? senderName
      : `${chatData.title || "Group"} • ${senderName}`;

    let body = "";
    switch (messageData.type) {
      case "text":
        body = messageData.text || "";
        break;
      case "image":
        body = "📷 Photo";
        break;
      case "file":
        body = "📎 File";
        break;
      case "audio":
        body = "🎵 Voice message";
        break;
      case "video":
        body = "🎬 Video";
        break;
      default:
        body = "New message";
    }

    // Collect FCM tokens for all members except sender
    const tokens = [];
    for (const memberId of memberIds) {
      if (memberId === senderId) continue; // Don't notify sender

      try {
        const tokensSnap = await db
          .collection("users")
          .doc(memberId)
          .collection("fcm_tokens")
          .get();

        tokensSnap.forEach((tokenDoc) => {
          tokens.push({
            token: tokenDoc.id,
            uid: memberId,
          });
        });
      } catch (e) {
        console.log(`Could not get tokens for ${memberId}: ${e}`);
      }
    }

    if (tokens.length === 0) {
      console.log("No FCM tokens found for recipients");
      return;
    }

    console.log(`Sending to ${tokens.length} token(s) for chat ${chatId}`);

    // Build the chat title for the recipient
    // For DM, the title should be the sender's name
    const chatTitle = chatType === "dm" ? senderName : (chatData.title || "Chat");

    // Send notifications
    const messages = tokens.map((t) => ({
      token: t.token,
      notification: {
        title: title,
        body: body,
      },
      data: {
        type: "chat_message",
        category: "chat_message",
        chat_id: chatId,
        chat_title: chatTitle,
        chat_type: chatType,
        sender_id: senderId,
        sender_name: senderName,
        message_type: messageData.type || "text",
        click_action: "FLUTTER_NOTIFICATION_CLICK",
      },
      android: {
        priority: "high",
        notification: {
          channelId: "chat_messages",
          priority: "high",
          defaultSound: true,
          defaultVibrateTimings: true,
        },
      },
      apns: {
        payload: {
          aps: {
            alert: {
              title: title,
              body: body,
            },
            badge: 1,
            sound: "default",
            "mutable-content": 1,
            "content-available": 1,
          },
        },
      },
    }));

    // Send all notifications (handle failures gracefully)
    const results = await Promise.allSettled(
      messages.map((msg) => messaging.send(msg))
    );

    let successCount = 0;
    let failCount = 0;
    const tokensToRemove = [];

    results.forEach((result, index) => {
      if (result.status === "fulfilled") {
        successCount++;
      } else {
        failCount++;
        const error = result.reason;
        // Remove invalid tokens
        if (
          error?.code === "messaging/invalid-registration-token" ||
          error?.code === "messaging/registration-token-not-registered"
        ) {
          tokensToRemove.push(tokens[index]);
        }
      }
    });

    // Clean up invalid tokens
    if (tokensToRemove.length > 0) {
      const batch = db.batch();
      for (const t of tokensToRemove) {
        batch.delete(
          db.collection("users").doc(t.uid).collection("fcm_tokens").doc(t.token)
        );
      }
      await batch.commit();
      console.log(`Removed ${tokensToRemove.length} invalid token(s)`);
    }

    console.log(
      `Notifications sent: ${successCount} success, ${failCount} failed`
    );
  }
);
