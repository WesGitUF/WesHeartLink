package com.example.heart_link_app

import android.app.*
import android.content.Context
import android.content.Intent
import android.os.Build
import android.os.IBinder
import androidx.core.app.NotificationCompat

class WorkoutForegroundService : Service() {

    companion object {
        const val CHANNEL_ID = "workout_tracking_channel"
        const val NOTIF_ID = 1001

        const val ACTION_START = "ACTION_START_WORKOUT"
        const val ACTION_STOP = "ACTION_STOP_WORKOUT"
        //const val ACTION_END_FROM_NOTIFICATION = "ACTION_END_FROM_NOTIFICATION"

        const val EXTRA_TITLE = "EXTRA_TITLE"
        const val EXTRA_TEXT = "EXTRA_TEXT"

        const val ACTION_REQUEST_END = "ACTION_REQUEST_END"
        const val ACTION_CONFIRM_END = "ACTION_CONFIRM_END"
        const val ACTION_CANCEL_END = "ACTION_CANCEL_END"

        fun start(context: Context, title: String, text: String) {
            val i = Intent(context, WorkoutForegroundService::class.java).apply {
                action = ACTION_START
                putExtra(EXTRA_TITLE, title)
                putExtra(EXTRA_TEXT, text)
            }
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                context.startForegroundService(i)
            } else {
                context.startService(i)
            }
        }

