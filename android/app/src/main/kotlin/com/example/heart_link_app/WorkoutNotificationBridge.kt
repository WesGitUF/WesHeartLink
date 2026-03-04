package com.example.heart_link_app

import io.flutter.plugin.common.EventChannel

object WorkoutNotificationBridge {
    private var sink: EventChannel.EventSink? = null

    fun setSink(eventSink: EventChannel.EventSink?) {
        sink = eventSink
    }

    fun sendEndWorkoutEvent() {
        sink?.success(mapOf("action" to "END_WORKOUT"))
    }
}