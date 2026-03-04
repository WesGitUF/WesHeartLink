package com.example.heart_link_app

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent

class WorkoutActionReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent?) {
        val action = intent?.action ?: return

        val svcIntent = Intent(context, WorkoutForegroundService::class.java).apply {
            this.action = action
        }

        // Start service so it can process the action and update notification
        if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.O) {
            context.startForegroundService(svcIntent)
        } else {
            context.startService(svcIntent)
        }
    }
}