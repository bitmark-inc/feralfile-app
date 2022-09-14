package com.bitmark.autonomy_flutter.service

import android.content.Context
import com.bitmark.autonomy_flutter.app.AutonomyApp
import com.onesignal.OSNotificationReceivedEvent
import com.onesignal.OneSignal

class NotificationServiceExtension() : OneSignal.OSRemoteNotificationReceivedHandler {

    companion object {
        private const val FLUTTER_SHARE_PREFS = "FlutterSharedPreferences"
    }

    override fun remoteNotificationReceived(context: Context, event: OSNotificationReceivedEvent) {
        val sharePrefs = context.getSharedPreferences(FLUTTER_SHARE_PREFS, Context.MODE_PRIVATE)
        val isNotificationEnabled = sharePrefs.getBoolean("flutter.notifications", false)
        if (isNotificationEnabled || AutonomyApp.isInForeground) {
            event.complete(event.notification)
        } else {
            event.complete(null)
        }
    }
}