package com.creativehub.rewardsapp

import android.app.NotificationChannel
import android.app.NotificationManager
import android.os.Build
import io.flutter.embedding.android.FlutterActivity

class MainActivity : FlutterActivity() {
    override fun onCreate(savedInstanceState: android.os.Bundle?) {
        super.onCreate(savedInstanceState)
        createWinnerAnnouncementsChannel()
    }

    // Must exist with IMPORTANCE_HIGH before any FCM "notification" message
    // arrives while the app is backgrounded/terminated -- there's no Dart
    // code running in that case to create it on demand, and Firebase's own
    // lazy auto-creation (from the default_notification_channel_id manifest
    // meta-data alone) would default to IMPORTANCE_DEFAULT, not HIGH.
    // Creating an already-existing channel is a safe no-op, so this runs
    // unconditionally on every launch rather than tracking "first run."
    private fun createWinnerAnnouncementsChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                "winner_announcements",
                "Winner Announcements",
                NotificationManager.IMPORTANCE_HIGH,
            ).apply {
                description = "Notifies you when you've won a giveaway"
            }
            val manager = getSystemService(NotificationManager::class.java)
            manager?.createNotificationChannel(channel)
        }
    }
}