        fun stop(context: Context) {
            val i = Intent(context, WorkoutForegroundService::class.java).apply {
                action = ACTION_STOP
            }
            context.startService(i)
        }
    }

    override fun onBind(intent: Intent?): IBinder? = null

    private var awaitingEndConfirm: Boolean = false
    private var lastTitle: String = "Workout in progress"
    private var lastText: String = "Tracking in background"

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        when (intent?.action) {
            ACTION_START -> {
                lastTitle = intent.getStringExtra(EXTRA_TITLE) ?: "Workout in progress"
                lastText = intent.getStringExtra(EXTRA_TEXT) ?: "Tracking in background"
                awaitingEndConfirm = false
                startForegroundInternal(lastTitle, lastText)
            }

            ACTION_REQUEST_END -> {
                awaitingEndConfirm = true
                updateNotificationConfirmState()

                android.os.Handler(mainLooper).postDelayed({
                    if (awaitingEndConfirm) {
                        awaitingEndConfirm = false
                        updateNotificationNormalState()
                    }
                }, 8000)
            }

            ACTION_CANCEL_END -> {
                // Cancel: revert to normal ongoing notification
                awaitingEndConfirm = false
                updateNotificationNormalState()
            }

            ACTION_CONFIRM_END -> {
                // Confirm: notify Flutter + stop the service
                WorkoutNotificationBridge.sendEndWorkoutEvent()
                stopForeground(true)
                stopSelf()
            }

            ACTION_STOP -> {
                stopForeground(true)
                stopSelf()
            }

            else -> { /* ignore */ }
        }
        return START_NOT_STICKY
    }

    private fun startForegroundInternal(title: String, text: String) {
        createChannelIfNeeded()

        // Tapping notification will open the app
        val openAppIntent = packageManager.getLaunchIntentForPackage(packageName)
        val contentPendingIntent = PendingIntent.getActivity(
            this,
            0,
            openAppIntent,
            pendingFlags()
        )

        // Action button -> BroadcastReceiver
        val requestEndIntent = Intent(this, WorkoutActionReceiver::class.java).apply {
            action = ACTION_REQUEST_END
        }
        val requestEndPendingIntent = PendingIntent.getBroadcast(
            this,
            1,
            requestEndIntent,
            pendingFlags()
        )

        val notif = NotificationCompat.Builder(this, CHANNEL_ID)
            .setSmallIcon(R.mipmap.ic_launcher)
            .setContentTitle(title)
            .setContentText(text)
            .setOngoing(true) // makes it persistent
            .setOnlyAlertOnce(true)
            .setContentIntent(contentPendingIntent)
            // treat it like a ongoing service notification and show on lock screen
            .setCategory(NotificationCompat.CATEGORY_SERVICE)
            .setVisibility(NotificationCompat.VISIBILITY_PUBLIC)
            .setPriority(NotificationCompat.PRIORITY_LOW)

            .addAction(
                NotificationCompat.Action(
                    0,
                    "End workout",
                    requestEndPendingIntent
                )
            )
            .build()

        startForeground(NOTIF_ID, notif)
    }

    private fun updateNotificationNormalState() {
        createChannelIfNeeded()

        val openAppIntent = packageManager.getLaunchIntentForPackage(packageName)
        val contentPendingIntent = PendingIntent.getActivity(
            this,
            0,
            openAppIntent,
            pendingFlags()
        )

        val requestEndIntent = Intent(this, WorkoutActionReceiver::class.java).apply {
            action = ACTION_REQUEST_END
        }
        val requestEndPendingIntent = PendingIntent.getBroadcast(
            this,
            1,
            requestEndIntent,
            pendingFlags()
        )

        val notif = NotificationCompat.Builder(this, CHANNEL_ID)
            .setSmallIcon(R.mipmap.ic_launcher)
            .setContentTitle(lastTitle)
            .setContentText(lastText)
            .setOngoing(true)
            .setOnlyAlertOnce(true)
            .setContentIntent(contentPendingIntent)
            .setCategory(NotificationCompat.CATEGORY_SERVICE)
            .setVisibility(NotificationCompat.VISIBILITY_PUBLIC)
            .setPriority(NotificationCompat.PRIORITY_LOW)
            .clearActions()
            .addAction(
                NotificationCompat.Action(
                    0,
                    "End workout",
                    requestEndPendingIntent
                )
            )
            .build()

        val nm = getSystemService(NotificationManager::class.java)
        nm.notify(NOTIF_ID, notif)
    }

    private fun updateNotificationConfirmState() {
        createChannelIfNeeded()

        val openAppIntent = packageManager.getLaunchIntentForPackage(packageName)
        val contentPendingIntent = PendingIntent.getActivity(
            this,
            0,
            openAppIntent,
            pendingFlags()
        )

        val confirmIntent = Intent(this, WorkoutActionReceiver::class.java).apply {
            action = ACTION_CONFIRM_END
        }
        val confirmPendingIntent = PendingIntent.getBroadcast(
            this,
            2,
            confirmIntent,
            pendingFlags()
        )

        val cancelIntent = Intent(this, WorkoutActionReceiver::class.java).apply {
            action = ACTION_CANCEL_END
        }
        val cancelPendingIntent = PendingIntent.getBroadcast(
            this,
            3,
            cancelIntent,
            pendingFlags()
        )

        val notif = NotificationCompat.Builder(this, CHANNEL_ID)
            .setSmallIcon(R.mipmap.ic_launcher)
            .setContentTitle("Confirm end?")
            .setContentText("Tap Confirm to end, or Cancel to keep tracking.")
            .setOngoing(true)
            .setOnlyAlertOnce(true)
            .setContentIntent(contentPendingIntent)
            .setCategory(NotificationCompat.CATEGORY_SERVICE)
            .setVisibility(NotificationCompat.VISIBILITY_PUBLIC)
            .setPriority(NotificationCompat.PRIORITY_HIGH)
            .clearActions()
            .addAction(NotificationCompat.Action(0, "Cancel", cancelPendingIntent))
            .addAction(NotificationCompat.Action(0, "Confirm End", confirmPendingIntent))
            .build()

        val nm = getSystemService(NotificationManager::class.java)
        nm.notify(NOTIF_ID, notif)
    }

    private fun createChannelIfNeeded() {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return
        val manager = getSystemService(NotificationManager::class.java)
        val channel = NotificationChannel(
            CHANNEL_ID,
            "Workout Tracking",
            // Use default to make it visible on the lock screen
            NotificationManager.IMPORTANCE_DEFAULT
            // NotificationManager.IMPORTANCE_LOW
        ).apply {
            description = "Shows when a workout is active"
            setSound(null, null)
            enableVibration(false)

            // allow it to show on lock screen
            lockscreenVisibility = Notification.VISIBILITY_PUBLIC
        }
        manager.createNotificationChannel(channel)
    }

    private fun pendingFlags(): Int {
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        } else {
            PendingIntent.FLAG_UPDATE_CURRENT
        }
    }
}