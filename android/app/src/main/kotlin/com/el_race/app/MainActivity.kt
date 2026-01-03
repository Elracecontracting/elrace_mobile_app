package com.el_race.app

import android.app.NotificationChannel
import android.app.NotificationManager
import android.content.Intent
import android.os.Build
import android.os.Bundle
import io.flutter.embedding.android.FlutterFragmentActivity

class MainActivity : FlutterFragmentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        
        // Create notification channels for Android 8.0+
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val notificationManager: NotificationManager =
                getSystemService(NOTIFICATION_SERVICE) as NotificationManager
            
            // High importance channel for general notifications
            val highChannel = NotificationChannel(
                "high_importance_channel",
                "High Importance Notifications",
                NotificationManager.IMPORTANCE_HIGH
            ).apply {
                description = "This channel is used for important notifications"
                enableLights(true)
                enableVibration(true)
            }
            notificationManager.createNotificationChannel(highChannel)
            
            // Prayer Adhan channel with maximum importance
            val adhanChannel = NotificationChannel(
                "prayer_adhan_channel",
                "Prayer Adhan",
                NotificationManager.IMPORTANCE_HIGH
            ).apply {
                description = "Notifications for prayer adhan times"
                enableLights(true)
                enableVibration(true)
                setSound(null, null) // Sound handled by AudioPlayer
                setShowBadge(true)
            }
            notificationManager.createNotificationChannel(adhanChannel)
        }
    }
    
    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent) // Important: update the activity's intent
        // Flutter will handle the notification through its listeners
    }
}